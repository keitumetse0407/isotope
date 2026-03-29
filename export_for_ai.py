#!/usr/bin/env python3
"""
ISOTOPE Project Exporter
=========================
Exports all critical code files into one document for AI analysis.

Usage:
    python3 export_for_ai.py > /root/isotope/ISOTOPE_FULL_PACKAGE.txt
"""

import os
from datetime import datetime
from pathlib import Path

# Files to include (most critical first)
CRITICAL_FILES = [
    # Core Backend
    "src/orchestrator.py",
    "src/risk_manager.py",
    "src/data_fetcher.py",
    "src/database.py",
    "src/api/main.py",
    
    # AI Agents
    "src/agents/base.py",
    "src/agents/trend_agent.py",
    "src/agents/momentum_agent.py",
    "src/agents/volatility_agent.py",
    "src/agents/structure_agent.py",
    "src/agents/sentiment_agent.py",
    
    # Mobile App
    "apps/mobile/lib/main.dart",
    "apps/mobile/lib/services/api_service.dart",
    "apps/mobile/pubspec.yaml",
    "apps/mobile/preview.html",
    
    # Main Entry
    "main.py",
    "config.py",
    
    # Documentation
    "README.md",
    "BOSS_PRESENTATION.md",
    "SELF_HOSTED_AI.md",
]

def read_file(filepath):
    """Read file content safely."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"ERROR READING FILE: {e}"

def export_project():
    """Export entire project to stdout."""
    
    print("=" * 80)
    print("ISOTOPE — COMPLETE CODE PACKAGE FOR AI ANALYSIS")
    print("=" * 80)
    print(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("Project: AI-Powered Gold Trading Signals Mobile App")
    print("Founder: Solo, 22, Limpopo SA | Budget: R0 | Goal: R10K MRR in 90 days")
    print("VPS: 185.167.97.193 (Amsterdam, 4GB RAM, 2 CPU)")
    print("\n" + "=" * 80)
    
    # Project Overview
    print("""
## CONTEXT FOR AI ANALYSIS

I'm a broke 22-year-old solo founder in South Africa building ISOTOPE.

WHAT'S BUILT:
✅ Multi-agent AI signal engine (5 agents: trend, momentum, volatility, structure, sentiment)
✅ FastAPI backend for mobile app
✅ Flutter app UI (HTML preview complete)
✅ Database logging (SQLite)
✅ VPS deployed (Amsterdam)

WHAT'S MISSING:
❌ Users (0 currently)
❌ Track record (no public signal history)
❌ Revenue (R0 MRR)
❌ Play Store submission (not yet)

MY CONSTRAINTS:
- Budget: R0 (literally broke)
- Marketing: R0 (can't afford ads)
- Time: Full-time on this
- Skills: Technical, zero marketing experience

MARKET REALITY (South Africa):
- $29/mo too expensive → R199/mo sweet spot
- WhatsApp distribution > Play Store
- Need verified track record before anyone pays
- FSCA compliance required (disclaimers)
- Realistic Month 12: R5K-R15K MRR, not $50K

COMPETITIVE LANDSCAPE:
- TradingView: Free RSI/MACD/EMA (our signals same, but we add AI confluence)
- Telegram signal groups: No track record, often scams
- Forex gurus: R500+/month, we're cheaper

MY ASK:
Given all code below, tell me:
1. What's WRONG with my approach?
2. What should I build NEXT (prioritized)?
3. How do I get first 10 paying users with R0 budget?
4. What technical debt will kill me at scale?
5. How do I optimize my AI assistant workflow?

Be brutal. No fluff. I need truth, not encouragement.

""")
    
    print("=" * 80)
    print("SECTION 1: CORE BACKEND")
    print("=" * 80)
    
    for filepath in CRITICAL_FILES:
        full_path = Path("/root/isotope") / filepath
        if full_path.exists():
            content = read_file(full_path)
            print(f"\n{'='*80}")
            print(f"FILE: {filepath}")
            print(f"SIZE: {len(content):,} characters")
            print(f"{'='*80}\n")
            print(content)
            print("\n")
        else:
            print(f"\n{'='*80}")
            print(f"FILE: {filepath}")
            print(f"STATUS: NOT FOUND")
            print(f"{'='*80}\n")
    
    print("\n" + "=" * 80)
    print("END OF PACKAGE")
    print("=" * 80)
    print(f"\nTotal files exported: {len(CRITICAL_FILES)}")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n---\n")
    print("INSTRUCTIONS FOR AI:")
    print("1. Review all code above")
    print("2. Identify critical issues")
    print("3. Provide prioritized action list")
    print("4. Optimize for: R0 budget, SA market, solo founder")
    print("5. Be brutally honest about what will fail")

if __name__ == "__main__":
    export_project()
