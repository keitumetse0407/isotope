import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Base paths
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)

# Database
DB_PATH = DATA_DIR / "isotope.db"

# Trading Constants
SYMBOL = "GC=F"  # Gold Futures
TIMEFRAMES = ["1h", "4h", "1d"]
LOOKBACK_CANDLES = 500

# Indicators
EMA_PERIODS = [9, 21, 50]
RSI_PERIOD = 14
MACD_FAST = 12
MACD_SLOW = 26
MACD_SIGNAL = 9
ATR_PERIOD = 14
BB_PERIOD = 20
BB_STD = 2

# Risk Management
MIN_RR_RATIO = 1.5
TP1_RR = 1.5
TP2_RR = 3.0

# API Keys (handled via .env)
ALPHA_VANTAGE_KEY = os.getenv("ALPHA_VANTAGE_KEY")

# WhatsApp Notifier
WHATSAPP_BOT_URL = os.getenv("WHATSAPP_BOT_URL", "http://113.30.189.89:8765/send_signal")

# Server Configuration
ORCHESTRATOR_PORT = int(os.getenv("ORCHESTRATOR_PORT", 8100))
DASHBOARD_PORT = int(os.getenv("DASHBOARD_PORT", 8101))
