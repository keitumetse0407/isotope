/**
 * ISOTOPE News Feed Sentiment Adapter
 *
 * Fetches gold-related news from RSS feeds and calculates sentiment scores.
 * Uses simple keyword-based sentiment analysis (no external API required).
 *
 * @module NewsFeedAdapter
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import axios, { AxiosInstance } from 'axios';
import { CircuitBreaker } from '../safety/circuit_breaker.js';
import type { SentimentScore } from '../engine/signal_core.js';

// ============================================
// TYPE DEFINITIONS
// ============================================

export interface NewsArticle {
  readonly title: string;
  readonly link: string;
  readonly pubDate: number;
  readonly source: string;
  readonly sentiment: number; // -1.0 to 1.0
}

export interface NewsFeedConfig {
  readonly feeds: ReadonlyArray<{
    readonly name: string;
    readonly url: string;
    readonly keywords: ReadonlyArray<string>;
  }>;
  readonly timeout: number;
  readonly maxArticles: number;
}

export interface SentimentResult {
  readonly sentiment: SentimentScore;
  readonly articles: NewsArticle[];
  readonly fetchTimeMs: number;
}

// ============================================
// CONSTANTS
// ============================================

const DEFAULT_FEEDS = [
  {
    name: 'reuters',
    url: 'https://feeds.reuters.com/reuters/businessNews',
    keywords: ['gold', 'xau', 'precious metal', 'fed', 'inflation', 'dollar'],
  },
  {
    name: 'kitco',
    url: 'https://www.kitco.com/rss/kitco-news',
    keywords: ['gold', 'silver', 'precious', 'mining', 'bullion'],
  },
];

const DEFAULT_CONFIG: NewsFeedConfig = {
  feeds: DEFAULT_FEEDS,
  timeout: 5000,
  maxArticles: 20,
};

// Sentiment keywords
const POSITIVE_KEYWORDS = [
  'bullish', 'rise', 'gain', 'surge', 'rally', 'jump', 'climb', 'soar',
  'optimistic', 'positive', 'upgrade', 'outperform', 'buy', 'overweight',
  'strong', 'growth', 'recovery', 'boom', 'record high', 'breakout',
];

const NEGATIVE_KEYWORDS = [
  'bearish', 'fall', 'drop', 'plunge', 'decline', 'slump', 'tumble', 'sink',
  'pessimistic', 'negative', 'downgrade', 'underperform', 'sell', 'weak',
  'loss', 'crash', 'correction', 'downturn', 'resistance', 'pressure',
];

// ============================================
// ERROR TYPES
// ============================================

export class NewsFeedError extends Error {
  constructor(
    message: string,
    public readonly source?: string,
    public override readonly cause?: unknown
  ) {
    super(message);
    this.name = 'NewsFeedError';
  }
}

// ============================================
// NEWS FEED ADAPTER
// ============================================

export class NewsFeedAdapter {
  private readonly clients: Map<string, AxiosInstance>;
  private readonly circuitBreakers: Map<string, CircuitBreaker>;
  private readonly config: NewsFeedConfig;
  private lastSentiment: SentimentResult | null = null;

  constructor(options: Partial<NewsFeedConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...options };

    // Create axios instances and circuit breakers for each feed
    this.clients = new Map();
    this.circuitBreakers = new Map();

    for (const feed of this.config.feeds) {
      this.clients.set(
        feed.name,
        axios.create({
          baseURL: feed.url,
          timeout: this.config.timeout,
          headers: {
            'User-Agent': 'ISOTOPE/2.0 (Gold Signal System)',
          },
        })
      );

      this.circuitBreakers.set(
        feed.name,
        new CircuitBreaker(`NewsFeed:${feed.name}`, {
          failureThreshold: 3,
          successThreshold: 2,
          timeout: 120000,
          halfOpenMaxRequests: 2,
        })
      );
    }
  }

  /**
   * Fetch news and calculate sentiment scores
   *
   * @returns Sentiment analysis result with articles
   */
  async fetchSentiment(): Promise<SentimentResult> {
    const startTime = Date.now();
    const allArticles: NewsArticle[] = [];

    // Fetch from all feeds in parallel
    const feedPromises = Array.from(this.config.feeds).map((feed) =>
      this.#fetchFeed(feed).catch((error) => {
        console.warn(`[NewsFeed] Failed to fetch ${feed.name}:`, error.message);
        return [];
      })
    );

    const results = await Promise.all(feedPromises);
    for (const articles of results) {
      allArticles.push(...articles);
    }

    // Sort by date and limit
    allArticles.sort((a, b) => b.pubDate - a.pubDate);
    const limitedArticles = allArticles.slice(0, this.config.maxArticles);

    // Calculate aggregate sentiment
    const sentiment = this.#calculateSentiment(limitedArticles);
    const fetchTimeMs = Date.now() - startTime;

    const result: SentimentResult = {
      sentiment,
      articles: limitedArticles,
      fetchTimeMs,
    };

    this.lastSentiment = result;
    return result;
  }

  /**
   * Get last fetched sentiment result
   */
  getLastSentiment(): SentimentResult | null {
    return this.lastSentiment;
  }

  /**
   * Get circuit breaker stats for all feeds
   */
  getStats(): {
    readonly feeds: Array<{
      readonly name: string;
      readonly circuitBreaker: ReturnType<CircuitBreaker['getStats']>;
    }>;
  } {
    const feeds = Array.from(this.config.feeds).map((feed) => {
      const cb = this.circuitBreakers.get(feed.name);
      return {
        name: feed.name,
        circuitBreaker: cb!.getStats(),
      };
    });

    return { feeds };
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  async #fetchFeed(feed: { name: string; url: string; keywords: readonly string[] }): Promise<NewsArticle[]> {
    const client = this.clients.get(feed.name);
    const circuitBreaker = this.circuitBreakers.get(feed.name);

    if (!client || !circuitBreaker) {
      throw new NewsFeedError(`Client not found for feed: ${feed.name}`);
    }

    try {
      const response = await circuitBreaker.execute(async () => {
        return client.get(feed.url, { responseType: 'text' });
      });

      const xml = response.data as string;
      return this.#parseRSS(xml, feed.name, [...feed.keywords]);
    } catch (error) {
      if (error instanceof Error) {
        throw new NewsFeedError(`Failed to fetch ${feed.name}`, feed.name, error);
      }
      throw error;
    }
  }

  #parseRSS(xml: string, source: string, keywords: string[]): NewsArticle[] {
    const articles: NewsArticle[] = [];

    // Simple RSS parsing (handles most standard feeds)
    const items = xml.split('<item>');

    for (let i = 1; i < items.length; i++) {
      const item = items[i];
      if (!item) continue;

      const titleMatch = item.match(/<title>([^<]+)<\/title>/);
      const linkMatch = item.match(/<link>([^<]+)<\/link>/);
      const dateMatch = item.match(/<pubDate>([^<]+)<\/pubDate>/);

      if (!titleMatch || !linkMatch) continue;

      const title = titleMatch[1] || '';
      const link = linkMatch[1] || '';
      const pubDate = dateMatch && dateMatch[1] ? new Date(dateMatch[1]).getTime() : Date.now();

      // Check if article is relevant to gold
      const titleLower = title.toLowerCase();
      const isRelevant = keywords.some((kw) => titleLower.includes(kw));

      if (isRelevant) {
        const sentiment = this.#analyzeArticleSentiment(titleLower);
        articles.push({
          title,
          link,
          pubDate,
          source,
          sentiment,
        });
      }
    }

    return articles;
  }

  #analyzeArticleSentiment(text: string): number {
    let score = 0;
    let matchCount = 0;

    const textLower = text.toLowerCase();

    // Count positive matches
    for (const keyword of POSITIVE_KEYWORDS) {
      if (textLower.includes(keyword)) {
        score += 1;
        matchCount++;
      }
    }

    // Count negative matches
    for (const keyword of NEGATIVE_KEYWORDS) {
      if (textLower.includes(keyword)) {
        score -= 1;
        matchCount++;
      }
    }

    // Normalize to -1.0 to 1.0
    if (matchCount === 0) return 0;
    return Math.max(-1, Math.min(1, score / matchCount));
  }

  #calculateSentiment(articles: NewsArticle[]): SentimentScore {
    if (articles.length === 0) {
      return {
        overall: 0,
        sources: {
          reuters: 0,
          kitco: 0,
          bloomberg: 0,
        },
        timestamp: Date.now(),
      };
    }

    // Calculate overall sentiment (average of all articles)
    const totalSentiment = articles.reduce((sum, article) => sum + article.sentiment, 0);
    const overall = totalSentiment / articles.length;

    // Calculate per-source sentiment
    const sourceSentiments: Record<string, number[]> = {};
    for (const article of articles) {
      if (!sourceSentiments[article.source]) {
        sourceSentiments[article.source] = [];
      }
      sourceSentiments[article.source]!.push(article.sentiment);
    }

    const sources = {
      reuters: this.#average(sourceSentiments['reuters'] || []),
      kitco: this.#average(sourceSentiments['kitco'] || []),
      bloomberg: this.#average(sourceSentiments['bloomberg'] || []),
    };

    return {
      overall,
      sources,
      timestamp: Date.now(),
    };
  }

  #average(values: number[]): number {
    if (values.length === 0) return 0;
    return values.reduce((sum, v) => sum + v, 0) / values.length;
  }
}

// ============================================
// EXPORTS
// ============================================

export default NewsFeedAdapter;
