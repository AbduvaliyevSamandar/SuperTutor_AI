# Deploy yo'riqnomasi

Loyiha 2 ta servis sifatida deploy qilinadi (ikkalasi ham bepul):

| Komponent | Servis | URL |
|---|---|---|
| Backend (FastAPI) | Fly.io | `https://supertutor-api.fly.dev` |
| Frontend (Flutter Web) | GitHub Pages | `https://abduvaliyevsamandar.github.io/SuperTutor_AI/` |

---

## 1. Supabase loyihasini yaratish

1. https://supabase.com → **New project** (Free tier, hech qanday CC kerak emas)
2. Project paydo bo'lgach: **Settings → API** ga o'ting va quyidagilarni nusxa oling:
   - `Project URL` (e.g., `https://xxx.supabase.co`) → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_KEY`
   - `service_role secret` key → `SUPABASE_SERVICE_KEY` ⚠️ **maxfiy**, hech qachon Flutter ilovaga qo'shmang
3. **SQL Editor → New query** → `supertutor-api/supabase/schema.sql` faylini ko'chirib qo'ying va RUN bosing.

## 2. Groq API kalitini olish

1. https://console.groq.com → Sign up (Google bilan tez)
2. **API Keys → Create API Key** → kalitni nusxa oling

---

## 3. Backend: Fly.io'ga deploy

```powershell
# 1. flyctl o'rnatish (Windows)
iwr https://fly.io/install.ps1 -useb | iex

# 2. Ro'yxatdan o'tish (bank kartasi so'raydi lekin pul yechmaydi — limit nazorat uchun)
fly auth signup

# 3. App yaratish
cd supertutor-api
fly launch --no-deploy --name supertutor-api --region fra --copy-config

# 4. Sirlarni o'rnatish
fly secrets set `
  GROQ_API_KEY=gsk_... `
  SUPABASE_URL=https://xxx.supabase.co `
  SUPABASE_ANON_KEY=eyJ... `
  SUPABASE_SERVICE_KEY=eyJ...

# 5. Deploy
fly deploy
```

Tekshirish: `https://supertutor-api.fly.dev/docs` ochilishi kerak.

### CI/CD orqali avtomatik deploy

`.github/workflows/deploy-api.yml` faylimiz har push'da Fly.io'ga deploy qiladi.
Buning uchun:
1. `fly auth token` → tokenni nusxa oling
2. GitHub repo → **Settings → Secrets → Actions → New repository secret**:
   - Name: `FLY_API_TOKEN`
   - Value: yuqoridagi token

---

## 4. Frontend: GitHub Pages'ga deploy

`.github/workflows/deploy-web.yml` har push'da Flutter web build qiladi va Pages'ga deploy qiladi.

GitHub repo'da:
1. **Settings → Pages → Source** = **GitHub Actions**
2. **Settings → Secrets → Actions** → 3 ta secret qo'shing:
   - `API_BASE_URL` = `https://supertutor-api.fly.dev`
   - `SUPABASE_URL` = `https://xxx.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJ...`
3. `main` branch'ga push qiling → Actions sahifasida deploy ko'rinadi.

URL: `https://abduvaliyevsamandar.github.io/SuperTutor_AI/`

---

## 5. Android APK build (Play Store'siz tarqatish)

```powershell
cd supertutor-app
# .env ichida API_BASE_URL=https://supertutor-api.fly.dev bo'lsin
flutter build apk --release
```

APK manzili: `supertutor-app/build/app/outputs/flutter-apk/app-release.apk`

Bu faylni Telegram/Drive'ga qo'yib ulashishingiz mumkin — bepul, Play Store fee'siz.

---

## Tekshiruv ro'yxati (deploy oldidan)

- [ ] Supabase loyiha yaratildi, `schema.sql` ishladi
- [ ] Groq kaliti olindi
- [ ] Fly.io account + flyctl o'rnatildi
- [ ] GitHub repo Secrets'iga `FLY_API_TOKEN`, `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` qo'shildi
- [ ] GitHub Pages "Source: GitHub Actions"'ga sozlandi
- [ ] `main`'ga push qilinib, ikki workflow ham yashil bo'ldi
