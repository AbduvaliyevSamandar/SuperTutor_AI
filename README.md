# SuperTutor AI

Bepul ko'p tilli AI o'qituvchi ilova — avatar bilan real-time suhbat.

## Loyiha tuzilishi

```
SuperTutor_AI/
├── supertutor-app/    Flutter ilovasi (Android + Web + iOS)
└── supertutor-api/    FastAPI backend (LLM + STT + TTS)
```

Ikkalasi alohida git repolari sifatida ishlatiladi.

## Tezkor boshlash

**Backend:**
```powershell
cd supertutor-api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
# .env ichiga GROQ_API_KEY ni qo'ying — https://console.groq.com (bepul)
uvicorn app.main:app --reload --port 8000
```

**Flutter app:**
```powershell
cd supertutor-app
flutter pub get
flutter run -d chrome   # yoki Android emulator
```

## Bepul xizmatlar

| Maqsad | Xizmat | Bepul limiti |
|---|---|---|
| LLM | Groq (Llama 3.3 70B) | 30 so'rov/min |
| STT | Groq Whisper-large-v3 | (shu kalit) |
| TTS | Microsoft Edge-TTS | cheksiz |
| Auth + DB | Supabase | 500 MB Postgres, 50K oylik faol foydalanuvchi |
| Backend hosting | Fly.io / Koyeb / HF Spaces | bepul tier |
| Frontend hosting | Cloudflare Pages | cheksiz |

## Deploy

To'liq deploy yo'riqnomasi: [DEPLOY.md](DEPLOY.md)

Qisqacha:
- **Backend** — Fly.io (Docker) — har push'da CI orqali avto-deploy
- **Frontend Web** — GitHub Pages — har push'da CI orqali avto-deploy
- **Android APK** — `flutter build apk --release`, to'g'ridan-to'g'ri ulashing

## MVP scope (Sprint 1)

- [x] Loyiha skeleton (Flutter + FastAPI)
- [x] Chat endpoint (Groq LLM)
- [x] STT endpoint (Groq Whisper)
- [x] TTS endpoint (Edge-TTS)
- [x] Home + Chat + Dashboard sahifalar
- [x] Animatsion avatar (lip-sync)
- [x] Mic recording + STT (mobile)
- [x] Supabase auth (login/signup)
- [x] Sessions tracking + real statistika
- [x] CI/CD: Fly.io + GitHub Pages workflows
- [ ] Rus, Nemis, Turk tillari (Sprint 2)
- [ ] Web mikrofon yozish (Sprint 2)
- [ ] Voice cloning (Premium, Sprint 3)
