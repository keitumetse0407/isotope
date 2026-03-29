"""
ISOTOPE Data Fetcher — Lightweight Market Data

Stark's Principle: "Get the data, don't overthink it."
Termux-Optimized: Minimal dependencies, async-friendly.

Sources:
- Primary: yfinance (free, no key)
- Backup: Alpha Vantage (500 calls/day)
"""

import asyncio
from dataclasses import dataclass
from typing import Optional
import logging
from datetime import datetime, timedelta

# Try to import yfinance, fall back to mock if unavailable
try:
    import yfinance as yf
    YFINANCE_AVAILABLE = True
except ImportError:
    YFINANCE_AVAILABLE = False

# Try Alpha Vantage
try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False


@dataclass
class OHLCV:
    """OHLCV data point."""
    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: int


@dataclass
class MarketData:
    """Complete market data for signal processing."""
    symbol: str
    current_price: float
    timestamp: datetime
    
    # EMAs
    ema9: Optional[float] = None
    ema21: Optional[float] = None
    ema50: Optional[float] = None
    
    # Momentum
    rsi14: Optional[float] = None
    macd_line: Optional[float] = None
    macd_signal: Optional[float] = None
    macd_histogram: Optional[float] = None
    
    # Volatility
    atr14: Optional[float] = None
    bb_upper: Optional[float] = None
    bb_middle: Optional[float] = None
    bb_lower: Optional[float] = None
    
    # Structure (calculated from price history)
    support_levels: list = None
    resistance_levels: list = None
    pivot_point: Optional[float] = None
    
    # Sentiment (optional)
    news_headlines: list = None
    sentiment_score: Optional[float] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary for orchestrator."""
        return {
            "current_price": self.current_price,
            "ema9": self.ema9,
            "ema21": self.ema21,
            "ema50": self.ema50,
            "rsi14": self.rsi14,
            "macd_line": self.macd_line,
            "macd_signal": self.macd_signal,
            "macd_histogram": self.macd_histogram,
            "atr14": self.atr14,
            "bb_upper": self.bb_upper,
            "bb_middle": self.bb_middle,
            "bb_lower": self.bb_lower,
            "support_levels": self.support_levels or [],
            "resistance_levels": self.resistance_levels or [],
            "pivot_point": self.pivot_point,
            "news_headlines": self.news_headlines or [],
            "sentiment_score": self.sentiment_score,
        }


class DataFetcher:
    """
    Fetches and processes market data.
    
    Optimized for Termux:
    - Minimal dependencies
    - Async-friendly
    - Graceful degradation
    """
    
    def __init__(self, symbol: str = "GC=F"):
        self.symbol = symbol  # Gold futures
        self.logger = logging.getLogger("isotope.data_fetcher")
        self._cache: Optional[MarketData] = None
        self._cache_timestamp: Optional[datetime] = None
        self._cache_ttl = timedelta(minutes=5)  # Cache for 5 minutes
    
    async def fetch(self, use_cache: bool = True) -> Optional[MarketData]:
        """
        Fetch market data.
        
        Args:
            use_cache: If True, return cached data if still valid
        
        Returns:
            MarketData or None if fetch fails
        """
        # Check cache
        if use_cache and self._is_cache_valid():
            self.logger.debug("Returning cached data")
            return self._cache
        
        try:
            if YFINANCE_AVAILABLE:
                data = await self._fetch_yfinance()
            elif AIOHTTP_AVAILABLE:
                data = await self._fetch_alpha_vantage()
            else:
                data = await self._fetch_mock()
            
            if data:
                self._cache = data
                self._cache_timestamp = datetime.now()
                self.logger.info(
                    f"Data fetched: {data.symbol} @ ${data.current_price:.2f}"
                )
            
            return data
            
        except Exception as e:
            self.logger.error(f"Data fetch failed: {e}", exc_info=True)
            return None
    
    def _is_cache_valid(self) -> bool:
        """Check if cached data is still valid."""
        if not self._cache or not self._cache_timestamp:
            return False
        return datetime.now() - self._cache_timestamp < self._cache_ttl
    
    async def _fetch_yfinance(self) -> Optional[MarketData]:
        """Fetch data from yfinance."""
        try:
            loop = asyncio.get_event_loop()
            
            # Run blocking yfinance in executor
            def _fetch():
                ticker = yf.Ticker(self.symbol)
                hist = ticker.history(period="2mo", interval="1h")
                return hist
            
            hist = await loop.run_in_executor(None, _fetch)
            
            if hist.empty:
                self.logger.warning("yfinance returned empty data")
                return None
            
            current_price = hist["Close"].iloc[-1]
            
            # Calculate indicators
            indicators = await self._calculate_indicators(hist)
            
            return MarketData(
                symbol=self.symbol,
                current_price=current_price,
                timestamp=datetime.now(),
                **indicators
            )
            
        except Exception as e:
            self.logger.error(f"yfinance fetch failed: {e}")
            return None
    
    async def _fetch_alpha_vantage(self) -> Optional[MarketData]:
        """Fetch data from Alpha Vantage (backup)."""
        import os
        
        api_key = os.getenv("ALPHA_VANTAGE_KEY")
        if not api_key:
            self.logger.warning("Alpha Vantage key not configured")
            return None
        
        url = (
            "https://www.alphavantage.co/query?"
            f"function=DIGITAL_CURRENCY_DAILY&"
            f"symbol=XAU&"
            f"market=USD&"
            f"apikey={api_key}"
        )
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as response:
                    data = await response.json()
                    
                    # Parse Alpha Vantage response
                    # ... (implementation depends on API structure)
                    
                    return None  # Placeholder
                    
        except Exception as e:
            self.logger.error(f"Alpha Vantage fetch failed: {e}")
            return None
    
    async def _fetch_mock(self) -> Optional[MarketData]:
        """
        Mock data for testing without API access.
        
        Generates realistic gold price data.
        """
        import random
        
        # Base gold price (~$2340)
        base_price = 2340.0
        
        # Add some randomness
        current_price = base_price + random.uniform(-20, 20)
        
        # Generate realistic indicators
        ema9 = current_price * (1 + random.uniform(-0.005, 0.005))
        ema21 = current_price * (1 + random.uniform(-0.01, 0.01))
        ema50 = current_price * (1 + random.uniform(-0.02, 0.02))
        
        rsi14 = 50 + random.uniform(-20, 20)
        
        macd_line = random.uniform(-5, 5)
        macd_signal = random.uniform(-3, 3)
        macd_histogram = macd_line - macd_signal
        
        atr14 = current_price * 0.01  # ~1% ATR
        
        bb_middle = current_price
        bb_upper = current_price * 1.02
        bb_lower = current_price * 0.98
        
        # Support/resistance from recent price action
        support_levels = [
            round(current_price * 0.99, 2),
            round(current_price * 0.98, 2),
        ]
        resistance_levels = [
            round(current_price * 1.01, 2),
            round(current_price * 1.02, 2),
        ]
        pivot_point = current_price
        
        return MarketData(
            symbol=self.symbol,
            current_price=round(current_price, 2),
            timestamp=datetime.now(),
            ema9=round(ema9, 2),
            ema21=round(ema21, 2),
            ema50=round(ema50, 2),
            rsi14=round(rsi14, 2),
            macd_line=round(macd_line, 2),
            macd_signal=round(macd_signal, 2),
            macd_histogram=round(macd_histogram, 2),
            atr14=round(atr14, 2),
            bb_upper=round(bb_upper, 2),
            bb_middle=round(bb_middle, 2),
            bb_lower=round(bb_lower, 2),
            support_levels=support_levels,
            resistance_levels=resistance_levels,
            pivot_point=round(pivot_point, 2),
        )
    
    async def _calculate_indicators(self, hist) -> dict:
        """Calculate technical indicators from price history."""
        try:
            import pandas as pd
            import numpy as np
            
            close = hist["Close"]
            high = hist["High"]
            low = hist["Low"]
            
            # EMAs
            ema9 = close.ewm(span=9, adjust=False).mean().iloc[-1]
            ema21 = close.ewm(span=21, adjust=False).mean().iloc[-1]
            ema50 = close.ewm(span=50, adjust=False).mean().iloc[-1]
            
            # RSI
            delta = close.diff()
            gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
            loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
            rs = gain / loss
            rsi = 100 - (100 / (1 + rs))
            rsi14 = rsi.iloc[-1]
            
            # MACD
            exp1 = close.ewm(span=12, adjust=False).mean()
            exp2 = close.ewm(span=26, adjust=False).mean()
            macd_line = exp1 - exp2
            macd_signal = macd_line.ewm(span=9, adjust=False).mean()
            macd_histogram = macd_line - macd_signal
            
            # ATR
            tr1 = high - low
            tr2 = abs(high - close.shift())
            tr3 = abs(low - close.shift())
            tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
            atr14 = tr.rolling(window=14).mean().iloc[-1]
            
            # Bollinger Bands
            bb_middle = close.rolling(window=20).mean()
            bb_std = close.rolling(window=20).std()
            bb_upper = bb_middle + (bb_std * 2)
            bb_lower = bb_middle - (bb_std * 2)
            
            # Support/Resistance (simplified)
            recent_lows = low.tail(20)
            recent_highs = high.tail(20)
            support_levels = [
                round(recent_lows.min(), 2),
                round(recent_lows.quantile(0.25), 2),
            ]
            resistance_levels = [
                round(recent_highs.max(), 2),
                round(recent_highs.quantile(0.75), 2),
            ]
            
            # Pivot point
            last_complete = hist.iloc[-2]
            pivot_point = (last_complete["High"] + last_complete["Low"] + last_complete["Close"]) / 3
            
            return {
                "ema9": float(ema9),
                "ema21": float(ema21),
                "ema50": float(ema50),
                "rsi14": float(rsi14),
                "macd_line": float(macd_line.iloc[-1]),
                "macd_signal": float(macd_signal.iloc[-1]),
                "macd_histogram": float(macd_histogram.iloc[-1]),
                "atr14": float(atr14),
                "bb_upper": float(bb_upper.iloc[-1]),
                "bb_middle": float(bb_middle.iloc[-1]),
                "bb_lower": float(bb_lower.iloc[-1]),
                "support_levels": support_levels,
                "resistance_levels": resistance_levels,
                "pivot_point": float(pivot_point),
            }
            
        except ImportError:
            self.logger.warning("pandas/numpy not available, using basic data")
            return {"ema9": None, "ema21": None, "ema50": None}
        except Exception as e:
            self.logger.error(f"Indicator calculation failed: {e}")
            return {}


# ============================================
# GLOBAL INSTANCE
# ============================================

data_fetcher = DataFetcher("GC=F")
