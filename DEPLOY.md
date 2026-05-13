# Deploy yo'riqnomasi

Loyiha 2 servisli bo'lib deploy qilinadi (ikkalasi ham bepul):

| Komponent | Servis | Texnologiya |
|---|---|---|
| Backend (FastAPI) | Render Web Service | Docker |
| Frontend (Flutter Web) | Render Static Site | Static |

---

## ⚡ Eng tez yo'l: Render Blueprint (avtomatik)

`render.yaml` repoda — bitta klik bilan ikkala servisni ham deploy qiladi.

### 1. Render hisob ochish
1. https://render.com → **Sign up with GitHub** (bepul, kartochka kerakmas)
2. Email tasdiqlangach, dashboard ochiladi.

### 2. Blueprint orqali deploy
1. Render Dashboard → **New** → **Blueprint**
2. **Connect GitHub** → `SuperTutor_AI` repo'sini tanlang
3. Render `render.yaml`'ni o'qiydi va 2 ta servis ko'rsatadi:
   - `supertutor-api` (Web Service, Docker)
   - `supertutor-web` (Static Site, Flutter)
4. **Apply** bosing

### 3. Maxfiy kalitlarni qo'shing
Har bir servis uchun **Environment** sahifasidan kalitlarni kiriting:

**supertutor-api** uchun:
```
GROQ_API_KEY=gsk_...
SUPABASE_URL=https://amtbevwkxtkzhnpiqcgi.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
SUPABASE_SERVICE_KEY=sb_secret_...
OPENAI_API_KEY=        (ixtiyoriy)
GEMINI_API_KEY=        (ixtiyoriy)
```

**supertutor-web** uchun:
```
SUPABASE_URL=https://amtbevwkxtkzhnpiqcgi.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
```
*`API_BASE_URL` avtomatik o'rnatiladi — `supertutor-api` host'idan.*

### 4. Manual Deploy
Har bir servis sahifasida **"Manual Deploy" → "Deploy latest commit"** bosing.

Tugagach:
- Backend: `https://supertutor-api.onrender.com/api/v1/health`
- Frontend: `https://supertutor-web.onrender.com`

---

## ⚠️ Render free tier muhim eslatmalar

- **Sleep**: 15 daqiqa faolsizdan keyin uxlab qoladi. Birinchi so'rov ~30 soniya cold start. (Frontend static — uxlamay-di)
- **Build vaqti**: birinchi build ~7-10 daqiqa (Flutter SDK yuklab oladi)
- **750 soat/oy**: bir nechta servis bo'lsa, taqsimlanadi
- **Disk yo'q**: davomli ma'lumotlar Supabase'da saqlanadi

Cold start muammosi bo'lsa, **UptimeRobot** (bepul) bilan har 10 daqiqada `/health` so'rov yuborib turib bo'ladi.

---

## Muqobil: Fly.io + GitHub Pages

`fly.toml` va `.github/workflows/` ham repoda — `render.yaml` ishlatmasangiz ham bularni ishlatishingiz mumkin. Batafsil — quyidagi bo'limga qarang.

<details>
<summary><b>Fly.io + GitHub Pages (eski yo'l)</b></summary>

### Backend → Fly.io
```powershell
iwr https://fly.io/install.ps1 -useb | iex
fly auth signup
cd supertutor-api
fly launch --no-deploy --name supertutor-api --region fra --copy-config
fly secrets set GROQ_API_KEY=... SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_KEY=...
fly deploy
```

### Frontend → GitHub Pages
1. Repo Settings → Pages → Source = GitHub Actions
2. Secrets qo'shing: `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`
3. Push qiling — `.github/workflows/deploy-web.yml` avtomatik build qiladi
</details>

---

## Android APK (Play Store'siz)

```powershell
cd supertutor-app
# .env'da API_BASE_URL=https://supertutor-api.onrender.com bo'lsin
flutter build apk --release
```

APK: `supertutor-app/build/app/outputs/flutter-apk/app-release.apk`

Telegram/Drive orqali ulashing — Play Store fee'siz.
