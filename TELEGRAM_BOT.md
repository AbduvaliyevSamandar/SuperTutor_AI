# SuperTutor AI — Telegram tarqatish bot

Bepul, oddiy bot APK'ni tarqatadi va statistikani yig'adi.

## Setup (10 daqiqa)

### 1. Bot yaratish
1. Telegram'da `@BotFather` ga yozing → `/newbot`
2. Nom: `SuperTutor AI`
3. Username: `supertutor_ai_uz_bot`
4. `/setdescription` → "Bepul AI til o'qituvchi. /start ni bosing va APK oling."
5. `/setcommands` →
   ```
   start - Boshlash va APK olish
   apk - Eng so'nggi APK ni yuklab olish
   web - Web versiyaga o'tish
   help - Yordam
   ```
6. Botdan **TOKEN**ni nusxa oling (`123456:ABC-DEF...`)

### 2. Render'da yangi servis (Web Service / Python)

`bot.py`:
```python
import os
import asyncio
from aiogram import Bot, Dispatcher, F
from aiogram.types import Message, FSInputFile
from aiogram.filters import Command
from aiogram.enums import ParseMode

BOT_TOKEN = os.environ["BOT_TOKEN"]
APK_URL = "https://github.com/AbduvaliyevSamandar/SuperTutor_AI/releases/latest/download/app-release.apk"
WEB_URL = "https://supertutor-web.onrender.com"

bot = Bot(token=BOT_TOKEN, parse_mode=ParseMode.HTML)
dp = Dispatcher()


@dp.message(Command("start"))
async def start(m: Message):
    await m.answer(
        "🦉 <b>SuperTutor AI</b>ga xush kelibsiz!\n\n"
        "Bepul AI til o'qituvchi:\n"
        "• Ingliz, Rus, Nemis, Turk + Matematika\n"
        "• IELTS Speaking/Writing/Reading/Listening simulyator\n"
        "• Talaffuz baholash, lug'at, AI chat\n\n"
        f"📱 APK: {APK_URL}\n"
        f"🌐 Web: {WEB_URL}\n\n"
        "/apk — to'g'ridan-to'g'ri APK\n"
        "/web — brauzerda ochish"
    )


@dp.message(Command("apk"))
async def apk(m: Message):
    await m.answer(f"📦 APK: {APK_URL}\n\nO'rnatish: Sozlamalar → Ilovalar → Noma'lum manbalardan o'rnatishga ruxsat bering.")


@dp.message(Command("web"))
async def web(m: Message):
    await m.answer(f"🌐 Brauzerda: {WEB_URL}")


@dp.message(Command("help"))
async def help_cmd(m: Message):
    await m.answer(
        "/start — boshlash\n"
        "/apk — Android APK linki\n"
        "/web — web versiya\n"
        "Savollar: elmurodovmaxmud77@gmail.com"
    )


async def main():
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
```

`requirements.txt`:
```
aiogram>=3.0
```

### 3. GitHub Release (APK uchun)

`gh release create v1.0.0 --notes "v1.0.0 - first public release" supertutor-app/build/app/outputs/flutter-apk/app-release.apk`

Yoki Web UI'dan: github.com/AbduvaliyevSamandar/SuperTutor_AI/releases/new

### 4. Foydalanuvchilar olish

- Telegram kanal yarating: @supertutor_ai_uz
- Instagram post bilan: "Bepul IELTS Speaking simulyator @supertutor_ai_uz_bot"
- TikTok video: ilova ekranda IELTS Speaking test ko'rsating
- Universitet guruhlariga ulashing
- Reddit: r/IELTS, r/languagelearning

Maqsad: birinchi haftada 100 foydalanuvchi, oyda 1000.
