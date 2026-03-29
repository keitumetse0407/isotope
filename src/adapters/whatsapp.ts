/**
 * ISOTOPE WhatsApp Notification Adapter
 *
 * Sends trading signals to WhatsApp via the existing bot at port 8765.
 * Formats signals according to the ISOTOPE notification standard.
 *
 * @module WhatsAppAdapter
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import axios, { AxiosInstance } from 'axios';
import { CircuitBreaker } from '../safety/circuit_breaker.js';
import type { Signal } from '../engine/signal_core.js';
import { config } from '../config.js';

// ============================================
// TYPE DEFINITIONS
// ============================================

export interface WhatsAppConfig {
  readonly botUrl: string;
  readonly botToken: string;
  readonly timeout: number;
  readonly recipientNumber?: string;
}

export interface SendMessageResult {
  readonly success: boolean;
  readonly messageId?: string;
  readonly error?: string;
}

// ============================================
// CONSTANTS
// ============================================

const DEFAULT_CONFIG: WhatsAppConfig = {
  botUrl: config.whatsapp.botUrl,
  botToken: config.whatsapp.botToken,
  timeout: 10000,
};

// ============================================
// ERROR TYPES
// ============================================

export class WhatsAppError extends Error {
  constructor(
    message: string,
    public override readonly cause?: unknown,
    public readonly statusCode?: number
  ) {
    super(message);
    this.name = 'WhatsAppError';
  }
}

// ============================================
// WHATSAPP ADAPTER
// ============================================

export class WhatsAppAdapter {
  private readonly client: AxiosInstance;
  private readonly circuitBreaker: CircuitBreaker;
  private readonly config: WhatsAppConfig;

  constructor(options: Partial<WhatsAppConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...options };

    this.client = axios.create({
      baseURL: this.config.botUrl,
      timeout: this.config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.botToken}`,
      },
    });

    this.circuitBreaker = new CircuitBreaker('WhatsApp', {
      failureThreshold: 3,
      successThreshold: 2,
      timeout: 60000,
      halfOpenMaxRequests: 2,
    });
  }

  /**
   * Send a trading signal to WhatsApp
   *
   * @param signal - The trading signal to send
   * @returns Result of the send operation
   * @throws {WhatsAppError} If send fails
   */
  async sendSignal(signal: Signal): Promise<SendMessageResult> {
    const message = this.#formatSignal(signal);

    try {
      await this.circuitBreaker.execute(async () => {
        const response = await this.client.post<{ success: boolean; messageId?: string }>('/send', {
          message,
          recipient: this.config.recipientNumber,
        });

        if (!response.data.success) {
          throw new WhatsAppError('WhatsApp bot returned failure');
        }

        return response.data;
      });

      return {
        success: true,
        messageId: Date.now().toString(),
      };
    } catch (error) {
      if (error instanceof WhatsAppError) {
        throw error;
      }

      throw new WhatsAppError(
        `Failed to send WhatsApp message: ${error instanceof Error ? error.message : 'Unknown error'}`,
        error
      );
    }
  }

  /**
   * Send a custom message to WhatsApp
   *
   * @param message - The message to send
   * @returns Result of the send operation
   */
  async sendMessage(message: string): Promise<SendMessageResult> {
    try {
      await this.circuitBreaker.execute(async () => {
        const response = await this.client.post<{ success: boolean; messageId?: string }>('/send', {
          message,
          recipient: this.config.recipientNumber,
        });

        return response.data;
      });

      return {
        success: true,
        messageId: Date.now().toString(),
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Send a system notification (error, warning, status)
   */
  async sendNotification(type: 'ERROR' | 'WARNING' | 'INFO', message: string): Promise<SendMessageResult> {
    const emoji = type === 'ERROR' ? '🚨' : type === 'WARNING' ? '⚠️' : 'ℹ️';
    const formattedMessage = `${emoji} ISOTOPE ${type}\n\n${message}`;

    return this.sendMessage(formattedMessage);
  }

  /**
   * Get circuit breaker statistics
   */
  getStats(): ReturnType<CircuitBreaker['getStats']> {
    return this.circuitBreaker.getStats();
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  #formatSignal(signal: Signal): string {
    const directionEmoji = signal.direction === 'BUY' ? '🟢' : signal.direction === 'SELL' ? '🔴' : '⚪';
    const stopLossDistance = Math.abs(signal.entry - signal.stopLoss);
    const stopLossPercent = ((stopLossDistance / signal.entry) * 100).toFixed(2);
    const tp1Distance = Math.abs(signal.takeProfit1 - signal.entry);
    const tp2Distance = Math.abs(signal.takeProfit2 - signal.entry);
    const confidencePercent = (signal.confidence * 100).toFixed(0);

    const time = new Date(signal.timestamp).toLocaleTimeString('en-ZA', {
      timeZone: 'Africa/Johannesburg',
      hour: '2-digit',
      minute: '2-digit',
    });

    return `
${directionEmoji} ISOTOPE SIGNAL — XAU/USD

📊 Direction: ${signal.direction}
💰 Entry: $${signal.entry.toLocaleString('en-US', { minimumFractionDigits: 2 })}
🛑 Stop Loss: $${signal.stopLoss.toLocaleString('en-US', { minimumFractionDigits: 2 })} (-$${stopLossDistance.toFixed(2)} | ${stopLossPercent}%)
🎯 TP1: $${signal.takeProfit1.toLocaleString('en-US', { minimumFractionDigits: 2 })} (+$${tp1Distance.toFixed(2)})
🎯 TP2: $${signal.takeProfit2.toLocaleString('en-US', { minimumFractionDigits: 2 })} (+$${tp2Distance.toFixed(2)})
📈 R:R = 1:${signal.riskReward.toFixed(1)}
⚡ Confidence: ${confidencePercent}%
🧠 Reason: ${signal.rationale}

⏰ Signal time: ${time} SAST
🤖 ISOTOPE v2.0 | ELEV8 DIGITAL
`.trim();
  }
}

// ============================================
// EXPORTS
// ============================================

export default WhatsAppAdapter;
