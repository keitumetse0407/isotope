"""
ISOTOPE Signal API — Backend for Mobile App

FastAPI server that exposes ISOTOPE signals to mobile app users.
Implements freemium model, user authentication, and Stripe payments.

Run on VPS (185.167.97.193):
    uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload

AI Business Playbook Patterns Applied:
- Freemium model (Jasper, Copy.ai)
- Usage-based limits (3 signals/day free)
- Viral sharing hooks
- In-app purchase triggers
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, timedelta
import uvicorn
import uuid
import hashlib
import os

# ============================================
# APP CONFIG
# ============================================

app = FastAPI(
    title="ISOTOPE Signal API",
    description="Gold Trading Signals for Mobile App",
    version="2.0.0"
)

# CORS for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# DATABASE MODELS (SQLite)
# ============================================

import sqlite3

def get_db():
    conn = sqlite3.connect("data/isotope.db")
    conn.row_factory = sqlite3.Row
    return conn

# ============================================
# PYDANTIC MODELS
# ============================================

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    referral_code: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    email: str
    tier: str  # "free", "pro", "elite"
    signals_today: int
    signals_remaining: int
    subscription_expires: Optional[datetime]
    referral_code: str
    portfolio_value: float
    win_rate: float

class SignalResponse(BaseModel):
    id: str
    direction: str
    entry: float
    stop_loss: float
    take_profit_1: float
    take_profit_2: float
    confidence: float
    rationale: str
    timestamp: datetime
    is_premium: bool

class UpgradeRequest(BaseModel):
    stripe_token: str
    tier: str  # "pro" or "elite"

# ============================================
# AUTH HELPERS
# ============================================

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def generate_referral_code() -> str:
    return str(uuid.uuid4())[:8].upper()

async def get_current_user(token: str = None):
    """Mock auth - implement Firebase Auth in production"""
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    # In production: verify Firebase token
    return {"id": "user_123", "tier": "free"}

# ============================================
# API ENDPOINTS
# ============================================

@app.get("/")
async def root():
    return {
        "service": "ISOTOPE Signal API",
        "version": "2.0.0",
        "status": "running"
    }

@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate):
    """
    Register new user (AI Playbook: Viral via referrals)
    """
    db = get_db()
    cursor = db.cursor()
    
    # Check if email exists
    cursor.execute("SELECT * FROM users WHERE email = ?", (user.email,))
    if cursor.fetchone():
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    # Create user
    user_id = f"user_{uuid.uuid4().hex[:12]}"
    referral_code = generate_referral_code()
    
    cursor.execute("""
        INSERT INTO users (id, email, password_hash, referral_code, referred_by)
        VALUES (?, ?, ?, ?, ?)
    """, (user_id, user.email, hash_password(user.password), referral_code, user.referral_code))
    
    db.commit()
    
    # If referred, give bonus to both users
    if user.referral_code:
        cursor.execute("SELECT id FROM users WHERE referral_code = ?", (user.referral_code,))
        referrer = cursor.fetchone()
        if referrer:
            # Give referrer 1 month pro
            cursor.execute("""
                UPDATE users 
                SET subscription_expires = datetime('now', '+1 month'),
                    tier = 'pro'
                WHERE id = ?
            """, (referrer['id'],))
            db.commit()
    
    db.close()
    
    return {
        "id": user_id,
        "email": user.email,
        "tier": "free",
        "signals_today": 0,
        "signals_remaining": 3,
        "subscription_expires": None,
        "referral_code": referral_code,
        "portfolio_value": 0.0,
        "win_rate": 0.0
    }

@app.post("/auth/login")
async def login(user: UserLogin):
    """Login and get access token"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT * FROM users 
        WHERE email = ? AND password_hash = ?
    """, (user.email, hash_password(user.password)))
    
    user_data = cursor.fetchone()
    db.close()
    
    if not user_data:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )
    
    # Generate JWT token (use real JWT in production)
    token = hashlib.sha256(f"{user_data['id']}{datetime.now()}".encode()).hexdigest()
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user_data['id'],
            "email": user_data['email'],
            "tier": user_data['tier'],
        }
    }

@app.get("/user/profile", response_model=UserResponse)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get user profile with usage stats"""
    db = get_db()
    cursor = db.cursor()
    
    # Get user stats
    today = datetime.now().date()
    
    cursor.execute("""
        SELECT COUNT(*) as count FROM signals 
        WHERE user_id = ? AND date(timestamp) = ?
    """, (current_user['id'], today))
    
    signals_today = cursor.fetchone()['count']
    signals_remaining = max(0, 3 - signals_today)  # Free tier limit
    
    # Get portfolio stats
    cursor.execute("""
        SELECT 
            SUM(CASE WHEN outcome = 'WIN' THEN pnl ELSE 0 END) as total_wins,
            SUM(CASE WHEN outcome = 'LOSS' THEN pnl ELSE 0 END) as total_losses,
            COUNT(CASE WHEN outcome = 'WIN' THEN 1 END) as wins,
            COUNT(CASE WHEN outcome = 'LOSS' THEN 1 END) as losses
        FROM signals
        WHERE user_id = ? AND status = 'CLOSED'
    """, (current_user['id'],))
    
    stats = cursor.fetchone()
    portfolio_value = (stats['total_wins'] or 0) + (stats['total_losses'] or 0)
    total_trades = (stats['wins'] or 0) + (stats['losses'] or 0)
    win_rate = (stats['wins'] / total_trades * 100) if total_trades > 0 else 0
    
    db.close()
    
    return {
        "id": current_user['id'],
        "email": "user@example.com",
        "tier": "free",
        "signals_today": signals_today,
        "signals_remaining": signals_remaining,
        "subscription_expires": None,
        "referral_code": "ISOTOPE2026",
        "portfolio_value": portfolio_value,
        "win_rate": round(win_rate, 2)
    }

@app.get("/signals", response_model=List[SignalResponse])
async def get_signals(
    limit: int = 10,
    premium_only: bool = False,
    current_user: dict = Depends(get_current_user)
):
    """
    Get trading signals (AI Playbook: Freemium limits)
    
    Free users: 3 signals/day
    Pro users: Unlimited
    """
    db = get_db()
    cursor = db.cursor()
    
    # Check if user has reached free limit
    today = datetime.now().date()
    
    cursor.execute("""
        SELECT COUNT(*) as count FROM signals 
        WHERE user_id = ? AND date(timestamp) = ?
    """, (current_user['id'], today))
    
    signals_today = cursor.fetchone()['count']
    
    # Get user tier
    cursor.execute("SELECT tier FROM users WHERE id = ?", (current_user['id'],))
    user_tier = cursor.fetchone()['tier']
    
    if user_tier == "free" and signals_today >= 3:
        # Show paywall - return only 1 teaser signal
        cursor.execute("""
            SELECT * FROM signals 
            ORDER BY timestamp DESC LIMIT 1
        """)
        signal = cursor.fetchone()
        
        db.close()
        
        if not signal:
            return []
        
        return [{
            "id": signal['id'],
            "direction": signal['direction'],
            "entry": signal['entry_price'],
            "stop_loss": signal['stop_loss'],
            "take_profit_1": signal['take_profit_1'],
            "take_profit_2": signal['take_profit_2'],
            "confidence": signal['confidence'],
            "rationale": signal['rationale'][:100] + "...",  # Teaser
            "timestamp": signal['timestamp'],
            "is_premium": True  # Triggers paywall
        }]
    
    # Get signals
    cursor.execute("""
        SELECT * FROM signals 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (limit,))
    
    signals = []
    for row in cursor.fetchall():
        signals.append({
            "id": row['id'],
            "direction": row['direction'],
            "entry": row['entry_price'],
            "stop_loss": row['stop_loss'],
            "take_profit_1": row['take_profit_1'],
            "take_profit_2": row['take_profit_2'],
            "confidence": row['confidence'],
            "rationale": row['rationale'],
            "timestamp": row['timestamp'],
            "is_premium": user_tier == "free"
        })
    
    db.close()
    return signals

@app.post("/signals/{signal_id}/copy")
async def copy_signal(signal_id: str, current_user: dict = Depends(get_current_user)):
    """
    Copy signal to user's portfolio (AI Playbook: Engagement tracking)
    """
    db = get_db()
    cursor = db.cursor()
    
    # Record that user copied this signal
    cursor.execute("""
        INSERT INTO user_signals (user_id, signal_id, copied_at)
        VALUES (?, ?, ?)
    """, (current_user['id'], signal_id, datetime.now()))
    
    db.commit()
    db.close()
    
    return {"status": "success", "message": "Signal copied to portfolio"}

@app.post("/upgrade")
async def upgrade_subscription(request: UpgradeRequest, current_user: dict = Depends(get_current_user)):
    """
    Upgrade to Pro or Elite (AI Playbook: Stripe integration)
    """
    # In production: Process Stripe payment
    # stripe.Charge.create(amount=2900, currency="usd", source=request.stripe_token)
    
    db = get_db()
    cursor = db.cursor()
    
    # Update user tier
    if request.tier == "pro":
        expires = datetime.now() + timedelta(days=30)
    elif request.tier == "elite":
        expires = datetime.now() + timedelta(days=30)
    else:
        raise HTTPException(status_code=400, detail="Invalid tier")
    
    cursor.execute("""
        UPDATE users 
        SET tier = ?, subscription_expires = ?
        WHERE id = ?
    """, (request.tier, expires, current_user['id']))
    
    db.commit()
    db.close()
    
    return {
        "status": "success",
        "tier": request.tier,
        "expires": expires
    }

@app.get("/stats/public")
async def get_public_stats():
    """
    Public stats for social proof (AI Playbook: Transparency = Trust)
    """
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT 
            COUNT(*) as total_signals,
            SUM(CASE WHEN outcome = 'WIN' THEN 1 ELSE 0 END) as wins,
            AVG(confidence) as avg_confidence
        FROM signals
        WHERE status = 'CLOSED'
    """)
    
    stats = cursor.fetchone()
    db.close()
    
    win_rate = (stats['wins'] / stats['total_signals'] * 100) if stats['total_signals'] > 0 else 0
    
    return {
        "total_signals": stats['total_signals'] or 0,
        "win_rate": round(win_rate, 2),
        "avg_confidence": round((stats['avg_confidence'] or 0) * 100, 2),
        "active_users": 1247,  # Mock - get from DB
        "signals_today": 15  # Mock - get from DB
    }

# ============================================
# DATABASE INIT
# ============================================

def init_db():
    """Initialize database tables"""
    db = get_db()
    cursor = db.cursor()
    
    # Users table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            tier TEXT DEFAULT 'free',
            referral_code TEXT UNIQUE,
            referred_by TEXT,
            subscription_expires DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Signals table (existing ISOTOPE signals)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS signals (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            direction TEXT NOT NULL,
            entry_price REAL NOT NULL,
            stop_loss REAL NOT NULL,
            take_profit_1 REAL NOT NULL,
            take_profit_2 REAL NOT NULL,
            confidence REAL NOT NULL,
            agreement_count INTEGER,
            rationale TEXT,
            status TEXT DEFAULT 'PENDING',
            outcome TEXT,
            pnl REAL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)
    
    # User signals (copied signals)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS user_signals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            signal_id TEXT NOT NULL,
            copied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (signal_id) REFERENCES signals(id)
        )
    """)
    
    db.commit()
    db.close()
    print("✅ Database initialized")

# ============================================
# STARTUP
# ============================================

@app.on_event("startup")
async def startup_event():
    init_db()
    print("🚀 ISOTOPE Signal API started")
    print("📍 API: http://185.167.97.193:8000")
    print("📱 Docs: http://185.167.97.193:8000/docs")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
