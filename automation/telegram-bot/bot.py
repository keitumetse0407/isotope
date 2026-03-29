"""
ISOTOPE Telegram Bot — Trial Conversion Flow

Handles:
- /start onboarding
- Disclaimer acceptance
- Trial signal delivery
- Day 1/3/6/7 conversion sequence
- Payment webhook integration
- Objection handlers

Author: ELEV8 DIGITAL | Built by Elkai
"""

import os
import logging
from datetime import datetime, timedelta
from typing import Optional

from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    ConversationHandler,
    ContextTypes,
    filters,
)

import httpx
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

# ============================================
# CONFIGURATION
# ============================================

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
FASTAPI_URL = os.getenv("FASTAPI_URL", "http://localhost:8100")
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://localhost:5678/webhook")
GOOGLE_SHEET_ID = os.getenv("GOOGLE_SHEET_ID", "")

# Conversation states
DISCLAIMER_ACCEPT, START_TRIAL, UPGRADE, OBJECTION = range(4)

# Message templates
MESSAGES = {
    "start": """
🔬 Welcome to ISOTOPE — AI-Powered Gold Signals

Hey {first_name}, I'm the ISOTOPE bot.

Before we begin, you need to know:

⚠️ DISCLAIMER (FSCA Compliance):
• These signals are EDUCATIONAL ONLY
• This is NOT financial advice
• Past performance ≠ future results
• You trade at YOUR OWN RISK
• We are NOT FSCA licensed

By continuing, you accept this disclaimer.

Type ACCEPT to continue, or EXIT to leave.
""",

    "accepted": """
✅ Disclaimer accepted. Logged at {timestamp}.

Here's what you get:

📊 FREE TRIAL (7 days):
• 2 signals/week (delayed by 1 hour)
• Access to public signal log
• Basic confidence scores

💎 PRO (R139/mo):
• Real-time signals (6AM, 12PM, 4PM SAST)
• 5-7 signals/week
• Confidence scores (60-85%)
• Weekly performance recap
• Private Telegram group

🏆 ELITE (R299/mo):
• Everything in PRO
• Private WhatsApp group
• Monthly 30-min audio Q&A
• Priority signal review

Ready to start your trial? You'll get your first signal within 24 hours.

Type START to begin your 7-day trial.
""",

    "trial_started": """
🎯 Trial Activated!

Your 7-day trial starts NOW ({date}).

What happens next:
• Day 1 (Today): Welcome + first signal preview
• Day 3: Check-in + win/loss sheet link
• Day 6: "Expires tomorrow" reminder
• Day 7: Trial ends → upgrade or lose access

📄 PUBLIC SIGNAL LOG:
https://docs.google.com/spreadsheets/d/{sheet_id}

We log EVERY signal — wins AND losses. No deletions. No edits.

Your first trial signal will arrive within 24 hours.

Questions? Reply here (I read all messages).
""",

    "day1": """
📬 Day 1: Welcome to ISOTOPE

Hey {first_name}, quick intro:

🧠 HOW IT WORKS:
1. Our AI analyzes gold (XAU/USD) at 6AM, 12PM, 4PM SAST
2. It scores 5 factors: Trend, Momentum, Volatility, Structure, Sentiment
3. If 4/5 agree + confidence >60% → signal sent
4. You decide: take it or leave it

📊 TODAY'S SIGNAL:
{signal_or_none}

📄 CHECK OUR TRACK RECORD:
https://docs.google.com/spreadsheets/d/{sheet_id}

This week: {win_rate}% win rate ({wins}W / {losses}L)

Reply STOP to cancel trial, or KEEP to continue.
""",

    "day3": """
📬 Day 3: Quick Check-In

Hey {first_name}, how's it going?

Quick question: Are you seeing the signals? Sometimes they land in spam.

📄 LIVE PERFORMANCE (Updated Daily):
https://docs.google.com/spreadsheets/d/{sheet_id}

Last 7 days: {win_rate}% win rate
Last 30 days: {30day_win_rate}% win rate

💡 TIP: Don't chase every signal. Wait for 70%+ confidence. Those hit 68% win rate historically.

Trial expires in 4 days. Upgrade now for R99 (first month, normally R139).

Upgrade link: https://yoco.com/isotope/r99-trial

Questions? Reply here.
""",

    "day6": """
⏰ Day 6: Trial Expires Tomorrow

Hey {first_name}, heads up:

Your trial expires in 24 hours ({expiry_time}).

Upgrade now and lock in:
• R99 first month (save R40)
• Real-time signals (no 1-hour delay)
• 5-7 signals/week (not 2)
• Private Telegram group

👉 Upgrade: https://yoco.com/isotope/r99-trial

❓ COMMON QUESTIONS:

"Is this worth it?"
→ R99 = 3 data bundles. One good signal covers 10 months.

"What if signals lose?"
→ You see our full history. Some lose. That's trading. But overall: {win_rate}% win rate.

"Can I cancel anytime?"
→ Yes. Reply CANCEL anytime. No questions.

Upgrade now → signals continue uninterrupted.
https://yoco.com/isotope/r99-trial
""",

    "day7": """
🚨 Day 7: Trial Ended

Hey {first_name}, your trial has ended.

You received {trial_signals} signals over 7 days.
Result: {trial_wins} wins, {trial_losses} losses ({trial_win_rate}%).

📄 FULL LOG:
https://docs.google.com/spreadsheets/d/{sheet_id}

🔓 UNLOCK FULL ACCESS:
• R99 first month (save R40)
• R50 credit if you upgrade in next 6 hours

👉 Claim R50 credit: https://yoco.com/isotope/r99-trial

After 6 hours, price returns to R139/mo.

Reply KEEP to stay on (R99), or BYE to leave.
""",

    "payment_success": """
🎉 Payment Received! Welcome to ISOTOPE Pro

Thanks, {first_name}! Your upgrade is confirmed.

✅ ACCESS UNLOCKED:
• Real-time signals (6AM, 12PM, 4PM SAST)
• 5-7 signals/week
• Confidence scores (60-85%)
• Private Telegram group: https://t.me/+{group_id}
• Weekly performance recaps

📅 NEXT SIGNAL:
Tomorrow at 6AM SAST (unless high-confidence setup tonight)

📄 YOUR SUBSCRIPTION:
• Plan: ISOTOPE Pro
• Amount: R99 (first month)
• Renewal: {renewal_date} at R139/mo
• Cancel: Reply CANCEL anytime

💡 PRO TIP: Wait for 70%+ confidence signals. They hit 68% win rate historically.

Questions? Reply here. I read every message.

— Elkai | ISOTOPE Founder
""",

    "objection_expensive": """
I get it. R99 feels like a lot.

But think about it:
• One good signal = R500-R1,500 profit (1:3 RR)
• R99 = 3 data bundles or 2 KFC meals
• You're paying for 30 days of research, not one signal

Worst case: You lose R99.
Best case: One signal changes your month.

Still hesitant? Start with R99 first month. Cancel anytime.

👉 Upgrade: https://yoco.com/isotope/r99-trial
""",

    "objection_dont_trust": """
Smart. You shouldn't.

Most signal sellers:
• Delete losing signals
• Fake track records
• Promise "guaranteed profits"

We don't:
• Public Google Sheet (linked above)
• Every signal logged with timestamp
• Wins AND losses visible
• No edits, no deletions

Check the sheet. If win rate <50% after 30 days, don't buy.

📄 Verify: https://docs.google.com/spreadsheets/d/{sheet_id}

Still want in? R99 first month. Cancel anytime.
""",

    "objection_think": """
Totally fair. Take your time.

But heads up:
• R99 offer expires in {hours_left} hours
• After that: R139/mo (R40 more)
• Founding member spots: {spots_left}/20 remaining

When you're ready: https://yoco.com/isotope/r99-trial

I'll be here. No pressure.
""",
}

# ============================================
# LOGGING
# ============================================

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

# ============================================
# DATABASE HELPERS (FastAPI Backend)
# ============================================

async def get_user_status(user_id: int) -> dict:
    """Fetch user status from FastAPI backend"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{FASTAPI_URL}/users/{user_id}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch user status: {e}")
            return {"status": "unknown", "trial_start": None, "tier": "free"}


async def update_user_status(user_id: int, **kwargs) -> bool:
    """Update user status in FastAPI backend"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.put(
                f"{FASTAPI_URL}/users/{user_id}",
                json=kwargs,
            )
            response.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"Failed to update user status: {e}")
            return False


async def log_disclaimer_acceptance(user_id: int, timestamp: str) -> bool:
    """Log disclaimer acceptance to Google Sheets via n8n"""
    async with httpx.AsyncClient() as client:
        try:
            await client.post(
                f"{N8N_WEBHOOK_URL}/disclaimer-accept",
                json={
                    "user_id": user_id,
                    "timestamp": timestamp,
                },
            )
            return True
        except Exception as e:
            logger.error(f"Failed to log disclaimer: {e}")
            return False


# ============================================
# CONVERSATION HANDLERS
# ============================================

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handle /start command"""
    first_name = update.effective_user.first_name or "there"
    
    await update.message.reply_text(
        MESSAGES["start"].format(first_name=first_name),
        parse_mode="Markdown",
    )
    
    return DISCLAIMER_ACCEPT


async def handle_disclaimer(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handle disclaimer acceptance or exit"""
    text = update.message.text.strip().upper()
    user_id = update.effective_user.id
    
    if text == "EXIT":
        await update.message.reply_text(
            "No worries. If you change your mind, type /start anytime.",
            parse_mode="Markdown",
        )
        return ConversationHandler.END
    
    if text == "ACCEPT":
        timestamp = datetime.now().isoformat()
        await log_disclaimer_acceptance(user_id, timestamp)
        await update_user_status(user_id, disclaimer_accepted=True, disclaimer_timestamp=timestamp)
        
        await update.message.reply_text(
            MESSAGES["accepted"].format(timestamp=timestamp),
            parse_mode="Markdown",
        )
        return START_TRIAL
    
    await update.message.reply_text(
        "Please type ACCEPT or EXIT",
        parse_mode="Markdown",
    )
    return DISCLAIMER_ACCEPT


async def start_trial(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handle trial start"""
    user_id = update.effective_user.id
    first_name = update.effective_user.first_name or "there"
    today = datetime.now().strftime("%d %B %Y")
    
    # Update user status
    trial_end = datetime.now() + timedelta(days=7)
    await update_user_status(
        user_id,
        trial_start=datetime.now().isoformat(),
        trial_end=trial_end.isoformat(),
        tier="trial",
    )
    
    # Schedule Day 1/3/6/7 messages (via n8n)
    async with httpx.AsyncClient() as client:
        await client.post(
            f"{N8N_WEBHOOK_URL}/trial-started",
            json={
                "user_id": user_id,
                "first_name": first_name,
                "trial_end": trial_end.isoformat(),
            },
        )
    
    await update.message.reply_text(
        MESSAGES["trial_started"].format(
            first_name=first_name,
            date=today,
            sheet_id=GOOGLE_SHEET_ID or "YOUR_SHEET_ID",
        ),
        parse_mode="Markdown",
    )
    
    return ConversationHandler.END


async def handle_text_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handle general text messages (objections, questions)"""
    text = update.message.text.strip().upper()
    user_id = update.effective_user.id
    first_name = update.effective_user.first_name or "there"
    
    # Objection handlers
    if "TOO EXPENSIVE" in text or "EXPENSIVE" in text:
        await update.message.reply_text(
            MESSAGES["objection_expensive"],
            parse_mode="Markdown",
        )
        return OBJECTION
    
    if "DON'T TRUST" in text or "TRUST" in text or "SCAM" in text:
        await update.message.reply_text(
            MESSAGES["objection_dont_trust"].format(sheet_id=GOOGLE_SHEET_ID or "YOUR_SHEET_ID"),
            parse_mode="Markdown",
        )
        return OBJECTION
    
    if "THINK" in text or "LATER" in text or "MAYBE" in text:
        # Calculate hours left in offer
        user_status = await get_user_status(user_id)
        trial_end = datetime.fromisoformat(user_status.get("trial_end", datetime.now().isoformat()))
        hours_left = max(0, int((trial_end - datetime.now()).total_seconds() / 3600))
        
        await update.message.reply_text(
            MESSAGES["objection_think"].format(
                hours_left=hours_left,
                spots_left=12,  # Would fetch from backend
            ),
            parse_mode="Markdown",
        )
        return OBJECTION
    
    # Cancellation
    if text == "CANCEL" or text == "STOP":
        await update_user_status(user_id, tier="cancelled", cancelled_at=datetime.now().isoformat())
        await update.message.reply_text(
            "You've been unsubscribed. Type /start anytime to return.",
            parse_mode="Markdown",
        )
        return ConversationHandler.END
    
    # Default: forward to human (or auto-reply)
    await update.message.reply_text(
        f"Thanks for your message, {first_name}. I read every message and will respond within 24 hours.\n\nFor immediate help: https://yoco.com/isotope/support",
        parse_mode="Markdown",
    )
    
    # Log message for review
    async with httpx.AsyncClient() as client:
        await client.post(
            f"{N8N_WEBHOOK_URL}/user-message",
            json={
                "user_id": user_id,
                "message": update.message.text,
                "timestamp": datetime.now().isoformat(),
            },
        )
    
    return ConversationHandler.END


async def payment_webhook_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle Yoco payment webhook (called via n8n)"""
    # This is triggered by n8n, not directly by user
    # n8n sends: user_id, payment_status, amount
    query = update.callback_query
    await query.answer()
    
    user_data = context.user_data
    user_id = user_data.get("user_id")
    
    if not user_id:
        await query.edit_message_text("Payment verification failed. Please contact support.")
        return
    
    # Update user status
    await update_user_status(
        user_id,
        tier="pro",
        payment_status="paid",
        payment_date=datetime.now().isoformat(),
    )
    
    await query.edit_message_text(
        MESSAGES["payment_success"].format(
            first_name=update.effective_user.first_name or "there",
            group_id="ISOTOPE_Pro_Group",
            renewal_date=(datetime.now() + timedelta(days=30)).strftime("%d %B %Y"),
        ),
        parse_mode="Markdown",
    )


# ============================================
# ERROR HANDLER
# ============================================

async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Log errors and notify admin"""
    logger.error(f"Update {update} caused error: {context.error}")
    
    # Notify admin (via Telegram)
    admin_id = int(os.getenv("ADMIN_USER_ID", "0"))
    if admin_id:
        try:
            await context.bot.send_message(
                chat_id=admin_id,
                text=f"⚠️ Bot Error:\nUpdate: {update}\nError: {context.error}",
            )
        except Exception as e:
            logger.error(f"Failed to notify admin: {e}")


# ============================================
# MAIN
# ============================================

def main() -> None:
    """Start the bot"""
    if not TELEGRAM_BOT_TOKEN:
        logger.error("TELEGRAM_BOT_TOKEN not set. Exiting.")
        return
    
    # Create Application
    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    
    # Create conversation handler
    conv_handler = ConversationHandler(
        entry_points=[CommandHandler("start", start_command)],
        states={
            DISCLAIMER_ACCEPT: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, handle_disclaimer),
            ],
            START_TRIAL: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, start_trial),
            ],
            UPGRADE: [
                CallbackQueryHandler(payment_webhook_handler, pattern="^payment_verify"),
            ],
            OBJECTION: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text_message),
            ],
        },
        fallbacks=[
            CommandHandler("cancel", lambda u, c: ConversationHandler.END),
        ],
    )
    
    application.add_handler(conv_handler)
    application.add_error_handler(error_handler)
    
    # Start the Bot
    logger.info("Starting ISOTOPE Telegram Bot...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
