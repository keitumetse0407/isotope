import yfinance as yf
import pandas as pd
from typing import Optional
import config

class DataMiner:
    """Fetches gold price data from yfinance and Alpha Vantage."""

    def __init__(self, symbol: str = config.SYMBOL):
        self.symbol = symbol

    async def fetch_yfinance_data(self, timeframe: str = "1h", period: str = "60d") -> pd.DataFrame:
        """Fetch historical gold data from Yahoo Finance."""
        try:
            # Download OHLCV data
            df = yf.download(
                self.symbol,
                period=period,
                interval=timeframe,
                progress=False
            )
            
            if df.empty:
                print(f"No data found for {self.symbol} with timeframe {timeframe}")
                return pd.DataFrame()

            # Clean DataFrame: Reset index and rename columns
            df.reset_index(inplace=True)
            df.columns = [col[0] if isinstance(col, tuple) else col for col in df.columns]
            
            # Map common columns for consistency
            column_mapping = {
                'Datetime': 'timestamp',
                'Date': 'timestamp',
                'Open': 'open',
                'High': 'high',
                'Low': 'low',
                'Close': 'close',
                'Adj Close': 'adj_close',
                'Volume': 'volume'
            }
            df.rename(columns=column_mapping, inplace=True)
            
            # Keep only relevant candles
            df = df.tail(config.LOOKBACK_CANDLES)
            
            return df

        except Exception as e:
            print(f"Error fetching data from yfinance: {e}")
            return pd.DataFrame()

if __name__ == "__main__":
    import asyncio
    
    async def test():
        miner = DataMiner()
        
        print("--- Testing 1h timeframe ---")
        df_1h = await miner.fetch_yfinance_data(timeframe="1h")
        if not df_1h.empty:
            print(f"Fetched {len(df_1h)} candles for 1h")
            print(df_1h.tail(3))
        
        print("\n--- Testing 4h timeframe ---")
        df_4h = await miner.fetch_yfinance_data(timeframe="4h", period="200d")
        if not df_4h.empty:
            print(f"Fetched {len(df_4h)} candles for 4h")
            print(df_4h.tail(3))

    asyncio.run(test())
