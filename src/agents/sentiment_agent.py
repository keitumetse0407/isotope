"""
Sentiment Agent — News RSS Analysis

Munger's Principle: "What do smart people believe?"
Taleb's Principle: "Be aware of narrative, but don't be fooled by it."

Analyzes gold market sentiment from news sources.
Note: For Termux, we use simple RSS parsing without heavy NLP.
"""

import asyncio
from typing import Optional
from .base import BaseAgent, AgentOutput


class SentimentAgent(BaseAgent):
    """
    Analyzes market sentiment from news sources.
    
    Sources (free RSS feeds):
    - Reuters Gold
    - Kitco Gold
    - Gold.org (World Gold Council)
    
    Sentiment scoring:
    - Positive keywords: +1
    - Negative keywords: -1
    - Neutral: 0
    """
    
    def __init__(self):
        super().__init__("sentiment_agent")
        
        # Simple keyword-based sentiment (no heavy NLP for Termux)
        self.positive_keywords = [
            "rally", "surge", "gain", "rise", "bullish", "buy", "upgrade",
            "outlook positive", "target raised", "demand strong", "safe haven"
        ]
        self.negative_keywords = [
            "drop", "fall", "decline", "bearish", "sell", "downgrade",
            "outlook negative", "target cut", "demand weak", "sell-off"
        ]
    
    async def analyze(self, data: dict) -> AgentOutput:
        """
        Analyze sentiment from provided news data.
        
        Input data must contain:
        - news_headlines: list[str] (optional, for real-time)
        - sentiment_score: float (optional, pre-calculated from -1 to 1)
        
        If no data provided, returns neutral HOLD.
        """
        headlines = data.get("news_headlines", [])
        precomputed_score = data.get("sentiment_score")
        
        # If precomputed score provided, use it
        if precomputed_score is not None:
            return self._score_to_signal(precomputed_score, "Precomputed sentiment score")
        
        # If headlines provided, analyze them
        if headlines:
            score = self._analyze_headlines(headlines)
            return self._score_to_signal(score, f"Analyzed {len(headlines)} headlines")
        
        # No data available - return neutral
        return AgentOutput(
            agent_name=self.name,
            signal="HOLD",
            confidence=0.0,
            rationale="No sentiment data available. Returning neutral.",
            metadata={"sentiment_score": 0.0, "sources_analyzed": 0}
        )
    
    def _analyze_headlines(self, headlines: list[str]) -> float:
        """
        Simple keyword-based sentiment analysis.
        
        Returns score from -1 (very negative) to +1 (very positive).
        """
        if not headlines:
            return 0.0
        
        total_score = 0.0
        
        for headline in headlines:
            headline_lower = headline.lower()
            headline_score = 0
            
            for keyword in self.positive_keywords:
                if keyword in headline_lower:
                    headline_score += 1
            
            for keyword in self.negative_keywords:
                if keyword in headline_lower:
                    headline_score -= 1
            
            total_score += headline_score
        
        # Normalize to -1 to 1
        avg_score = total_score / len(headlines)
        # Clamp to -1 to 1
        return max(-1.0, min(1.0, avg_score / 3))  # Divide by 3 to prevent extreme scores
    
    def _score_to_signal(self, score: float, source: str) -> AgentOutput:
        """Convert sentiment score to trading signal."""
        if score > 0.5:
            signal = "BUY"
            confidence = min(0.5 + score * 0.5, 0.9)
            rationale = f"Positive sentiment ({score:.2f}). {source}"
        elif score < -0.5:
            signal = "SELL"
            confidence = min(0.5 + abs(score) * 0.5, 0.9)
            rationale = f"Negative sentiment ({score:.2f}). {source}"
        elif score > 0.2:
            signal = "BUY"
            confidence = 0.45 + score * 0.3
            rationale = f"Mildly positive sentiment ({score:.2f}). {source}"
        elif score < -0.2:
            signal = "SELL"
            confidence = 0.45 + abs(score) * 0.3
            rationale = f"Mildly negative sentiment ({score:.2f}). {source}"
        else:
            signal = "HOLD"
            confidence = 0.3
            rationale = f"Neutral sentiment ({score:.2f}). {source}"
        
        return AgentOutput(
            agent_name=self.name,
            signal=signal,
            confidence=round(confidence, 2),
            rationale=rationale,
            metadata={
                "sentiment_score": round(score, 2),
                "sentiment_state": "positive" if score > 0.2 else "negative" if score < -0.2 else "neutral"
            }
        )
    
    async def fetch_rss_sentiment(self) -> Optional[float]:
        """
        Fetch and analyze RSS feeds.
        
        Note: For production, implement actual RSS fetching.
        For now, returns None (uses precomputed scores).
        """
        # TODO: Implement RSS fetching with aiohttp
        # For Termux, keep it lightweight
        return None


def create_sentiment_agent() -> SentimentAgent:
    """Factory function to create sentiment agent."""
    return SentimentAgent()
