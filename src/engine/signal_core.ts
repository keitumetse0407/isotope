/**
 * ISOTOPE Signal Core Engine
 * 
 * High-frequency XAU/USD signal processing with <10ms latency target.
 * Implements confluence-based decision engine with 5-factor analysis.
 * 
 * @module SignalCore
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import { EventEmitter } from 'events';
import { performance } from 'perf_hooks';

// ============================================
// TYPE DEFINITIONS
// ============================================

export type Direction = 'BUY' | 'SELL' | 'HOLD';

export type Timeframe = 'M1' | 'M5' | 'M15' | 'H1' | 'H4' | 'D1';

export interface PriceData {
  readonly symbol: 'XAU/USD';
  readonly timestamp: number;
  readonly open: number;
  readonly high: number;
  readonly low: number;
  readonly close: number;
  readonly volume: number;
}

export interface TechnicalIndicators {
  readonly ema9: number;
  readonly ema21: number;
  readonly ema50: number;
  readonly rsi14: number;
  readonly macd: {
    readonly line: number;
    readonly signal: number;
    readonly histogram: number;
  };
  readonly atr14: number;
  readonly bollingerBands: {
    readonly upper: number;
    readonly middle: number;
    readonly lower: number;
    readonly width: number;
  };
}

export interface SentimentScore {
  readonly overall: number; // -1.0 to 1.0
  readonly sources: {
    readonly reuters: number;
    readonly kitco: number;
    readonly bloomberg: number;
  };
  readonly timestamp: number;
}

export interface SupportResistance {
  readonly support: number[];
  readonly resistance: number[];
  readonly pivotPoint: number;
}

export interface Signal {
  readonly id: string;
  readonly direction: Direction;
  readonly entry: number;
  readonly stopLoss: number;
  readonly takeProfit1: number;
  readonly takeProfit2: number;
  readonly confidence: number; // 0.0 - 1.0
  readonly timeframe: Timeframe;
  readonly rationale: string;
  readonly riskReward: number;
  readonly timestamp: number;
  readonly processingLatencyMs: number;
}

export interface SignalFactors {
  readonly trend: { score: number; aligned: boolean };
  readonly momentum: { score: number; rsi: number; macdBullish: boolean };
  readonly volatility: { score: number; atrPercent: number; bbWidth: number };
  readonly structure: { score: number; nearSupport: boolean; nearResistance: boolean };
  readonly sentiment: { score: number; overall: number };
}

export interface SignalResult {
  readonly signal: Signal | null;
  readonly factors: SignalFactors;
  readonly agreementCount: number; // 0-5 factors agreeing
  readonly latencyMs: number;
}

// ============================================
// ERROR TYPES
// ============================================

export class SignalProcessingError extends Error {
  constructor(
    message: string,
    public override readonly cause?: unknown,
    public readonly latencyMs?: number
  ) {
    super(message);
    this.name = 'SignalProcessingError';
  }
}

export class LatencyExceededError extends Error {
  constructor(
    public readonly actualMs: number,
    public readonly targetMs: number
  ) {
    super(`Latency ${actualMs}ms exceeded target ${targetMs}ms`);
    this.name = 'LatencyExceededError';
  }
}

// ============================================
// CONFIGURATION
// ============================================

export interface SignalCoreConfig {
  readonly maxLatencyMs: number;
  readonly minConfidenceThreshold: number;
  readonly minAgreementCount: number; // Minimum factors that must agree
  readonly defaultRiskPercent: number;
  readonly stopLossAtrMultiplier: number;
  readonly takeProfit1AtrMultiplier: number;
  readonly takeProfit2AtrMultiplier: number;
}

const DEFAULT_CONFIG: SignalCoreConfig = {
  maxLatencyMs: 10,
  minConfidenceThreshold: 0.7,
  minAgreementCount: 4, // 4 out of 5 factors must agree
  defaultRiskPercent: 1.0,
  stopLossAtrMultiplier: 1.5,
  takeProfit1AtrMultiplier: 2.25, // 1:1.5 RR
  takeProfit2AtrMultiplier: 4.5,  // 1:3 RR
};

// ============================================
// SIGNAL CORE ENGINE
// ============================================

export class SignalCore extends EventEmitter {
  private readonly config: SignalCoreConfig;
  private signalCount = 0;

  constructor(config: Partial<SignalCoreConfig> = {}) {
    super();
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Process price data and generate trading signal
   *
   * @param price - Current XAU/USD price data
   * @param indicators - Pre-calculated technical indicators
   * @param sentiment - Market sentiment scores
   * @param levels - Support/resistance levels
   * @returns SignalResult with signal (if generated) and analysis factors
   */
  process(
    price: PriceData,
    indicators: TechnicalIndicators,
    sentiment: SentimentScore,
    levels: SupportResistance
  ): SignalResult {
    const startTime = performance.now();

    try {
      // Factor 1: Trend Analysis (EMA alignment)
      const trend = this.analyzeTrend(indicators);

      // Factor 2: Momentum (RSI + MACD)
      const momentum = this.analyzeMomentum(indicators);

      // Factor 3: Volatility (ATR + Bollinger Bands)
      const volatility = this.analyzeVolatility(indicators, price);

      // Factor 4: Structure (Support/Resistance)
      const structure = this.analyzeStructure(price, levels);

      // Factor 5: Sentiment
      const sentimentFactor = this.analyzeSentiment(sentiment);

      // Calculate agreement count and direction
      const factors: SignalFactors = { trend, momentum, volatility, structure, sentiment: sentimentFactor };
      const agreementCount = this.countAgreements(factors);

      // Generate signal if enough factors agree
      let signal: Signal | null = null;

      if (agreementCount >= this.config.minAgreementCount) {
        const direction = this.determineDirection(factors);
        const confidence = this.calculateConfidence(factors, agreementCount);

        if (confidence >= this.config.minConfidenceThreshold) {
          signal = this.buildSignal(direction, price, indicators, levels, confidence, agreementCount, factors);
        }
      }

      const latencyMs = performance.now() - startTime;

      // Emit metrics
      this.emit('processed', { latencyMs, signalGenerated: signal !== null, agreementCount });

      // Check latency budget
      if (latencyMs > this.config.maxLatencyMs) {
        this.emit('latency_warning', { actual: latencyMs, target: this.config.maxLatencyMs });
      }

      return {
        signal,
        factors,
        agreementCount,
        latencyMs,
      };
    } catch (error) {
      const latencyMs = performance.now() - startTime;
      this.emit('error', { error, latencyMs });
      throw new SignalProcessingError(
        `Signal processing failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        error,
        latencyMs
      );
    }
  }

  // ============================================
  // FACTOR ANALYSIS METHODS
  // ============================================

  private analyzeTrend(indicators: TechnicalIndicators): SignalFactors['trend'] {
    const { ema9, ema21, ema50 } = indicators;
    
    // Bullish: EMA9 > EMA21 > EMA50
    // Bearish: EMA9 < EMA21 < EMA50
    const bullishAlignment = ema9 > ema21 && ema21 > ema50;
    const bearishAlignment = ema9 < ema21 && ema21 < ema50;
    
    const score = bullishAlignment ? 1 : bearishAlignment ? -1 : 0;
    const aligned = bullishAlignment || bearishAlignment;

    return { score, aligned };
  }

  private analyzeMomentum(indicators: TechnicalIndicators): SignalFactors['momentum'] {
    const { rsi14, macd } = indicators;
    
    // RSI signals
    const rsiOversold = rsi14 < 30;
    const rsiOverbought = rsi14 > 70;
    const rsiNeutral = rsi14 >= 40 && rsi14 <= 60;
    
    // MACD signals
    const macdBullish = macd.histogram > 0 && macd.line > macd.signal;
    const macdBearish = macd.histogram < 0 && macd.line < macd.signal;
    
    // Calculate momentum score (-1 to 1)
    let score = 0;
    if (rsiOversold && macdBullish) score = 1;
    else if (rsiOverbought && macdBearish) score = -1;
    else if (macdBullish) score = 0.5;
    else if (macdBearish) score = -0.5;
    else if (rsiNeutral) score = 0;

    return {
      score,
      rsi: rsi14,
      macdBullish,
    };
  }

  private analyzeVolatility(indicators: TechnicalIndicators, price: PriceData): SignalFactors['volatility'] {
    const { atr14, bollingerBands } = indicators;
    
    const atrPercent = (atr14 / price.close) * 100;
    const bbWidth = bollingerBands.width;
    
    // High volatility = wider bands, higher ATR
    // Score based on whether volatility supports directional move
    const isExpanding = bbWidth > 0.05; // 5% width threshold
    const score = isExpanding ? 1 : 0.5;

    return {
      score,
      atrPercent,
      bbWidth,
    };
  }

  private analyzeStructure(price: PriceData, levels: SupportResistance): SignalFactors['structure'] {
    const { support, resistance, pivotPoint } = levels;
    const currentPrice = price.close;
    
    // Check proximity to key levels (within 0.5%)
    const nearSupport = support.some(level => Math.abs(currentPrice - level) / level < 0.005);
    const nearResistance = resistance.some(level => Math.abs(currentPrice - level) / level < 0.005);
    const nearPivot = Math.abs(currentPrice - pivotPoint) / pivotPoint < 0.003;
    
    // Score based on position relative to structure
    let score = 0;
    if (nearSupport && !nearResistance) score = 1; // Bullish bounce potential
    else if (nearResistance && !nearSupport) score = -1; // Bearish rejection potential
    else if (nearPivot) score = 0;
    else score = 0.5; // Neutral zone

    return {
      score,
      nearSupport,
      nearResistance,
    };
  }

  private analyzeSentiment(sentiment: SentimentScore): SignalFactors['sentiment'] {
    const { overall } = sentiment;
    
    // Map sentiment (-1 to 1) to score
    const score = overall;
    
    return {
      score,
      overall,
    };
  }

  // ============================================
  // SIGNAL GENERATION HELPERS
  // ============================================

  private countAgreements(factors: SignalFactors): number {
    const scores = [
      factors.trend.score,
      factors.momentum.score,
      factors.volatility.score,
      factors.structure.score,
      factors.sentiment.score,
    ];
    
    // Count factors with strong directional bias (|score| > 0.5)
    return scores.filter(s => Math.abs(s) > 0.5).length;
  }

  private determineDirection(factors: SignalFactors): Direction {
    const totalScore = 
      factors.trend.score +
      factors.momentum.score +
      factors.volatility.score * 0.5 + // Volatility is neutral enabler
      factors.structure.score +
      factors.sentiment.score;
    
    if (totalScore > 1.5) return 'BUY';
    if (totalScore < -1.5) return 'SELL';
    return 'HOLD';
  }

  private calculateConfidence(factors: SignalFactors, agreementCount: number): number {
    const baseConfidence = agreementCount / 5; // 0.0 - 1.0 based on agreement
    
    // Boost confidence if all factors point same direction
    const scores = [
      factors.trend.score,
      factors.momentum.score,
      factors.structure.score,
      factors.sentiment.score,
    ];
    const allSameSign = scores.every(s => s > 0) || scores.every(s => s < 0);
    
    const confidenceBoost = allSameSign ? 0.15 : 0;
    
    return Math.min(baseConfidence + confidenceBoost, 1.0);
  }

  private buildSignal(
    direction: Direction,
    price: PriceData,
    indicators: TechnicalIndicators,
    _levels: SupportResistance,
    confidence: number,
    agreementCount: number,
    factors: SignalFactors
  ): Signal {
    const entry = price.close;
    const atr = indicators.atr14;

    // Calculate stop loss and take profit based on ATR multipliers from config
    const stopLossDistance = atr * this.config.stopLossAtrMultiplier;
    const tp1Distance = atr * this.config.takeProfit1AtrMultiplier;
    const tp2Distance = atr * this.config.takeProfit2AtrMultiplier;

    const stopLoss = direction === 'BUY'
      ? entry - stopLossDistance
      : entry + stopLossDistance;

    const takeProfit1 = direction === 'BUY'
      ? entry + tp1Distance
      : entry - tp1Distance;

    const takeProfit2 = direction === 'BUY'
      ? entry + tp2Distance
      : entry - tp2Distance;

    const riskReward = (takeProfit1 - entry) / (entry - stopLoss);

    this.signalCount++;

    return {
      id: `SIG-${Date.now()}-${this.signalCount}`,
      direction,
      entry,
      stopLoss,
      takeProfit1,
      takeProfit2,
      confidence,
      timeframe: 'H1',
      rationale: this.generateRationale(factors, direction, agreementCount),
      riskReward: Math.abs(riskReward),
      timestamp: Date.now(),
      processingLatencyMs: 0, // Will be set by caller
    };
  }

  private generateRationale(factors: SignalFactors, direction: Direction, agreementCount: number): string {
    const reasons: string[] = [];
    const bias = direction === 'BUY' ? 'bullish' : 'bearish';

    // Trend contribution
    if (factors.trend.aligned) {
      reasons.push(`EMA ${bias} alignment`);
    } else if (factors.trend.score > 0) {
      reasons.push('EMA partial bullish');
    } else if (factors.trend.score < 0) {
      reasons.push('EMA partial bearish');
    }

    // Momentum contribution
    if (factors.momentum.rsi < 30) {
      reasons.push('RSI oversold');
    } else if (factors.momentum.rsi > 70) {
      reasons.push('RSI overbought');
    }
    if (factors.momentum.macdBullish) {
      reasons.push('MACD bullish crossover');
    } else if (!factors.momentum.macdBullish && factors.momentum.score < 0) {
      reasons.push('MACD bearish');
    }

    // Volatility contribution
    if (factors.volatility.bbWidth > 0.05) {
      reasons.push('expanding Bollinger Bands');
    }
    if (factors.volatility.atrPercent > 1) {
      reasons.push(`high volatility (ATR ${factors.volatility.atrPercent.toFixed(1)}%)`);
    }

    // Structure contribution
    if (factors.structure.nearSupport) {
      reasons.push('price near support');
    }
    if (factors.structure.nearResistance) {
      reasons.push('price near resistance');
    }

    // Sentiment contribution
    if (factors.sentiment.overall > 0.3) {
      reasons.push('positive news sentiment');
    } else if (factors.sentiment.overall < -0.3) {
      reasons.push('negative news sentiment');
    }

    const strength = agreementCount >= 5 ? 'Strong' : agreementCount >= 4 ? 'Moderate' : 'Weak';
    return `${strength} ${bias} confluence (${agreementCount}/5): ${reasons.join(' + ') || 'neutral factors'}`;
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /**
   * Get current signal statistics
   */
  getStats(): { totalProcessed: number; config: SignalCoreConfig } {
    return {
      totalProcessed: this.signalCount,
      config: this.config,
    };
  }

  /**
   * Update configuration at runtime
   */
  updateConfig(updates: Partial<SignalCoreConfig>): void {
    Object.assign(this.config, updates);
    this.emit('config_updated', this.config);
  }
}

// ============================================
// EXPORTS
// ============================================

export default SignalCore;
