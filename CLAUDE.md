# ISOTOPE — Autonomous Gold Signal Intelligence System
> Built by Elkai | ELEV8 DIGITAL | Dennilton, Limpopo, ZA
> VPS: 185.167.97.193 | Ubuntu 22.04 | Stack: Python 3.11+

---

## MISSION
Build the most sophisticated autonomous gold trading signal system possible.
Tony Stark should feel insecure looking at this. No cap.
Start with gold (XAU/USD). Expand after gold is locked and profitable.

---

## ARCHITECTURE — THE ISOTOPE CORE

```
isotope/
├── agents/
│   ├── data_miner.py          # Fetches gold price data (yfinance + Alpha Vantage)
│   ├── pattern_detector.py    # Technical analysis engine
│   ├── sentiment_analyzer.py  # News sentiment (free RSS feeds)
│   ├── signal_generator.py    # Combines all inputs → BUY/SELL/HOLD
│   ├── risk_manager.py        # Position sizing, SL/TP calculator
│   └── performance_tracker.py # Tracks signal accuracy over time
├── core/
│   ├── orchestrator.py        # Master controller (FastAPI, port 8100)
│   ├── scheduler.py           # Runs signals at 08:00, 12:00, 16:00 SAST
│   ├── memory.py              # SQLite — stores signals, outcomes, accuracy
│   └── notifier.py            # Sends signals via WhatsApp (existing bot)
├── dashboard/
│   ├── server.py              # FastAPI dashboard (port 8101)
│   └── index.html             # Real-time CLI + web dashboard
├── data/
│   └── isotope.db             # SQLite database
├── tests/
│   └── backtest.py            # Backtesting engine
├── config.py                  # All config, env vars, constants
├── main.py                    # Single entry point: python main.py
├── requirements.txt
└── .env                       # Secrets only — never commit this
```

---

## TECH STACK

| Layer | Tool | Why |
|-------|------|-----|
| Data | yfinance | Free, no key, reliable gold OHLCV |
| Data backup | Alpha Vantage free | 500 calls/day, real-time gold |
| Analysis | pandas, numpy, ta-lib | Industry standard |
| ML signals | scikit-learn | Lightweight, VPS-friendly |
| API | FastAPI + uvicorn | Fast, async |
| Database | SQLite (aiosqlite) | Zero config, VPS-friendly |
| Scheduler | APScheduler | Cron-like, Python native |
| Notifications | WhatsApp via existing bot at port 8765 | Already live |
| Process | systemd service | Auto-restart on crash |

---

## GOLD DATA SOURCES (FREE, NO KEY NEEDED)

```python
# Primary: yfinance — always available
import yfinance as yf
gold = yf.download("GC=F", period="1d", interval="1h")

# Backup: Alpha Vantage (get free key at alphavantage.co)
# ALPHA_VANTAGE_KEY in .env — 500 calls/day free

# Sentiment: RSS feeds (no key needed)
# - Reuters Gold: https://feeds.reuters.com/reuters/businessNews
# - Kitco: https://www.kitco.com/rss/
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

```python
# Every signal MUST include these:
signal = {
    "direction": "BUY" | "SELL",
    "entry": float,           # Entry price
    "stop_loss": float,       # Always set. No exceptions.
    "take_profit_1": float,   # First target (1:1.5 RR minimum)
    "take_profit_2": float,   # Second target (1:3 RR)
    "confidence": float,      # 0.0 - 1.0
    "timeframe": "H1" | "H4" | "D1",
    "rationale": str,         # Why. Always explain.
    "risk_reward": float,     # Minimum 1.5
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
🤖 ISOTOPE v1.0 | ELEV8 DIGITAL
```

---

## CODING STANDARDS (FOLLOW ALWAYS)

- **Python 3.11+** — use `asyncio` everywhere, nothing blocking
- **Type hints on every function** — no exceptions
- **Every agent is a class** — clean OOP
- **Config lives in `config.py`** — never hardcode values
- **Secrets live in `.env`** — never in code
- **Every error is caught and logged** — no silent failures
- **Every function has a docstring** — one line minimum
- **SQLite for all persistence** — no Postgres/Redis until scale demands it
- **One responsibility per file** — if a file does two things, split it
- **Test signal logic in backtest.py before production**

---

## VPS CONTEXT

- **IP**: 185.167.97.193
- **OS**: Ubuntu 22.04 LTS
- **User**: root
- **Project path**: /root/isotope/
- **Services**: systemd (isotope.service)
- **Existing bots**: WhatsApp bot on original VPS (113.30.189.89) — notifier.py must POST to it
- **Port 8100**: Orchestrator API
- **Port 8101**: Dashboard

---

## DEPLOYMENT

```bash
# Start everything
python main.py

# Or via systemd
systemctl start isotope
systemctl status isotope
journalctl -u isotope -f
```

---

## PHASE PLAN

```
PHASE 1 (NOW)    → Data pipeline + single strategy signal working
PHASE 2          → All 5 confluence systems active
PHASE 3          → ML model trained on historical gold data
PHASE 4          → Live accuracy tracking + self-improvement
PHASE 5          → Add Silver, then indices, then crypto
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

---

## WHEN STUCK

1. Check `journalctl -u isotope -f` first
2. Check `data/isotope.db` for bad data
3. Check `config.py` for wrong values
4. Run `python tests/backtest.py` to isolate signal logic
5. If still stuck → escalate to Claude in chat with exact error + file + line number
