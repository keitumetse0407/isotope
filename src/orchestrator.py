"""
ISOTOPE Orchestrator — The Brain

Stark's Principle: "The machine is the product."
Munger's Principle: "Lollapalooza — act only when multiple forces converge."
Dalio's Principle: "Believability-weighted decision making."
Taleb's Principle: "Barbell positioning, convex payoffs."

Combines all agent outputs into a single, high-confidence signal.
"""

import asyncio
from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime
import logging

from .agents.base import BaseAgent, AgentOutput, AgentRegistry, registry
from .agents.trend_agent import create_trend_agent
from .agents.momentum_agent import create_momentum_agent
from .agents.volatility_agent import create_volatility_agent
from .agents.structure_agent import create_structure_agent
from .agents.sentiment_agent import create_sentiment_agent


# ============================================
# DATA CLASSES
# ============================================

@dataclass
class ConfluenceSignal:
    """Final signal after confluence analysis."""
    direction: str  # BUY, SELL, HOLD
    confidence: float  # 0.0 - 1.0
    agreement_count: int  # How many agents agree (0-5)
    total_agents: int  # Total agents consulted
    entry_price: float
    stop_loss: float
    take_profit_1: float
    take_profit_2: float
    risk_reward: float
    rationale: str
    agent_signals: list[AgentOutput]
    timestamp: int = field(default_factory=lambda: int(datetime.now().timestamp() * 1000))
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "direction": self.direction,
            "confidence": self.confidence,
            "agreement_count": self.agreement_count,
            "total_agents": self.total_agents,
            "entry_price": self.entry_price,
            "stop_loss": self.stop_loss,
            "take_profit_1": self.take_profit_1,
            "take_profit_2": self.take_profit_2,
            "risk_reward": self.risk_reward,
            "rationale": self.rationale,
            "agent_signals": [
                {
                    "agent": s.agent_name,
                    "signal": s.signal,
                    "confidence": s.confidence,
                }
                for s in self.agent_signals
            ],
            "timestamp": self.timestamp,
        }


@dataclass
class OrchestratorConfig:
    """Configuration for the orchestrator."""
    min_agreement_count: int = 4  # Munger's Lollapalooza: 4/5 must agree
    min_confidence_threshold: float = 0.70
    max_latency_ms: float = 10.0
    agent_timeout_seconds: float = 5.0
    enable_believability_weighting: bool = True  # Dalio's principle


# ============================================
# ORCHESTRATOR
# ============================================

class Orchestrator:
    """
    Central decision-making engine.
    
    Process:
    1. Receive market data
    2. Run all agents in parallel
    3. Apply believability weighting (Dalio)
    4. Count confluence (Munger)
    5. Generate final signal with risk parameters (Taleb)
    """
    
    def __init__(self, config: Optional[OrchestratorConfig] = None):
        self.config = config or OrchestratorConfig()
        self.logger = logging.getLogger("isotope.orchestrator")
        self._setup_agents()
        self._signal_count = 0
        self._last_signal: Optional[ConfluenceSignal] = None
    
    def _setup_agents(self):
        """Register all agents."""
        registry.register(create_trend_agent())
        registry.register(create_momentum_agent())
        registry.register(create_volatility_agent())
        registry.register(create_structure_agent())
        registry.register(create_sentiment_agent())
        self.logger.info(f"Registered {len(registry.get_all())} agents")
    
    async def process(self, market_data: dict) -> Optional[ConfluenceSignal]:
        """
        Process market data through all agents and generate signal.
        
        Market data must contain:
        - current_price: float
        - ema9, ema21, ema50: float
        - rsi14: float
        - macd_line, macd_signal, macd_histogram: float
        - atr14: float
        - bb_upper, bb_middle, bb_lower: float
        - support_levels: list[float]
        - resistance_levels: list[float]
        - pivot_point: float (optional)
        - news_headlines: list[str] (optional)
        - sentiment_score: float (optional)
        """
        start_time = asyncio.get_event_loop().time()
        
        try:
            # Step 1: Run all agents in parallel (Stark's efficiency)
            agent_outputs = await registry.run_all(
                market_data,
                timeout=self.config.agent_timeout_seconds
            )
            
            # Filter out HOLD signals for agreement counting
            non_hold_signals = [s for s in agent_outputs if s.signal != "HOLD"]
            
            if not non_hold_signals:
                self.logger.debug("All agents returned HOLD")
                return None
            
            # Step 2: Apply Dalio's believability weighting
            if self.config.enable_believability_weighting:
                weights = registry.get_believability_weights()
                weighted_signals = self._apply_believability_weighting(
                    agent_outputs, weights
                )
            else:
                weighted_signals = agent_outputs
            
            # Step 3: Count confluence (Munger's Lollapalooza)
            buy_signals = [s for s in weighted_signals if s.signal == "BUY"]
            sell_signals = [s for s in weighted_signals if s.signal == "SELL"]
            
            agreement_count = max(len(buy_signals), len(sell_signals))
            
            # Step 4: Determine direction
            if len(buy_signals) > len(sell_signals):
                direction = "BUY"
                contributing_signals = buy_signals
            elif len(sell_signals) > len(buy_signals):
                direction = "SELL"
                contributing_signals = sell_signals
            else:
                # Tie - return HOLD
                self.logger.debug("Agents tied - returning HOLD")
                return None
            
            # Step 5: Check if agreement meets threshold
            if agreement_count < self.config.min_agreement_count:
                self.logger.debug(
                    f"Agreement {agreement_count} < threshold {self.config.min_agreement_count}"
                )
                return None
            
            # Step 6: Calculate weighted confidence
            avg_confidence = sum(s.confidence for s in contributing_signals) / len(contributing_signals)
            
            if avg_confidence < self.config.min_confidence_threshold:
                self.logger.debug(
                    f"Confidence {avg_confidence:.2f} < threshold {self.config.min_confidence_threshold}"
                )
                return None
            
            # Step 7: Build final signal with risk parameters (Taleb's barbell)
            signal = self._build_signal(
                direction=direction,
                confidence=avg_confidence,
                agreement_count=agreement_count,
                agent_signals=agent_outputs,
                market_data=market_data
            )
            
            # Track latency
            latency_ms = (asyncio.get_event_loop().time() - start_time) * 1000
            signal.metadata = {"latency_ms": round(latency_ms, 2)}
            
            if latency_ms > self.config.max_latency_ms:
                self.logger.warning(
                    f"Signal processing exceeded latency target: {latency_ms:.2f}ms"
                )
            
            self._signal_count += 1
            self._last_signal = signal
            
            self.logger.info(
                f"Signal generated: {direction} | Confidence: {avg_confidence:.2f} | "
                f"Agreement: {agreement_count}/{len(agent_outputs)} | Latency: {latency_ms:.2f}ms"
            )
            
            return signal
            
        except Exception as e:
            self.logger.error(f"Orchestrator error: {e}", exc_info=True)
            return None
    
    def _apply_believability_weighting(
        self,
        signals: list[AgentOutput],
        weights: dict[str, float]
    ) -> list[AgentOutput]:
        """
        Apply Dalio's believability weighting to agent signals.
        
        Each signal's confidence is adjusted by the agent's historical accuracy.
        """
        weighted_signals = []
        
        for signal in signals:
            weight = weights.get(signal.agent_name, 0.5)
            # Adjust confidence: high-believability agents get boost
            adjusted_confidence = signal.confidence * (0.5 + weight * 0.5)
            adjusted_confidence = min(1.0, max(0.0, adjusted_confidence))
            
            weighted_signal = AgentOutput(
                agent_name=signal.agent_name,
                signal=signal.signal,
                confidence=round(adjusted_confidence, 2),
                rationale=signal.rationale,
                metadata=signal.metadata,
                timestamp=signal.timestamp
            )
            weighted_signals.append(weighted_signal)
        
        return weighted_signals
    
    def _build_signal(
        self,
        direction: str,
        confidence: float,
        agreement_count: int,
        agent_signals: list[AgentOutput],
        market_data: dict
    ) -> ConfluenceSignal:
        """
        Build final signal with risk parameters.
        
        Taleb's Principle: Convex payoffs, limited downside.
        """
        price = market_data["current_price"]
        atr = market_data.get("atr14", price * 0.01)  # Default 1% if no ATR
        
        # Calculate stops and targets based on ATR (Taleb's barbell)
        stop_distance = atr * 1.5  # 1.5 ATR stop
        tp1_distance = atr * 2.25  # 1:1.5 RR
        tp2_distance = atr * 4.5   # 1:3 RR
        
        if direction == "BUY":
            entry = price
            stop_loss = price - stop_distance
            take_profit_1 = price + tp1_distance
            take_profit_2 = price + tp2_distance
        else:  # SELL
            entry = price
            stop_loss = price + stop_distance
            take_profit_1 = price - tp1_distance
            take_profit_2 = price - tp2_distance
        
        risk_reward = abs(take_profit_1 - entry) / abs(entry - stop_loss)
        
        # Generate rationale
        rationale = self._generate_rationale(direction, agreement_count, agent_signals)
        
        return ConfluenceSignal(
            direction=direction,
            confidence=round(confidence, 2),
            agreement_count=agreement_count,
            total_agents=len(agent_signals),
            entry_price=round(entry, 2),
            stop_loss=round(stop_loss, 2),
            take_profit_1=round(take_profit_1, 2),
            take_profit_2=round(take_profit_2, 2),
            risk_reward=round(risk_reward, 2),
            rationale=rationale,
            agent_signals=agent_signals
        )
    
    def _generate_rationale(
        self,
        direction: str,
        agreement_count: int,
        agent_signals: list[AgentOutput]
    ) -> str:
        """Generate human-readable rationale."""
        strength = "Strong" if agreement_count >= 5 else "Moderate"
        bias = "bullish" if direction == "BUY" else "bearish"
        
        # Extract key points from each agent
        agent_summaries = []
        for signal in agent_signals:
            if signal.signal == direction:  # Only include agreeing agents
                # Extract key metric from rationale
                key_point = signal.rationale.split(".")[0]
                agent_summaries.append(f"{signal.agent_name}: {key_point}")
        
        rationale = (
            f"{strength} {bias} confluence ({agreement_count}/5 agents aligned). "
            f"{' | '.join(agent_summaries[:3])}."  # Top 3 points
        )
        
        return rationale
    
    @property
    def stats(self) -> dict:
        """Get orchestrator statistics."""
        return {
            "total_signals": self._signal_count,
            "last_signal": self._last_signal.to_dict() if self._last_signal else None,
            "agent_summary": registry.summary(),
        }


# ============================================
# GLOBAL ORCHESTRATOR INSTANCE
# ============================================

orchestrator = Orchestrator()
