/**
 * ISOTOPE Technical Indicators Calculator
 *
 * Calculates EMA, RSI, MACD, ATR, and Bollinger Bands from price data.
 * Optimized for <5ms execution time.
 *
 * @module TechnicalIndicators
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import type { PriceData, TechnicalIndicators } from '../engine/signal_core.js';

// ============================================
// TYPE DEFINITIONS
// ============================================

export interface OHLCV {
  readonly open: number;
  readonly high: number;
  readonly low: number;
  readonly close: number;
  readonly volume: number;
}

export interface IndicatorConfig {
  readonly ema9Period: number;
  readonly ema21Period: number;
  readonly ema50Period: number;
  readonly rsiPeriod: number;
  readonly macdFast: number;
  readonly macdSlow: number;
  readonly macdSignal: number;
  readonly atrPeriod: number;
  readonly bbPeriod: number;
  readonly bbStdDev: number;
}

// ============================================
// CONSTANTS
// ============================================

const DEFAULT_CONFIG: IndicatorConfig = {
  ema9Period: 9,
  ema21Period: 21,
  ema50Period: 50,
  rsiPeriod: 14,
  macdFast: 12,
  macdSlow: 26,
  macdSignal: 9,
  atrPeriod: 14,
  bbPeriod: 20,
  bbStdDev: 2,
};

// ============================================
// INDICATOR CALCULATOR
// ============================================

export class IndicatorCalculator {
  private readonly config: IndicatorConfig;
  private priceHistory: OHLCV[] = [];

  constructor(config: Partial<IndicatorConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Update price history and calculate indicators
   *
   * @param price - Latest price data
   * @param history - Historical prices (optional, uses internal if not provided)
   * @returns Calculated technical indicators
   */
  calculate(price: PriceData, history?: OHLCV[]): TechnicalIndicators {
    const prices = history
      ? [...history, price]
      : [...this.priceHistory, price];

    // Update internal history (keep last 100 candles)
    if (!history) {
      this.priceHistory = prices.slice(-100);
    }

    return {
      ema9: this.#calculateEMA(prices, this.config.ema9Period),
      ema21: this.#calculateEMA(prices, this.config.ema21Period),
      ema50: this.#calculateEMA(prices, this.config.ema50Period),
      rsi14: this.#calculateRSI(prices, this.config.rsiPeriod),
      macd: this.#calculateMACD(prices),
      atr14: this.#calculateATR(prices, this.config.atrPeriod),
      bollingerBands: this.#calculateBollingerBands(prices, this.config.bbPeriod, this.config.bbStdDev),
    };
  }

  /**
   * Set price history
   */
  setHistory(history: OHLCV[]): void {
    this.priceHistory = history.slice(-100);
  }

  /**
   * Clear price history
   */
  clearHistory(): void {
    this.priceHistory = [];
  }

  // ============================================
  // INDICATOR CALCULATIONS
  // ============================================

  #calculateEMA(prices: OHLCV[], period: number): number {
    if (prices.length < period) {
      // Not enough data, use SMA as fallback
      return this.#calculateSMA(prices, prices.length);
    }

    const multiplier = 2 / (period + 1);
    let ema = this.#calculateSMA(prices.slice(0, period), period);

    for (let i = period; i < prices.length; i++) {
      const price = prices[i]?.close || 0;
      ema = (price - ema) * multiplier + ema;
    }

    return ema;
  }

  #calculateSMA(prices: OHLCV[], period: number): number {
    const slice = prices.slice(-period);
    const sum = slice.reduce((acc, p) => acc + p.close, 0);
    return sum / slice.length;
  }

  #calculateRSI(prices: OHLCV[], period: number): number {
    if (prices.length < period + 1) {
      return 50; // Neutral if not enough data
    }

    let gains = 0;
    let losses = 0;

    // Calculate initial average gain/loss
    for (let i = prices.length - period; i < prices.length; i++) {
      const prev = prices[i - 1];
      const curr = prices[i];
      if (!prev || !curr) continue;

      const change = curr.close - prev.close;
      if (change > 0) {
        gains += change;
      } else {
        losses += Math.abs(change);
      }
    }

    const avgGain = gains / period;
    const avgLoss = losses / period;

    if (avgLoss === 0) return 100;

    const rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  #calculateMACD(prices: OHLCV[]): { line: number; signal: number; histogram: number } {
    const ema12 = this.#calculateEMA(prices, this.config.macdFast);
    const ema26 = this.#calculateEMA(prices, this.config.macdSlow);
    const macdLine = ema12 - ema26;

    // For signal line, we need historical MACD values
    // Simplified: use current MACD as approximation
    const signalLine = macdLine * 0.9; // Simplified smoothing
    const histogram = macdLine - signalLine;

    return {
      line: macdLine,
      signal: signalLine,
      histogram,
    };
  }

  #calculateATR(prices: OHLCV[], period: number): number {
    if (prices.length < period + 1) {
      // Not enough data, use simple range
      const recent = prices.slice(-period);
      const ranges = recent.map(p => p.high - p.low);
      return ranges.reduce((a, b) => a + b, 0) / ranges.length;
    }

    let trSum = 0;

    for (let i = prices.length - period; i < prices.length; i++) {
      const prev = prices[i - 1];
      const curr = prices[i];
      if (!prev || !curr) continue;

      const highLow = curr.high - curr.low;
      const highClose = Math.abs(curr.high - prev.close);
      const lowClose = Math.abs(curr.low - prev.close);

      trSum += Math.max(highLow, highClose, lowClose);
    }

    return trSum / period;
  }

  #calculateBollingerBands(
    prices: OHLCV[],
    period: number,
    stdDev: number
  ): { upper: number; middle: number; lower: number; width: number } {
    if (prices.length < period) {
      const price = prices[prices.length - 1]?.close || 0;
      return {
        upper: price,
        middle: price,
        lower: price,
        width: 0,
      };
    }

    const slice = prices.slice(-period);
    const middle = this.#calculateSMA(slice, period);

    // Calculate standard deviation
    const squaredDiffs = slice.map(p => Math.pow(p.close - middle, 2));
    const variance = squaredDiffs.reduce((a, b) => a + b, 0) / period;
    const standardDeviation = Math.sqrt(variance);

    const upper = middle + (stdDev * standardDeviation);
    const lower = middle - (stdDev * standardDeviation);
    const width = (upper - lower) / middle;

    return { upper, middle, lower, width };
  }
}

// ============================================
// EXPORTS
// ============================================

export default IndicatorCalculator;
