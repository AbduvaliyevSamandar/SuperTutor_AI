import 'package:flutter/material.dart';
import '../../core/theme.dart';

class _StaticPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _StaticPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: children,
      ),
    );
  }
}

Widget _h(String t) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(t,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800)),
    );

Widget _p(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t,
          style: const TextStyle(
              color: AppColors.ink,
              height: 1.45,
              fontWeight: FontWeight.w500)),
    );

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPage(
      title: 'SuperTutor haqida',
      children: [
        Center(child: Image.asset('assets/icon/icon.png', width: 96, height: 96)),
        const SizedBox(height: 12),
        const Center(
          child: Text('SuperTutor AI',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        const Center(child: Text('v1.0.0')),
        _h('Bizning maqsad'),
        _p('Har qanday inson bepul, sifatli AI o\'qituvchi yordamida til o\'rganib, IELTS yoki boshqa sertifikatlarni topshira oladigan darajada tayyorlanishi.'),
        _h('Texnologiyalar'),
        _p('• Flutter (Android + iOS + Web)\n• FastAPI backend\n• Groq, OpenAI, Gemini LLM cascade\n• Whisper STT, Edge-TTS\n• Supabase auth + Postgres'),
        _h('Open source'),
        _p('Kod GitHub\'da:\nhttps://github.com/AbduvaliyevSamandar/SuperTutor_AI'),
        _h('Murojaat'),
        _p('Taklif yoki xato: elmurodovmaxmud77@gmail.com'),
      ],
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPage(
      title: 'Maxfiylik siyosati',
      children: [
        _h('Qanday ma\'lumotlarni yig\'amiz'),
        _p('• Email va parol (Supabase auth)\n• Mashg\'ulot sessiyalari va statistika\n• Saqlangan lug\'at so\'zlari\n• Quiz natijalari'),
        _h('Ma\'lumotlar qayerda saqlanadi'),
        _p('Barcha foydalanuvchi ma\'lumotlari Supabase (PostgreSQL, Tokyo) da. AI bilan suhbat tarixi serverda saqlanmaydi (faqat statistika va sessiya uzunligi).'),
        _h('Ovoz va rasm'),
        _p('Mikrofon yozuvlari va yuklangan rasmlar STT / Vision so\'rovi uchun ishlatiladi, server diskida saqlanmaydi.'),
        _h('Uchinchi tomonlar'),
        _p('• Groq — LLM va STT\n• Supabase — auth + DB\n• Microsoft Edge-TTS — ovoz\n• Render — serverlar'),
        _h('Akkauntni o\'chirish'),
        _p('Profil → Akkauntni o\'chirish. Barcha ma\'lumotlar bir martalik o\'chiriladi.'),
      ],
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPage(
      title: 'Yordam va FAQ',
      children: const [
        _FaqItem(
          q: 'AI nima uchun sekin javob beradi?',
          a: 'Birinchi so\'rov serverni uyg\'otadi (~30 soniya). Keyingi so\'rovlar tez bo\'ladi. Bu Render bepul tarifining xususiyati.',
        ),
        _FaqItem(
          q: 'Mikrofon ishlamayapti',
          a: 'Sozlamalardan SuperTutor uchun mikrofon ruxsatini yoqing. Telefonni qayta ishga tushiring.',
        ),
        _FaqItem(
          q: 'Yuraklarim qachon qaytadi?',
          a: 'Har 30 daqiqada 1 yurak qaytadi. 350 💎 ga to\'liq sotib olishingiz ham mumkin.',
        ),
        _FaqItem(
          q: 'XP qanday ishlaydi?',
          a: 'Quiz to\'g\'ri javob = 5 XP. Suhbatda har xabar = 1-2 XP. Kunlik maqsadga yetganda +5 💎 bonus.',
        ),
        _FaqItem(
          q: 'Parolni unutdim',
          a: 'Login ekrandagi "Parolni unutdingizmi?" tugmasini bosing — email + yangi parolni kiriting.',
        ),
        _FaqItem(
          q: 'Rasmga matematika masala yuborsam bo\'ladimi?',
          a: 'Ha. Matematika chatida 📷 kamera tugmasini bosing — AI rasmni o\'qiydi va jadval ko\'rinishida tushuntiradi.',
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Text(q,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(a,
                  style: const TextStyle(
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
