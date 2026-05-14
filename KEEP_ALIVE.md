# Render Backend Keep-Alive

Render free tier suspends the API after **15 minutes of inactivity**, and the
next request blocks for 30–50 s while it cold-starts. That's the #1 source of
visible exceptions in the app.

## Solution: UptimeRobot (free)

1. Sign up: https://uptimerobot.com (free, no card)
2. **Add New Monitor → HTTP(s)**
3. Friendly name: `SuperTutor API`
4. URL: `https://supertutor-api.onrender.com/api/v1/health`
5. Monitoring interval: **5 minutes** (free tier allows down to 5 min)
6. Save

Now the API gets a request every 5 minutes — it never falls asleep. Cold
starts gone.

## Bonus: same for the bot
If you have `supertutor-bot` worker on Render, it has no HTTP endpoint, so
this trick doesn't apply. Workers stay alive on the free tier as long as
they keep emitting any output (the aiogram bot polls Telegram every few
seconds, which counts).

## Verify

After 24 h of UptimeRobot pings, open the app — it should respond instantly,
no 30-second wait, no warmup overlay.
