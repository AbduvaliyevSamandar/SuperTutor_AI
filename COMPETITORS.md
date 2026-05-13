# SuperTutor AI — raqobatchilar va GitHub namunalar tahlili

Bu hujjat — bizning ilovani jahonga tayyorlash uchun qaysi loyihalardan qanday
g'oyalar, dizayn va kod patternlar olishimiz haqida.

---

## 🎯 Eng yaxshi 5 ta Flutter o'rganish ilovasi (open source)

| # | Repo | ⭐ | Nima uchun foydali |
|---|------|----|---------------------|
| 1 | [ollinmagno/duolingo-flutter](https://github.com/ollinmagno/duolingo-flutter) | 86 | Toza Flutter Duolingo klonida. Ekran tartibini ko'chirish uchun eng yaqin namuna. |
| 2 | [hbx921/vocaday_app](https://github.com/hbx921/vocaday_app) | 47 | Flutter + Firebase + BLoC + Clean Architecture. Quiz/Puzzle/Flashcard 3 rejim. Arxitektura shabloni. |
| 3 | [gabrielglbh/Kan-Practice](https://github.com/gabrielglbh/Kan-Practice) | 200+ | Yapon tili uchun pishgan SRS ilova. Lug'at-trener uchun eng yaxshi namuna. |
| 4 | [dov-vai/ClozeCall](https://github.com/dov-vai/ClozeCall) | - | Bo'sh joyni to'ldirish (cloze) UX'i — gaplar tuzish mashqlari uchun. |
| 5 | [Shakleen/Vocab](https://github.com/Shakleen/Vocab) | - | Lug'at qidiruv + saqlash + quiz patterni. |

**Bonus (Next.js — Flutter'ga ko'chirib o'tkazish uchun):**
- [sanidhyy/duolingo-clone](https://github.com/sanidhyy/duolingo-clone) ⭐546 — yuraklar/missiyalar/do'kon kodi. `actions/challenge-progress.ts` va `store/use-hearts-modal.ts` o'qing.
- [bryanjenningz/react-duolingo](https://github.com/bryanjenningz/react-duolingo) ⭐404 — toza Zustand state model.

---

## 🔁 Spaced Repetition (SRS) — Anki algoritmi

3 ta asosiy paket:

1. **[dart-fsrs](https://github.com/open-spaced-repetition/dart-fsrs)** — toza Dart, MIT, pub.dev'da. **Bu paketni ishlatamiz.**
2. **[fsrs-rs-dart](https://github.com/open-spaced-repetition/fsrs-rs-dart)** — Rust binding (yuqori unumdorlik).
3. **[ankidroid/Anki-Android](https://github.com/ankidroid/Anki-Android)** ⭐11.1k — **GPL-3.0, kodini ko'chirib bo'lmaydi**, faqat UX namunasi (Again/Hard/Good/Easy tugmalari) uchun.

Yana: [h16nning/skola](https://github.com/h16nning/skola) — zamonaviy PWA, toza review ekrani.

---

## 🎨 Duolingo'simon 5 ta UI mexanizm — kodga ko'chirish kerak

### 1. Skill tree (vertikal aylanma yo'l)
- **Flutter paket**: [stargazing-dino/skill_tree](https://github.com/Nolence/skill_tree) — graf joylashuvini beradi.
- **Namuna**: `sanidhyy/duolingo-clone/app/(main)/learn/` — chap-o'ng siljiydigan doiralar. Flutter'ga `CustomPainter` bilan ko'chirish kerak (egri chiziq + `AnimatedScale` faol nodda).

### 2. Yuraklar + qaytarib to'ldirish
- `sanidhyy/duolingo-clone/store/use-hearts-modal.ts` + `actions/user-progress.ts`
- State machine: max 5 yurak → noto'g'ri javobda −1 → mashq orqali yoki vaqt o'tib qaytadi → bitsa pul (gemma) kerak
- ~150 satr kod, bizga ko'chirish oson

### 3. Multiple-choice quiz + konfetti + ovoz
- `sanidhyy/duolingo-clone/app/lesson/`
- Flutter'da: `confetti: ^0.7.0` + `audioplayers` (to'g'ri/xato ovoz)

### 4. XP popup + olov streak
- O'zgaruvchan XP (10/15/20), "duble-yoki-hech-narsa" qo'yim
- `actions/challenge-progress.ts`

### 5. Cloze ("so'zlarni joyiga qo'y") — gap tuzish
- [dov-vai/ClozeCall](https://github.com/dov-vai/ClozeCall) — Flutter uchun eng yaxshi namuna. Drag-and-drop tile'lar.

---

## 🤖 AI chat tutor — kod patternlar

| Repo | Foydasi | Litsenziya |
|------|---------|------------|
| [shakedzy/companion](https://github.com/shakedzy/companion) ⭐173 | ChatGPT + Whisper + TTS to'liq duplex pipeline | CC BY-NC — faqat o'qish |
| [jasonkang14/ai-english-tutor](https://github.com/jasonkang14/ai-english-tutor) | Whisper + GPT + TTS toza ulanish | Permissive |
| [Thiagohgl/ai-pronunciation-trainer](https://github.com/Thiagohgl/ai-pronunciation-trainer) ⭐474 | Whisper + fonetik solishtirish (Epitran) — **talaffuz baholash** | AGPL — faqat o'qish |
| [coqui-ai/TTS](https://github.com/coqui-ai/TTS) | Self-hosted TTS (o'zbek ovozi yasash mumkin) | MPL-2.0 |
| [flyerhq/flutter-chat-ui](https://github.com/flyerhq/flutter-chat-ui) | **Production darajadagi chat bubble + voice xabarlar** | Apache-2.0 ✅ |

`flutter-chat-ui` ni ishlatishimiz mumkin — hozirgi chat ekrani kuchayadi.

---

## 📚 Lug'at + so'z trener

- **Kan-Practice** — `lib/presentation/word_lists/` — har so'z uchun statistika (g'alaba foizi, oxirgi takrorlash, kalendar).
- **Vocaday** — Quiz/Puzzle/Flashcard 3 rejim.
- **Shakleen/Vocab** — "so'zni saqlash → review navbatga qo'shilish" pattern.
- **O'zbek tili uchun**:
  - [Tatoeba](https://tatoeba.org) — CC-BY litsenziyali misol gaplar
  - [Wiktionary dump](https://dumps.wikimedia.org) — bepul ta'riflar bazasi

---

## 🎭 Lottie animatsiyalari (bepul mascot)

1. **[lottiefiles.com/free-animations/mascot-animation](https://lottiefiles.com/free-animations/mascot-animation)** — minglab tayyor mascot loop (idle/yutdi/yutqazdi/o'ylayapti)
2. **[lottiefiles.com/6534-education](https://lottiefiles.com/6534-education)** — ta'lim mavzusi
3. **dotLottie State Machines** — bitta fayl, ko'p holat (kodda almashtiriladi)
4. **[Lottielab](https://www.lottielab.com/) + Figma** — o'zimizning brand mascot (bepul versiya)
5. **[Kenney.nl](https://kenney.nl/) "Animal Pack"** — CC0 (mutlaqo bepul) hayvon personajlar

Bizning hozirgi yuz CustomPaint qilingan — **Lottie sotib olmasdan ham yangilab bo'ladi**.

---

## 💼 Yopiq raqobatchilardan o'rganadigan g'oyalar

| Ilova | Olamiz | Sabab |
|-------|--------|-------|
| **Duolingo** | Streak freeze (gemma bilan) | Foydalanuvchi qoldirib ketishini 21%ga kamaytiradi |
| **Duolingo** | O'zgaruvchan XP, "duble-yoki-hech-narsa" qo'yim | Geymifikatsiya |
| **Duolingo** | "Play first / sign-up later" onboarding | Konversiya yuqori |
| **Babbel** | Qisqa darslar — "kofe buyurtma qilish" kabi aniq natija | Konkret his |
| **Drops** | 5 daqiqalik majburiy uzilish | Tanqislik → faolligi oshiradi |
| **HelloChinese** | Pinyin rang bilan ohang ko'rsatish | Bizda — kirill ↔ lotin yoki o'zbek unli moslashuvi rang bilan |
| **Lingvist** | Adaptiv qiyinlik | FSRS bilan o'z-o'zidan keladi |

---

## 🏆 Keyingi bosqich — ta'sir/mehnat tartibida

| # | Funksiya | Ta'sir | Mehnat | Izoh |
|---|----------|--------|--------|------|
| 1 | **dart-fsrs review motor + Again/Good/Easy** | Yuqori | Past (1-2 kun) | Paket bor, qaytarish boostr |
| 2 | **Multiple-choice quiz + konfetti + ovoz** | Yuqori | Past (1 kun) | "Duolingo hissiyoti"ning #1 ekrani |
| 3 | **Vertikal skill-path bosh ekran** | Yuqori | O'rta (3-4 kun) | Brand belgisi |
| 4 | **Yuraklar + streak hisoblagich** | Yuqori | Past (1-2 kun) | Engagement +60% (Duolingo ma'lumotlari) |
| 5 | **Lottie mascot (3 holat)** | O'rta | Past (yarim kun) | Personajlik |
| 6 | **Whisper + LLM chat tutor (yangilab)** | Yuqori | O'rta (3-5 kun) | Bizning ustunlik |
| 7 | **Cloze gap to'ldirish** | O'rta | O'rta (2-3 kun) | ClozeCall'dan port |
| 8 | **Pishgan onboarding** | O'rta | Past (1 kun) | Birinchi taassurot |
| 9 | **Talaffuz baholash** | Yuqori | Yuqori (1-2 hafta) | Differensiator — keyinroq |
| 10 | **Leaderboard / missiyalar** | O'rta | O'rta | >100 DAU bo'lganda |

**2 haftalik MVP**: 1, 2, 3, 4, 5 + 6 (chat ekranini yaxshilash). Qolganlari keyinroq.

---

## 📌 Eng tezkor ish: TOP 3

1. **`dart-fsrs` paketini qo'shing** — saqlangan so'zlar avtomatik review navbatga tushadi
2. **Skill tree ekranini yarating** — `Darslar` tabi hozirgi list o'rniga vertikal yo'l
3. **Hearts + audio feedback** — quizda noto'g'ri = -1 yurak + xato ovoz; to'g'ri = XP + to'g'ri ovoz + konfetti
