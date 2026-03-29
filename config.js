/**
 * ISOTOPE Configuration
 *
 * Centralized configuration with runtime validation.
 * All secrets loaded from environment variables.
 */
import { z } from 'zod';
// ============================================
// ENVIRONMENT SCHEMA
// ============================================
const envSchema = z.object({
    // Meta API
    META_API_KEY: z.string().min(1),
    META_API_SECRET: z.string().min(1),
    META_API_URL: z.string().url(),
    // Upstash Redis
    UPSTASH_REDIS_URL: z.string().url(),
    UPSTASH_REDIS_TOKEN: z.string().min(1),
    // OpenRouter (optional - RSS fallback available)
    OPENROUTER_API_KEY: z.string().optional(),
    OPENROUTER_MODEL: z.string().default('anthropic/claude-3.5-sonnet'),
    USE_OPENROUTER_SENTIMENT: z.string().transform((v) => v === 'true').default('false'),
    // Alpha Vantage
    ALPHA_VANTAGE_KEY: z.string().min(1),
    // WhatsApp Bot
    WHATSAPP_BOT_URL: z.string().url(),
    WHATSAPP_BOT_TOKEN: z.string().min(1),
    // Core Config
    NODE_ENV: z.enum(['development', 'production', 'test']).default('production'),
    LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
    PORT: z.string().transform(Number).default('8100'),
    DASHBOARD_PORT: z.string().transform(Number).default('8101'),
    // Signal Processing
    MAX_LATENCY_MS: z.string().transform(Number).default('10'),
    MAX_RECONNECT_ATTEMPTS: z.string().transform(Number).default('5'),
    RECONNECT_BASE_DELAY_MS: z.string().transform(Number).default('1000'),
    // Risk Management
    DEFAULT_RISK_PERCENT: z.string().transform(Number).default('1.0'),
    MAX_DAILY_SIGNALS: z.string().transform(Number).default('20'),
    MIN_CONFIDENCE_THRESHOLD: z.string().transform(Number).default('0.7'),
    // Database
    DATABASE_PATH: z.string().default('/root/isotope/data/isotope.db'),
});
// ============================================
// VALIDATION
// ============================================
function validateEnv() {
    const result = envSchema.safeParse(process.env);
    if (!result.success) {
        const errors = result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
        throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
    }
    return result.data;
}
// ============================================
// EXPORTED CONFIG
// ============================================
const validated = validateEnv();
export const config = {
    metaAPI: {
        apiKey: validated.META_API_KEY,
        apiSecret: validated.META_API_SECRET,
        url: validated.META_API_URL,
    },
    redis: {
        url: validated.UPSTASH_REDIS_URL,
        token: validated.UPSTASH_REDIS_TOKEN,
    },
    openRouter: {
        apiKey: validated.OPENROUTER_API_KEY,
        model: validated.OPENROUTER_MODEL,
        useSentiment: validated.USE_OPENROUTER_SENTIMENT,
    },
    alphaVantage: {
        apiKey: validated.ALPHA_VANTAGE_KEY,
    },
    whatsapp: {
        botUrl: validated.WHATSAPP_BOT_URL,
        botToken: validated.WHATSAPP_BOT_TOKEN,
    },
    signal: {
        maxLatencyMs: validated.MAX_LATENCY_MS,
        maxReconnectAttempts: validated.MAX_RECONNECT_ATTEMPTS,
        reconnectBaseDelayMs: validated.RECONNECT_BASE_DELAY_MS,
        minConfidenceThreshold: validated.MIN_CONFIDENCE_THRESHOLD,
        defaultRiskPercent: validated.DEFAULT_RISK_PERCENT,
        maxDailySignals: validated.MAX_DAILY_SIGNALS,
    },
    app: {
        nodeEnv: validated.NODE_ENV,
        logLevel: validated.LOG_LEVEL,
        port: validated.PORT,
        dashboardPort: validated.DASHBOARD_PORT,
    },
    database: {
        path: validated.DATABASE_PATH,
    },
};
// ============================================
// RUNTIME VALIDATION EXPORT
// ============================================
export function validateConfig() {
    // Already validated on import, but exposed for explicit calls
    console.log(`[Config] Validated for ${config.app.nodeEnv} environment`);
}
export default config;
//# sourceMappingURL=config.js.map