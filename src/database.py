"""
ISOTOPE Database — SQLite Persistence

Dalio's Principle: "Radical transparency. Record everything."
Stores signals, outcomes, performance metrics for learning.

Termux-optimized: SQLite requires no server, minimal resources.
"""

import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any
import logging


class Database:
    """
    SQLite database for ISOTOPE.
    
    Tables:
    - signals: All generated signals
    - outcomes: Signal results (win/loss)
    - agent_performance: Per-agent accuracy tracking
    - daily_stats: Daily performance summaries
    """
    
    def __init__(self, db_path: str = "data/isotope.db"):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(exist_ok=True)
        self.logger = logging.getLogger("isotope.database")
        self.conn: Optional[sqlite3.Connection] = None
        self._connect()
        self._create_tables()
    
    def _connect(self):
        """Connect to SQLite database."""
        self.conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self.logger.info(f"Database connected: {self.db_path}")
    
    def _create_tables(self):
        """Create database schema."""
        cursor = self.conn.cursor()
        
        # Signals table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS signals (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                direction TEXT NOT NULL,
                entry_price REAL NOT NULL,
                stop_loss REAL NOT NULL,
                take_profit_1 REAL NOT NULL,
                take_profit_2 REAL NOT NULL,
                confidence REAL NOT NULL,
                agreement_count INTEGER NOT NULL,
                total_agents INTEGER NOT NULL,
                risk_reward REAL NOT NULL,
                rationale TEXT,
                position_size REAL,
                risk_amount REAL,
                risk_percent REAL,
                status TEXT DEFAULT 'PENDING',
                outcome TEXT,
                pnl REAL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Agent performance table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS agent_performance (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                signal_id TEXT NOT NULL,
                agent_name TEXT NOT NULL,
                agent_signal TEXT NOT NULL,
                agent_confidence REAL NOT NULL,
                was_correct INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (signal_id) REFERENCES signals(id)
            )
        """)
        
        # Daily stats table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS daily_stats (
                date TEXT PRIMARY KEY,
                signals_count INTEGER DEFAULT 0,
                wins INTEGER DEFAULT 0,
                losses INTEGER DEFAULT 0,
                total_pnl REAL DEFAULT 0,
                max_drawdown REAL DEFAULT 0,
                win_rate REAL DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # System events table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS system_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                event_data TEXT,
                timestamp INTEGER NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        self.conn.commit()
        self.logger.info("Database tables created/verified")
    
    # ============================================
    # SIGNAL OPERATIONS
    # ============================================
    
    def save_signal(self, signal_data: Dict) -> str:
        """
        Save a generated signal.
        
        Args:
            signal_data: Signal dictionary from orchestrator
        
        Returns:
            Signal ID
        """
        cursor = self.conn.cursor()
        
        signal_id = f"SIG-{datetime.now().timestamp()}"
        
        cursor.execute("""
            INSERT INTO signals (
                id, timestamp, direction, entry_price, stop_loss,
                take_profit_1, take_profit_2, confidence,
                agreement_count, total_agents, risk_reward,
                rationale, position_size, risk_amount, risk_percent
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            signal_id,
            signal_data.get("timestamp", int(datetime.now().timestamp())),
            signal_data.get("direction"),
            signal_data.get("entry_price"),
            signal_data.get("stop_loss"),
            signal_data.get("take_profit_1"),
            signal_data.get("take_profit_2"),
            signal_data.get("confidence"),
            signal_data.get("agreement_count"),
            signal_data.get("total_agents"),
            signal_data.get("risk_reward"),
            signal_data.get("rationale"),
            signal_data.get("position_size"),
            signal_data.get("risk_amount"),
            signal_data.get("risk_percent"),
        ))
        
        # Save individual agent signals
        for agent_signal in signal_data.get("agent_signals", []):
            cursor.execute("""
                INSERT INTO agent_performance (
                    signal_id, agent_name, agent_signal, agent_confidence
                ) VALUES (?, ?, ?, ?)
            """, (
                signal_id,
                agent_signal.get("agent"),
                agent_signal.get("signal"),
                agent_signal.get("confidence"),
            ))
        
        self.conn.commit()
        self.logger.info(f"Signal saved: {signal_id}")
        return signal_id
    
    def update_signal_outcome(
        self,
        signal_id: str,
        outcome: str,
        pnl: float
    ):
        """
        Update signal with outcome.
        
        Args:
            signal_id: Signal ID
            outcome: 'WIN' or 'LOSS'
            pnl: Profit/loss amount
        """
        cursor = self.conn.cursor()
        
        cursor.execute("""
            UPDATE signals
            SET status = 'CLOSED', outcome = ?, pnl = ?
            WHERE id = ?
        """, (outcome, pnl, signal_id))
        
        # Update agent correctness
        cursor.execute("""
            SELECT direction FROM signals WHERE id = ?
        """, (signal_id,))
        row = cursor.fetchone()
        
        if row:
            signal_direction = row["direction"]
            was_correct = 1 if outcome == "WIN" else 0
            
            cursor.execute("""
                UPDATE agent_performance
                SET was_correct = ?
                WHERE signal_id = ? AND agent_signal = ?
            """, (was_correct, signal_id, signal_direction))
        
        self.conn.commit()
        self.logger.info(f"Signal outcome updated: {signal_id} = {outcome} (${pnl:.2f})")
    
    def get_signal(self, signal_id: str) -> Optional[Dict]:
        """Get signal by ID."""
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM signals WHERE id = ?", (signal_id,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_recent_signals(self, limit: int = 10) -> List[Dict]:
        """Get most recent signals."""
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT * FROM signals ORDER BY timestamp DESC LIMIT ?",
            (limit,)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def get_pending_signals(self) -> List[Dict]:
        """Get signals awaiting outcome."""
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT * FROM signals WHERE status = 'PENDING'"
        )
        return [dict(row) for row in cursor.fetchall()]
    
    # ============================================
    # AGENT PERFORMANCE
    # ============================================
    
    def get_agent_stats(self, agent_name: str) -> Dict:
        """Get performance stats for an agent."""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN was_correct = 1 THEN 1 ELSE 0 END) as correct,
                AVG(agent_confidence) as avg_confidence
            FROM agent_performance
            WHERE agent_name = ?
        """, (agent_name,))
        
        row = cursor.fetchone()
        
        if row and row["total"] > 0:
            return {
                "total": row["total"],
                "correct": row["correct"],
                "accuracy": row["correct"] / row["total"],
                "avg_confidence": row["avg_confidence"],
            }
        
        return {"total": 0, "correct": 0, "accuracy": 0.0, "avg_confidence": 0.0}
    
    def get_all_agent_stats(self) -> Dict[str, Dict]:
        """Get stats for all agents."""
        agents = ["trend_agent", "momentum_agent", "volatility_agent", 
                  "structure_agent", "sentiment_agent"]
        
        return {agent: self.get_agent_stats(agent) for agent in agents}
    
    # ============================================
    # DAILY STATS
    # ============================================
    
    def update_daily_stats(
        self,
        date: str,
        signals_count: int,
        wins: int,
        losses: int,
        total_pnl: float
    ):
        """Update or insert daily statistics."""
        cursor = self.conn.cursor()
        
        win_rate = wins / (wins + losses) if (wins + losses) > 0 else 0
        
        cursor.execute("""
            INSERT OR REPLACE INTO daily_stats (
                date, signals_count, wins, losses, total_pnl, win_rate
            ) VALUES (?, ?, ?, ?, ?, ?)
        """, (date, signals_count, wins, losses, total_pnl, win_rate))
        
        self.conn.commit()
    
    def get_daily_stats(self, date: str) -> Optional[Dict]:
        """Get stats for a specific date."""
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM daily_stats WHERE date = ?", (date,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_last_7_days_stats(self) -> List[Dict]:
        """Get stats for last 7 days."""
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT * FROM daily_stats ORDER BY date DESC LIMIT 7"
        )
        return [dict(row) for row in cursor.fetchall()]
    
    # ============================================
    # SYSTEM EVENTS
    # ============================================
    
    def log_event(self, event_type: str, event_data: Dict):
        """Log a system event."""
        cursor = self.conn.cursor()
        
        import json
        cursor.execute("""
            INSERT INTO system_events (event_type, event_data, timestamp)
            VALUES (?, ?, ?)
        """, (event_type, json.dumps(event_data), int(datetime.now().timestamp())))
        
        self.conn.commit()
    
    def get_recent_events(self, limit: int = 50) -> List[Dict]:
        """Get recent system events."""
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT * FROM system_events ORDER BY timestamp DESC LIMIT ?",
            (limit,)
        )
        
        import json
        events = []
        for row in cursor.fetchall():
            event = dict(row)
            if event.get("event_data"):
                event["event_data"] = json.loads(event["event_data"])
            events.append(event)
        
        return events
    
    # ============================================
    # ANALYTICS
    # ============================================
    
    def get_overall_stats(self) -> Dict:
        """Get overall system performance stats."""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            SELECT 
                COUNT(*) as total_signals,
                SUM(CASE WHEN outcome = 'WIN' THEN 1 ELSE 0 END) as wins,
                SUM(CASE WHEN outcome = 'LOSS' THEN 1 ELSE 0 END) as losses,
                SUM(pnl) as total_pnl,
                AVG(pnl) as avg_pnl,
                MAX(pnl) as max_win,
                MIN(pnl) as max_loss
            FROM signals
            WHERE status = 'CLOSED'
        """)
        
        row = cursor.fetchone()
        
        if row and row["total_signals"] > 0:
            total = row["wins"] + row["losses"]
            return {
                "total_signals": row["total_signals"],
                "wins": row["wins"],
                "losses": row["losses"],
                "win_rate": row["wins"] / total if total > 0 else 0,
                "total_pnl": row["total_pnl"] or 0,
                "avg_pnl": row["avg_pnl"] or 0,
                "max_win": row["max_win"] or 0,
                "max_loss": row["max_loss"] or 0,
                "profit_factor": abs(row["max_win"] / row["max_loss"]) if row["max_loss"] and row["max_loss"] != 0 else 0,
            }
        
        return {
            "total_signals": 0,
            "wins": 0,
            "losses": 0,
            "win_rate": 0,
            "total_pnl": 0,
            "avg_pnl": 0,
            "max_win": 0,
            "max_loss": 0,
            "profit_factor": 0,
        }
    
    def close(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.logger.info("Database connection closed")


# ============================================
# GLOBAL INSTANCE
# ============================================

db = Database()
