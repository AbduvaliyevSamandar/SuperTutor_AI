# iOS deploy yo'riqnoma

iOS uchun **Mac kompyuter** (yoki MacInCloud bulut servisi) + **Apple Developer account ($99/yil)** kerak.

## 1. Mac'da prepare

```bash
# Flutter o'rnatish (agar yo'q bo'lsa)
brew install --cask flutter

# Loyihani klonlash
git clone https://github.com/AbduvaliyevSamandar/SuperTutor_AI
cd SuperTutor_AI/supertutor-app

# Dependencies
flutter pub get
cd ios && pod install && cd ..

# .env yarating
cat > .env <<EOF
API_BASE_URL=https://supertutor-api.onrender.com
SUPABASE_URL=https://amtbevwkxtkzhnpiqcgi.supabase.co
SUPABASE_ANON_KEY=sb_publishable_kbV0yQIJRb8dcdWw8Xuiuw_BxY1gRAH
EOF
```

## 2. Xcode'da signing sozlash

```bash
open ios/Runner.xcworkspace
```

Xcode'da:
1. **Runner → Signing & Capabilities**
2. **Team**: Apple Developer accountingizni tanlang
3. **Bundle Identifier**: `com.supertutor.app` (unique bo'lishi kerak)
4. **Automatically manage signing**: ON

## 3. Test build (simulator)

```bash
flutter run -d "iPhone 15 Pro"
```

## 4. Real qurilmaga build

```bash
flutter build ios --release
# Keyin Xcode'da Product → Archive → Distribute App → App Store Connect
```

## 5. App Store Connect

1. https://appstoreconnect.apple.com → **My Apps → +**
2. Yangi app yarating: **SuperTutor AI**
3. Bundle ID: `com.supertutor.app`
4. Listing'ga `STORE_LISTING.md` matnini joylashtiring
5. Screenshots: 6.5" iPhone (1284×2778) — 3 tagacha
6. Privacy Policy URL: `https://github.com/AbduvaliyevSamandar/SuperTutor_AI/blob/main/PRIVACY.md`
7. Submit for Review (1-3 kun)

## ⚠ Eslatma

iOS Review Apple tomonidan qattiq tekshiriladi. Tayyor bo'lishingiz kerak:
- Demo account: `test@supertutor.ai` / `Test123456`
- Privacy policy URL (yuqorida)
- Permission lar `Info.plist`'da explicit yozilgan (qilingan)

## Birinchi marotaba ikkilanmang

iOS qiyinroq. Avval Android+Web bilan boshlang. iOS keyinroq, real foydalanuvchilarning talabi bo'lganda qo'shasiz.
