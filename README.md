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

## MVP scope (Sprint 1)

- [x] Loyiha skeleton (Flutter + FastAPI)
- [x] Chat endpoint (Groq LLM)
- [x] STT endpoint (Groq Whisper)
- [x] TTS endpoint (Edge-TTS)
- [x] Home + Chat + Dashboard sahifalar
- [x] Oddiy avatar widget
- [ ] Supabase auth
- [ ] Statistika real-time saqlash
- [ ] Mic recording UI
- [ ] Lottie avatar
- [ ] Deploy (Fly.io + Cloudflare Pages)
