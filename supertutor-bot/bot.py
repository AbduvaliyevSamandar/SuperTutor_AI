"""SuperTutor AI — Telegram distribution bot.

Setup:
1. @BotFather -> /newbot -> get TOKEN
2. Render new Web Service (Python) pointing to this repo, root: supertutor-bot
3. Set env BOT_TOKEN=<token>
4. Service runs `python bot.py` (Procfile/start command)
"""
import asyncio
import os

from aiogram import Bot, Dispatcher
from aiogram.enums import ParseMode
from aiogram.filters import Command
from aiogram.types import Message, InlineKeyboardMarkup, InlineKeyboardButton

BOT_TOKEN = os.environ["BOT_TOKEN"]
APK_URL = "https://github.com/AbduvaliyevSamandar/SuperTutor_AI/releases/latest/download/app-release.apk"
WEB_URL = "https://supertutor-web.onrender.com"
REPO_URL = "https://github.com/AbduvaliyevSamandar/SuperTutor_AI"

bot = Bot(token=BOT_TOKEN, parse_mode=ParseMode.HTML)
dp = Dispatcher()


def _main_kb() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text="📱 Android APK", url=APK_URL)],
        [InlineKeyboardButton(text="🌐 Brauzer (web)", url=WEB_URL)],
        [InlineKeyboardButton(text="⭐ GitHub", url=REPO_URL)],
    ])


@dp.message(Command("start"))
async def start(m: Message) -> None:
    text = (
        "🦉 <b>SuperTutor AI</b>ga xush kelibsiz!\n\n"
        "Bepul AI til o'qituvchi va IELTS prep:\n"
        "• 🇬🇧 Ingliz, 🇷🇺 Rus, 🇩🇪 Nemis, 🇹🇷 Turk, 📐 Matematika\n"
        "• 🎓 IELTS to'liq simulyator (Speaking + Writing + Reading + Listening)\n"
        "• 🎙 Talaffuz baholash, 📷 rasmga matematika javob\n"
        "• 📚 SRS lug'at, hikoyalar, grammatika, do'stlar leaderboard\n\n"
        "<b>Reklamasiz. To'lovsiz. Cheksiz.</b>\n\n"
        "Quyidagi tugmalardan birini tanlang:"
    )
    await m.answer(text, reply_markup=_main_kb())


@dp.message(Command("apk"))
async def apk(m: Message) -> None:
    await m.answer(
        f"📦 <b>Android APK</b>\n\n{APK_URL}\n\n"
        "<b>O'rnatish:</b>\n"
        "1. Linkni bosib APK ni yuklab oling\n"
        "2. Sozlamalar → <i>Noma'lum manbalardan o'rnatish</i> yoqing\n"
        "3. APK fayl ustiga teging → o'rnating",
        reply_markup=_main_kb(),
    )


@dp.message(Command("web"))
async def web(m: Message) -> None:
    await m.answer(
        f"🌐 <b>Brauzer versiyasi</b>\n{WEB_URL}\n\n"
        "Telefon va kompyuterdan ishlatish mumkin.",
        reply_markup=_main_kb(),
    )


@dp.message(Command("help"))
async def help_cmd(m: Message) -> None:
    await m.answer(
        "<b>Buyruqlar:</b>\n"
        "/start — Asosiy menyu\n"
        "/apk — Android APK linki\n"
        "/web — Brauzer versiyasi\n"
        "/help — Yordam\n\n"
        "Savollar yoki xato xabarlari uchun: elmurodovmaxmud77@gmail.com",
    )


@dp.message()
async def fallback(m: Message) -> None:
    await m.answer(
        "Buyruqlarni ishlatib ko'ring: /start, /apk, /web, /help",
        reply_markup=_main_kb(),
    )


async def main() -> None:
    print(f"Bot starting, APK URL: {APK_URL}")
    await dp.start_polling(bot, allowed_updates=dp.resolve_used_update_types())


if __name__ == "__main__":
    asyncio.run(main())
