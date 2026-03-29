"""
Structure Agent — Support/Resistance Analysis

Munger's Principle: "Price matters. Buy low, sell high."
Dalio's Principle: "Understand the market structure."

Identifies key support/resistance levels and price position relative to them.
"""

from .base import BaseAgent, AgentOutput


class StructureAgent(BaseAgent):
    """
    Analyzes price structure relative to support/resistance levels.
    
    Key insights:
    - Price at support = potential BUY
    - Price at resistance = potential SELL
    - Price breaking level = follow the breakout
    """
    
    def __init__(self):
        super().__init__("structure_agent")
        self.proximity_threshold = 0.005  # 0.5% from level = "at" level
    
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze price structure.
        
        Input data must contain:
        - current_price: float
        - support_levels: list[float]
        - resistance_levels: list[float]
        - pivot_point: float (optional)
        """
        price = data.get("current_price")
        supports = data.get("support_levels", [])
        resistances = data.get("resistance_levels", [])
        pivot = data.get("pivot_point")
        
        if not price or not supports or not resistances:
            raise ValueError("Missing required structure data")
        
        # Find nearest support and resistance
        nearest_support = max([s for s in supports if s < price], default=None)
        nearest_resistance = min([r for r in resistances if r > price], default=None)
        
        # Calculate distances
        support_distance = (price - nearest_support) / price if nearest_support else float('inf')
        resistance_distance = (nearest_resistance - price) / price if nearest_resistance else float('inf')
        
        # Check if at key levels
        at_support = support_distance <= self.proximity_threshold
        at_resistance = resistance_distance <= self.proximity_threshold
        
        # Determine signal based on position
        if at_support and not at_resistance:
            # Price at support - potential bounce
            signal = "BUY"
            confidence = 0.75
            rationale = (
                f"Price at support (${nearest_support:.2f}, distance: {support_distance:.2%}). "
                f"Potential bounce zone. Price: ${price:.2f}"
            )
        elif at_resistance and not at_support:
            # Price at resistance - potential rejection
            signal = "SELL"
            confidence = 0.75
            rationale = (
                f"Price at resistance (${nearest_resistance:.2f}, distance: {resistance_distance:.2%}). "
                f"Potential rejection zone. Price: ${price:.2f}"
            )
        elif at_support and at_resistance:
            # Squeezed between levels - wait for breakout
            signal = "HOLD"
            confidence = 0.40
            rationale = (
                f"Price squeezed between support (${nearest_support:.2f}) and "
                f"resistance (${nearest_resistance:.2f}). Wait for breakout."
            )
        else:
            # Price in no-man's land
            # Check if breaking through levels
            broken_support = any(price < s < price * 1.01 for s in supports)
            broken_resistance = any(price > r > price * 0.99 for r in resistances)
            
            if broken_support:
                # Support broken - bearish
                signal = "SELL"
                confidence = 0.65
                rationale = f"Support broken at ${price:.2f}. Bearish breakout."
            elif broken_resistance:
                # Resistance broken - bullish
                signal = "BUY"
                confidence = 0.65
                rationale = f"Resistance broken at ${price:.2f}. Bullish breakout."
            else:
                # Neutral zone
                signal = "HOLD"
                confidence = 0.35
                rationale = (
                    f"Price in neutral zone. Nearest support: ${nearest_support}, "
                    f"nearest resistance: ${nearest_resistance}. No clear structure signal."
                )
        
        return AgentOutput(
            agent_name=self.name,
            signal=signal,
            confidence=round(confidence, 2),
            rationale=rationale,
            metadata={
                "nearest_support": nearest_support,
                "nearest_resistance": nearest_resistance,
                "support_distance_pct": round(support_distance * 100, 2) if support_distance != float('inf') else None,
                "resistance_distance_pct": round(resistance_distance * 100, 2) if resistance_distance != float('inf') else None,
                "at_support": at_support,
                "at_resistance": at_resistance,
            }
        )


def create_structure_agent() -> StructureAgent:
    """Factory function to create structure agent."""
    return StructureAgent()
