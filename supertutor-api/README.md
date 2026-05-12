# SuperTutor API

FastAPI backend for SuperTutor AI — Groq LLM + Whisper STT + Edge-TTS.

## Quick start

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
# edit .env and put your GROQ_API_KEY
uvicorn app.main:app --reload --port 8000
```

Open http://localhost:8000/docs

## Free services used

| Component | Provider | Sign up |
|---|---|---|
| LLM | Groq (Llama 3.3 70B) | https://console.groq.com |
| STT | Groq Whisper-large-v3 | (same key) |
| TTS | Microsoft Edge-TTS | no key needed |
| Auth + DB | Supabase | https://supabase.com |

## Endpoints

- `GET  /api/v1/health` — service status
- `POST /api/v1/chat` — chat completion with tutor system prompt
- `POST /api/v1/stt` — multipart audio file → text
- `POST /api/v1/tts` — text → mp3 audio

## Utility scripts

```powershell
# Apply schema.sql to Supabase Postgres (via session pooler)
$env:PGPASSWORD = "<db password>"
python scripts/apply_schema.py

# Create a confirmed test user
$env:SUPABASE_URL = "https://<ref>.supabase.co"
$env:SUPABASE_SERVICE_KEY = "<sb_secret_...>"
python scripts/create_test_user.py user@example.com Pass123
```

## Deploy

Recommended free hosts (no sleep):
- **Fly.io** — `fly launch` (Dockerfile auto-generated)
- **Koyeb** — connect GitHub repo, auto deploy
- **Hugging Face Spaces** — Docker Space, great for AI inference
