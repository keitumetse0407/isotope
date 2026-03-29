"""
Momentum Agent — RSI + MACD Analysis

Munger's Principle: "Price is what you pay. Value is what you get."
Taleb's Principle: "Look for oversold/overbought extremes."

Combines RSI(14) and MACD to identify momentum shifts.
"""

from .base import BaseAgent, AgentOutput


class MomentumAgent(BaseAgent):
    """
    Detects momentum using RSI and MACD.
    
    RSI Signals:
    - <30: Oversold (potential BUY)
    - >70: Overbought (potential SELL)
    - 40-60: Neutral
    
    MACD Signals:
    - Line > Signal + Histogram > 0: Bullish
    - Line < Signal + Histogram < 0: Bearish
    """
    
    def __init__(self):
        super().__init__("momentum_agent")
        self.rsi_oversold = 30
        self.rsi_overbought = 70
    
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze RSI + MACD momentum.
        
        Input data must contain:
        - rsi14: float
        - macd_line: float
        - macd_signal: float
        - macd_histogram: float
        """
        rsi = data.get("rsi14")
        macd_line = data.get("macd_line")
        macd_signal = data.get("macd_signal")
        macd_hist = data.get("macd_histogram")
        
        if not all([rsi, macd_line is not None, macd_signal is not None, macd_hist is not None]):
            raise ValueError("Missing required momentum data")
        
        # RSI analysis
        rsi_oversold = rsi < self.rsi_oversold
        rsi_overbought = rsi > self.rsi_overbought
        rsi_neutral = self.rsi_oversold <= rsi <= self.rsi_overbought
        
        # MACD analysis
        macd_bullish = macd_line > macd_signal and macd_hist > 0
        macd_bearish = macd_line < macd_signal and macd_hist < 0
        
        # Combine signals
        if rsi_oversold and macd_bullish:
            # Strong BUY signal - oversold + bullish MACD
            signal = "BUY"
            confidence = 0.85
            rationale = (
                f"Strong momentum reversal: RSI oversold ({rsi:.1f}) + "
                f"MACD bullish cross (hist: {macd_hist:.2f})"
            )
        elif rsi_overbought and macd_bearish:
            # Strong SELL signal - overbought + bearish MACD
            signal = "SELL"
            confidence = 0.85
            rationale = (
                f"Strong momentum reversal: RSI overbought ({rsi:.1f}) + "
                f"MACD bearish cross (hist: {macd_hist:.2f})"
            )
        elif rsi_oversold:
            # Moderate BUY - oversold but MACD not confirmed
            signal = "BUY"
            confidence = 0.55
            rationale = f"RSI oversold ({rsi:.1f}), awaiting MACD confirmation"
        elif rsi_overbought:
            # Moderate SELL - overbought but MACD not confirmed
            signal = "SELL"
            confidence = 0.55
            rationale = f"RSI overbought ({rsi:.1f}), awaiting MACD confirmation"
        elif macd_bullish:
            # Moderate BUY - MACD bullish but RSI neutral
            signal = "BUY"
            confidence = 0.60
            rationale = f"MACD bullish (hist: {macd_hist:.2f}), RSI neutral ({rsi:.1f})"
        elif macd_bearish:
            # Moderate SELL - MACD bearish but RSI neutral
            signal = "SELL"
            confidence = 0.60
            rationale = f"MACD bearish (hist: {macd_hist:.2f}), RSI neutral ({rsi:.1f})"
        else:
            # No clear signal
            signal = "HOLD"
            confidence = 0.30
            rationale = (
                f"No clear momentum signal. RSI: {rsi:.1f}, "
                f"MACD hist: {macd_hist:.2f}"
            )
        
        return AgentOutput(
            agent_name=self.name,
            signal=signal,
            confidence=round(confidence, 2),
            rationale=rationale,
            metadata={
                "rsi": rsi,
                "rsi_state": "oversold" if rsi_oversold else "overbought" if rsi_overbought else "neutral",
                "macd_line": macd_line,
                "macd_signal": macd_signal,
                "macd_histogram": macd_hist,
                "macd_state": "bullish" if macd_bullish else "bearish" if macd_bearish else "neutral"
            }
        )


def create_momentum_agent() -> MomentumAgent:
    """Factory function to create momentum agent."""
    return MomentumAgent()
