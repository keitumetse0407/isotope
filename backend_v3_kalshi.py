"""
ISOTOPE v3.0 — KALSHI-STYLE PREDICTION MARKET + 24/7 AUTONOMOUS TRADING

Built by Keitumetse (Elkai) | ELEV8 DIGITAL
Inspired by: Kalshi ($11B valuation), Saitama (One Punch), Munger (Lollapalooza)

KALSHI ADAPTATION:
- Users trade YES/NO contracts on gold events (not just vote)
- Contract price = crowd's probability (e.g., 73¢ = 73% chance)
- Winners get $1 per contract, losers get $0
- Platform earns: transaction fees + spread
- 24/7 AI agents trade autonomously alongside users
- Users can COPY top AI agents (auto-follow their trades)

REVENUE STREAMS:
1. Subscription (Pro R139/mo, Elite R299/mo)
2. Transaction fees (2% per contract trade)
3. Spread (buy at 73¢, sell at 71¢ = 2¢ spread)
4. Premium AI agents (Elite tier only)
5. Revenue share for top predictors (20% of their followers' fees)

24/7 MODE:
- AI agents trade while you sleep
- Users allocate % of portfolio to each agent
- Agents rebalance hourly based on market conditions
- Stop-loss on every agent position
- Daily P/L report via WhatsApp

MODULAR ARCHITECTURE:
- Plugin system for new features
- Hot-reload configuration
- No tedious rebuilds needed
- Add new AI agents via config file
- Add new prediction markets via admin panel

SAITAMA EASTER EGG:
- One-Punch Mode: 100% confidence signals (rare, powerful)
- Bald UI theme (joke feature)
- "Serious Series" achievement for 10-win streak
"""

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime, timedelta
from enum import Enum
import uuid
import random
import json
import asyncio
from dataclasses import dataclass, asdict
from contextlib import asynccontextmanager

# ============================================
# LIFESPAN MANAGEMENT
# ============================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🚀 ISOTOPE v3.0 starting...")
    print("📊 Kalshi-style prediction market: ACTIVE")
    print("🤖 24/7 AI trading agents: ACTIVE")
    print("🔌 Modular plugin system: READY")
    print("👊 Saitama mode: HIDDEN")
    
    # Start background tasks
    asyncio.create_task(run_24_7_trading_loop())
    
    yield
    
    # Shutdown
    print("🛑 ISOTOPE shutting down...")

app = FastAPI(
    title="ISOTOPE v3.0",
    description="Kalshi-Style Prediction Market + 24/7 AI Trading",
    version="3.0.0",
    lifespan=lifespan
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# ENUMS & DATA CLASSES
# ============================================

class ContractType(str, Enum):
    YES = "YES"
    NO = "NO"

class MarketStatus(str, Enum):
    OPEN = "open"
    CLOSED = "closed"
    RESOLVED = "resolved"

class AgentStrategy(str, Enum):
    MOMENTUM = "momentum"
    MEAN_REVERSION = "mean_reversion"
    BREAKOUT = "breakout"
    SENTIMENT = "sentiment"
    KALLY_CROSSOVER = "kally_crossover"  # Saitama special

class SubscriptionTier(str, Enum):
    FREE = "free"
    PRO = "pro"
    ELITE = "elite"

# ============================================
# PYDANTIC MODELS
# ============================================

class PredictionMarket(BaseModel):
    id: str
    question: str
    category: str  # "gold", "forex", "crypto", "events"
    yes_bid: float  # Price to buy YES (0-100 cents)
    yes_ask: float  # Price to sell YES
    no_bid: float   # Price to buy NO
    no_ask: float   # Price to sell NO
    last_price: float
    volume: int
    open_interest: int
    closes_at: datetime
    status: MarketStatus = MarketStatus.OPEN
    result: Optional[bool] = None  # True = YES wins, False = NO wins
    
    def get_yes_price(self) -> float:
        """Current price to buy YES contract"""
        return self.yes_ask
    
    def get_no_price(self) -> float:
        """Current price to buy NO contract"""
        return self.no_ask

class UserPosition(BaseModel):
    id: str
    user_id: str
    market_id: str
    contract_type: ContractType
    quantity: int
    entry_price: float
    current_value: float
    unrealized_pnl: float
    realized_pnl: float = 0.0
    opened_at: datetime
    closed_at: Optional[datetime] = None

class UserPortfolio(BaseModel):
    user_id: str
    cash_balance: float
    portfolio_value: float
    total_positions: int
    unrealized_pnl: float
    realized_pnl: float
    positions: List[UserPosition] = []

class AIAgent(BaseModel):
    id: str
    name: str
    strategy: AgentStrategy
    description: str
    performance_30d: float  # % return
    win_rate: float
    total_trades: int
    followers: int
    min_allocation: float  # Minimum $ to copy
    management_fee: float  # % of profits
    is_active: bool = True
    is_premium: bool = False  # Elite only

class CopyTradeAllocation(BaseModel):
    agent_id: str
    user_id: str
    allocation_amount: float
    allocation_percent: float
    current_value: float
    pnl: float
    started_at: datetime

class Signal(BaseModel):
    id: str
    direction: str
    entry: float
    stopLoss: float
    takeProfit1: float
    takeProfit2: float
    confidence: float
    timeframe: str
    rationale: str
    riskReward: float
    timestamp: str
    status: str = "active"
    agent_name: str = "ISOTOPE Core"
    is_saitama_mode: bool = False  # Easter egg

class User(BaseModel):
    id: str
    email: str
    name: str
    subscription: SubscriptionTier = SubscriptionTier.FREE
    balance: float = 10000.0  # Demo balance
    real_money_balance: float = 0.0  # For real trading
    disclaimer_accepted: bool = False
    created_at: datetime = Field(default_factory=datetime.now)
    is_24_7_mode_enabled: bool = False
    saitama_unlocked: bool = False  # Easter egg

class LeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    name: str
    total_pnl: float
    win_rate: float
    roi: float
    followers: int
    is_ai_agent: bool = False

# ============================================
# IN-MEMORY DATABASE (Replace with SQLite/Postgres)
# ============================================

# Markets
MARKETS: Dict[str, PredictionMarket] = {
    "gold_fri_close": PredictionMarket(
        id="gold_fri_close",
        question="Will gold close higher than open on Friday?",
        category="gold",
        yes_bid=71,
        yes_ask=73,
        no_bid=27,
        no_ask=29,
        last_price=72,
        volume=15420,
        open_interest=8500,
        closes_at=datetime.now() + timedelta(days=2),
        status=MarketStatus.OPEN
    ),
    "gold_2400_march": PredictionMarket(
        id="gold_2400_march",
        question="Will gold hit $2400 before March 31?",
        category="gold",
        yes_bid=45,
        yes_ask=48,
        no_bid=52,
        no_ask=55,
        last_price=46,
        volume=8900,
        open_interest=4200,
        closes_at=datetime(2026, 3, 31, 23, 59, 59),
        status=MarketStatus.OPEN
    ),
    "usdzar_1950": PredictionMarket(
        id="usdzar_1950",
        question="Will USD/ZAR break 19.50 this week?",
        category="forex",
        yes_bid=62,
        yes_ask=65,
        no_bid=35,
        no_ask=38,
        last_price=63,
        volume=5600,
        open_interest=2800,
        closes_at=datetime.now() + timedelta(days=5),
        status=MarketStatus.OPEN
    ),
    "loadshedding_stage4": PredictionMarket(
        id="loadshedding_stage4",
        question="Will Stage 6+ load shedding be announced this month?",
        category="events",
        yes_bid=38,
        yes_ask=42,
        no_bid=58,
        no_ask=62,
        last_price=40,
        volume=12300,
        open_interest=6700,
        closes_at=datetime(2026, 3, 31, 23, 59, 59),
        status=MarketStatus.OPEN
    ),
}

# User portfolios
PORTFOLIOS: Dict[str, UserPortfolio] = {}

# AI Agents
AI_AGENTS: Dict[str, AIAgent] = {
    "agent_momentum": AIAgent(
        id="agent_momentum",
        name="Momentum Master",
        strategy=AgentStrategy.MOMENTUM,
        description="Rides strong trends. Best in trending markets.",
        performance_30d=18.5,
        win_rate=0.72,
        total_trades=156,
        followers=234,
        min_allocation=100.0,
        management_fee=0.15,
        is_active=True,
        is_premium=False
    ),
    "agent_mean_rev": AIAgent(
        id="agent_mean_rev",
        name="Mean Reversion King",
        strategy=AgentStrategy.MEAN_REVERSION,
        description="Buys dips, sells rips. Range-bound specialist.",
        performance_30d=12.3,
        win_rate=0.68,
        total_trades=289,
        followers=187,
        min_allocation=100.0,
        management_fee=0.12,
        is_active=True,
        is_premium=False
    ),
    "agent_sentiment": AIAgent(
        id="agent_sentiment",
        name="Sentiment Sniper",
        strategy=AgentStrategy.SENTIMENT,
        description="News + social media analysis. Contrarian plays.",
        performance_30d=24.7,
        win_rate=0.65,
        total_trades=98,
        followers=412,
        min_allocation=500.0,
        management_fee=0.20,
        is_active=True,
        is_premium=True  # Elite only
    ),
    "agent_saitama": AIAgent(
        id="agent_saitama",
        name="👊 ONE PUNCH MAN",
        strategy=AgentStrategy.KALLY_CROSSOVER,
        description="SECRET AGENT. Only activates on 100% confidence. ONE PUNCH = ONE TRADE.",
        performance_30d=999.9,  # Easter egg
        win_rate=1.0,
        total_trades=7,  # Saitama only needs 7 trades
        followers=666,
        min_allocation=1000.0,
        management_fee=0.30,
        is_active=False,  # Hidden until unlocked
        is_premium=True
    ),
}

# Copy trade allocations
COPY_TRADES: Dict[str, CopyTradeAllocation] = {}

# Active signals
SIGNALS: List[Signal] = []

# Users
USERS: Dict[str, User] = {}

# ============================================
# 24/7 AUTONOMOUS TRADING LOOP
# ============================================

async def run_24_7_trading_loop():
    """
    Background task: AI agents trade 24/7 while users sleep.
    Runs every 5 minutes, checks all markets, executes trades.
    """
    print("🤖 24/7 AI Trading Loop started...")
    
    while True:
        try:
            await asyncio.sleep(300)  # 5 minutes
            
            # For each active AI agent
            for agent_id, agent in AI_AGENTS.items():
                if not agent.is_active:
                    continue
                
                # Analyze markets
                for market_id, market in MARKETS.items():
                    if market.status != MarketStatus.OPEN:
                        continue
                    
                    # Agent-specific logic
                    should_trade = False
                    contract_type = ContractType.YES
                    quantity = 10
                    
                    if agent.strategy == AgentStrategy.MOMENTUM:
                        # Trade with momentum
                        if market.last_price > 70:
                            should_trade = True
                            contract_type = ContractType.YES
                        elif market.last_price < 30:
                            should_trade = True
                            contract_type = ContractType.NO
                    
                    elif agent.strategy == AgentStrategy.MEAN_REVERSION:
                        # Fade extremes
                        if market.last_price > 80:
                            should_trade = True
                            contract_type = ContractType.NO
                        elif market.last_price < 20:
                            should_trade = True
                            contract_type = ContractType.YES
                    
                    elif agent.strategy == AgentStrategy.KALLY_CROSSOVER:
                        # SAITAMA MODE: Only 100% confidence
                        if random.random() < 0.01:  # 1% chance = rare
                            should_trade = True
                            quantity = 100  # Big bet
                            print("👊 ONE PUNCH MAN ACTIVATED!")
                    
                    if should_trade:
                        # Execute trade (mock)
                        print(f"🤖 {agent.name} trading {market.question}: {contract_type.value} x{quantity}")
                        
                        # Update followers' copy trades
                        for alloc in list(COPY_TRADES.values()):
                            if alloc.agent_id == agent_id:
                                # Auto-copy trade for followers
                                pass  # Implement in production
                        
        except Exception as e:
            print(f"❌ 24/7 loop error: {e}")
            await asyncio.sleep(60)

# ============================================
# PREDICTION MARKET ENDPOINTS
# ============================================

@app.get("/markets")
async def get_markets(category: Optional[str] = None):
    """Get all active prediction markets"""
    if category:
        return [m.dict() for m in MARKETS.values() if m.category == category]
    return [m.dict() for m in MARKETS.values() if m.status == MarketStatus.OPEN]

@app.get("/market/{market_id}")
async def get_market(market_id: str):
    """Get single market details"""
    if market_id not in MARKETS:
        raise HTTPException(404, "Market not found")
    return MARKETS[market_id].dict()

@app.post("/market/{market_id}/trade")
async def trade_contract(
    market_id: str,
    contract_type: ContractType,
    quantity: int,
    user_id: str
):
    """
    Buy YES or NO contracts on a prediction market.
    
    KALSHI MECHANICS:
    - YES contract costs yes_ask cents, pays $1 if event happens
    - NO contract costs no_ask cents, pays $1 if event doesn't happen
    - Can sell anytime before close at current market price
    """
    if market_id not in MARKETS:
        raise HTTPException(404, "Market not found")
    
    market = MARKETS[market_id]
    
    if market.status != MarketStatus.OPEN:
        raise HTTPException(400, "Market is closed")
    
    # Calculate cost
    if contract_type == ContractType.YES:
        price_per_contract = market.yes_ask / 100  # Convert cents to dollars
    else:
        price_per_contract = market.no_ask / 100
    
    total_cost = price_per_contract * quantity
    
    # Check user balance
    if user_id not in PORTFOLIOS:
        PORTFOLIOS[user_id] = UserPortfolio(
            user_id=user_id,
            cash_balance=10000.0,  # Demo starting balance
            portfolio_value=10000.0,
            total_positions=0,
            unrealized_pnl=0.0,
            realized_pnl=0.0
        )
    
    portfolio = PORTFOLIOS[user_id]
    
    if portfolio.cash_balance < total_cost:
        raise HTTPException(400, f"Insufficient balance. Need ${total_cost:.2f}, have ${portfolio.cash_balance:.2f}")
    
    # Create position
    position = UserPosition(
        id=str(uuid.uuid4()),
        user_id=user_id,
        market_id=market_id,
        contract_type=contract_type,
        quantity=quantity,
        entry_price=price_per_contract,
        current_value=price_per_contract * quantity,
        unrealized_pnl=0.0,
        opened_at=datetime.now()
    )
    
    # Update portfolio
    portfolio.cash_balance -= total_cost
    portfolio.positions.append(position)
    portfolio.total_positions = len([p for p in portfolio.positions if p.closed_at is None])
    
    # Update market volume
    market.volume += quantity
    
    # Transaction fee (2%)
    fee = total_cost * 0.02
    
    return {
        "success": True,
        "position": position.dict(),
        "total_cost": total_cost,
        "fee": fee,
        "remaining_balance": portfolio.cash_balance,
        "message": f"Bought {quantity} {contract_type.value} contracts @ {price_per_contract*100:.0f}¢ each"
    }

@app.post("/position/{position_id}/sell")
async def sell_position(position_id: str, user_id: str):
    """Sell position before market closes"""
    portfolio = PORTFOLIOS.get(user_id)
    if not portfolio:
        raise HTTPException(404, "Portfolio not found")
    
    position = next((p for p in portfolio.positions if p.id == position_id), None)
    if not position:
        raise HTTPException(404, "Position not found")
    
    if position.closed_at is not None:
        raise HTTPException(400, "Position already closed")
    
    market = MARKETS.get(position.market_id)
    if not market:
        raise HTTPException(404, "Market not found")
    
    # Calculate current value
    if position.contract_type == ContractType.YES:
        exit_price = market.yes_bid / 100
    else:
        exit_price = market.no_bid / 100
    
    exit_value = exit_price * position.quantity
    pnl = exit_value - (position.entry_price * position.quantity)
    
    # Update position
    position.closed_at = datetime.now()
    position.realized_pnl = pnl
    position.current_value = exit_value
    
    # Update portfolio
    portfolio.cash_balance += exit_value
    portfolio.realized_pnl += pnl
    
    return {
        "success": True,
        "exit_value": exit_value,
        "pnl": pnl,
        "new_balance": portfolio.cash_balance,
        "message": f"Sold position: {'Profit' if pnl >= 0 else 'Loss'} of ${abs(pnl):.2f}"
    }

@app.get("/portfolio/{user_id}")
async def get_portfolio(user_id: str):
    """Get user's portfolio with all positions"""
    if user_id not in PORTFOLIOS:
        PORTFOLIOS[user_id] = UserPortfolio(
            user_id=user_id,
            cash_balance=10000.0,
            portfolio_value=10000.0,
            total_positions=0,
            unrealized_pnl=0.0,
            realized_pnl=0.0
        )
    
    portfolio = PORTFOLIOS[user_id]
    
    # Update unrealized PnL
    unrealized = 0.0
    for pos in portfolio.positions:
        if pos.closed_at is None:
            market = MARKETS.get(pos.market_id)
            if market:
                if pos.contract_type == ContractType.YES:
                    current_price = market.yes_bid / 100
                else:
                    current_price = market.no_bid / 100
                pos.current_value = current_price * pos.quantity
                pos.unrealized_pnl = pos.current_value - (pos.entry_price * pos.quantity)
                unrealized += pos.unrealized_pnl
    
    portfolio.unrealized_pnl = unrealized
    portfolio.portfolio_value = portfolio.cash_balance + sum(p.current_value for p in portfolio.positions if p.closed_at is None)
    
    return portfolio.dict()

# ============================================
# AI AGENTS & COPY TRADING
# ============================================

@app.get("/agents")
async def get_agents(premium_only: bool = False):
    """Get all AI trading agents"""
    agents = list(AI_AGENTS.values())
    if premium_only:
        agents = [a for a in agents if a.is_premium]
    return [a.dict() for a in agents if a.is_active]

@app.get("/agent/{agent_id}")
async def get_agent(agent_id: str):
    """Get single agent details"""
    if agent_id not in AI_AGENTS:
        raise HTTPException(404, "Agent not found")
    return AI_AGENTS[agent_id].dict()

@app.post("/agent/{agent_id}/copy")
async def copy_agent(agent_id: str, user_id: str, allocation_amount: float):
    """
    Copy trade an AI agent.
    User allocates $ amount, agent trades autonomously on their behalf.
    """
    if agent_id not in AI_AGENTS:
        raise HTTPException(404, "Agent not found")
    
    agent = AI_AGENTS[agent_id]
    
    if not agent.is_active:
        raise HTTPException(400, "Agent is not active")
    
    if allocation_amount < agent.min_allocation:
        raise HTTPException(400, f"Minimum allocation: ${agent.min_allocation}")
    
    # Check user balance
    if user_id not in PORTFOLIOS:
        PORTFOLIOS[user_id] = UserPortfolio(user_id=user_id, cash_balance=10000.0, portfolio_value=10000.0, total_positions=0, unrealized_pnl=0.0, realized_pnl=0.0)
    
    portfolio = PORTFOLIOS[user_id]
    if portfolio.cash_balance < allocation_amount:
        raise HTTPException(400, "Insufficient balance")
    
    # Create copy trade allocation
    allocation = CopyTradeAllocation(
        agent_id=agent_id,
        user_id=user_id,
        allocation_amount=allocation_amount,
        allocation_percent=allocation_amount / portfolio.portfolio_value * 100 if portfolio.portfolio_value > 0 else 0,
        current_value=allocation_amount,
        pnl=0.0,
        started_at=datetime.now()
    )
    
    COPY_TRADES[f"{user_id}_{agent_id}"] = allocation
    
    # Reserve funds
    portfolio.cash_balance -= allocation_amount
    
    # Update agent followers
    agent.followers += 1
    
    return {
        "success": True,
        "allocation": allocation.dict(),
        "message": f"Now copying {agent.name} with ${allocation_amount:.2f}",
        "management_fee": f"{agent.management_fee*100:.0f}% of profits"
    }

@app.get("/copy-trades/{user_id}")
async def get_copy_trades(user_id: str):
    """Get user's active copy trade allocations"""
    user_allocations = [a.dict() for a in COPY_TRADES.values() if a.user_id == user_id]
    return user_allocations

# ============================================
# 24/7 MODE TOGGLE
# ============================================

@app.post("/user/{user_id}/toggle-247")
async def toggle_247_mode(user_id: str, enable: bool):
    """Enable/disable 24/7 autonomous trading"""
    if user_id not in USERS:
        USERS[user_id] = User(id=user_id, email="user@example.com", name="User")
    
    user = USERS[user_id]
    user.is_24_7_mode_enabled = enable
    
    return {
        "success": True,
        "24_7_mode": enable,
        "message": "24/7 autonomous trading ENABLED 🤖" if enable else "24/7 mode disabled"
    }

@app.get("/user/{user_id}/247-status")
async def get_247_status(user_id: str):
    """Get 24/7 mode status and today's P/L"""
    if user_id not in USERS:
        return {"enabled": False, "today_pnl": 0.0, "message": "24/7 mode not enabled"}
    
    user = USERS[user_id]
    
    # Calculate today's P/L from copy trades
    today_pnl = sum(a.pnl for a in COPY_TRADES.values() if a.user_id == user_id)
    
    return {
        "enabled": user.is_24_7_mode_enabled,
        "today_pnl": today_pnl,
        "active_agents": len([a for a in COPY_TRADES.values() if a.user_id == user_id]),
        "message": "🤖 AI trading while you sleep" if user.is_24_7_mode_enabled else "Manual mode"
    }

# ============================================
# SAITAMA EASTER EGG
# ============================================

@app.post("/saitama/unlock/{user_id}")
async def unlock_saitama(user_id: str, secret_code: str):
    """
    Unlock Saitama mode.
    Secret code: "ONE_PUNCH" (case insensitive)
    
    Unlocks:
    - ONE PUNCH MAN AI agent
    - Bald UI theme option
    - Serious Series achievement tracking
    """
    if secret_code.upper() != "ONE_PUNCH":
        return {"success": False, "message": "Wrong code. Hint: It's what Saitama does."}
    
    if user_id not in USERS:
        USERS[user_id] = User(id=user_id, email="user@example.com", name="User")
    
    user = USERS[user_id]
    user.saitama_unlocked = True
    
    # Activate Saitama agent
    AI_AGENTS["agent_saitama"].is_active = True
    
    return {
        "success": True,
        "message": "👊 ONE PUNCH MAN UNLOCKED! Welcome to the Serious Series.",
        "unlocked_features": [
            "ONE PUNCH MAN AI Agent (100% confidence only)",
            "Bald Mode UI Theme",
            "Serious Series Achievements",
            "Secret Saitama Signals"
        ]
    }

@app.get("/saitama/signals")
async def get_saitama_signals():
    """
    Get Saitama-mode signals.
    Only available if user unlocked Saitama.
    These are 100% confidence, rare signals.
    """
    # In production, check user's unlock status
    saitama_signals = [
        Signal(
            id="saitama_001",
            direction="BUY",
            entry=2330.00,
            stopLoss=2320.00,
            takeProfit1=2380.00,
            takeProfit2=2430.00,
            confidence=1.0,
            timeframe="D1",
            rationale="👊 ONE PUNCH: All 5 agents + sentiment + macro alignment. This is THE trade.",
            riskReward=10.0,
            timestamp=datetime.now().isoformat(),
            status="active",
            agent_name="👊 ONE PUNCH MAN",
            is_saitama_mode=True
        )
    ]
    return [s.dict() for s in saitama_signals]

# ============================================
# LEADERBOARD (Weekly)
# ============================================

@app.get("/leaderboard")
async def get_leaderboard(period: str = "weekly"):
    """
    Get leaderboard for top traders.
    Includes both humans and AI agents.
    """
    leaderboard = [
        LeaderboardEntry(rank=1, user_id="agent_sentiment", name="🤖 Sentiment Sniper", total_pnl=2470.00, win_rate=0.65, roi=24.7, followers=412, is_ai_agent=True),
        LeaderboardEntry(rank=2, user_id="u_thabo", name="Thabo M.", total_pnl=1850.00, win_rate=0.72, roi=18.5, followers=89, is_ai_agent=False),
        LeaderboardEntry(rank=3, user_id="agent_momentum", name="🤖 Momentum Master", total_pnl=1850.00, win_rate=0.72, roi=18.5, followers=234, is_ai_agent=True),
        LeaderboardEntry(rank=4, user_id="u_priya", name="Priya K.", total_pnl=1230.00, win_rate=0.68, roi=12.3, followers=56, is_ai_agent=False),
        LeaderboardEntry(rank=5, user_id="agent_mean_rev", name="🤖 Mean Reversion King", total_pnl=1230.00, win_rate=0.68, roi=12.3, followers=187, is_ai_agent=True),
    ]
    
    # Add Saitama if unlocked (he's always #1)
    if AI_AGENTS["agent_saitama"].is_active:
        leaderboard.insert(0, LeaderboardEntry(rank=1, user_id="agent_saitama", name="👊 ONE PUNCH MAN", total_pnl=99999.00, win_rate=1.0, roi=999.9, followers=666, is_ai_agent=True))
        # Re-number ranks
        for i, entry in enumerate(leaderboard):
            entry.rank = i + 1
    
    return [e.dict() for e in leaderboard]

# ============================================
# MODULAR PLUGIN SYSTEM
# ============================================

class PluginConfig(BaseModel):
    name: str
    enabled: bool
    config: Dict[str, Any] = {}

PLUGINS: Dict[str, PluginConfig] = {
    "whatsapp_notifications": PluginConfig(name="WhatsApp Notifications", enabled=True),
    "telegram_signals": PluginConfig(name="Telegram Signals", enabled=True),
    "auto_rebalance": PluginConfig(name="Auto Rebalance", enabled=False),
    "risk_management": PluginConfig(name="Advanced Risk Management", enabled=True),
    "saitama_mode": PluginConfig(name="Saitama Mode", enabled=False),
}

@app.get("/plugins")
async def get_plugins():
    """Get all available plugins"""
    return [p.dict() for p in PLUGINS.values()]

@app.post("/plugins/{plugin_id}/toggle")
async def toggle_plugin(plugin_id: str, enable: bool):
    """Enable/disable a plugin"""
    if plugin_id not in PLUGINS:
        raise HTTPException(404, "Plugin not found")
    
    PLUGINS[plugin_id].enabled = enable
    
    return {
        "success": True,
        "plugin": plugin_id,
        "enabled": enable,
        "message": f"{PLUGINS[plugin_id].name} {'enabled' if enable else 'disabled'}"
    }

@app.post("/plugins/custom")
async def add_custom_plugin(name: str, config: Dict[str, Any]):
    """
    Add a custom plugin without rebuilding.
    Hot-reload supported.
    """
    plugin_id = f"custom_{name.lower().replace(' ', '_')}"
    PLUGINS[plugin_id] = PluginConfig(name=name, enabled=True, config=config)
    
    return {
        "success": True,
        "plugin_id": plugin_id,
        "message": f"Custom plugin '{name}' added and activated"
    }

# ============================================
# LEGACY ENDPOINTS (Backward Compatibility)
# ============================================

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "3.0.0", "timestamp": datetime.now().isoformat()}

@app.get("/signals/latest")
async def get_latest_signal():
    """Get latest AI signal (legacy endpoint)"""
    signal = Signal(
        id="sig_" + datetime.now().strftime("%Y%m%d_%H%M%S"),
        direction="BUY",
        entry=2345.00,
        stopLoss=2330.00,
        takeProfit1=2367.50,
        takeProfit2=2390.00,
        confidence=0.87,
        timeframe="H4",
        rationale="Strong EMA alignment + RSI recovery + MACD positive + Support bounce + DXY divergence = 5/5 agents agree",
        riskReward=3.0,
        timestamp=datetime.now().isoformat(),
        status="active"
    )
    return signal.dict()

@app.get("/signals")
async def get_signals():
    return [Signal(
        id="sig_001",
        direction="BUY",
        entry=2345.00,
        stopLoss=2330.00,
        takeProfit1=2367.50,
        takeProfit2=2390.00,
        confidence=0.87,
        timeframe="H4",
        rationale="Multi-agent confluence",
        riskReward=3.0,
        timestamp=datetime.now().isoformat(),
        status="active"
    ).dict()]

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("  ISOTOPE v3.0 — KALSHI-STYLE PREDICTION MARKET")
    print("  24/7 AI Trading | Copy Trading | Saitama Mode")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8100)
