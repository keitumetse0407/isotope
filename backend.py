"""
ISOTOPE FastAPI Backend — Mobile App API
Runs on port 8100
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import random

app = FastAPI(title="ISOTOPE API", version="1.0.0")

# Enable CORS for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# MODELS
# ============================================

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

class User(BaseModel):
    id: str
    email: str
    name: str
    subscription: str = "free"
    trialEndsAt: Optional[str] = None
    disclaimerAccepted: bool = False

class Prediction(BaseModel):
    id: str
    question: str
    userVote: str  # "YES" or "NO"
    crowdYesPercent: float
    closesAt: str
    status: str = "open"

class LeaderboardEntry(BaseModel):
    rank: int
    userId: str
    name: str
    score: float
    accuracy: float
    streak: int

# ============================================
# MOCK DATA (Replace with real orchestrator)
# ============================================

CURRENT_SIGNAL = Signal(
    id="sig_" + datetime.now().strftime("%Y%m%d_%H%M%S"),
    direction="BUY",
    entry=2345.00,
    stopLoss=2330.00,
    takeProfit1=2367.50,
    takeProfit2=2390.00,
    confidence=0.87,
    timeframe="H4",
    rationale="Strong EMA alignment (9>21>50) + RSI recovery from oversold (32→45) + MACD histogram turning positive + Price bouncing off key support at $2330 + DXY showing bearish divergence. 5/5 agents agree → STRONG SIGNAL.",
    riskReward=3.0,
    timestamp=datetime.now().isoformat(),
    status="active"
)

PREDICTIONS = [
    Prediction(
        id="pred_001",
        question="Will gold close higher than open on Friday?",
        userVote="YES",
        crowdYesPercent=73.5,
        closesAt="2026-03-29T17:00:00Z",
        status="open"
    )
]

LEADERBOARD = [
    LeaderboardEntry(rank=1, userId="u1", name="Thabo M.", score=92.0, accuracy=0.85, streak=5),
    LeaderboardEntry(rank=2, userId="u2", name="Priya K.", score=87.0, accuracy=0.80, streak=4),
    LeaderboardEntry(rank=3, userId="u3", name="Johan V.", score=81.0, accuracy=0.75, streak=3),
]

# ============================================
# ENDPOINTS
# ============================================

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/signals/latest")
async def get_latest_signal():
    """Get the latest AI signal"""
    return CURRENT_SIGNAL

@app.get("/signals")
async def get_signals(limit: int = 10):
    """Get recent signals"""
    return [CURRENT_SIGNAL]

@app.get("/predictions")
async def get_predictions():
    """Get active predictions"""
    return PREDICTIONS

@app.post("/predictions/vote")
async def vote_prediction(prediction_id: str, vote: str):
    """Vote on a prediction"""
    return {"success": True, "message": f"Voted {vote} on {prediction_id}"}

@app.get("/leaderboard")
async def get_leaderboard():
    """Get weekly leaderboard"""
    return LEADERBOARD

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    """Get user by ID"""
    return User(
        id=user_id,
        email="user@example.com",
        name="Test User",
        subscription="free",
        disclaimerAccepted=True
    )

@app.post("/users")
async def create_user(email: str, name: str):
    """Create new user"""
    return User(
        id="user_" + datetime.now().strftime("%Y%m%d%H%M%S"),
        email=email,
        name=name,
        subscription="free",
        disclaimerAccepted=False
    )

@app.put("/users/{user_id}/disclaimer")
async def accept_disclaimer(user_id: str, data: dict):
    """Accept FSCA disclaimer"""
    return {"success": True, "message": "Disclaimer accepted"}

@app.post("/users/{user_id}/trial")
async def start_trial(user_id: str):
    """Start free trial"""
    return {"success": True, "trialEndsAt": "2026-04-05T00:00:00Z"}

@app.get("/admin/stats")
async def get_admin_stats():
    """Get admin dashboard stats"""
    return {
        "totalUsers": 0,
        "trialUsers": 0,
        "proUsers": 0,
        "eliteUsers": 0,
        "mrr": 0.0,
        "todayRevenue": 0.0,
        "totalRevenue": 0.0,
        "totalSignals": 1,
        "wins": 1,
        "losses": 0,
        "automationStatus": {}
    }

@app.get("/performance")
async def get_performance():
    """Get signal performance"""
    return {
        "totalSignals": 1,
        "wins": 1,
        "losses": 0,
        "accuracy": 1.0,
        "avgGain": 1.8
    }

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    import uvicorn
    print("🚀 ISOTOPE API starting on port 8100...")
    uvicorn.run(app, host="0.0.0.0", port=8100)
