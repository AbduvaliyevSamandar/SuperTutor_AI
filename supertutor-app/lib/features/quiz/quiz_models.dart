class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] ?? '',
        question: j['question'] ?? '',
        options: List<String>.from(j['options'] ?? const []),
        correctIndex: j['correct_index'] ?? 0,
        explanation: j['explanation'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}

class Quiz {
  final String id;
  final String subject;
  final String level;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.subject,
    required this.level,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        id: j['quiz_id'] ?? '',
        subject: j['subject'] ?? '',
        level: j['level'] ?? '',
        questions: ((j['questions'] as List?) ?? const [])
            .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q)))
            .toList(),
      );
}

class QuestionResult {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final bool correct;
  final String explanation;

  const QuestionResult({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.correct,
    required this.explanation,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> j) => QuestionResult(
        question: j['question'] ?? '',
        correctAnswer: j['correct_answer'] ?? '',
        userAnswer: j['user_answer'] ?? '',
        correct: j['correct'] ?? false,
        explanation: j['explanation'] ?? '',
      );
}

class QuizResultSummary {
  final int score;
  final int total;
  final int percentage;
  final List<String> weakTopics;
  final List<QuestionResult> results;

  const QuizResultSummary({
    required this.score,
    required this.total,
    required this.percentage,
    required this.weakTopics,
    required this.results,
  });

  factory QuizResultSummary.fromJson(Map<String, dynamic> j) => QuizResultSummary(
        score: j['score'] ?? 0,
        total: j['total'] ?? 0,
        percentage: j['percentage'] ?? 0,
        weakTopics: List<String>.from(j['weak_topics'] ?? const []),
        results: ((j['results'] as List?) ?? const [])
            .map((r) => QuestionResult.fromJson(Map<String, dynamic>.from(r)))
            .toList(),
      );
}
