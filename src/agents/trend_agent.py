"""
Trend Agent — EMA Alignment Analysis

Munger's Principle: "Trend is your friend until it ends."
Dalio's Principle: "Know what regime you're in."

Analyzes EMA 9/21/50 alignment to determine trend direction.
"""

from typing import Optional
from .base import BaseAgent, AgentOutput


class TrendAgent(BaseAgent):
    """
    Detects trend direction using exponential moving average alignment.
    
    Bullish: EMA9 > EMA21 > EMA50
    Bearish: EMA9 < EMA21 < EMA50
    Ranging: No clear alignment
    """
    
    def __init__(self):
        super().__init__("trend_agent")
        self.ema_short = 9
        self.ema_medium = 21
        self.ema_long = 50
    
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze EMA alignment.
        
        Input data must contain:
        - ema9: float
        - ema21: float
        - ema50: float
        - current_price: float
        """
        ema9 = data.get("ema9")
        ema21 = data.get("ema21")
        ema50 = data.get("ema50")
        price = data.get("current_price")
        
        if not all([ema9, ema21, ema50, price]):
            raise ValueError("Missing required EMA data")
        
        # Check alignment
        bullish_alignment = ema9 > ema21 > ema50
        bearish_alignment = ema9 < ema21 < ema50
        
        # Calculate confidence based on separation between EMAs
        if bullish_alignment:
            separation = (ema9 - ema50) / ema50 * 100  # Percentage separation
            confidence = min(0.5 + separation * 0.5, 1.0)  # More separation = more confidence
            signal = "BUY"
            rationale = (
                f"Bullish EMA alignment (9>{ema21:.2f}>{ema50:.2f}). "
                f"Separation: {separation:.2f}%. "
                f"Price: ${price:.2f}"
            )
        elif bearish_alignment:
            separation = (ema50 - ema9) / ema50 * 100
            confidence = min(0.5 + separation * 0.5, 1.0)
            signal = "SELL"
            rationale = (
                f"Bearish EMA alignment (9<{ema21:.2f}<{ema50:.2f}). "
                f"Separation: {separation:.2f}%. "
                f"Price: ${price:.2f}"
            )
        else:
            # No clear trend - ranging market
            signal = "HOLD"
            confidence = 0.3  # Low confidence in ranging market
            rationale = (
                f"No clear EMA alignment. Market ranging. "
                f"EMA9: {ema9:.2f}, EMA21: {ema21:.2f}, EMA50: {ema50:.2f}"
            )
        
        return AgentOutput(
            agent_name=self.name,
            signal=signal,
            confidence=round(confidence, 2),
            rationale=rationale,
            metadata={
                "ema9": ema9,
                "ema21": ema21,
                "ema50": ema50,
                "alignment": "bullish" if bullish_alignment else "bearish" if bearish_alignment else "none",
                "separation_percent": round(separation if bullish_alignment or bearish_alignment else 0, 2)
            }
        )


# ============================================
# FACTORY FUNCTION
# ============================================

def create_trend_agent() -> TrendAgent:
    """Factory function to create and register trend agent."""
    return TrendAgent()
