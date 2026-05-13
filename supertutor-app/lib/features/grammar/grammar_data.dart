class GrammarLesson {
  final String code;
  final String title;
  final String emoji;
  final String summary;
  final String content;
  final List<String> examples;
  const GrammarLesson({
    required this.code,
    required this.title,
    required this.emoji,
    required this.summary,
    required this.content,
    required this.examples,
  });
}

const grammarLessons = <GrammarLesson>[
  GrammarLesson(
    code: 'present_simple',
    title: 'Present Simple',
    emoji: '🕐',
    summary: 'Doimiy harakatlar va faktlar',
    content: '''Present Simple — odatdagi, takrorlanadigan harakatlar yoki umumiy haqiqatlarni bildiradi.

**Tuzilishi:**
- I / You / We / They + V (verb base form)
- He / She / It + V**+s**

**Salbiy:** do not (don't) / does not (doesn't)
**Savol:** Do / Does + subject + V?

**Qachon ishlatamiz:**
- Har kungi odatlar: "I drink tea every morning."
- Umumiy haqiqatlar: "Water boils at 100°C."
- Tartibli mashg'ulotlar: "She plays tennis on Saturdays."''',
    examples: [
      'I work in an office.',
      'She speaks three languages.',
      'They don\'t live here anymore.',
    ],
  ),
  GrammarLesson(
    code: 'past_simple',
    title: 'Past Simple',
    emoji: '⏪',
    summary: 'O\'tgan zamondagi harakatlar',
    content: '''Past Simple — o'tgan zamonda tugagan harakatlarni bildiradi.

**Tuzilishi:** Subject + V**-ed** (regular) yoki past form (irregular)

**Salbiy:** did not (didn't) + V (base form)
**Savol:** Did + subject + V?

**Qachon:**
- Aniq vaqt: "I visited Paris last summer."
- Tugagan voqealar: "She finished her homework."
- Yashash tarixi: "He was born in 2001."

**Irregular fe'llar:** go → went, see → saw, eat → ate, take → took.''',
    examples: [
      'I went to school yesterday.',
      'They didn\'t come to the party.',
      'Did you see that movie?',
    ],
  ),
  GrammarLesson(
    code: 'present_continuous',
    title: 'Present Continuous',
    emoji: '⏳',
    summary: 'Hozir bo\'layotgan harakat',
    content: '''Present Continuous (am/is/are + V**-ing**) — hozir, bu daqiqada yoki yaqin kelajakdagi rejalashtirgan harakatlar uchun.

**Tuzilishi:**
- I am + V-ing
- He/She/It is + V-ing
- You/We/They are + V-ing

**Qachon:**
- Hozir: "I am writing an email."
- Yaqin kelajak (reja): "We are flying to Dubai tomorrow."
- Vaqtinchalik: "She is staying with friends this week."''',
    examples: [
      'They are watching TV.',
      'I am learning English with SuperTutor.',
      'What are you doing right now?',
    ],
  ),
  GrammarLesson(
    code: 'present_perfect',
    title: 'Present Perfect',
    emoji: '✅',
    summary: 'O\'tgan + hozir bog\'liq',
    content: '''Present Perfect (have / has + V**-3** / past participle) — o'tgan harakat hozirgi natijasi yoki tajriba bog'lanadi.

**Tuzilishi:**
- I/You/We/They have + V3
- He/She/It has + V3

**Marker so'zlar:** ever, never, just, already, yet, since, for.

**Qachon:**
- Hayot tajribasi: "Have you ever been to London?"
- Yangi yakunlangan: "I have just finished dinner."
- Hozirgacha davom etgan: "She has lived here for 5 years."''',
    examples: [
      'I have never seen snow.',
      'They have already left.',
      'How long have you studied English?',
    ],
  ),
  GrammarLesson(
    code: 'future_will',
    title: 'Future (will / going to)',
    emoji: '🚀',
    summary: 'Kelajakdagi rejalar va bashoratlar',
    content: '''Kelajak zamonni 2 xil ifodalash mumkin:

**will** — bashorat yoki spontan qaror:
- "It will rain tomorrow."
- "I'll help you with that."

**be going to** — oldindan rejalashtirilgan yoki ko'rinib turgan natija:
- "I am going to study tonight." (reja)
- "Look! It's going to fall." (aniq bashorat)

**Negative:** will not (won't) / am/is/are not going to.
**Question:** Will you...? / Are you going to...?''',
    examples: [
      'I think she will win the match.',
      'We are going to visit grandma this weekend.',
      'Won\'t you join us?',
    ],
  ),
  GrammarLesson(
    code: 'modals',
    title: 'Modal fe\'llar',
    emoji: '⚙️',
    summary: 'can / must / should / may',
    content: '''Modal fe'llar yordamchi fe'llar bo'lib, asosiy fe'lga ma'no qo'shadi.

- **can / could** — qobiliyat, ruxsat: "I can swim."
- **must / have to** — majburiyat: "You must wear a seatbelt."
- **should / ought to** — maslahat: "You should sleep more."
- **may / might** — ehtimol: "It may rain later."
- **will / would** — kelajak / xushmuomalalik: "Would you help me?"

Modal fe'llar shaxsga qarab o'zgarmaydi (s qo'shilmaydi). Keyin to'g'ridan-to'g'ri V (base form).''',
    examples: [
      'You should drink more water.',
      'Can I borrow your pen?',
      'They might come to the party.',
    ],
  ),
  GrammarLesson(
    code: 'conditionals',
    title: 'Conditional gaplar',
    emoji: '🔀',
    summary: 'Agar... bo\'lsa...',
    content: '''Conditional (if-clauses) — shartli gaplar. 3 ta asosiy turi bor:

**Type 1 — real (haqiqiy):** If + Present Simple, will + V
- "If it rains, I will stay home."

**Type 2 — unreal (xayoliy):** If + Past Simple, would + V
- "If I had time, I would travel more."

**Type 3 — past unreal:** If + Past Perfect, would have + V3
- "If I had studied, I would have passed."

**Type 0 — umumiy haqiqat:** If + Present, Present
- "If you heat ice, it melts."''',
    examples: [
      'If you study, you will pass.',
      'I would buy a car if I had money.',
      'If she had called, I would have answered.',
    ],
  ),
  GrammarLesson(
    code: 'articles',
    title: 'Artikllar (a / an / the)',
    emoji: '📜',
    summary: 'Noaniq va aniq artikllar',
    content: '''Ingliz tilida 3 ta artikl bor:

- **a** — undosh tovush oldida: a book, a university (you-...).
- **an** — unli tovush oldida: an apple, an hour (silent h).
- **the** — aniq narsa, ma'lum bo'lgan: "the sun", "the book on the table".

**No article:**
- Ko'plik umumiy: "Dogs are friendly."
- Sanab bo'lmaydigan: "I love music."
- Tilning nomi: "She speaks English."''',
    examples: [
      'I bought a new phone yesterday.',
      'An hour ago, I saw an old friend.',
      'The President gave a speech.',
    ],
  ),
];
