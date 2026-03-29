"""
Volatility Agent — ATR + Bollinger Bands Analysis

Taleb's Principle: "Volatility is not risk. Volatility is opportunity."
Munger's Principle: "Know when conditions favor action."

Measures market volatility to determine if conditions support directional moves.
"""

from .base import BaseAgent, AgentOutput


class VolatilityAgent(BaseAgent):
    """
    Analyzes volatility using ATR and Bollinger Bands.
    
    High volatility + expanding bands = favorable for directional moves
    Low volatility + contracting bands = wait for breakout
    """
    
    def __init__(self):
        super().__init__("volatility_agent")
        self.bb_width_threshold = 0.05  # 5% BB width = significant
        self.atr_percent_threshold = 1.0  # 1% ATR = significant
    
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze volatility conditions.
        
        Input data must contain:
        - atr14: float
        - bb_upper: float
        - bb_middle: float
        - bb_lower: float
        - current_price: float
        """
        atr = data.get("atr14")
        bb_upper = data.get("bb_upper")
        bb_middle = data.get("bb_middle")
        bb_lower = data.get("bb_lower")
        price = data.get("current_price")
        
        if not all([atr, bb_upper, bb_middle, bb_lower, price]):
            raise ValueError("Missing required volatility data")
        
        # Calculate metrics
        atr_percent = (atr / price) * 100
        bb_width = (bb_upper - bb_lower) / bb_middle
        
        # Position within bands
        bb_position = (price - bb_lower) / (bb_upper - bb_lower)  # 0 = lower, 1 = upper
        
        # Volatility assessment
        high_volatility = atr_percent > self.atr_percent_threshold
        expanding_bands = bb_width > self.bb_width_threshold
        
        # Determine signal
        if high_volatility and expanding_bands:
            # High volatility environment - favorable for trends
            if bb_position > 0.7:
                # Price near upper band - potential continuation or reversal
                signal = "HOLD"
                confidence = 0.50
                rationale = (
                    f"High volatility (ATR: {atr_percent:.2f}%), BB expanding ({bb_width:.2%}). "
                    f"Price near upper band (${price:.2f}) - watch for breakout or rejection"
                )
            elif bb_position < 0.3:
                # Price near lower band
                signal = "HOLD"
                confidence = 0.50
                rationale = (
                    f"High volatility (ATR: {atr_percent:.2f}%), BB expanding ({bb_width:.2%}). "
                    f"Price near lower band (${price:.2f}) - watch for breakdown or bounce"
                )
            else:
                # Price in middle - volatility supports directional move
                signal = "HOLD"
                confidence = 0.60
                rationale = (
                    f"High volatility environment (ATR: {atr_percent:.2f}%, BB: {bb_width:.2%}). "
                    f"Conditions favor directional moves. Price: ${price:.2f}"
                )
        elif not high_volatility and not expanding_bands:
            # Low volatility - compression before expansion
            signal = "HOLD"
            confidence = 0.40
            rationale = (
                f"Low volatility (ATR: {atr_percent:.2f}%, BB: {bb_width:.2%}). "
                f"Market compressing - potential breakout ahead. Wait for confirmation."
            )
        else:
            # Mixed signals
            signal = "HOLD"
            confidence = 0.45
            rationale = (
                f"Mixed volatility signals. ATR: {atr_percent:.2f}%, "
                f"BB Width: {bb_width:.2%}, Position: {bb_position:.2%}"
            )
        
        return AgentOutput(
            agent_name=self.name,
            signal=signal,
            confidence=round(confidence, 2),
            rationale=rationale,
            metadata={
                "atr": atr,
                "atr_percent": round(atr_percent, 2),
                "bb_width": round(bb_width, 4),
                "bb_position": round(bb_position, 2),
                "volatility_state": "high" if high_volatility else "low",
                "bands_state": "expanding" if expanding_bands else "contracting"
            }
        )


def create_volatility_agent() -> VolatilityAgent:
    """Factory function to create volatility agent."""
    return VolatilityAgent()
