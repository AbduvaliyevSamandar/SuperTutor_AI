# Render Backend Keep-Alive

Render free tier suspends the API after **15 minutes of inactivity**. Next request blocks 30-50s while cold-starting. This was the #1 source of visible errors in the app.

## 🚀 Solution: UptimeRobot (bepul, 5 daqiqada)

### Aniq qadamlar

1. **Sign up** (no card needed): https://uptimerobot.com/signUp
2. Email + parol → **Register for FREE**
3. Confirm email → kirish
4. Dashboard ochiladi → **Add New Monitor** (yashil tugma)
5. Sozlash:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `SuperTutor API`
   - **URL (or IP)**: `https://supertutor-api.onrender.com/api/v1/health`
   - **Monitoring Interval**: `5 minutes`
   - Boshqalarni o'zgartirmang
6. **Create Monitor** bosing

Tamom! Endi har 5 daqiqada UptimeRobot `/health` so'rov yuboradi → Render uyg'oq turadi → cold start g'oyib bo'ladi.

### Verifikatsiya

24 soatdan keyin:
- App ochish → darhol ishlaydi (avval 30s kutardi)
- Profile/stats/leaderboard ekranlari instant
- Hech qanday "Server uyg'onmoqda" toast'i ko'rinmaydi

### Bonus: 2 ta monitor

Frontend ham bor:
- **Friendly Name**: `SuperTutor Web`
- **URL**: `https://supertutor-web.onrender.com`

Lekin web static — uxlamaydi. Bu monitor faqat uptime statistika uchun.

### UptimeRobot Free tier limitlar

- 50 ta monitor
- 5 daqiqalik minimum interval (bizga yetadi)
- 24 oylik storage
- SMS yo'q (email bor)

Yetadi.

## Bonus: GitHub Actions ham keep-alive sifatida

Agar UptimeRobot ham ishlamasa, GitHub Actions har 14 daqiqada ping yuborishi mumkin (cron schedule). Lekin GitHub Actions free tier oyiga 2000 daqiqa — 24/7 ping uchun yetmaydi (oyiga ~3000 daqiqa kerak).

UptimeRobot eng ishonchli.
