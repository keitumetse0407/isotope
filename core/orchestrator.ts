/**
 * ISOTOPE Core Orchestrator
 *
 * Master controller that coordinates all subsystems:
 * - Data fetching (Alpha Vantage)
 * - Signal processing (SignalCore)
 * - Notifications (WhatsApp)
 * - API server (Fastify)
 *
 * @module Orchestrator
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import Fastify, { FastifyInstance } from 'fastify';
import { SignalCore, type Signal, type PriceData } from '../engine/signal_core.js';
import { IndicatorCalculator } from '../engine/indicator_calculator.js';
import { AlphaVantageAdapter } from '../adapters/alpha_vantage.js';
import { NewsFeedAdapter } from '../adapters/news_feed.js';
import { WhatsAppAdapter } from '../adapters/whatsapp.js';
import { config } from '../../config.js';

// ============================================
// TYPE DEFINITIONS
// ============================================

export interface OrchestratorConfig {
  readonly port: number;
  readonly dashboardPort: number;
  readonly signalSchedule: ReadonlyArray<string>; // Cron expressions
  readonly autoSendSignals: boolean;
}

export interface SystemStatus {
  readonly status: 'running' | 'stopped' | 'error';
  readonly uptime: number;
  readonly lastSignal: Signal | null;
  readonly signalsToday: number;
  readonly adapters: {
    readonly alphaVantage: ReturnType<AlphaVantageAdapter['getStats']>;
    readonly newsFeed: ReturnType<NewsFeedAdapter['getStats']>;
    readonly whatsapp: ReturnType<WhatsAppAdapter['getStats']>;
  };
}

export interface ProcessSignalResult {
  readonly signal: Signal | null;
  readonly latencyMs: number;
  readonly sent: boolean;
  readonly error?: string;
}

// ============================================
// CONSTANTS
// ============================================

const DEFAULT_CONFIG: OrchestratorConfig = {
  port: config.app.port,
  dashboardPort: config.app.dashboardPort,
  signalSchedule: ['0 8 * * *', '0 12 * * *', '0 16 * * *'], // 08:00, 12:00, 16:00 SAST
  autoSendSignals: true,
};

// ============================================
// ORCHESTRATOR CLASS
// ============================================

export class Orchestrator {
  private readonly signalCore: SignalCore;
  private readonly indicatorCalc: IndicatorCalculator;
  private readonly alphaVantage: AlphaVantageAdapter;
  private readonly newsFeed: NewsFeedAdapter;
  private readonly whatsapp: WhatsAppAdapter;
  private readonly apiServer: FastifyInstance;
  private readonly dashboardServer: FastifyInstance;
  private readonly config: OrchestratorConfig;

  private isRunning = false;
  private startTime = 0;
  private lastSignal: Signal | null = null;
  private signalsToday = 0;
  private lastSignalDate: Date | null = null;
  private processInterval: NodeJS.Timeout | null = null;

  constructor(options: Partial<OrchestratorConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...options };

    // Initialize subsystems
    this.signalCore = new SignalCore({
      maxLatencyMs: config.signal.maxLatencyMs,
      minConfidenceThreshold: config.signal.minConfidenceThreshold,
    });

    this.indicatorCalc = new IndicatorCalculator();
    this.alphaVantage = new AlphaVantageAdapter();
    this.newsFeed = new NewsFeedAdapter();
    this.whatsapp = new WhatsAppAdapter();

    // Initialize Fastify servers
    this.apiServer = Fastify({ logger: true });
    this.dashboardServer = Fastify({ logger: true });

    // Wire up event handlers
    this.#setupEventHandlers();
  }

  /**
   * Start the orchestrator
   */
  async start(): Promise<void> {
    if (this.isRunning) {
      throw new Error('Orchestrator is already running');
    }

    console.log('[Orchestrator] Starting...');
    this.startTime = Date.now();
    this.isRunning = true;

    // Start API servers
    await this.#startServers();

    // Start signal processing loop (every 5 minutes)
    this.#startSignalLoop();

    // Send startup notification
    await this.whatsapp.sendNotification('INFO', 'ISOTOPE v2.0 started successfully');

    console.log('[Orchestrator] Started successfully');
  }

  /**
   * Stop the orchestrator gracefully
   */
  async stop(): Promise<void> {
    if (!this.isRunning) return;

    console.log('[Orchestrator] Stopping...');
    this.isRunning = false;

    // Stop signal loop
    if (this.processInterval) {
      clearInterval(this.processInterval);
      this.processInterval = null;
    }

    // Stop servers
    await Promise.all([
      this.apiServer.close(),
      this.dashboardServer.close(),
    ]);

    // Send shutdown notification
    await this.whatsapp.sendNotification('INFO', 'ISOTOPE v2.0 stopped gracefully');

    console.log('[Orchestrator] Stopped');
  }

  /**
   * Process a single signal cycle manually
   */
  async processSignal(): Promise<ProcessSignalResult> {
    const startTime = Date.now();

    try {
      // Reset daily counter if new day
      this.#checkNewDay();

      // Check daily signal limit
      if (this.signalsToday >= config.signal.maxDailySignals) {
        return {
          signal: null,
          latencyMs: 0,
          sent: false,
          error: 'Daily signal limit reached',
        };
      }

      // Fetch price data
      const priceResult = await this.alphaVantage.fetchPrice();
      const price = priceResult.price;

      // Calculate indicators
      const indicators = this.indicatorCalc.calculate(price);

      // Fetch sentiment
      const sentimentResult = await this.newsFeed.fetchSentiment();
      const sentiment = sentimentResult.sentiment;

      // Calculate support/resistance (simplified)
      const levels = this.#calculateLevels(price, indicators);

      // Process signal
      const result = this.signalCore.process(price, indicators, sentiment, levels);

      // Send signal if generated and auto-send is enabled
      let sent = false;
      if (result.signal && this.config.autoSendSignals) {
        await this.whatsapp.sendSignal(result.signal);
        this.lastSignal = result.signal;
        this.signalsToday++;
        this.lastSignalDate = new Date();
        sent = true;
      }

      return {
        signal: result.signal,
        latencyMs: Date.now() - startTime,
        sent,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('[Orchestrator] Signal processing failed:', errorMessage);

      return {
        signal: null,
        latencyMs: Date.now() - startTime,
        sent: false,
        error: errorMessage,
      };
    }
  }

  /**
   * Get current system status
   */
  getStatus(): SystemStatus {
    return {
      status: this.isRunning ? 'running' : 'stopped',
      uptime: Date.now() - this.startTime,
      lastSignal: this.lastSignal,
      signalsToday: this.signalsToday,
      adapters: {
        alphaVantage: this.alphaVantage.getStats(),
        newsFeed: this.newsFeed.getStats(),
        whatsapp: this.whatsapp.getStats(),
      },
    };
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  #setupEventHandlers(): void {
    // Signal core events
    this.signalCore.on('processed', (data) => {
      console.log(
        `[Signal] Processed in ${data.latencyMs.toFixed(2)}ms | ` +
        `Agreement: ${data.agreementCount}/5 | ` +
        `Generated: ${data.signalGenerated}`
      );
    });

    this.signalCore.on('latency_warning', (data) => {
      console.warn(
        `[⚠️ LATENCY] ${data.actual.toFixed(2)}ms exceeded ${data.target}ms target`
      );
    });

    this.signalCore.on('error', (data) => {
      console.error(
        `[Error] Signal processing failed after ${data.latencyMs}ms:`,
        data.error
      );
    });
  }

  async #startServers(): Promise<void> {
    // Setup API routes
    this.#setupApiRoutes();
    this.#setupDashboardRoutes();

    // Start servers
    await this.apiServer.listen({ port: this.config.port, host: '0.0.0.0' });
    await this.dashboardServer.listen({ port: this.config.dashboardPort, host: '0.0.0.0' });

    console.log(`[API] Listening on port ${this.config.port}`);
    console.log(`[Dashboard] Listening on port ${this.config.dashboardPort}`);
  }

  #setupApiRoutes(): void {
    // Health check
    this.apiServer.get('/health', async () => ({
      status: 'ok',
      uptime: Date.now() - this.startTime,
      timestamp: Date.now(),
    }));

    // Status endpoint
    this.apiServer.get('/status', async () => this.getStatus());

    // Manual signal trigger
    this.apiServer.post('/signal', async () => {
      const result = await this.processSignal();
      return result;
    });

    // Adapter stats
    this.apiServer.get('/stats', async () => ({
      alphaVantage: this.alphaVantage.getStats(),
      newsFeed: this.newsFeed.getStats(),
      whatsapp: this.whatsapp.getStats(),
    }));
  }

  #setupDashboardRoutes(): void {
    // Serve dashboard HTML
    this.dashboardServer.get('/', async (_, reply) => {
      reply.type('text/html');
      return this.#getDashboardHtml();
    });

    // Dashboard API
    this.dashboardServer.get('/api/status', async () => this.getStatus());
    this.dashboardServer.get('/api/signals', async () => ({
      lastSignal: this.lastSignal,
      signalsToday: this.signalsToday,
    }));
  }

  #startSignalLoop(): void {
    // Process signals every 5 minutes
    this.processInterval = setInterval(() => {
      if (this.isRunning) {
        this.processSignal().catch((error) => {
          console.error('[Orchestrator] Scheduled signal failed:', error);
        });
      }
    }, 5 * 60 * 1000);
  }

  #checkNewDay(): void {
    const today = new Date();
    if (!this.lastSignalDate || this.lastSignalDate.toDateString() !== today.toDateString()) {
      this.signalsToday = 0;
      console.log('[Orchestrator] New day started, reset signal counter');
    }
  }

  #calculateLevels(
    price: PriceData,
    indicators: { ema9: number; ema21: number; ema50: number; bollingerBands: { upper: number; lower: number } }
  ): { support: number[]; resistance: number[]; pivotPoint: number } {
    // Simplified support/resistance calculation
    const support = [
      indicators.ema50,
      indicators.bollingerBands.lower,
      price.low * 0.995,
    ].filter((n) => n < price.close);

    const resistance = [
      indicators.ema9,
      indicators.bollingerBands.upper,
      price.high * 1.005,
    ].filter((n) => n > price.close);

    const pivotPoint = (price.high + price.low + price.close) / 3;

    return {
      support: support.slice(0, 3),
      resistance: resistance.slice(0, 3),
      pivotPoint,
    };
  }

  #getDashboardHtml(): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ISOTOPE Dashboard</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #1a1a2e; color: #eee; padding: 2rem; }
    .card { background: #16213e; border-radius: 8px; padding: 1.5rem; margin: 1rem 0; }
    .status { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 4px; font-weight: bold; }
    .status.running { background: #0f0; color: #000; }
    .status.stopped { background: #f00; color: #fff; }
    h1 { color: #00d9ff; }
    .metric { display: inline-block; margin-right: 2rem; }
    .metric-value { font-size: 2rem; font-weight: bold; color: #00d9ff; }
    .metric-label { font-size: 0.875rem; color: #888; }
  </style>
</head>
<body>
  <h1>🔬 ISOTOPE Dashboard</h1>
  <div id="app">Loading...</div>
  <script>
    async function load() {
      const res = await fetch('/api/status');
      const data = await res.json();
      document.getElementById('app').innerHTML = \`
        <div class="card">
          <p>Status: <span class="status \${data.status}">\${data.status.toUpperCase()}</span></p>
          <p>Uptime: \${Math.round(data.uptime / 1000)}s</p>
        </div>
        <div class="card">
          <div class="metric">
            <div class="metric-value">\${data.signalsToday}</div>
            <div class="metric-label">Signals Today</div>
          </div>
          <div class="metric">
            <div class="metric-value">\${data.lastSignal ? 'Yes' : 'No'}</div>
            <div class="metric-label">Last Signal</div>
          </div>
        </div>
      \`;
    }
    load();
    setInterval(load, 5000);
  </script>
</body>
</html>
    `.trim();
  }
}

// ============================================
// EXPORTS
// ============================================

export default Orchestrator;
