# ISOTOPE — Autonomous Gold Signal Intelligence System
> Built by Elkai | ELEV8 DIGITAL | Dennilton, Limpopo, ZA
> VPS: 185.167.97.193 | Ubuntu 22.04 | Stack: TypeScript 5.x | Node.js 20+

---

## MISSION
Build the most sophisticated autonomous gold trading signal system possible.
Tony Stark should feel insecure looking at this. No cap.
Start with gold (XAU/USD). Expand after gold is locked and profitable.

---

## ARCHITECTURE — THE ISOTOPE CORE

```
isotope/
├── src/
│   ├── engine/
│   │   ├── signal_core.ts       # Core signal processing engine (<10ms target)
│   │   ├── latency_tracker.ts   # Performance monitoring
│   │   └── execution_queue.ts   # Async signal queue
│   ├── adapters/
│   │   ├── meta_api.ts          # MetaTrader/TradingView integration
│   │   ├── tradingview.ts       # TradingView websocket client
│   │   ├── news_feed.ts         # RSS/news sentiment fetcher
│   │   └── whatsapp.ts          # WhatsApp notification adapter
│   ├── safety/
│   │   ├── circuit_breaker.ts   # API failure protection
│   │   ├── config_validator.ts  # Environment validation
│   │   └── error_types.ts       # Typed error hierarchy
│   └── utils/
│       ├── logger.ts            # Structured logging
│       ├── metrics.ts           # Prometheus-style metrics
│       └── helpers.ts           # Shared utilities
├── core/
│   ├── orchestrator.ts          # Master controller (Fastify, port 8100)
│   ├── scheduler.ts             # Runs signals at 08:00, 12:00, 16:00 SAST
│   ├── memory.ts                # SQLite — stores signals, outcomes, accuracy
│   └── notifier.ts              # WhatsApp notification service
├── dashboard/
│   ├── server.ts                # Fastify dashboard (port 8101)
│   └── index.html               # Real-time web dashboard
├── tests/
│   ├── engine/
│   │   └── signal_core.test.ts
│   ├── adapters/
│   └── integration/
├── data/
│   └── isotope.db               # SQLite database
├── config.ts                    # All config, env vars, constants
├── main.ts                      # Single entry point: node main.ts
├── package.json
├── tsconfig.json
├── rules.md                     # Engineering standards & performance benchmarks
├── mcp-config.json              # MCP server configuration
└── .env                         # Secrets only — never commit this
```

---

## TECH STACK

| Layer | Tool | Why |
|-------|------|-----|
| Runtime | Node.js 20+ | Async performance, V8 optimization |
| Language | TypeScript 5.x | Strict types, <10ms latency enforcement |
| Data | yfinance (via Python bridge) | Free, reliable gold OHLCV |
| Data backup | Alpha Vantage | 500 calls/day, real-time gold |
| Analysis | technicalindicators | Lightweight TA library |
| ML signals | scikit-learn (Python bridge) | Trained models via subprocess |
| API | Fastify | Fastest Node.js HTTP framework |
| Database | SQLite (better-sqlite3) | Zero config, synchronous queries |
| Scheduler | node-cron | Cron-like, Node.js native |
| Notifications | WhatsApp via existing bot at port 8765 | Already live |
| Process | systemd service | Auto-restart on crash |
| Caching | Upstash Redis | Serverless, VPS-friendly |

---

## PERFORMANCE BENCHMARKS (NON-NEGOTIABLE)

| Metric | Target | Hard Limit |
|--------|--------|------------|
| Signal Processing Latency | <5ms | <10ms |
| API Response Time | <50ms | <100ms |
| Data Fetch Timeout | <2s | <5s |
| Database Query Time | <10ms | <50ms |

**All benchmarks enforced via `rules.md`**

---

## GOLD DATA SOURCES

```typescript
// Primary: TradingView WebSocket (real-time)
import { TradingViewAdapter } from './adapters/tradingview';
const tv = new TradingViewAdapter({ symbol: 'XAUUSD' });
tv.on('price', (data) => processSignal(data));

// Backup: Alpha Vantage (get free key at alphavantage.co)
// ALPHA_VANTAGE_KEY in .env — 500 calls/day free

// Sentiment: RSS feeds (no key needed)
// - Reuters Gold: https://feeds.reuters.com/reuters/businessNews
// - Kitco: https://www.kitco.com/rss/
```

---

## SIGNAL ENGINE — HOW IT THINKS

Every signal is a CONFLUENCE of 5 systems. All 5 must agree before firing.

```
1. TREND        → EMA 9/21/50 alignment
2. MOMENTUM     → RSI(14) + MACD histogram
3. VOLATILITY   → ATR(14) + Bollinger Band width
4. STRUCTURE    → Support/Resistance levels
5. SENTIMENT    → News score (positive/negative/neutral)

SIGNAL STRENGTH:
  5/5 agree → STRONG SIGNAL (fire immediately)
  4/5 agree → MODERATE SIGNAL (fire with caveat)
  3/5 agree → WEAK SIGNAL (log only, don't send)
  <3/5       → NO SIGNAL
```

---

## RISK MANAGEMENT (NON-NEGOTIABLE)

```typescript
// Every signal MUST include these:
interface Signal {
  direction: 'BUY' | 'SELL';
  entry: number;           // Entry price
  stopLoss: number;        // Always set. No exceptions.
  takeProfit1: number;     // First target (1:1.5 RR minimum)
  takeProfit2: number;     // Second target (1:3 RR)
  confidence: number;      // 0.0 - 1.0
  timeframe: 'H1' | 'H4' | 'D1';
  rationale: string;       // Why. Always explain.
  riskReward: number;      // Minimum 1.5
  processingLatencyMs: number; // Performance tracking
}
```

---

## WHATSAPP NOTIFICATION FORMAT

```
🔔 ISOTOPE SIGNAL — XAU/USD

📊 Direction: BUY
💰 Entry: $2,345.00
🛑 Stop Loss: $2,330.00 (-$15 | 1.5%)
🎯 TP1: $2,367.50 (+$22.50)
🎯 TP2: $2,390.00 (+$45.00)
📈 R:R = 1:3.0
⚡ Confidence: 87%
🧠 Reason: Strong EMA alignment + RSI recovery from oversold + positive DXY divergence

⏰ Signal time: 08:00 SAST
🤖 ISOTOPE v2.0 | ELEV8 DIGITAL
```

---

## CODING STANDARDS (FOLLOW ALWAYS)

- **TypeScript 5.x strict mode** — no `any`, all types explicit
- **All functions have return types** — no exceptions
- **Readonly for immutables** — prevent accidental mutations
- **Discriminated unions for state** — type-safe state machines
- **Config lives in `config.ts`** — never hardcode values
- **Secrets live in `.env`** — validated at startup by `config_validator.ts`
- **Every error is caught and logged** — no silent failures
- **One responsibility per file** — if a file does two things, split it
- **Latency tracked for every signal** — enforce <10ms budget
- **Test signal logic before production** — `tests/engine/signal_core.test.ts`

---

## VPS CONTEXT

- **IP**: 185.167.97.193
- **OS**: Ubuntu 22.04 LTS
- **User**: root
- **Project path**: /root/isotope/
- **Services**: systemd (isotope.service)
- **Existing bots**: WhatsApp bot on original VPS (113.30.189.89) — adapter must POST to it
- **Port 8100**: Orchestrator API
- **Port 8101**: Dashboard
- **Node.js**: 20.x LTS

---

## DEPLOYMENT

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Start everything
npm start

# Or via systemd
systemctl start isotope
systemctl status isotope
journalctl -u isotope -f
```

---

## PHASE PLAN

```
PHASE 1 (NOW)    → TypeScript architecture + signal_core.ts skeleton
PHASE 2          → Adapters for TradingView + MetaAPI
PHASE 3          → All 5 confluence systems active
PHASE 4          → ML model trained on historical gold data
PHASE 5          → Live accuracy tracking + self-improvement
PHASE 6          → Add Silver, then indices, then crypto
```

---

## ELKAI'S RULES (NEVER BREAK THESE)

1. **Free everything** — no paid APIs until revenue justifies it
2. **WhatsApp-first** — all signals delivered to WhatsApp, no exceptions
3. **Accuracy over frequency** — 3 great signals/day beats 20 bad ones
4. **Always explain signals** — users must understand WHY
5. **Never send a signal without a stop loss** — protect the user
6. **Backtest before live** — prove it works historically first
7. **One problem at a time** — finish Phase 1 completely before Phase 2
8. **<10ms latency always** — performance is a feature

---

## WHEN STUCK

1. Check `journalctl -u isotope -f` first
2. Check `data/isotope.db` for bad data
3. Check `config.ts` for wrong values
4. Run `npm test` to isolate signal logic
5. Check `rules.md` for engineering standards
6. If still stuck → escalate with exact error + file + line number

---

## ENGINEERING STANDARDS

See **`rules.md`** for complete engineering standards including:
- TypeScript strict type enforcement
- Error handling patterns for socket drops
- Security rules (zero hardcoded secrets)
- Performance benchmarks
- Testing requirements

---

*Last updated: March 2026 | Stack migrated to TypeScript for maximum performance*
