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
  GrammarLesson(
    code: 'comparatives',
    title: 'Comparatives & Superlatives',
    emoji: '⚖️',
    summary: 'Solishtirish darajalari',
    content: '''**Comparative** (ikki narsa solishtirish):
- 1 bo'g'in: -er (taller, bigger, faster)
- 2+ bo'g'in: more + adjective (more beautiful)

**Superlative** (ko'pchilikning eng):
- 1 bo'g'in: the -est (tallest, biggest)
- 2+ bo'g'in: the most + adjective (the most beautiful)

**Irregular**: good→better→best, bad→worse→worst, far→further→furthest.''',
    examples: [
      'She is taller than her brother.',
      'This is the most interesting book I\'ve read.',
      'Today is hotter than yesterday.',
    ],
  ),
  GrammarLesson(
    code: 'plurals',
    title: 'Ko\'plik shakli',
    emoji: '👯',
    summary: 'Regular and irregular plurals',
    content: '''**Regular:**
- Most nouns + s: book → books
- -s, -x, -ch, -sh + es: box → boxes, watch → watches
- consonant + y → ies: city → cities
- -f, -fe → ves: knife → knives, leaf → leaves

**Irregular:**
- man → men, woman → women, child → children
- foot → feet, tooth → teeth, mouse → mice
- fish → fish, sheep → sheep (no change)''',
    examples: [
      'There are three cats in the garden.',
      'The children are playing outside.',
      'I have two pairs of glasses.',
    ],
  ),
  GrammarLesson(
    code: 'prepositions',
    title: 'Prepositions (in, on, at)',
    emoji: '📍',
    summary: 'Vaqt va joy ko\'rsatkichlari',
    content: '''**Joy uchun:**
- **in** — ichida: in the room, in the city
- **on** — ustida: on the table, on the wall
- **at** — nuqtada: at home, at the door

**Vaqt uchun:**
- **in** — uzun davr: in 2026, in January, in the morning
- **on** — kun: on Monday, on July 4
- **at** — aniq vaqt: at 5pm, at midnight, at night''',
    examples: [
      'The book is on the table.',
      'I was born in 2001.',
      'Let\'s meet at the cafe at 7pm.',
    ],
  ),
  GrammarLesson(
    code: 'pronouns',
    title: 'Olmoshlar (Pronouns)',
    emoji: '👤',
    summary: 'Subject, object, possessive',
    content: '''**Subject** (gap ega): I, you, he, she, it, we, they
**Object** (predmet): me, you, him, her, it, us, them
**Possessive adjective** (egalik): my, your, his, her, its, our, their
**Possessive pronoun**: mine, yours, his, hers, ours, theirs

**Reflexive**: myself, yourself, himself, herself, itself, ourselves, themselves.''',
    examples: [
      'She gave me her book.',
      'This pen is mine, not yours.',
      'He cut himself while cooking.',
    ],
  ),
  GrammarLesson(
    code: 'questions',
    title: 'Savol tuzish (Wh- + Yes/No)',
    emoji: '❓',
    summary: 'Question formation',
    content: '''**Yes/No savol:**
- Auxiliary + subject + verb: Do you like coffee? Have you been there?

**Wh- savol** (What, Where, When, Who, Why, How):
- Wh + auxiliary + subject + verb: Where do you live?
- Subject question (ega haqida): Who called you?

**Be fe'l bilan:**
- Are you tired? — What is your name?''',
    examples: [
      'Where did you go yesterday?',
      'Have you finished your homework?',
      'Why are you so happy?',
    ],
  ),
  GrammarLesson(
    code: 'passive',
    title: 'Passive voice',
    emoji: '🔄',
    summary: 'Majhul nisbat',
    content: '''**Active**: Subject + verb + object
**Passive**: Object + be + past participle (+ by + agent)

- Active: The chef cooks the meal.
- Passive: The meal is cooked (by the chef).

**Times in passive:**
- Present: is/are + V3
- Past: was/were + V3
- Present Perfect: has/have been + V3
- Future: will be + V3

Active'da kim qilganini bilganda; passive'da nima qilinganini ta'kidlash uchun.''',
    examples: [
      'The book was written in 1850.',
      'English is spoken in many countries.',
      'A new bridge will be built next year.',
    ],
  ),
  GrammarLesson(
    code: 'reported_speech',
    title: 'Reported speech',
    emoji: '💬',
    summary: 'Boshqaning gapini yetkazish',
    content: '''Birovning gapini qayta aytishda zamonlar siljiydi:

- Present → Past: "I am tired" → He said he was tired.
- Past → Past Perfect: "I went home" → She said she had gone home.
- Will → Would: "I will help" → He said he would help.

**Wh- savollar**: He asked where I lived.
**Yes/No**: She asked if I was ready.

Vaqt so'zlar ham o'zgaradi: today → that day, yesterday → the day before, tomorrow → the next day.''',
    examples: [
      'She said she was learning English.',
      'He told me he had finished the project.',
      'They asked if we could come tomorrow.',
    ],
  ),
  GrammarLesson(
    code: 'used_to',
    title: 'Used to / Be used to',
    emoji: '🔁',
    summary: 'Past habits and current familiarity',
    content: '''**used to + V** — o'tmishda doimiy edi, hozir yo'q:
- I used to smoke (now I don't).
- She used to live in Paris.

**be used to + V-ing / noun** — o'rganib qolgan:
- I am used to waking up early.
- He is used to the cold weather.

**get used to** — o'rganmoqda:
- I'm getting used to working from home.''',
    examples: [
      'I used to play football every weekend.',
      'She is used to spicy food now.',
      'He is getting used to the new schedule.',
    ],
  ),
  GrammarLesson(
    code: 'gerund_infinitive',
    title: 'Gerund vs Infinitive',
    emoji: '🔣',
    summary: 'V-ing yoki to + V',
    content: '''**Gerund (V-ing)** keladigan fe'llar: enjoy, finish, suggest, mind, avoid, keep, practice.
- I enjoy reading books.
- She finished writing the report.

**Infinitive (to + V)**: want, decide, hope, plan, promise, agree, learn.
- I want to travel.
- He decided to leave.

**Ikkalasi ham**: like, love, hate, start, begin, continue, prefer.
- I like swimming. / I like to swim.''',
    examples: [
      'She enjoys cooking traditional dishes.',
      'I decided to study harder this year.',
      'Stop smoking — it\'s bad for you.',
    ],
  ),
  GrammarLesson(
    code: 'phrasal_verbs',
    title: 'Phrasal verbs',
    emoji: '🧩',
    summary: 'Verb + particle combos',
    content: '''Phrasal verb — fe'l + predlog/qo'shimcha, ma'nosi o'zgaradi:

- **give up** — voz kechmoq: Don\'t give up!
- **look after** — qaramoq: She looks after her grandmother.
- **turn on/off** — yoqmoq/o'chirmoq: Turn off the light.
- **find out** — bilib olmoq: I'll find out the truth.
- **put up with** — chidamoq: I can't put up with this noise.

Eng ko'p ishlatiladiganlardan 100 tasini yodlash B1-B2 darajaga olib chiqadi.''',
    examples: [
      'I gave up smoking last year.',
      'Can you look after the kids tonight?',
      'I won\'t put up with this anymore.',
    ],
  ),
  GrammarLesson(
    code: 'relative_clauses',
    title: 'Relative clauses',
    emoji: '🔗',
    summary: 'who / which / that / whose',
    content: '''Tasviriy ergash gaplar:

- **who** — odam: The man who called you is here.
- **which** — narsa: The book which I bought is interesting.
- **that** — odam yoki narsa: The car that I want is red.
- **whose** — egalik: She is the woman whose dog barked.
- **where** — joy: This is the cafe where we met.

**Defining** (zarur) — vergulsiz.
**Non-defining** (qo'shimcha) — vergul bilan.''',
    examples: [
      'The teacher who teaches us English is friendly.',
      'I love books which are about history.',
      'My friend, whose mother is a doctor, is studying medicine.',
    ],
  ),
  GrammarLesson(
    code: 'so_such',
    title: 'So / Such / Too / Enough',
    emoji: '🎚️',
    summary: 'Intensifiers',
    content: '''**so + adjective/adverb**: It's so hot today!
**such + (a) + adjective + noun**: It's such a beautiful day!

**too + adjective** (haddan tashqari, salbiy): The tea is too hot to drink.
**adjective + enough** (yetarli, ijobiy): The tea is hot enough.
**enough + noun**: We have enough time.

Farqi: too — yomon ortiqcha; enough — kerakli miqdor.''',
    examples: [
      'She is so kind to everyone.',
      'This box is too heavy to carry.',
      'Do we have enough food for the party?',
    ],
  ),
  GrammarLesson(
    code: 'time_clauses',
    title: 'When / While / As soon as',
    emoji: '⏰',
    summary: 'Vaqt ergash gaplari',
    content: '''**when** — qachon, paytida: When I was young, I played football.
**while** — paytida (uzoq harakat): She read while he cooked.
**as soon as** — bilan birga, darrov: Call me as soon as you arrive.
**before / after**: Brush your teeth before you sleep.
**until / till**: Wait here until I come back.

Asosiy qoida: vaqt ergash gaplarida **kelajak zamon ishlatilmaydi** — Present Simple keladi.
- ✗ When I will see her, I will tell her.
- ✓ When I see her, I will tell her.''',
    examples: [
      'I\'ll call you when I arrive.',
      'She was sleeping while I was studying.',
      'As soon as you finish, let me know.',
    ],
  ),
  GrammarLesson(
    code: 'modals_perfect',
    title: 'Modal perfect (should have, must have)',
    emoji: '🕰',
    summary: 'O\'tmishdagi taxmin/afsus',
    content: '''**should have + V3** — afsus, o'tmishdagi tavsiya:
- You should have studied harder. (lekin qilmadingiz)

**must have + V3** — aniq taxmin:
- The ground is wet — it must have rained.

**could have + V3** — imkoniyat bor edi:
- I could have helped if you'd asked.

**might have + V3** — ehtimol:
- He might have forgotten the meeting.

**shouldn't have / couldn't have** — salbiy.''',
    examples: [
      'You should have called me yesterday.',
      'She must have left already.',
      'I could have won the race.',
    ],
  ),
  GrammarLesson(
    code: 'subjunctive_wish',
    title: 'I wish / If only',
    emoji: '🌟',
    summary: 'Xohish, afsus',
    content: '''**I wish + Past Simple** — hozirgi xohish (haqiqat emas):
- I wish I had more money. (lekin yo'q)

**I wish + Past Perfect** — o'tmishdagi afsus:
- I wish I had studied medicine. (lekin qilmadim)

**I wish + would** — boshqa odam xulqi:
- I wish he would stop smoking.

**If only** — kuchliroq variant: If only I were taller!''',
    examples: [
      'I wish I lived near the sea.',
      'I wish I hadn\'t said that yesterday.',
      'If only I could speak French!',
    ],
  ),
  GrammarLesson(
    code: 'reading_skills',
    title: 'Connectors (linking words)',
    emoji: '🔗',
    summary: 'Bog\'lovchi so\'zlar',
    content: '''**Ketma-ketlik**: first, then, next, after that, finally
**Sabab**: because, since, as, due to, owing to
**Natija**: so, therefore, as a result, consequently
**Qarama-qarshi**: but, however, although, despite, nevertheless
**Qo'shimcha**: also, in addition, moreover, furthermore
**Misol**: for example, such as, for instance
**Xulosa**: in conclusion, to sum up, overall

IELTS Writing va Speaking'da bu so'zlar band scoreni 0.5-1.0 ga oshiradi.''',
    examples: [
      'First, we visited the museum. Then we had lunch.',
      'Although it was raining, we went outside.',
      'In conclusion, technology has changed our lives.',
    ],
  ),
];
