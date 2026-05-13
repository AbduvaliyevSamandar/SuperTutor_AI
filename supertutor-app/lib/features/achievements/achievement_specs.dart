import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AchievementSpec {
  final String code;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final bool Function(AchievementStats s) check;
  const AchievementSpec({
    required this.code,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.check,
  });
}

class AchievementStats {
  final int xpTotal;
  final int streakDays;
  final int totalSessions;
  final int totalMessages;
  final int englishSessions;
  final int mathSessions;
  final int savedWords;
  final int quizzesTaken;
  final int bestQuizPercentage;

  const AchievementStats({
    this.xpTotal = 0,
    this.streakDays = 0,
    this.totalSessions = 0,
    this.totalMessages = 0,
    this.englishSessions = 0,
    this.mathSessions = 0,
    this.savedWords = 0,
    this.quizzesTaken = 0,
    this.bestQuizPercentage = 0,
  });
}

const achievements = <AchievementSpec>[
  AchievementSpec(
    code: 'first_chat',
    emoji: '👋',
    title: 'Salom dunyo!',
    description: 'Birinchi suhbat',
    color: AppColors.secondary,
    check: _firstChat,
  ),
  AchievementSpec(
    code: 'xp_50',
    emoji: '⚡',
    title: 'Boshlovchi',
    description: '50 XP yiging',
    color: AppColors.gold,
    check: _xp50,
  ),
  AchievementSpec(
    code: 'xp_500',
    emoji: '💪',
    title: 'Tirishqoq',
    description: '500 XP yiging',
    color: AppColors.gold,
    check: _xp500,
  ),
  AchievementSpec(
    code: 'xp_2000',
    emoji: '🚀',
    title: 'Marafonchi',
    description: '2000 XP yiging',
    color: AppColors.heart,
    check: _xp2000,
  ),
  AchievementSpec(
    code: 'streak_3',
    emoji: '🔥',
    title: '3 kun ketma-ket',
    description: '3 kunlik streak',
    color: AppColors.fire,
    check: _streak3,
  ),
  AchievementSpec(
    code: 'streak_7',
    emoji: '🔥',
    title: 'Bir hafta',
    description: '7 kunlik streak',
    color: AppColors.fire,
    check: _streak7,
  ),
  AchievementSpec(
    code: 'streak_30',
    emoji: '👑',
    title: 'Oybop',
    description: '30 kunlik streak',
    color: AppColors.gold,
    check: _streak30,
  ),
  AchievementSpec(
    code: 'eng_10',
    emoji: '🇬🇧',
    title: 'Inglizcha 10',
    description: '10 ta ingliz tili sessiyasi',
    color: AppColors.secondary,
    check: _eng10,
  ),
  AchievementSpec(
    code: 'math_10',
    emoji: '📐',
    title: 'Matematik',
    description: '10 ta matematika sessiyasi',
    color: AppColors.fire,
    check: _math10,
  ),
  AchievementSpec(
    code: 'words_25',
    emoji: '📖',
    title: 'Lug\'atchi',
    description: '25 ta so\'z saqlang',
    color: AppColors.primary,
    check: _words25,
  ),
  AchievementSpec(
    code: 'quiz_first',
    emoji: '🎯',
    title: 'Birinchi test',
    description: 'Bir testni tugatang',
    color: AppColors.secondary,
    check: _quizFirst,
  ),
  AchievementSpec(
    code: 'quiz_perfect',
    emoji: '💯',
    title: 'A\'lochi',
    description: '100% bilan tugatish',
    color: AppColors.gold,
    check: _quizPerfect,
  ),
  AchievementSpec(
    code: 'quiz_10',
    emoji: '🧠',
    title: '10 test',
    description: '10 ta test ishladingiz',
    color: AppColors.heart,
    check: _quiz10,
  ),
  AchievementSpec(
    code: 'sessions_50',
    emoji: '🏆',
    title: '50 sessiya',
    description: 'Davomli o\'qish',
    color: AppColors.gold,
    check: _sessions50,
  ),
  AchievementSpec(
    code: 'messages_100',
    emoji: '💬',
    title: 'Suhbat ustasi',
    description: '100 xabar yozish',
    color: AppColors.secondary,
    check: _msg100,
  ),
  AchievementSpec(
    code: 'polyglot',
    emoji: '🌍',
    title: 'Poliglot',
    description: '3+ tilda suhbat',
    color: AppColors.primary,
    check: _polyglot,
  ),
  AchievementSpec(
    code: 'early_bird',
    emoji: '🌅',
    title: 'Erta turuvchi',
    description: 'Birinchi oyni tugatish',
    color: AppColors.gold,
    check: _streak30,
  ),
  AchievementSpec(
    code: 'words_100',
    emoji: '📚',
    title: 'Lug\'at kitobi',
    description: '100 ta so\'z saqlang',
    color: AppColors.primary,
    check: _words100,
  ),
  AchievementSpec(
    code: 'quiz_5_perfect',
    emoji: '⭐',
    title: 'Yulduz',
    description: '5 ta test ≥80%',
    color: AppColors.gold,
    check: _quizPerfect,
  ),
  AchievementSpec(
    code: 'master',
    emoji: '🎓',
    title: 'Magistr',
    description: 'Hamma yutuqlar deyarli',
    color: AppColors.heart,
    check: _master,
  ),
];

bool _firstChat(AchievementStats s) => s.totalSessions >= 1;
bool _xp50(AchievementStats s) => s.xpTotal >= 50;
bool _xp500(AchievementStats s) => s.xpTotal >= 500;
bool _xp2000(AchievementStats s) => s.xpTotal >= 2000;
bool _streak3(AchievementStats s) => s.streakDays >= 3;
bool _streak7(AchievementStats s) => s.streakDays >= 7;
bool _streak30(AchievementStats s) => s.streakDays >= 30;
bool _eng10(AchievementStats s) => s.englishSessions >= 10;
bool _math10(AchievementStats s) => s.mathSessions >= 10;
bool _words25(AchievementStats s) => s.savedWords >= 25;
bool _words100(AchievementStats s) => s.savedWords >= 100;
bool _quizFirst(AchievementStats s) => s.quizzesTaken >= 1;
bool _quizPerfect(AchievementStats s) => s.bestQuizPercentage >= 100;
bool _quiz10(AchievementStats s) => s.quizzesTaken >= 10;
bool _sessions50(AchievementStats s) => s.totalSessions >= 50;
bool _msg100(AchievementStats s) => s.totalMessages >= 100;
bool _polyglot(AchievementStats s) => s.englishSessions >= 1 && s.mathSessions >= 1;
bool _master(AchievementStats s) => s.xpTotal >= 5000 && s.streakDays >= 30;
