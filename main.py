"""
ISOTOPE v2.0 — Main Entry Point

Autonomous Gold Signal Intelligence System

Stark's Principle: "It works. It's beautiful. Ship it."
Munger's Principle: "Simplicity is the ultimate sophistication."
Dalio's Principle: "The machine produces the results."
Taleb's Principle: "Antifragile. Gets better with time."

Run on Termux:
    python main.py

Or as background service:
    nohup python main.py > isotope.log 2>&1 &

Modes:
    python main.py              # Full system with dashboard
    python main.py --demo       # Demo mode (no real signals)
    python main.py --once       # Run single signal cycle
    python main.py --dashboard  # Dashboard only
"""

import asyncio
import logging
import signal
import sys
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("data/isotope.log"),
    ]
)
logger = logging.getLogger("isotope.main")

# Import ISOTOPE components
from src.orchestrator import orchestrator, OrchestratorConfig
from src.risk_manager import create_risk_manager, RiskLimits
from src.data_fetcher import data_fetcher
from src.database import db
from src.dashboard import TerminalDashboard


# ============================================
# CONFIGURATION
# ============================================

class Config:
    """ISOTOPE Configuration."""
    
    # Account
    ACCOUNT_BALANCE = 10000.0  # Starting balance
    
    # Signal schedule (SAST - South Africa Standard Time)
    SIGNAL_TIMES = ["08:00", "12:00", "16:00"]
    
    # Risk limits
    RISK_LIMITS = RiskLimits(
        max_risk_per_trade=0.02,      # 2%
        max_daily_loss=0.05,          # 5%
        max_daily_signals=3,
        min_risk_reward=1.5,
        max_position_size=0.10,
        kelly_fraction=0.25,
    )
    
    # Orchestrator
    ORCHESTRATOR_CONFIG = OrchestratorConfig(
        min_agreement_count=4,        # Munger's Lollapalooza
        min_confidence_threshold=0.70,
        max_latency_ms=10.0,
        agent_timeout_seconds=5.0,
        enable_believability_weighting=True,
    )
    
    # Data
    CACHE_TTL_MINUTES = 5
    
    # Files
    DATA_DIR = Path("data")
    DB_PATH = DATA_DIR / "isotope.db"
    LOG_PATH = DATA_DIR / "isotope.log"


# ============================================
# ISOTOPE CORE
# ============================================

class IsotopeSystem:
    """
    Main ISOTOPE system controller.
    
    Coordinates:
    - Data fetching
    - Signal generation
    - Risk management
    - Notifications
    - Database logging
    """
    
    def __init__(self, demo_mode: bool = False):
        self.config = Config()
        self.demo_mode = demo_mode
        self.risk_manager = create_risk_manager(
            account_balance=self.config.ACCOUNT_BALANCE,
            limits=self.config.RISK_LIMITS
        )
        self.running = False
        self.signals_generated = 0
        self.start_time = datetime.now()
        self.logger = logging.getLogger("isotope.system")
        self.dashboard = TerminalDashboard()
        
        # Ensure data directory exists
        self.config.DATA_DIR.mkdir(exist_ok=True)
        
        # Log startup
        db.log_event("SYSTEM_START", {
            "demo_mode": demo_mode,
            "account_balance": self.config.ACCOUNT_BALANCE,
        })
    
    async def run_once(self) -> Optional[dict]:
        """
        Run a single signal generation cycle.
        
        Returns:
            Signal dict if generated, None otherwise
        """
        self.logger.info("=== Signal Cycle Started ===")
        
        # Step 1: Check if we can accept signals
        if not self.risk_manager.can_accept_signal():
            self.logger.warning("Risk manager blocking signals")
            return None
        
        # Step 2: Fetch market data
        self.logger.info("Fetching market data...")
        market_data = await data_fetcher.fetch()
        
        if not market_data:
            self.logger.error("Failed to fetch market data")
            return None
        
        self.logger.info(f"Data fetched: XAU/USD @ ${market_data.current_price:.2f}")
        
        # Step 3: Generate signal through orchestrator
        self.logger.info("Running signal analysis...")
        signal_result = await orchestrator.process(market_data.to_dict())
        
        if not signal_result:
            self.logger.info("No signal generated (insufficient confluence)")
            return None
        
        # Step 4: Apply risk management
        position = self.risk_manager.calculate_position(
            signal_direction=signal_result.direction,
            entry_price=signal_result.entry_price,
            stop_loss=signal_result.stop_loss,
            signal_confidence=signal_result.confidence,
        )
        
        if not position.is_approved:
            self.logger.warning(
                f"Risk manager rejected signal: {position.rejection_reason}"
            )
            return None
        
        # Step 5: Build final signal
        signal_dict = {
            **signal_result.to_dict(),
            "position_size": position.position_size,
            "risk_amount": position.risk_amount,
            "risk_percent": position.risk_percent,
        }
        
        self.signals_generated += 1
        
        # Save to database
        signal_id = db.save_signal(signal_dict)
        signal_dict["id"] = signal_id
        
        db.log_event("SIGNAL_GENERATED", {
            "signal_id": signal_id,
            "direction": signal_result.direction,
            "confidence": signal_result.confidence,
        })
        
        self.logger.info(
            f"✅ SIGNAL GENERATED: {signal_result.direction} | "
            f"Entry: ${signal_result.entry_price:.2f} | "
            f"SL: ${signal_result.stop_loss:.2f} | "
            f"TP1: ${signal_result.take_profit_1:.2f} | "
            f"Size: {position.position_size} lots | "
            f"Risk: {position.risk_percent:.2f}% | "
            f"ID: {signal_id}"
        )
        
        return signal_dict
    
    async def run_scheduler(self):
        """
        Run signal scheduler.
        
        Checks every minute if it's signal time.
        Optimized for Termux battery life.
        """
        self.running = True
        self.logger.info("Scheduler started. Waiting for signal times...")
        self.logger.info(f"Signal times: {self.config.SIGNAL_TIMES}")
        
        while self.running:
            now = datetime.now()
            current_time = now.strftime("%H:%M")
            
            # Check if it's signal time
            if current_time in self.config.SIGNAL_TIMES and now.second < 10:
                # Within first 10 seconds of signal minute
                await self.run_once()
            
            # Sleep until next minute (battery-friendly)
            await asyncio.sleep(60 - now.second)
    
    def stop(self):
        """Stop the system."""
        self.running = False
        self.logger.info("System stopping...")
    
    @property
    def stats(self) -> dict:
        """Get system statistics."""
        uptime = datetime.now() - self.start_time
        hours, remainder = divmod(int(uptime.total_seconds()), 3600)
        minutes, _ = divmod(remainder, 60)
        
        return {
            "signals_generated": self.signals_generated,
            "risk_manager": self.risk_manager.stats,
            "orchestrator": orchestrator.stats,
            "database": db.get_overall_stats(),
            "uptime": f"{hours}h {minutes}m",
        }
    
    async def get_dashboard_data(self) -> dict:
        """Get data for dashboard display."""
        recent_signals = db.get_recent_signals(5)
        agent_stats = db.get_all_agent_stats()
        
        # Format recent signals for display
        formatted_signals = []
        for sig in recent_signals:
            formatted_signals.append({
                "direction": sig["direction"],
                "entry_price": sig["entry_price"],
                "confidence": sig["confidence"],
                "time": datetime.fromtimestamp(sig["timestamp"]).strftime("%H:%M"),
            })
        
        # Format agent data
        agents = {}
        for agent_name, stats in agent_stats.items():
            agents[agent_name] = {
                "state": "idle",
                "believability": stats.get("accuracy", 0.5),
            }
        
        risk_stats = self.risk_manager.stats
        
        return {
            "price": 2340.00,  # Would come from live data
            "change": 0,
            "system_state": "RUNNING" if self.running else "STOPPED",
            "signals_today": risk_stats["daily_signals"],
            "max_signals": self.config.RISK_LIMITS.max_daily_signals,
            "uptime": self.stats["uptime"],
            "latency_ms": 5.0,  # Would come from orchestrator
            "risk_state": risk_stats["risk_state"],
            "daily_pnl": risk_stats["daily_pnl"],
            "daily_loss_limit": self.config.RISK_LIMITS.max_daily_loss * 100,
            "daily_loss_used": abs(risk_stats["daily_pnl"]) if risk_stats["daily_pnl"] < 0 else 0,
            "agents": agents,
            "recent_signals": formatted_signals,
            "current_signal": None,  # Would track active signals
        }


# ============================================
# SIGNAL HANDLERS
# ============================================

def setup_signal_handlers(system: IsotopeSystem):
    """Setup graceful shutdown handlers."""
    
    def handle_signal(sig, frame):
        logger.info(f"Received signal {sig}. Shutting down gracefully...")
        system.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)


# ============================================
# WHATSAPP NOTIFIER (Placeholder)
# ============================================

async def send_whatsapp_notification(signal_dict: dict):
    """
    Send signal to WhatsApp.
    
    TODO: Implement with your existing WhatsApp bot at port 8765.
    """
    if not signal_dict:
        return
    
    message = f"""
🔔 ISOTOPE SIGNAL — XAU/USD

📊 Direction: {signal_dict['direction']}
💰 Entry: ${signal_dict['entry_price']:.2f}
🛑 Stop Loss: ${signal_dict['stop_loss']:.2f}
🎯 TP1: ${signal_dict['take_profit_1']:.2f}
🎯 TP2: ${signal_dict['take_profit_2']:.2f}
📈 R:R = 1:{signal_dict['risk_reward']:.1f}
⚡ Confidence: {signal_dict['confidence']*100:.0f}%
📊 Agreement: {signal_dict['agreement_count']}/{signal_dict['total_agents']} agents
💰 Position: {signal_dict['position_size']} lots
⚠️ Risk: {signal_dict['risk_percent']:.1f}%

🧠 Reason: {signal_dict['rationale']}

⏰ Time: {datetime.now().strftime('%H:%M SAST')}
🤖 ISOTOPE v2.0 | ELEV8 DIGITAL
"""
    
    # TODO: POST to WhatsApp bot
    # async with aiohttp.ClientSession() as session:
    #     await session.post(
    #         "http://113.30.189.89:8765/api/send",
    #         json={"message": message}
    #     )
    
    logger.info("WhatsApp notification prepared (not sent - implement POST)")
    print(message)


# ============================================
# MAIN
# ============================================

async def run_full_system(system: IsotopeSystem):
    """Run full system with scheduler."""
    logger.info("Starting signal scheduler...")
    try:
        await system.run_scheduler()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    finally:
        system.stop()
        db.log_event("SYSTEM_STOP", {"reason": "user_interrupt"})
        logger.info("ISOTOPE shutdown complete")


async def run_with_dashboard(system: IsotopeSystem):
    """Run system with live dashboard."""
    logger.info("Starting dashboard...")
    
    async def dashboard_data_source():
        # Run one signal cycle
        await system.run_once()
        # Get dashboard data
        return await system.get_dashboard_data()
    
    await system.dashboard.run(dashboard_data_source, update_interval=2.0)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="ISOTOPE v2.0 — Autonomous Gold Signal System"
    )
    parser.add_argument(
        "--demo",
        action="store_true",
        help="Run in demo mode (no real signals)"
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run single signal cycle and exit"
    )
    parser.add_argument(
        "--dashboard",
        action="store_true",
        help="Run dashboard only (demo data)"
    )
    parser.add_argument(
        "--stats",
        action="store_true",
        help="Show system statistics and exit"
    )
    return parser.parse_args()


async def main():
    """Main entry point."""
    args = parse_args()
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🔬 ISOTOPE v2.0 — Gold Signal Intelligence System      ║
║                                                           ║
║   Built by Elkai | ELEV8 DIGITAL                         ║
║   Stark + Munger + Dalio + Taleb Principles              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    # Handle different modes
    if args.dashboard:
        # Dashboard only with demo data
        from src.dashboard import run_demo
        print("🎬 Starting dashboard (demo mode)...")
        print("Press Ctrl+C to exit")
        await run_demo()
        return
    
    if args.stats:
        # Show statistics
        stats = db.get_overall_stats()
        print("\n📊 ISOTOPE Statistics")
        print("=" * 40)
        print(f"Total Signals: {stats['total_signals']}")
        print(f"Wins: {stats['wins']} | Losses: {stats['losses']}")
        print(f"Win Rate: {stats['win_rate']*100:.1f}%")
        print(f"Total PnL: ${stats['total_pnl']:.2f}")
        print(f"Avg PnL: ${stats['avg_pnl']:.2f}")
        print(f"Max Win: ${stats['max_win']:.2f}")
        print(f"Max Loss: ${stats['max_loss']:.2f}")
        return
    
    logger.info("ISOTOPE v2.0 initializing...")
    
    # Initialize system
    demo_mode = args.demo
    system = IsotopeSystem(demo_mode=demo_mode)
    setup_signal_handlers(system)
    
    mode_str = " (DEMO MODE)" if demo_mode else ""
    logger.info(f"Account: ${system.config.ACCOUNT_BALANCE:,.2f}{mode_str}")
    logger.info(f"Risk per trade: {system.config.RISK_LIMITS.max_risk_per_trade*100:.1f}%")
    logger.info(f"Max daily signals: {system.config.RISK_LIMITS.max_daily_signals}")
    logger.info(f"Signal times: {', '.join(system.config.SIGNAL_TIMES)}")
    
    if args.once:
        # Single signal cycle
        logger.info("Running single signal cycle...")
        signal_result = await system.run_once()
        if signal_result:
            await send_whatsapp_notification(signal_result)
        else:
            logger.info("No signal generated")
        return
    
    # Full system with scheduler
    await run_full_system(system)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 ISOTOPE stopped by user")
    except Exception as e:
        logger.critical(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
