/**
 * ISOTOPE Configuration
 *
 * Centralized configuration with runtime validation.
 * All secrets loaded from environment variables.
 */
export interface MetaAPIConfig {
    apiKey: string;
    apiSecret: string;
    url: string;
}
export interface RedisConfig {
    url: string;
    token: string;
}
export interface SignalConfig {
    maxLatencyMs: number;
    maxReconnectAttempts: number;
    reconnectBaseDelayMs: number;
    minConfidenceThreshold: number;
    defaultRiskPercent: number;
    maxDailySignals: number;
}
export interface AppConfig {
    nodeEnv: 'development' | 'production' | 'test';
    logLevel: 'debug' | 'info' | 'warn' | 'error';
    port: number;
    dashboardPort: number;
}
export declare const config: {
    readonly metaAPI: {
        apiKey: string;
        apiSecret: string;
        url: string;
    };
    readonly redis: {
        url: string;
        token: string;
    };
    readonly openRouter: {
        readonly apiKey: string | undefined;
        readonly model: string;
        readonly useSentiment: boolean;
    };
    readonly alphaVantage: {
        readonly apiKey: string;
    };
    readonly whatsapp: {
        readonly botUrl: string;
        readonly botToken: string;
    };
    readonly signal: {
        maxLatencyMs: number;
        maxReconnectAttempts: number;
        reconnectBaseDelayMs: number;
        minConfidenceThreshold: number;
        defaultRiskPercent: number;
        maxDailySignals: number;
    };
    readonly app: {
        nodeEnv: "development" | "production" | "test";
        logLevel: "debug" | "info" | "warn" | "error";
        port: number;
        dashboardPort: number;
    };
    readonly database: {
        readonly path: string;
    };
};
export declare function validateConfig(): void;
export default config;
//# sourceMappingURL=config.d.ts.map