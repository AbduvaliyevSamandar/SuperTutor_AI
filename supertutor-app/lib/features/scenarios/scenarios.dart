import '../../core/theme.dart';
import 'package:flutter/material.dart';

class Scenario {
  final String emoji;
  final String title;
  final String description;
  final String subject;
  final String openingUserMessage;
  final Color color;
  const Scenario({
    required this.emoji,
    required this.title,
    required this.description,
    required this.subject,
    required this.openingUserMessage,
    required this.color,
  });
}

const scenarios = <Scenario>[
  Scenario(
    emoji: '☕',
    title: 'Kafeda buyurtma',
    description: 'Kofe yoki choy buyurtma berishni mashq qiling',
    subject: 'english',
    openingUserMessage:
        "Hi! I'd like to order a coffee. What do you recommend?",
    color: AppColors.fire,
  ),
  Scenario(
    emoji: '✈️',
    title: 'Aeroportda',
    description: 'Reys haqida savol berish va check-in',
    subject: 'english',
    openingUserMessage:
        "Excuse me, I have a question about my flight to London.",
    color: AppColors.secondary,
  ),
  Scenario(
    emoji: '🏨',
    title: 'Mehmonxonada',
    description: 'Xona band qilish va savollar',
    subject: 'english',
    openingUserMessage:
        "Hello! I'd like to check in. I have a reservation under my name.",
    color: AppColors.gold,
  ),
  Scenario(
    emoji: '🛒',
    title: 'Do\'konda',
    description: 'Kiyim sotib olish, narx so\'rash',
    subject: 'english',
    openingUserMessage:
        "Hi, I'm looking for a blue shirt. Do you have one in size M?",
    color: AppColors.heart,
  ),
  Scenario(
    emoji: '🩺',
    title: 'Shifokorda',
    description: 'Soglik ahvolini tushuntirish',
    subject: 'english',
    openingUserMessage:
        "Hello doctor, I haven't been feeling well for a few days.",
    color: AppColors.primary,
  ),
  Scenario(
    emoji: '💼',
    title: 'Ish suhbati',
    description: 'O\'zingiz haqingizda gapirish',
    subject: 'english',
    openingUserMessage:
        "Thank you for inviting me. I'd like to tell you about my background.",
    color: AppColors.secondary,
  ),
  Scenario(
    emoji: '🚕',
    title: 'Taksida',
    description: 'Manzilni aytish va narx',
    subject: 'english',
    openingUserMessage:
        "Hi, can you take me to the train station, please? How much will it cost?",
    color: AppColors.fire,
  ),
  Scenario(
    emoji: '🎓',
    title: 'Universitetda',
    description: 'Imtihon haqida savol',
    subject: 'english',
    openingUserMessage:
        "Excuse me, I have a question about the exam schedule.",
    color: AppColors.primary,
  ),
  Scenario(
    emoji: '🤝',
    title: 'Yangi tanishuv',
    description: 'O\'zingizni tanishtirish',
    subject: 'english',
    openingUserMessage:
        "Hi! I'm new here. My name is Sam. What about you?",
    color: AppColors.gold,
  ),
  Scenario(
    emoji: '📞',
    title: 'Telefon suhbati',
    description: 'Rasmiy qo\'ng\'iroq',
    subject: 'english',
    openingUserMessage:
        "Hello, I'm calling to make an appointment. Are you available this week?",
    color: AppColors.heart,
  ),
];
