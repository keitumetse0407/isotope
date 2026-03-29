"""
ISOTOPE Agent Tests

Tests for the multi-agent system.
Run: python -m pytest tests/test_agents.py -v
"""

import asyncio
import pytest
from src.agents.trend_agent import TrendAgent
from src.agents.momentum_agent import MomentumAgent
from src.agents.volatility_agent import VolatilityAgent
from src.agents.structure_agent import StructureAgent
from src.agents.sentiment_agent import SentimentAgent


# ============================================
# MOCK DATA
# ============================================

BULLISH_MARKET_DATA = {
    "current_price": 2345.00,
    "ema9": 2350.00,
    "ema21": 2345.00,
    "ema50": 2335.00,
    "rsi14": 55,
    "macd_line": 3.5,
    "macd_signal": 2.0,
    "macd_histogram": 1.5,
    "atr14": 18.0,
    "bb_upper": 2360.00,
    "bb_middle": 2345.00,
    "bb_lower": 2330.00,
    "support_levels": [2335.00, 2330.00, 2325.00],
    "resistance_levels": [2355.00, 2360.00, 2365.00],
    "pivot_point": 2345.00,
}

BEARISH_MARKET_DATA = {
    "current_price": 2335.00,
    "ema9": 2330.00,
    "ema21": 2338.00,
    "ema50": 2350.00,
    "rsi14": 35,
    "macd_line": -2.5,
    "macd_signal": -1.0,
    "macd_histogram": -1.5,
    "atr14": 20.0,
    "bb_upper": 2350.00,
    "bb_middle": 2335.00,
    "bb_lower": 2320.00,
    "support_levels": [2325.00, 2320.00, 2315.00],
    "resistance_levels": [2345.00, 2350.00, 2355.00],
    "pivot_point": 2335.00,
}

OVERSOLD_DATA = {
    **BULLISH_MARKET_DATA,
    "rsi14": 25,  # Oversold
    "macd_histogram": 0.5,  # Slightly bullish
}

OVERBOUGHT_DATA = {
    **BEARISH_MARKET_DATA,
    "rsi14": 75,  # Overbought
    "macd_histogram": -0.5,  # Slightly bearish
}


# ============================================
# TREND AGENT TESTS
# ============================================

class TestTrendAgent:
    
    @pytest.mark.asyncio
    async def test_bullish_alignment(self):
        agent = TrendAgent()
        result = await agent.analyze(BULLISH_MARKET_DATA)
        
        assert result.signal == "BUY"
        assert result.confidence > 0.5
        assert "Bullish EMA alignment" in result.rationale
    
    @pytest.mark.asyncio
    async def test_bearish_alignment(self):
        agent = TrendAgent()
        result = await agent.analyze(BEARISH_MARKET_DATA)
        
        assert result.signal == "SELL"
        assert result.confidence > 0.5
        assert "Bearish EMA alignment" in result.rationale
    
    @pytest.mark.asyncio
    async def test_no_alignment(self):
        agent = TrendAgent()
        data = {
            "current_price": 2340.00,
            "ema9": 2342.00,
            "ema21": 2340.00,
            "ema50": 2341.00,  # No clear alignment
        }
        result = await agent.analyze(data)
        
        assert result.signal == "HOLD"
        assert result.confidence < 0.5


# ============================================
# MOMENTUM AGENT TESTS
# ============================================

class TestMomentumAgent:
    
    @pytest.mark.asyncio
    async def test_oversold_with_bullish_macd(self):
        agent = MomentumAgent()
        result = await agent.analyze(OVERSOLD_DATA)
        
        assert result.signal == "BUY"
        assert result.confidence >= 0.8  # Strong signal
    
    @pytest.mark.asyncio
    async def test_overbought_with_bearish_macd(self):
        agent = MomentumAgent()
        result = await agent.analyze(OVERBOUGHT_DATA)
        
        assert result.signal == "SELL"
        assert result.confidence >= 0.8
    
    @pytest.mark.asyncio
    async def test_neutral_rsi(self):
        agent = MomentumAgent()
        data = {
            "rsi14": 50,
            "macd_line": 0.5,
            "macd_signal": 0.3,
            "macd_histogram": 0.2,
        }
        result = await agent.analyze(data)
        
        # Should be moderate BUY or HOLD depending on MACD
        assert result.signal in ["BUY", "HOLD"]


# ============================================
# STRUCTURE AGENT TESTS
# ============================================

class TestStructureAgent:
    
    @pytest.mark.asyncio
    async def test_at_support(self):
        agent = StructureAgent()
        data = {
            "current_price": 2335.50,  # Near support
            "support_levels": [2335.00, 2330.00],
            "resistance_levels": [2350.00, 2355.00],
        }
        result = await agent.analyze(data)
        
        assert result.signal == "BUY"
        assert "support" in result.rationale.lower()
    
    @pytest.mark.asyncio
    async def test_at_resistance(self):
        agent = StructureAgent()
        data = {
            "current_price": 2349.50,  # Near resistance
            "support_levels": [2335.00, 2330.00],
            "resistance_levels": [2350.00, 2355.00],
        }
        result = await agent.analyze(data)
        
        assert result.signal == "SELL"
        assert "resistance" in result.rationale.lower()


# ============================================
# SENTIMENT AGENT TESTS
# ============================================

class TestSentimentAgent:
    
    @pytest.mark.asyncio
    async def test_positive_sentiment(self):
        agent = SentimentAgent()
        data = {
            "news_headlines": [
                "Gold rallies on safe haven demand",
                "Analysts upgrade gold target to $2500",
                "Bullish outlook for precious metals"
            ]
        }
        result = await agent.analyze(data)
        
        assert result.signal == "BUY"
        assert result.metadata["sentiment_score"] > 0
    
    @pytest.mark.asyncio
    async def test_negative_sentiment(self):
        agent = SentimentAgent()
        data = {
            "news_headlines": [
                "Gold drops on strong dollar",
                "Analysts cut gold forecasts",
                "Bearish outlook for precious metals"
            ]
        }
        result = await agent.analyze(data)
        
        assert result.signal == "SELL"
        assert result.metadata["sentiment_score"] < 0
    
    @pytest.mark.asyncio
    async def test_no_data(self):
        agent = SentimentAgent()
        result = await agent.analyze({})
        
        assert result.signal == "HOLD"
        assert result.confidence == 0.0


# ============================================
# INTEGRATION TESTS
# ============================================

class TestAgentIntegration:
    
    @pytest.mark.asyncio
    async def test_all_agents_bullish_scenario(self):
        """Test all agents in bullish market conditions."""
        agents = [
            TrendAgent(),
            MomentumAgent(),
            VolatilityAgent(),
            StructureAgent(),
            SentimentAgent(),
        ]
        
        data = {
            **BULLISH_MARKET_DATA,
            "news_headlines": ["Gold outlook positive"],
        }
        
        results = await asyncio.gather(*[
            agent.analyze(data) for agent in agents
        ])
        
        # Count BUY signals
        buy_count = sum(1 for r in results if r.signal == "BUY")
        
        # In strong bullish scenario, expect at least 3/5 BUY signals
        assert buy_count >= 3
    
    @pytest.mark.asyncio
    async def test_all_agents_bearish_scenario(self):
        """Test all agents in bearish market conditions."""
        agents = [
            TrendAgent(),
            MomentumAgent(),
            VolatilityAgent(),
            StructureAgent(),
            SentimentAgent(),
        ]
        
        data = {
            **BEARISH_MARKET_DATA,
            "news_headlines": ["Gold outlook negative"],
        }
        
        results = await asyncio.gather(*[
            agent.analyze(data) for agent in agents
        ])
        
        # Count SELL signals
        sell_count = sum(1 for r in results if r.signal == "SELL")
        
        # In strong bearish scenario, expect at least 3/5 SELL signals
        assert sell_count >= 3


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
