# SuperTutor AI — to'liq yo'l xaritasi

**Maqsad:** A1 dan C2/IELTS gacha bitta ilovada to'liq o'rganish.
Duolingo + Babbel + Busuu + ChatGPT + Anki birgalikda — lekin AI-first va bepul.

---

## ✅ Sprint 1 — yakunlangan (live)

- Auth (Supabase email/parol, Google ulanmagan)
- Real-time chat AI tutor — 5 til (EN/RU/DE/TR/Math)
- Mikrofon (mobile + web) → STT → LLM → TTS
- Vision: rasm yuklash, matematika javobi jadval ko'rinishida
- LLM cascade (Groq → OpenAI → Gemini) + STT cascade
- Statistika: streak (auto-trigger), sessiyalar, XP
- Duolingo-style dizayn, lip-sync avatar
- Render deploy + APK build

---

## 🚧 Sprint 2 — auth + lug'at + test (hozir bajaramiz)

| # | Funksiya | Tafsilot |
|---|----------|----------|
| 2.1 | **Auth fix** | Backend /auth/signup endpoint, email-confirmation by-pass, aniq xato xabarlari |
| 2.2 | **Google Sign-In** | UI tugma + Supabase OAuth (Google project user-side sozlaydi) |
| 2.3 | **Bottom nav: 5 tab** | Bosh / Darslar / Lug'at / Statistika / Profil |
| 2.4 | **Lug'at sahifasi** | Qidiruv, LLM-da ta'rif + misol + tarjima + audio talaffuz |
| 2.5 | **"Mening so'zlarim"** | Save → spaced repetition kartochka |
| 2.6 | **Quiz mode** | LLM auto-generated test (ko'p tanlovli, to'ldirish, listening) |
| 2.7 | **Test natijalari sahifasi** | Tahlil: kuchli/zaif mavzular, javoblar bo'yicha to'g'ri yechim |

---

## 🎯 Sprint 3 — strukturali kurs

| # | Funksiya |
|---|----------|
| 3.1 | **Darslar tree** (Duolingo'ga o'xshash) — A1.1 → A1.2 → ... |
| 3.2 | Har dars: kichik suhbat + 5 quiz + 1 grammar nugget |
| 3.3 | **Yuraklar** (hearts) — 5 ta xato → kutish yoki gemmar bilan to'ldirish |
| 3.4 | **Kunlik maqsad** — 10/20/30/50 XP |
| 3.5 | **Grammatika kartalari** — qoidalar + misollar + mashqlar |
| 3.6 | **Mavzular bo'yicha lug'at** (restoran, sayohat, ish, ...) |

---

## 📚 Sprint 4 — IELTS / sertifikat tayyorgarligi

| # | Funksiya |
|---|----------|
| 4.1 | **IELTS Speaking simulyator** — 3 part, AI examiner, baholash |
| 4.2 | **IELTS Writing** — Task 1 (graph) + Task 2 (essay), AI feedback |
| 4.3 | **IELTS Listening** — TED-style audio + savollar |
| 4.4 | **IELTS Reading** — uzun matn + 13 savol/section |
| 4.5 | **Mock test** — to'liq 2h IELTS, baholash 9 ball tizimida |
| 4.6 | **Talaffuz scoring** — Whisper + LLM bilan har so'z baholash |

---

## 🎮 Sprint 5 — gamification + social

| # | Funksiya |
|---|----------|
| 5.1 | Leaderboard (haftalik, do'stlar) |
| 5.2 | Achievementlar/badges (50 ta) |
| 5.3 | Daily challenge (premium oziq-ovqat) |
| 5.4 | Do'stlar tizimi + friend XP |
| 5.5 | Streak shield (1 kun o'tkazib yuborish hifozati) |

---

## 🤖 Sprint 6 — AI premium

| # | Funksiya |
|---|----------|
| 6.1 | Lottie/3D avatar (real lip-sync) |
| 6.2 | Personalized learning path (LLM siz uchun plan tuzadi) |
| 6.3 | Adaptive difficulty |
| 6.4 | Voice cloning (siz xohlagan ovoz bilan tutor) |
| 6.5 | Image-to-story (rasm bering, AI til hikoyasi tuzadi) |
| 6.6 | "Practice with celebrity" rejimi |

---

## 📐 Texnik qarorlar

**Frontend:**
- Flutter bittagina kod base (Android + iOS + Web)
- Riverpod state, go_router, dio
- flutter_markdown (jadval/format), image_picker, record, just_audio
- Lottie keyinroq (3D avatar uchun)

**Backend:**
- FastAPI + Postgres (Supabase)
- LLM cascade (Groq + OpenAI + Gemini)
- Vision cascade
- Future: Redis keshlash (lug'at qidiruvlari uchun), websocket (real-time conversation)

**Yangi DB jadvallari (Sprint 2-4):**

```sql
-- Lug'at
vocabulary_entries (id, user_id, word, language, definition, examples, saved_at, last_reviewed)
-- Test natijalari  
quiz_results (id, user_id, subject, score, total, weak_topics, created_at)
quiz_questions (id, quiz_id, question, options, correct_answer, user_answer, correct)
-- Darslar
lessons (id, subject, level, order, title, exercises_json)
user_progress (user_id, lesson_id, completed_at, xp_earned, mistakes_count)
-- Yuraklar/XP
user_currency (user_id, hearts, xp, gems, last_heart_refill)
```

**Mavjud ilovalardan o'rganganlarim:**
- **Duolingo**: skill tree, hearts, streak fire, gem store, XP races, daily quests
- **Babbel**: real-life dialogues, grammar tips inline, review session
- **Busuu**: native speaker feedback (community), vocabulary trainer with SRS
- **Anki**: spaced repetition algorithm (FSRS), markdown cards
- **Lingvist**: AI-curated word frequency learning
- **ChatGPT/Claude**: open-ended conversational practice

Bizning farqimiz: **bitta ilovada hammasi**, real-time **ovozli avatar suhbat**, **vision tahlil** (qo'lda yozilgan ishni baholash) — bu hech bir raqibda yo'q.

---

## ⏱ Vaqt baholash

- Sprint 2: 4-6 soat
- Sprint 3: 8-12 soat
- Sprint 4: 12-20 soat (IELTS engine murakkab)
- Sprint 5: 6-10 soat
- Sprint 6: 15+ soat

Bugun Sprint 2 ni boshlaymiz.
