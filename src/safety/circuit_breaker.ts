/**
 * ISOTOPE Circuit Breaker
 *
 * Protects against cascading failures from external API calls.
 * Implements the circuit breaker pattern with three states:
 * - CLOSED: Normal operation, requests flow through
 * - OPEN: Circuit tripped, requests fail immediately
 * - HALF_OPEN: Testing if service recovered
 *
 * @module CircuitBreaker
 * @author ELEV8 DIGITAL | Built by Elkai
 * @version 2.0.0
 */

import { EventEmitter } from 'events';

// ============================================
// TYPE DEFINITIONS
// ============================================

export type CircuitState = 'CLOSED' | 'OPEN' | 'HALF_OPEN';

export interface CircuitBreakerOptions {
  readonly failureThreshold: number; // Failures before opening circuit
  readonly successThreshold: number; // Successes before closing circuit
  readonly timeout: number; // ms to wait before trying again
  readonly halfOpenMaxRequests: number; // Max requests in half-open state
}

export interface CircuitBreakerEvent {
  readonly state: CircuitState;
  readonly failureCount: number;
  readonly successCount: number;
  readonly lastError?: Error | undefined;
  readonly timestamp: number;
}

// ============================================
// ERROR TYPES
// ============================================

export class CircuitOpenError extends Error {
  constructor(
    message: string,
    public readonly retryAfterMs?: number
  ) {
    super(message);
    this.name = 'CircuitOpenError';
  }
}

export class CircuitBreakerError extends Error {
  constructor(
    message: string,
    public override readonly cause?: unknown,
    public readonly state?: CircuitState
  ) {
    super(message);
    this.name = 'CircuitBreakerError';
  }
}

// ============================================
// DEFAULT CONFIGURATION
// ============================================

const DEFAULT_OPTIONS: CircuitBreakerOptions = {
  failureThreshold: 5, // Open after 5 consecutive failures
  successThreshold: 3, // Close after 3 consecutive successes in half-open
  timeout: 30000, // Try again after 30 seconds
  halfOpenMaxRequests: 3, // Allow 3 test requests in half-open
};

// ============================================
// CIRCUIT BREAKER CLASS
// ============================================

export class CircuitBreaker extends EventEmitter {
  private state: CircuitState = 'CLOSED';
  private failureCount = 0;
  private successCount = 0;
  private lastError?: Error;
  private lastFailureTime?: number;
  private halfOpenRequests = 0;

  private readonly options: CircuitBreakerOptions;
  private readonly name: string;

  constructor(name: string, options: Partial<CircuitBreakerOptions> = {}) {
    super();
    this.name = name;
    this.options = { ...DEFAULT_OPTIONS, ...options };
  }

  /**
   * Execute a function with circuit breaker protection
   *
   * @param fn - Async function to execute
   * @returns Result of the function
   * @throws {CircuitOpenError} If circuit is open
   * @throws {CircuitBreakerError} If function fails in half-open state
   */
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    await this.#checkState();

    try {
      const result = await fn();
      await this.#onSuccess();
      return result;
    } catch (error) {
      await this.#onFailure(error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * Get current circuit state and statistics
   */
  getState(): CircuitBreakerEvent {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      lastError: this.lastError,
      timestamp: Date.now(),
    };
  }

  /**
   * Manually reset the circuit breaker
   */
  reset(): void {
    this.state = 'CLOSED';
    this.failureCount = 0;
    this.successCount = 0;
    delete this.lastError;
    delete this.lastFailureTime;
    this.halfOpenRequests = 0;
    this.emit('state_change', this.getState());
  }

  /**
   * Manually force circuit open (for maintenance)
   */
  forceOpen(): void {
    this.state = 'OPEN';
    this.lastFailureTime = Date.now();
    this.emit('state_change', this.getState());
  }

  // ============================================
  // PRIVATE STATE MANAGEMENT
  // ============================================

  async #checkState(): Promise<void> {
    if (this.state === 'CLOSED') {
      return;
    }

    if (this.state === 'OPEN') {
      const timeSinceFailure = Date.now() - (this.lastFailureTime || 0);

      if (timeSinceFailure >= this.options.timeout) {
        this.#transitionTo('HALF_OPEN');
        this.halfOpenRequests = 0;
        return;
      }

      const retryAfter = this.options.timeout - timeSinceFailure;
      throw new CircuitOpenError(
        `Circuit breaker '${this.name}' is OPEN. Retry after ${retryAfter}ms`,
        retryAfter
      );
    }

    // HALF_OPEN state
    if (this.halfOpenRequests >= this.options.halfOpenMaxRequests) {
      throw new CircuitOpenError(
        `Circuit breaker '${this.name}' half-open request limit exceeded`,
        this.options.timeout
      );
    }

    this.halfOpenRequests++;
  }

  async #onSuccess(): Promise<void> {
    this.successCount++;

    if (this.state === 'HALF_OPEN') {
      if (this.successCount >= this.options.successThreshold) {
        this.#transitionTo('CLOSED');
        this.successCount = 0;
        this.failureCount = 0;
      }
    } else {
      // Reset failure count on success in CLOSED state
      this.failureCount = 0;
    }
  }

  async #onFailure(error: Error): Promise<void> {
    this.failureCount++;
    this.lastError = error;
    this.lastFailureTime = Date.now();

    if (this.state === 'HALF_OPEN') {
      this.#transitionTo('OPEN');
      this.emit('trip', { error, state: this.getState() });
    } else if (this.failureCount >= this.options.failureThreshold) {
      this.#transitionTo('OPEN');
      this.emit('trip', { error, state: this.getState() });
    } else {
      this.emit('failure', { error, failureCount: this.failureCount, state: this.getState() });
    }
  }

  #transitionTo(newState: CircuitState): void {
    const oldState = this.state;
    this.state = newState;
    this.emit('state_change', this.getState());
    console.log(`[CircuitBreaker:${this.name}] ${oldState} → ${newState}`);
  }

  /**
   * Get statistics for monitoring
   */
  getStats(): {
    readonly name: string;
    readonly state: CircuitState;
    readonly failureCount: number;
    readonly successCount: number;
    readonly options: CircuitBreakerOptions;
  } {
    return {
      name: this.name,
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      options: this.options,
    };
  }
}

// ============================================
// EXPORTS
// ============================================

export default CircuitBreaker;
