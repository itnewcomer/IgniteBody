import 'package:hive_flutter/hive_flutter.dart';

// MARK: - レベルシステム

class LevelSystem {
  static const List<int> thresholds = [0, 50, 150, 300, 500, 800, 1200, 1800, 2600, 3600];

  static int level(int xp) {
    int lv = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) lv = i;
    }
    return lv.clamp(0, thresholds.length - 1);
  }

  static double progress(int xp) {
    final lv = level(xp);
    final current = thresholds[lv];
    final next = lv < thresholds.length - 1 ? thresholds[lv + 1] : thresholds[lv] + 1000;
    return (xp - current) / (next - current);
  }

  static String avatar(int lv) {
    const avatars = ['🌱', '🌿', '🍃', '🌳', '⚡', '🔥', '💪', '🧠', '✨', '🌟'];
    return avatars[lv.clamp(0, avatars.length - 1)];
  }

  static String title(int lv) {
    const titles = [
      'まだ眠ってる体',
      '目覚めかけ',
      '動き始めた',
      '習慣の芽',
      'エンジン始動',
      '燃え始めた',
      '本気モード',
      '体が変わった',
      '継続の達人',
      'レジェンド',
    ];
    return titles[lv.clamp(0, titles.length - 1)];
  }

  static int xpFor(int seconds) {
    final base = (seconds / 30).floor().clamp(1, 999999);
    final bonus = seconds >= 300 ? 5 : 0;
    return base + bonus;
  }
}

// MARK: - 育成プロフィール

class BodyProfile {
  static const _boxName = 'profile';
  static const _xpKey = 'totalXP';

  static Box get _box => Hive.box(_boxName);

  static int get totalXP => _box.get(_xpKey, defaultValue: 0) as int;

  static void addXP(int xp) {
    _box.put(_xpKey, totalXP + xp);
  }

  static int get level => LevelSystem.level(totalXP);
  static double get levelProgress => LevelSystem.progress(totalXP);
  static String get avatar => LevelSystem.avatar(level);
  static String get levelTitle => LevelSystem.title(level);
}

// MARK: - ワークアウトセッション

class WorkoutSession {
  final String exerciseName;
  final String exerciseIcon;
  final int targetSeconds;
  final int actualSeconds;
  final bool completed;
  final int earnedXP;
  final DateTime date;

  WorkoutSession({
    required this.exerciseName,
    required this.exerciseIcon,
    required this.targetSeconds,
    required this.actualSeconds,
    required this.completed,
    required this.earnedXP,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'exerciseName': exerciseName,
    'exerciseIcon': exerciseIcon,
    'targetSeconds': targetSeconds,
    'actualSeconds': actualSeconds,
    'completed': completed,
    'earnedXP': earnedXP,
    'date': date.toIso8601String(),
  };

  factory WorkoutSession.fromMap(Map map) => WorkoutSession(
    exerciseName: map['exerciseName'] as String,
    exerciseIcon: map['exerciseIcon'] as String,
    targetSeconds: map['targetSeconds'] as int,
    actualSeconds: map['actualSeconds'] as int,
    completed: map['completed'] as bool,
    earnedXP: map['earnedXP'] as int,
    date: DateTime.parse(map['date'] as String),
  );
}

class SessionStore {
  static const _boxName = 'sessions';
  static Box get _box => Hive.box(_boxName);

  static List<WorkoutSession> get all {
    return _box.values
        .map((e) => WorkoutSession.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static void save(WorkoutSession session) {
    _box.add(session.toMap());
  }

  static List<WorkoutSession> last7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return all.where((s) => s.date.isAfter(cutoff)).toList();
  }
}

// MARK: - 種目

enum ExerciseCategory {
  move('動く'),
  strength('筋トレ'),
  stretch('ストレッチ'),
  walk('散歩');

  const ExerciseCategory(this.label);
  final String label;
}

class Exercise {
  final String name;
  final String icon;
  final ExerciseCategory category;
  final int defaultSeconds;
  bool isActive;

  Exercise({
    required this.name,
    required this.icon,
    required this.category,
    required this.defaultSeconds,
    this.isActive = true,
  });

  static List<Exercise> get defaults => [
    Exercise(name: 'その場ジョギング',     icon: '🏃', category: ExerciseCategory.move,     defaultSeconds: 60),
    Exercise(name: 'ジャンピングジャック', icon: '⬆️', category: ExerciseCategory.move,     defaultSeconds: 60),
    Exercise(name: 'スクワット',          icon: '🦵', category: ExerciseCategory.strength, defaultSeconds: 60),
    Exercise(name: '腕立て伏せ',          icon: '💪', category: ExerciseCategory.strength, defaultSeconds: 60),
    Exercise(name: '体幹プランク',        icon: '🌀', category: ExerciseCategory.strength, defaultSeconds: 60),
    Exercise(name: '全身ストレッチ',      icon: '🧘', category: ExerciseCategory.stretch,  defaultSeconds: 180),
    Exercise(name: '深呼吸',             icon: '🌬️', category: ExerciseCategory.stretch,  defaultSeconds: 60),
    Exercise(name: '散歩',               icon: '🚶', category: ExerciseCategory.walk,     defaultSeconds: 300),
  ];
}

class ExerciseStore {
  static const _boxName = 'exercises';
  static Box get _box => Hive.box(_boxName);

  static List<Exercise> get all {
    if (_box.isEmpty) _seed();
    return _box.values.map((e) {
      final m = e as Map;
      return Exercise(
        name: m['name'] as String,
        icon: m['icon'] as String,
        category: ExerciseCategory.values.firstWhere((c) => c.name == m['category']),
        defaultSeconds: m['defaultSeconds'] as int,
        isActive: m['isActive'] as bool,
      );
    }).toList();
  }

  static void _seed() {
    for (final e in Exercise.defaults) {
      _box.add({
        'name': e.name,
        'icon': e.icon,
        'category': e.category.name,
        'defaultSeconds': e.defaultSeconds,
        'isActive': true,
      });
    }
  }

  static List<Exercise> get active => all.where((e) => e.isActive).toList();
}
