/**
 * ISOTOPE Alpha Vantage Data Adapter
 *
 * Fetches real-time and historical XAU/USD price data from Alpha Vantage API.
 * Includes circuit breaker protection and automatic retry logic.
 *
 * @module AlphaVantageAdapter
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import { CircuitBreaker, CircuitOpenError } from '../safety/circuit_breaker.js';
import { config } from '../config.js';
import type { PriceData } from '../engine/signal_core.js';

// ============================================
// TYPE DEFINITIONS
// ============================================

export interface AlphaVantageResponse {
  readonly Meta_Data: {
    readonly Symbol: string;
    readonly Last_Refreshed: string;
    readonly Time_Zone: string;
  };
  readonly Time_Series_Daily: {
    [date: string]: {
      readonly '1. open': string;
      readonly '2. high': string;
      readonly '3. low': string;
      readonly '4. close': string;
      readonly '5. volume': string;
    };
  };
}

export interface AlphaVantageConfig {
  readonly apiKey: string;
  readonly baseUrl: string;
  readonly timeout: number;
  readonly symbol: string;
}

export interface FetchResult {
  readonly price: PriceData;
  readonly fetchTimeMs: number;
  readonly source: 'live' | 'cached';
}

// ============================================
// CONSTANTS
// ============================================

const DEFAULT_CONFIG: AlphaVantageConfig = {
  apiKey: config.alphaVantage.apiKey,
  baseUrl: 'https://www.alphavantage.co/query',
  timeout: 5000,
  symbol: 'XAUUSD',
};

const CACHE_TTL_MS = 60000; // Cache price data for 1 minute

// ============================================
// ERROR TYPES
// ============================================

export class AlphaVantageError extends Error {
  constructor(
    message: string,
    public override readonly cause?: unknown,
    public readonly statusCode?: number
  ) {
    super(message);
    this.name = 'AlphaVantageError';
  }
}

// ============================================
// ALPHA VANTAGE ADAPTER
// ============================================

export class AlphaVantageAdapter {
  private readonly client: AxiosInstance;
  private readonly circuitBreaker: CircuitBreaker;
  private readonly config: AlphaVantageConfig;
  private cache: PriceData | null = null;
  private cacheTimestamp: number = 0;

  constructor(options: Partial<AlphaVantageConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...options };

    this.client = axios.create({
      baseURL: this.config.baseUrl,
      timeout: this.config.timeout,
      params: {
        function: 'TIME_SERIES_DAILY',
        symbol: this.config.symbol,
        apikey: this.config.apiKey,
        outputsize: 'compact',
        datatype: 'json',
      },
    });

    this.circuitBreaker = new CircuitBreaker('AlphaVantage', {
      failureThreshold: 5,
      successThreshold: 2,
      timeout: 60000,
      halfOpenMaxRequests: 2,
    });
  }

  /**
   * Fetch current XAU/USD price data
   *
   * @param useCache - Whether to use cached data if available (default: true)
   * @returns Price data with fetch metadata
   * @throws {AlphaVantageError} If fetch fails
   * @throws {CircuitOpenError} If circuit breaker is open
   */
  async fetchPrice(useCache: boolean = true): Promise<FetchResult> {
    // Check cache first
    if (useCache && this.isCacheValid()) {
      return {
        price: this.cache!,
        fetchTimeMs: 0,
        source: 'cached',
      };
    }

    const startTime = Date.now();

    try {
      const price = await this.circuitBreaker.execute<PriceData>(() => this.#doFetch());
      const fetchTimeMs = Date.now() - startTime;

      // Update cache
      this.cache = price;
      this.cacheTimestamp = Date.now();

      return {
        price,
        fetchTimeMs,
        source: 'live',
      };
    } catch (error) {
      // If circuit is open but we have cache, return stale cache
      if (error instanceof CircuitOpenError && this.cache) {
        console.warn('[AlphaVantage] Circuit open, returning cached data');
        return {
          price: this.cache,
          fetchTimeMs: 0,
          source: 'cached',
        };
      }

      throw error;
    }
  }

  /**
   * Get circuit breaker statistics
   */
  getStats(): {
    readonly circuitBreaker: ReturnType<CircuitBreaker['getStats']>;
    readonly cache: { readonly valid: boolean; readonly age: number };
  } {
    return {
      circuitBreaker: this.circuitBreaker.getStats(),
      cache: {
        valid: this.isCacheValid(),
        age: Date.now() - this.cacheTimestamp,
      },
    };
  }

  /**
   * Clear the price cache
   */
  clearCache(): void {
    this.cache = null;
    this.cacheTimestamp = 0;
  }

  /**
   * Force circuit breaker open (for maintenance)
   */
  forceCircuitOpen(): void {
    this.circuitBreaker.forceOpen();
  }

  /**
   * Reset circuit breaker
   */
  resetCircuit(): void {
    this.circuitBreaker.reset();
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  isCacheValid(): boolean {
    if (!this.cache) return false;
    const age = Date.now() - this.cacheTimestamp;
    return age < CACHE_TTL_MS;
  }

  async #doFetch(): Promise<PriceData> {
    try {
      const response = await this.client.get<AlphaVantageResponse>('');
      const data = response.data as unknown as AlphaVantageResponse;

      // Validate response
      if (!data.Time_Series_Daily) {
        throw new AlphaVantageError(
          'Invalid response from Alpha Vantage',
          data,
          response.status
        );
      }

      // Get latest price (first entry in Time_Series_Daily)
      const dates = Object.keys(data.Time_Series_Daily);
      if (dates.length === 0) {
        throw new AlphaVantageError('No price data available');
      }

      const latestDate = dates[0]!;
      const series = data.Time_Series_Daily[latestDate]!;

      const price: PriceData = {
        symbol: 'XAU/USD',
        timestamp: this.#parseTimestamp(latestDate),
        open: this.#parseNumber(series['1. open']),
        high: this.#parseNumber(series['2. high']),
        low: this.#parseNumber(series['3. low']),
        close: this.#parseNumber(series['4. close']),
        volume: this.#parseNumber(series['5. volume']),
      };

      return price;
    } catch (error) {
      if (error instanceof AxiosError) {
        throw new AlphaVantageError(
          `Alpha Vantage request failed: ${error.message}`,
          error.cause,
          error.response?.status
        );
      }
      throw error;
    }
  }

  #parseTimestamp(dateStr: string): number {
    // Alpha Vantage returns "YYYY-MM-DD" format
    const [year, month, day] = dateStr.split('-').map(Number);
    if (!year || !month || !day) {
      throw new AlphaVantageError(`Invalid date format: ${dateStr}`);
    }
    return new Date(year, month - 1, day).getTime();
  }

  #parseNumber(value: string): number {
    const num = parseFloat(value);
    if (isNaN(num)) {
      throw new AlphaVantageError(`Invalid number format: ${value}`);
    }
    return num;
  }
}

// ============================================
// EXPORTS
// ============================================

export default AlphaVantageAdapter;
