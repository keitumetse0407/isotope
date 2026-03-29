"""
ISOTOPE Terminal Dashboard — Phase 1

Stark's Principle: "If it doesn't look good, it doesn't work good."
Displays real-time system status, signals, and performance.

Termux-compatible: Uses simple ANSI escape codes, no heavy GUI.
"""

import asyncio
import os
from datetime import datetime
from typing import Optional, Dict, Any


class TerminalDashboard:
    """
    Real-time terminal dashboard for ISOTOPE.
    
    Shows:
    - Current market price
    - System status
    - Recent signals
    - Risk manager state
    - Agent status
    """
    
    def __init__(self):
        self.width = 80
        self.height = 24
        self.data: dict[str, Any] = {}
    
    def clear(self):
        """Clear terminal screen."""
        os.system('clear' if os.name == 'posix' else 'cls')
    
    def draw_header(self):
        """Draw dashboard header."""
        print("╔" + "═" * (self.width - 2) + "╗")
        print("║" + " " * 20 + "🔬 ISOTOPE v2.0" + " " * 41 + "║")
        print("║" + " " * 15 + "Autonomous Gold Signal System" + " " * 34 + "║")
        print("║" + " " * 26 + "ELEV8 DIGITAL" + " " * 39 + "║")
        print("╠" + "═" * (self.width - 2) + "╣")
    
    def draw_market_status(self, data: dict):
        """Draw market status section."""
        print("║ 📊 MARKET STATUS" + " " * 58 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        price = data.get("price", "N/A")
        change = data.get("change", 0)
        change_str = f"+{change:.2f}" if change > 0 else f"{change:.2f}"
        change_icon = "📈" if change > 0 else "📉" if change < 0 else "➡"
        
        print(f"║   XAU/USD: ${price:>10}  {change_icon} {change_str:>8}  " + " " * 37 + "║")
        print(f"║   Updated: {datetime.now().strftime('%H:%M:%S')}" + " " * 54 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_system_status(self, data: dict):
        """Draw system status section."""
        print("║ ⚙️  SYSTEM STATUS" + " " * 58 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        status = data.get("system_state", "RUNNING")
        status_icon = "🟢" if status == "RUNNING" else "🟡" if status == "CAUTION" else "🔴"
        
        print(f"║   State: {status_icon} {status:<10}  Signals Today: {data.get('signals_today', 0):>2}/{data.get('max_signals', 3)}  " + " " * 28 + "║")
        print(f"║   Uptime: {data.get('uptime', '0h 0m'):<12}  Latency: {data.get('latency_ms', 0):>6.2f}ms  " + " " * 32 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_risk_status(self, data: dict):
        """Draw risk manager status."""
        print("║ 🛡️  RISK MANAGEMENT" + " " * 56 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        risk_state = data.get("risk_state", "NORMAL")
        state_icon = "🟢" if risk_state == "NORMAL" else "🟡" if risk_state == "CAUTION" else "🔴"
        
        daily_pnl = data.get("daily_pnl", 0)
        pnl_color = "🟢" if daily_pnl > 0 else "🔴" if daily_pnl < 0 else "⚪"
        
        print(f"║   Risk State: {state_icon} {risk_state:<10}  Daily PnL: {pnl_color} ${daily_pnl:+.2f}  " + " " * 30 + "║")
        print(f"║   Daily Loss Limit: {data.get('daily_loss_limit', 5.0):.1f}%  |  Used: {data.get('daily_loss_used', 0):.2f}%  " + " " * 28 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_agent_status(self, data: dict):
        """Draw agent status section."""
        print("║ 🤖 AGENT STATUS" + " " * 60 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        agents = data.get("agents", {})
        agent_rows = [
            ("Trend", agents.get("trend_agent", {"state": "N/A", "believability": 0.5})),
            ("Momentum", agents.get("momentum_agent", {"state": "N/A", "believability": 0.5})),
            ("Volatility", agents.get("volatility_agent", {"state": "N/A", "believability": 0.5})),
            ("Structure", agents.get("structure_agent", {"state": "N/A", "believability": 0.5})),
            ("Sentiment", agents.get("sentiment_agent", {"state": "N/A", "believability": 0.5})),
        ]
        
        for name, agent_data in agent_rows:
            state = agent_data.get("state", "N/A")
            state_icon = "🟢" if state == "idle" else "🟡" if state == "running" else "🔴" if state == "error" else "⚪"
            believability = agent_data.get("believability", 0) * 100
            
            print(f"║   {name:<12} {state_icon} {state:<10}  Believability: {believability:>5.1f}%  " + " " * 28 + "║")
        
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_recent_signals(self, data: dict):
        """Draw recent signals section."""
        print("║ 📈 RECENT SIGNALS" + " " * 57 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        signals = data.get("recent_signals", [])
        
        if not signals:
            print("║   No signals generated yet" + " " * 49 + "║")
        else:
            for signal in signals[-3:]:  # Last 3 signals
                direction = signal.get("direction", "HOLD")
                direction_icon = "🟢" if direction == "BUY" else "🔴" if direction == "SELL" else "⚪"
                entry = signal.get("entry_price", 0)
                confidence = signal.get("confidence", 0) * 100
                time = signal.get("time", "N/A")
                
                print(f"║   {direction_icon} {direction:<4} @ ${entry:.2f}  Confidence: {confidence:>5.1f}%  {time:>8}  " + " " * 22 + "║")
        
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_current_signal(self, data: dict):
        """Draw current active signal if any."""
        print("║ 🎯 CURRENT SIGNAL" + " " * 57 + "║")
        print("╟" + "─" * (self.width - 2) + "╢")
        
        signal = data.get("current_signal")
        
        if not signal:
            print("║   No active signal" + " " * 56 + "║")
        else:
            direction = signal.get("direction", "HOLD")
            direction_icon = "🟢" if direction == "BUY" else "🔴"
            
            print(f"║   {direction_icon} {direction:<4} XAU/USD" + " " * 58 + "║")
            print(f"║   Entry: ${signal.get('entry', 0):.2f}  |  SL: ${signal.get('stop_loss', 0):.2f}  |  TP1: ${signal.get('tp1', 0):.2f}  " + " " * 15 + "║")
            print(f"║   R:R: 1:{signal.get('rr', 0):.1f}  |  Confidence: {signal.get('confidence', 0)*100:.0f}%  |  Size: {signal.get('size', 0):.2f} lots  " + " " * 10 + "║")
        
        print("╟" + "─" * (self.width - 2) + "╢")
    
    def draw_footer(self):
        """Draw dashboard footer."""
        print("╠" + "═" * (self.width - 2) + "╣")
        print("║" + " " * 15 + "Ctrl+C to stop | Logs: data/isotope.log" + " " * 23 + "║")
        print("╚" + "═" * (self.width - 2) + "╝")
    
    def render(self, data: dict):
        """Render complete dashboard."""
        self.clear()
        self.data = data
        
        self.draw_header()
        self.draw_market_status(data)
        self.draw_system_status(data)
        self.draw_risk_status(data)
        self.draw_agent_status(data)
        self.draw_recent_signals(data)
        self.draw_current_signal(data)
        self.draw_footer()
    
    async def run(self, data_source: callable, update_interval: float = 2.0):
        """
        Run dashboard with live updates.
        
        Args:
            data_source: Async function that returns dashboard data
            update_interval: Seconds between updates
        """
        try:
            while True:
                data = await data_source()
                self.render(data)
                await asyncio.sleep(update_interval)
        except KeyboardInterrupt:
            pass


# ============================================
# DEMO MODE
# ============================================

async def demo_data_source():
    """Generate demo data for dashboard testing."""
    import random
    
    return {
        "price": 2340.00 + random.uniform(-10, 10),
        "change": random.uniform(-5, 5),
        "system_state": "RUNNING",
        "signals_today": random.randint(0, 3),
        "max_signals": 3,
        "uptime": "2h 15m",
        "latency_ms": random.uniform(3, 8),
        "risk_state": random.choice(["NORMAL", "NORMAL", "NORMAL", "CAUTION"]),
        "daily_pnl": random.uniform(-100, 150),
        "daily_loss_limit": 5.0,
        "daily_loss_used": abs(random.uniform(0, 3)),
        "agents": {
            "trend_agent": {"state": "idle", "believability": 0.75 + random.uniform(0, 0.2)},
            "momentum_agent": {"state": "idle", "believability": 0.65 + random.uniform(0, 0.2)},
            "volatility_agent": {"state": "idle", "believability": 0.70 + random.uniform(0, 0.15)},
            "structure_agent": {"state": "idle", "believability": 0.80 + random.uniform(0, 0.15)},
            "sentiment_agent": {"state": "idle", "believability": 0.55 + random.uniform(0, 0.2)},
        },
        "recent_signals": [
            {"direction": "BUY", "entry_price": 2338.50, "confidence": 0.82, "time": "08:00"},
            {"direction": "SELL", "entry_price": 2345.00, "confidence": 0.75, "time": "12:00"},
        ] if random.random() > 0.3 else [],
        "current_signal": {
            "direction": "BUY",
            "entry": 2340.00,
            "stop_loss": 2325.00,
            "tp1": 2362.50,
            "rr": 1.5,
            "confidence": 0.82,
            "size": 0.12,
        } if random.random() > 0.5 else None,
    }


async def run_demo():
    """Run dashboard in demo mode."""
    dashboard = TerminalDashboard()
    print("🎬 Starting dashboard demo mode...")
    print("Press Ctrl+C to exit")
    await asyncio.sleep(2)
    await dashboard.run(demo_data_source, update_interval=1.0)


if __name__ == "__main__":
    try:
        asyncio.run(run_demo())
    except KeyboardInterrupt:
        print("\n👋 Dashboard closed")
