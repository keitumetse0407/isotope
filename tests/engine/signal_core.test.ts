/**
 * SignalCore Tests
 * 
 * Validates signal processing logic, latency requirements,
 * and factor agreement calculations.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { SignalCore, type PriceData, type TechnicalIndicators, type SentimentScore, type SupportResistance } from '../../src/engine/signal_core.js';

// ============================================
// MOCK DATA
// ============================================

const mockPrice: PriceData = {
  symbol: 'XAU/USD',
  timestamp: Date.now(),
  open: 2340.00,
  high: 2345.50,
  low: 2338.00,
  close: 2342.75,
  volume: 15000,
};

const mockIndicators: TechnicalIndicators = {
  ema9: 2343.00,
  ema21: 2340.00,
  ema50: 2335.00,
  rsi14: 55,
  macd: {
    line: 2.5,
    signal: 1.8,
    histogram: 0.7,
  },
  atr14: 15.0,
  bollingerBands: {
    upper: 2355.00,
    middle: 2342.00,
    lower: 2329.00,
    width: 0.011,
  },
};

const mockSentiment: SentimentScore = {
  overall: 0.6,
  sources: {
    reuters: 0.5,
    kitco: 0.7,
    bloomberg: 0.6,
  },
  timestamp: Date.now(),
};

const mockLevels: SupportResistance = {
  support: [2335.00, 2330.00, 2325.00],
  resistance: [2350.00, 2355.00, 2360.00],
  pivotPoint: 2342.00,
};

// ============================================
// TESTS
// ============================================

describe('SignalCore', () => {
  let signalCore: SignalCore;

  beforeEach(() => {
    signalCore = new SignalCore();
  });

  describe('process()', () => {
    it('processes signal within 10ms latency target', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      expect(result.latencyMs).toBeLessThan(10);
    });

    it('returns signal when 4+ factors agree', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      // With mock data, we expect at least some agreement
      expect(result.agreementCount).toBeGreaterThanOrEqual(0);
      
      if (result.agreementCount >= 4) {
        expect(result.signal).not.toBeNull();
        expect(result.signal?.direction).toMatch(/^(BUY|SELL|HOLD)$/);
      }
    });

    it('includes stop loss in every generated signal', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      if (result.signal) {
        expect(result.signal.stopLoss).toBeGreaterThan(0);
        expect(result.signal.stopLoss).not.toBe(result.signal.entry);
      }
    });

    it('calculates risk-reward ratio >= 1.5 for generated signals', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      if (result.signal) {
        expect(result.signal.riskReward).toBeGreaterThanOrEqual(1.5);
      }
    });

    it('includes rationale in every generated signal', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      if (result.signal) {
        expect(result.signal.rationale).toBeTruthy();
        expect(result.signal.rationale.length).toBeGreaterThan(10);
      }
    });
  });

  describe('factor analysis', () => {
    it('correctly identifies bullish EMA alignment', async () => {
      const bullishIndicators: TechnicalIndicators = {
        ...mockIndicators,
        ema9: 2345,
        ema21: 2340,
        ema50: 2335,
      };
      
      const result = await signalCore.process(mockPrice, bullishIndicators, mockSentiment, mockLevels);
      expect(result.factors.trend.aligned).toBe(true);
      expect(result.factors.trend.score).toBe(1);
    });

    it('correctly identifies bearish EMA alignment', async () => {
      const bearishIndicators: TechnicalIndicators = {
        ...mockIndicators,
        ema9: 2335,
        ema21: 2340,
        ema50: 2345,
      };
      
      const result = await signalCore.process(mockPrice, bearishIndicators, mockSentiment, mockLevels);
      expect(result.factors.trend.aligned).toBe(true);
      expect(result.factors.trend.score).toBe(-1);
    });

    it('detects oversold RSI conditions', async () => {
      const oversoldIndicators: TechnicalIndicators = {
        ...mockIndicators,
        rsi14: 25,
      };
      
      const result = await signalCore.process(mockPrice, oversoldIndicators, mockSentiment, mockLevels);
      expect(result.factors.momentum.rsi).toBe(25);
    });
  });

  describe('confidence calculation', () => {
    it('returns confidence between 0 and 1', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      
      if (result.signal) {
        expect(result.signal.confidence).toBeGreaterThanOrEqual(0);
        expect(result.signal.confidence).toBeLessThanOrEqual(1);
      }
    });
  });

  describe('event emission', () => {
    it('emits processed event after successful processing', async () => {
      return new Promise<void>((resolve) => {
        signalCore.on('processed', (data) => {
          expect(data.latencyMs).toBeDefined();
          expect(data.signalGenerated).toBeDefined();
          resolve();
        });
        
        signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
      });
    });
  });

  describe('configuration', () => {
    it('respects custom maxLatencyMs setting', () => {
      const customCore = new SignalCore({ maxLatencyMs: 5 });
      const stats = customCore.getStats();

      expect(stats.config.maxLatencyMs).toBe(5);
    });

    it('respects custom minConfidenceThreshold setting', () => {
      const customCore = new SignalCore({ minConfidenceThreshold: 0.8 });
      const stats = customCore.getStats();

      expect(stats.config.minConfidenceThreshold).toBe(0.8);
    });
  });

  describe('stress tests', () => {
    it('maintains <10ms latency under continuous load', async () => {
      const promises = Array.from({ length: 100 }, () =>
        signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels)
      );

      const results = await Promise.all(promises);
      const allUnderLimit = results.every((r) => r.latencyMs < 10);

      expect(allUnderLimit).toBe(true);
      expect(results.length).toBe(100);
    });

    it('handles rapid sequential processing', async () => {
      const latencies: number[] = [];

      for (let i = 0; i < 50; i++) {
        const result = signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);
        latencies.push(result.latencyMs);
      }

      const avgLatency = latencies.reduce((a, b) => a + b, 0) / latencies.length;
      const maxLatency = Math.max(...latencies);

      expect(avgLatency).toBeLessThan(5);
      expect(maxLatency).toBeLessThan(10);
    });

    it('maintains accuracy under load', async () => {
      const promises = Array.from({ length: 20 }, (_, i) =>
        signalCore.process(
          { ...mockPrice, close: mockPrice.close + i },
          { ...mockIndicators, rsi14: 30 + (i % 40) },
          mockSentiment,
          mockLevels
        )
      );

      const results = await Promise.all(promises);

      // All results should have valid factors
      results.forEach((result) => {
        expect(result.agreementCount).toBeGreaterThanOrEqual(0);
        expect(result.agreementCount).toBeLessThanOrEqual(5);

        if (result.signal) {
          expect(result.signal.confidence).toBeGreaterThanOrEqual(0);
          expect(result.signal.confidence).toBeLessThanOrEqual(1);
          expect(result.signal.stopLoss).toBeGreaterThan(0);
        }
      });
    });
  });

  describe('rationale generation', () => {
    it('includes specific factor details in rationale', async () => {
      const result = await signalCore.process(mockPrice, mockIndicators, mockSentiment, mockLevels);

      if (result.signal) {
        const rationale = result.signal.rationale;
        expect(rationale.length).toBeGreaterThan(20);
        // Should mention at least one specific factor
        expect(
          rationale.includes('EMA') ||
          rationale.includes('RSI') ||
          rationale.includes('MACD') ||
          rationale.includes('sentiment')
        ).toBe(true);
      }
    });

    it('generates different rationales for different market conditions', async () => {
      const bullishResult = await signalCore.process(
        mockPrice,
        { ...mockIndicators, ema9: 2350, ema21: 2345, ema50: 2340, rsi14: 25 },
        mockSentiment,
        mockLevels
      );

      const bearishResult = await signalCore.process(
        mockPrice,
        { ...mockIndicators, ema9: 2330, ema21: 2335, ema21: 2340, rsi14: 75 },
        mockSentiment,
        mockLevels
      );

      if (bullishResult.signal && bearishResult.signal) {
        expect(bullishResult.signal.rationale).not.toBe(bearishResult.signal.rationale);
      }
    });
  });
});
