"""
ISOTOPE Multi-Agent Architecture
================================

Embodiment of Stark + Munger + Dalio + Taleb principles:
- Simple, modular agents (Stark)
- Inversion rules, avoid stupidity (Munger)
- Believability-weighted decisions (Dalio)
- Antifragile, barbell positioning (Taleb)

Each agent is independent, testable, and replaceable.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import asyncio


class AgentState(Enum):
    IDLE = "idle"
    RUNNING = "running"
    ERROR = "error"
    DISABLED = "disabled"


@dataclass
class AgentOutput:
    """Standardized output from any agent."""
    agent_name: str
    signal: str  # "BUY", "SELL", "HOLD"
    confidence: float  # 0.0 - 1.0
    rationale: str
    metadata: dict = field(default_factory=dict)
    timestamp: int = field(default_factory=lambda: int(asyncio.get_event_loop().time() * 1000))


class BaseAgent(ABC):
    """
    All agents inherit from this base class.
    
    Stark's Principle: "Simple interface, powerful implementation."
    Munger's Principle: "Know your circle of competence."
    """
    
    def __init__(self, name: str):
        self.name = name
        self.state = AgentState.IDLE
        self.total_calls = 0
        self.successful_calls = 0
        self.failed_calls = 0
        self._believability_score = 0.5  # Starts neutral, updates with performance
    
    @abstractmethod
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze input data and return a signal.
        
        Must be implemented by each agent.
        Must complete within timeout (defined in orchestrator).
        """
        pass
    
    async def __call__(self, data: dict) -> Optional[AgentOutput]:
        """
        Wrapper that handles errors gracefully.
        
        Taleb's Principle: "Survival first."
        """
        self.total_calls += 1
        
        try:
            self.state = AgentState.RUNNING
            output = await self.analyze(data)
            self.successful_calls += 1
            self.state = AgentState.IDLE
            return output
        except Exception as e:
            self.failed_calls += 1
            self.state = AgentState.ERROR
            # Return neutral output instead of crashing
            return AgentOutput(
                agent_name=self.name,
                signal="HOLD",
                confidence=0.0,
                rationale=f"Agent error: {str(e)}",
                metadata={"error": str(e)}
            )
    
    @property
    def success_rate(self) -> float:
        """Dalio's believability: historical accuracy."""
        if self.total_calls == 0:
            return 0.5
        return self.successful_calls / self.total_calls
    
    def update_believability(self, was_correct: bool):
        """Update believability score based on outcome."""
        # Simple exponential moving average
        alpha = 0.1  # Learning rate
        if was_correct:
            self._believability_score = (
                (1 - alpha) * self._believability_score + alpha * 1.0
            )
        else:
            self._believability_score = (
                (1 - alpha) * self._believability_score + alpha * 0.0
            )
    
    @property
    def believability(self) -> float:
        """Get current believability score (0.0 - 1.0)."""
        return self._believability_score
    
    def disable(self):
        """Temporarily disable agent (e.g., during market events)."""
        self.state = AgentState.DISABLED
    
    def enable(self):
        """Re-enable agent."""
        self.state = AgentState.IDLE


# ============================================
# AGENT REGISTRY
# ============================================

class AgentRegistry:
    """
    Central registry for all agents.
    
    Stark's Principle: "Modular, swappable components."
    """
    
    def __init__(self):
        self._agents: dict[str, BaseAgent] = {}
    
    def register(self, agent: BaseAgent):
        """Register an agent."""
        self._agents[agent.name] = agent
    
    def get(self, name: str) -> Optional[BaseAgent]:
        """Get agent by name."""
        return self._agents.get(name)
    
    def get_all(self) -> list[BaseAgent]:
        """Get all registered agents."""
        return list(self._agents.values())
    
    async def run_all(self, data: dict, timeout: float = 5.0) -> list[AgentOutput]:
        """
        Run all agents in parallel with timeout.
        
        Stark's Principle: "Parallel processing for speed."
        Taleb's Principle: "Circuit breaker on failures."
        """
        async def run_with_timeout(agent: BaseAgent) -> Optional[AgentOutput]:
            if agent.state == AgentState.DISABLED:
                return None
            try:
                return await asyncio.wait_for(agent(data), timeout=timeout)
            except asyncio.TimeoutError:
                return AgentOutput(
                    agent_name=agent.name,
                    signal="HOLD",
                    confidence=0.0,
                    rationale=f"Agent timed out after {timeout}s"
                )
            except Exception as e:
                return AgentOutput(
                    agent_name=agent.name,
                    signal="HOLD",
                    confidence=0.0,
                    rationale=f"Agent failed: {str(e)}"
                )
        
        tasks = [run_with_timeout(agent) for agent in self._agents.values()]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out None (disabled agents) and failed results
        return [r for r in results if r is not None]
    
    def get_believability_weights(self) -> dict[str, float]:
        """
        Get believability weights for all agents.
        
        Dalio's Principle: "Believability-weighted decisions."
        """
        return {
            name: agent.believability
            for name, agent in self._agents.items()
        }
    
    def summary(self) -> dict:
        """Get summary of all agents."""
        return {
            name: {
                "state": agent.state.value,
                "success_rate": agent.success_rate,
                "believability": agent.believability,
            }
            for name, agent in self._agents.items()
        }


# ============================================
# GLOBAL REGISTRY INSTANCE
# ============================================

registry = AgentRegistry()
