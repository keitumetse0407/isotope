"""
ISOTOPE Risk Manager — The Guardian

Munger's Principle: "Never lose money. Rule #1. Never forget Rule #1."
Taleb's Principle: "Barbell positioning. Survive first, thrive second."
Dalio's Principle: "Risk is what you don't see. Measure everything."

Enforces strict risk management on every signal.
"""

from dataclasses import dataclass
from typing import Optional
from enum import Enum
import logging


class RiskState(Enum):
    NORMAL = "normal"
    CAUTION = "caution"  # After losses, reduce size
    HALTED = "halted"    # Daily loss limit hit


@dataclass
class RiskLimits:
    """
    Iron-clad risk limits. Non-negotiable.
    
    Munger's Rule: "Never lose money."
    Taleb's Rule: "Survive."
    """
    max_risk_per_trade: float = 0.02      # 2% of account
    max_daily_loss: float = 0.05          # 5% of account
    max_daily_signals: int = 3            # Scarcity = quality
    min_risk_reward: float = 1.5          # Minimum 1:1.5 RR
    max_position_size: float = 0.10       # Never >10% on one trade
    kelly_fraction: float = 0.25          # Quarter-Kelly (conservative)


@dataclass
class PositionCalculation:
    """Result of position size calculation."""
    position_size: float  # In lots/units
    risk_amount: float    # In account currency
    stop_loss_distance: float  # In price units
    risk_percent: float   # Actual % of account at risk
    is_approved: bool
    rejection_reason: Optional[str] = None


class RiskManager:
    """
    Enforces risk management on every signal.
    
    Responsibilities:
    1. Calculate position size (Kelly-inspired, conservative)
    2. Enforce daily loss limits
    3. Track signal count
    4. Adjust risk based on recent performance
    """
    
    def __init__(
        self,
        account_balance: float,
        limits: Optional[RiskLimits] = None
    ):
        self.account_balance = account_balance
        self.limits = limits or RiskLimits()
        self.logger = logging.getLogger("isotope.risk_manager")
        
        # Daily tracking
        self.daily_pnl = 0.0
        self.daily_signals = 0
        self.consecutive_losses = 0
        self.consecutive_wins = 0
        
        # Risk state
        self.state = RiskState.NORMAL
        
        # Performance tracking (for adaptive sizing)
        self.last_10_signals: list[bool] = []  # True = win, False = loss
    
    def calculate_position(
        self,
        signal_direction: str,
        entry_price: float,
        stop_loss: float,
        signal_confidence: float,
        instrument_type: str = "XAU/USD"
    ) -> PositionCalculation:
        """
        Calculate position size using Kelly-inspired formula.
        
        Taleb's Barbell: Small bets with convex payoffs.
        Munger's Rule: Never risk more than you can afford.
        
        Args:
            signal_direction: BUY or SELL
            entry_price: Entry price
            stop_loss: Stop loss price
            signal_confidence: Signal confidence (0.0 - 1.0)
            instrument_type: XAU/USD, etc.
        
        Returns:
            PositionCalculation with size and approval status
        """
        # Check risk state first
        if self.state == RiskState.HALTED:
            return PositionCalculation(
                position_size=0,
                risk_amount=0,
                stop_loss_distance=0,
                risk_percent=0,
                is_approved=False,
                rejection_reason="Risk manager halted - daily loss limit reached"
            )
        
        # Calculate stop loss distance
        stop_distance = abs(entry_price - stop_loss)
        
        if stop_distance <= 0:
            return PositionCalculation(
                position_size=0,
                risk_amount=0,
                stop_distance=0,
                risk_percent=0,
                is_approved=False,
                rejection_reason="Invalid stop loss distance"
            )
        
        # Check minimum risk-reward
        if signal_direction == "BUY":
            potential_reward = entry_price - stop_loss
        else:
            potential_reward = stop_loss - entry_price
        
        # Kelly-inspired formula (heavily discounted)
        # Full Kelly: (p * b - q) / b
        # Where: p = win prob, q = loss prob, b = odds
        # We use: confidence as p, signal R:R as b
        
        win_probability = signal_confidence
        loss_probability = 1 - win_probability
        
        # Conservative Kelly fraction
        kelly = (win_probability * 2 - loss_probability) / 2  # Simplified
        kelly = max(0, kelly)  # No negative sizing
        
        # Apply our conservative fraction (Quarter-Kelly)
        risk_fraction = kelly * self.limits.kelly_fraction
        
        # Adjust for recent performance (adaptive)
        risk_fraction = self._adjust_for_performance(risk_fraction)
        
        # Apply risk state modifier
        if self.state == RiskState.CAUTION:
            risk_fraction *= 0.5  # Half size in caution mode
        
        # Calculate risk amount
        risk_amount = self.account_balance * risk_fraction
        
        # Enforce maximum risk per trade
        max_risk = self.account_balance * self.limits.max_risk_per_trade
        risk_amount = min(risk_amount, max_risk)
        
        # Calculate position size
        # For XAU/USD: 1 lot = $100 per $1 move
        # Position size = risk_amount / stop_distance
        if instrument_type == "XAU/USD":
            position_size = risk_amount / stop_distance / 100  # Convert to lots
        else:
            position_size = risk_amount / stop_distance
        
        # Enforce maximum position size
        max_position_value = self.account_balance * self.limits.max_position_size
        if instrument_type == "XAU/USD":
            max_position = max_position_value / entry_price / 100
        else:
            max_position = max_position_value / entry_price
        
        position_size = min(position_size, max_position)
        
        # Recalculate actual risk
        actual_risk = position_size * stop_distance * 100  # For XAU/USD
        actual_risk_percent = (actual_risk / self.account_balance) * 100
        
        # Final approval check
        if actual_risk_percent > self.limits.max_risk_per_trade * 100:
            return PositionCalculation(
                position_size=0,
                risk_amount=0,
                stop_loss_distance=stop_distance,
                risk_percent=actual_risk_percent,
                is_approved=False,
                rejection_reason=f"Risk {actual_risk_percent:.2f}% exceeds limit"
            )
        
        return PositionCalculation(
            position_size=round(position_size, 2),
            risk_amount=round(actual_risk, 2),
            stop_loss_distance=round(stop_distance, 2),
            risk_percent=round(actual_risk_percent, 2),
            is_approved=True
        )
    
    def _adjust_for_performance(self, base_risk_fraction: float) -> float:
        """
        Adjust risk based on recent performance.
        
        Dalio's Principle: "Learn from outcomes."
        Taleb's Principle: "Cut losses, let winners run."
        """
        if len(self.last_10_signals) < 5:
            # Not enough data - use base
            return base_risk_fraction
        
        recent_win_rate = sum(self.last_10_signals[-5:]) / 5
        
        if recent_win_rate < 0.4:
            # Poor recent performance - reduce risk
            return base_risk_fraction * 0.5
        elif recent_win_rate > 0.7:
            # Good recent performance - can increase slightly
            return min(base_risk_fraction * 1.2, self.limits.max_risk_per_trade)
        else:
            return base_risk_fraction
    
    def record_outcome(
        self,
        pnl: float,
        was_win: bool
    ):
        """
        Record signal outcome for adaptive learning.
        
        Args:
            pnl: Profit/loss in account currency
            was_win: True if signal was profitable
        """
        self.daily_pnl += pnl
        self.daily_signals += 1
        
        # Track consecutive
        if was_win:
            self.consecutive_wins += 1
            self.consecutive_losses = 0
        else:
            self.consecutive_losses += 1
            self.consecutive_wins = 0
        
        # Update rolling window
        self.last_10_signals.append(was_win)
        if len(self.last_10_signals) > 10:
            self.last_10_signals.pop(0)
        
        # Update risk state
        self._update_risk_state()
        
        self.logger.info(
            f"Outcome recorded: {'WIN' if was_win else 'LOSS'} | "
            f"PnL: ${pnl:.2f} | Daily: ${self.daily_pnl:.2f} | "
            f"State: {self.state.value}"
        )
    
    def _update_risk_state(self):
        """Update risk state based on daily PnL and streaks."""
        daily_loss_percent = abs(self.daily_pnl) / self.account_balance
        
        # Check for halt condition
        if self.daily_pnl <= -self.account_balance * self.limits.max_daily_loss:
            self.state = RiskState.HALTED
            self.logger.warning(
                "RISK HALTED - Daily loss limit reached. "
                "No more signals today."
            )
            return
        
        # Check for caution condition
        if (
            self.consecutive_losses >= 3 or
            daily_loss_percent > 0.03  # 3% down
        ):
            self.state = RiskState.CAUTION
            self.logger.info("Risk CAUTION - Reducing position sizes")
            return
        
        # Normal operation
        self.state = RiskState.NORMAL
    
    def can_accept_signal(self) -> bool:
        """Check if we can accept a new signal."""
        if self.state == RiskState.HALTED:
            return False
        
        if self.daily_signals >= self.limits.max_daily_signals:
            self.logger.warning(
                f"Daily signal limit reached ({self.daily_signals}/{self.limits.max_daily_signals})"
            )
            return False
        
        return True
    
    def reset_daily(self):
        """Reset daily counters (call at start of each trading day)."""
        self.daily_pnl = 0.0
        self.daily_signals = 0
        self.consecutive_losses = 0
        self.consecutive_wins = 0
        self.state = RiskState.NORMAL
        self.logger.info("Daily counters reset")
    
    @property
    def stats(self) -> dict:
        """Get risk manager statistics."""
        return {
            "account_balance": self.account_balance,
            "daily_pnl": self.daily_pnl,
            "daily_pnl_percent": (self.daily_pnl / self.account_balance) * 100,
            "daily_signals": self.daily_signals,
            "max_daily_signals": self.limits.max_daily_signals,
            "consecutive_wins": self.consecutive_wins,
            "consecutive_losses": self.consecutive_losses,
            "risk_state": self.state.value,
            "recent_win_rate": (
                sum(self.last_10_signals[-5:]) / 5
                if len(self.last_10_signals) >= 5 else 0.0
            ),
        }


# ============================================
# FACTORY
# ============================================

def create_risk_manager(
    account_balance: float = 10000.0,
    limits: Optional[RiskLimits] = None
) -> RiskManager:
    """Create and configure risk manager."""
    return RiskManager(account_balance=account_balance, limits=limits)
