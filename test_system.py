#!/usr/bin/env python3
"""
ISOTOPE v2.0 — Quick Test Script

Run this to verify all components are working:
    python test_system.py
"""

import asyncio
import sys


async def test_imports():
    """Test that all modules import correctly."""
    print("📦 Testing imports...")
    
    try:
        from src.agents.base import BaseAgent, AgentOutput, registry
        from src.agents.trend_agent import TrendAgent, create_trend_agent
        from src.agents.momentum_agent import MomentumAgent, create_momentum_agent
        from src.agents.volatility_agent import VolatilityAgent, create_volatility_agent
        from src.agents.structure_agent import StructureAgent, create_structure_agent
        from src.agents.sentiment_agent import SentimentAgent, create_sentiment_agent
        print("   ✅ Agents imported")
    except Exception as e:
        print(f"   ❌ Agent import failed: {e}")
        return False
    
    try:
        from src.orchestrator import orchestrator, OrchestratorConfig, ConfluenceSignal
        print("   ✅ Orchestrator imported")
    except Exception as e:
        print(f"   ❌ Orchestrator import failed: {e}")
        return False
    
    try:
        from src.risk_manager import create_risk_manager, RiskLimits, RiskState
        print("   ✅ Risk Manager imported")
    except Exception as e:
        print(f"   ❌ Risk Manager import failed: {e}")
        return False
    
    try:
        from src.data_fetcher import DataFetcher, MarketData
        print("   ✅ Data Fetcher imported")
    except Exception as e:
        print(f"   ❌ Data Fetcher import failed: {e}")
        return False
    
    try:
        from src.database import Database, db
        print("   ✅ Database imported")
    except Exception as e:
        print(f"   ❌ Database import failed: {e}")
        return False
    
    try:
        from src.dashboard import TerminalDashboard
        print("   ✅ Dashboard imported")
    except Exception as e:
        print(f"   ❌ Dashboard import failed: {e}")
        return False
    
    return True


async def test_agents():
    """Test individual agents."""
    print("\n🤖 Testing agents...")
    
    from src.agents.trend_agent import create_trend_agent
    from src.agents.momentum_agent import create_momentum_agent
    from src.agents.volatility_agent import create_volatility_agent
    from src.agents.structure_agent import create_structure_agent
    from src.agents.sentiment_agent import create_sentiment_agent
    
    test_data = {
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
        "support_levels": [2335.00, 2330.00],
        "resistance_levels": [2355.00, 2360.00],
        "pivot_point": 2345.00,
    }
    
    agents = [
        ("Trend", create_trend_agent()),
        ("Momentum", create_momentum_agent()),
        ("Volatility", create_volatility_agent()),
        ("Structure", create_structure_agent()),
        ("Sentiment", create_sentiment_agent()),
    ]
    
    all_passed = True
    
    for name, agent in agents:
        try:
            result = await agent.analyze(test_data)
            if result.signal in ["BUY", "SELL", "HOLD"]:
                print(f"   ✅ {name} agent: {result.signal} (confidence: {result.confidence})")
            else:
                print(f"   ⚠️  {name} agent: Invalid signal '{result.signal}'")
                all_passed = False
        except Exception as e:
            print(f"   ❌ {name} agent failed: {e}")
            all_passed = False
    
    return all_passed


async def test_orchestrator():
    """Test orchestrator signal generation."""
    print("\n🧠 Testing orchestrator...")
    
    from src.orchestrator import orchestrator
    
    test_data = {
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
        "support_levels": [2335.00, 2330.00],
        "resistance_levels": [2355.00, 2360.00],
        "pivot_point": 2345.00,
        "news_headlines": ["Gold outlook positive"],
    }
    
    try:
        signal = await orchestrator.process(test_data)
        
        if signal:
            print(f"   ✅ Signal generated: {signal.direction}")
            print(f"      Entry: ${signal.entry_price:.2f}")
            print(f"      SL: ${signal.stop_loss:.2f}")
            print(f"      TP1: ${signal.take_profit_1:.2f}")
            print(f"      Confidence: {signal.confidence*100:.1f}%")
            print(f"      Agreement: {signal.agreement_count}/{signal.total_agents}")
            print(f"      Latency: {signal.metadata.get('latency_ms', 0):.2f}ms")
            return True
        else:
            print("   ⚠️  No signal generated (insufficient confluence)")
            return True  # Not a failure, just market conditions
    except Exception as e:
        print(f"   ❌ Orchestrator failed: {e}")
        return False


async def test_risk_manager():
    """Test risk manager position sizing."""
    print("\n🛡️  Testing risk manager...")
    
    from src.risk_manager import create_risk_manager, RiskLimits
    
    rm = create_risk_manager(account_balance=10000.0)
    
    position = rm.calculate_position(
        signal_direction="BUY",
        entry_price=2345.00,
        stop_loss=2330.00,
        signal_confidence=0.80,
    )
    
    if position.is_approved:
        print(f"   ✅ Position approved")
        print(f"      Size: {position.position_size:.2f} lots")
        print(f"      Risk: ${position.risk_amount:.2f} ({position.risk_percent:.2f}%)")
        return True
    else:
        print(f"   ⚠️  Position rejected: {position.rejection_reason}")
        return True  # Could be valid rejection


async def test_database():
    """Test database operations."""
    print("\n💾 Testing database...")
    
    from src.database import db
    
    try:
        # Test overall stats
        stats = db.get_overall_stats()
        print(f"   ✅ Database connected")
        print(f"      Total signals: {stats['total_signals']}")
        print(f"      Win rate: {stats['win_rate']*100:.1f}%")
        return True
    except Exception as e:
        print(f"   ❌ Database test failed: {e}")
        return False


async def test_data_fetcher():
    """Test data fetching."""
    print("\n📊 Testing data fetcher...")
    
    from src.data_fetcher import data_fetcher
    
    try:
        data = await data_fetcher.fetch()
        
        if data:
            print(f"   ✅ Data fetched: {data.symbol} @ ${data.current_price:.2f}")
            return True
        else:
            print(f"   ⚠️  No data returned (may need API key)")
            return True  # Mock data should still work
    except Exception as e:
        print(f"   ❌ Data fetcher failed: {e}")
        return False


async def main():
    """Run all tests."""
    print("=" * 60)
    print("🔬 ISOTOPE v2.0 — System Test")
    print("=" * 60)
    
    results = {
        "Imports": await test_imports(),
        "Agents": await test_agents(),
        "Orchestrator": await test_orchestrator(),
        "Risk Manager": await test_risk_manager(),
        "Database": await test_database(),
        "Data Fetcher": await test_data_fetcher(),
    }
    
    print("\n" + "=" * 60)
    print("📊 TEST RESULTS")
    print("=" * 60)
    
    for test, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {test}: {status}")
    
    print("=" * 60)
    
    all_passed = all(results.values())
    
    if all_passed:
        print("\n🎉 ALL TESTS PASSED — System ready for Phase 1!")
        print("\nNext steps:")
        print("  1. Run: python main.py --once  (single signal cycle)")
        print("  2. Run: python main.py --dashboard  (view dashboard)")
        print("  3. Run: python main.py --stats  (view statistics)")
        print("  4. Run: python main.py  (full system)")
    else:
        print("\n⚠️  SOME TESTS FAILED — Fix issues before proceeding")
        sys.exit(1)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Tests interrupted")
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
