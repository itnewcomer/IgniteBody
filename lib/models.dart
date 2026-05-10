import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'exercise_database.dart';

// MARK: - StatAxis（6軸）

enum StatAxis {
  chest('胸', '🫀'),
  back('背中', '🔙'),
  shoulder('肩', '⬆️'),
  arms('腕', '💪'),
  legs('脚', '🦵'),
  abs('腹筋', '🌀');

  const StatAxis(this.label, this.icon);
  final String label;
  final String icon;
}

// MARK: - WorkoutEvents（記録時にペットへ通知するイベントバス）

class WorkoutEvent {
  final Map<StatAxis, double> gains;
  final int xp;
  final int sequence;
  WorkoutEvent({required this.gains, required this.xp, required this.sequence});
}

class WorkoutEvents {
  static final ValueNotifier<WorkoutEvent?> lastEvent =
      ValueNotifier<WorkoutEvent?>(null);
  static int _seq = 0;

  /// セット/セッションが保存された直後に呼ぶ。Map のキーは StatAxis 名（"chest" など）。
  static void emitSet(Map<String, double> gainsByName, int xp) {
    _seq++;
    final gains = <StatAxis, double>{};
    for (final e in gainsByName.entries) {
      final axis = StatAxis.values.firstWhere(
        (a) => a.name == e.key,
        orElse: () => StatAxis.chest,
      );
      gains[axis] = e.value;
    }
    lastEvent.value = WorkoutEvent(gains: gains, xp: xp, sequence: _seq);
  }
}

class LevelUpEvent {
  final int fromLevel;
  final int toLevel;
  final StatAxis dominant;
  final int sequence;
  LevelUpEvent({
    required this.fromLevel,
    required this.toLevel,
    required this.dominant,
    required this.sequence,
  });
}

class LevelUpEvents {
  static final ValueNotifier<LevelUpEvent?> lastEvent =
      ValueNotifier<LevelUpEvent?>(null);
  static int _seq = 0;

  static void emit(int from, int to, StatAxis dominant) {
    _seq++;
    lastEvent.value = LevelUpEvent(
      fromLevel: from,
      toLevel: to,
      dominant: dominant,
      sequence: _seq,
    );
  }
}

// MARK: - PetEvolution（ペットの進化段階）

class PetEvolution {
  static String emoji(int level, StatAxis dominant) {
    if (level == 0) return '🥚';
    if (level == 1) return _stage1(dominant);
    if (level <= 3) return _stage2(dominant);
    if (level <= 5) return _stage3(dominant);
    if (level <= 7) return _stage4(dominant);
    return _stage5(dominant);
  }

  static String _stage1(StatAxis dominant) => '🐣';

  static String _stage2(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '🐥';
      case StatAxis.back: return '🐦';
      case StatAxis.shoulder: return '🦆';
      case StatAxis.arms: return '🦁';
      case StatAxis.legs: return '🐺';
      case StatAxis.abs: return '🐊';
    }
  }

  static String _stage3(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '🦅';
      case StatAxis.back: return '🦅';
      case StatAxis.shoulder: return '🦉';
      case StatAxis.arms: return '🐯';
      case StatAxis.legs: return '🐉';
      case StatAxis.abs: return '🦖';
    }
  }

  static String _stage4(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '⚡';
      case StatAxis.back: return '🌩️';
      case StatAxis.shoulder: return '✨';
      case StatAxis.arms: return '🔥';
      case StatAxis.legs: return '💨';
      case StatAxis.abs: return '🌀';
    }
  }

  static String _stage5(StatAxis dominant) => '🌟';

  static String name(int level, StatAxis dominant) {
    if (level == 0) return '???';
    if (level == 1) return 'ベビー';
    if (level <= 3) {
      switch (dominant) {
        case StatAxis.chest: return 'チェスター';
        case StatAxis.back: return 'バッカー';
        case StatAxis.shoulder: return 'ショルダー';
        case StatAxis.arms: return 'アームズ';
        case StatAxis.legs: return 'レガシー';
        case StatAxis.abs: return 'コアラ';
      }
    }
    if (level <= 5) {
      switch (dominant) {
        case StatAxis.chest: return 'チェスタードラゴン';
        case StatAxis.back: return 'バックビースト';
        case StatAxis.shoulder: return 'ショルダーウィング';
        case StatAxis.arms: return 'アームタイガー';
        case StatAxis.legs: return 'レッグドレイク';
        case StatAxis.abs: return 'コアゴン';
      }
    }
    if (level <= 7) return '${_stage4Label(dominant)}・改';
    return 'IGNIS MAXIMUS';
  }

  static String _stage4Label(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return 'サンダーバード';
      case StatAxis.back: return 'ストームレイヴン';
      case StatAxis.shoulder: return 'オーラフェニックス';
      case StatAxis.arms: return 'ブレイズタイガー';
      case StatAxis.legs: return 'テンペストウルフ';
      case StatAxis.abs: return 'サイクロンビースト';
    }
  }

  static String message(int level) {
    if (level == 0) return '...zzz';
    if (level == 1) return 'がんばってるね！';
    if (level <= 3) return '一緒に鍛えよう！';
    if (level <= 5) return '調子いいじゃないか！';
    if (level <= 7) return 'すごい成長だ！';
    return 'キミは本物のレジェンド！';
  }
}

// MARK: - LevelSystem

class LevelSystem {
  static const List<int> thresholds = [
    0, 200, 800, 2000, 5000, 10000, 20000, 35000, 55000, 80000
  ];

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
    final next = lv < thresholds.length - 1
        ? thresholds[lv + 1]
        : thresholds[lv] + 10000;
    return (xp - current) / (next - current);
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

  /// ゲイン合計 × 100。XP の唯一の源泉。
  static int xpForGains(Map<StatAxis, double> gains) {
    final total = gains.values.fold(0.0, (a, b) => a + b);
    return (total * 100).round().clamp(0, 999999);
  }
}

// MARK: - BodyProfile

class BodyProfile {
  static const _boxName = 'profile';
  static Box get _box => Hive.box(_boxName);

  // XP
  static int get totalXP => _box.get('totalXP', defaultValue: 0) as int;
  static void addXP(int xp) {
    if (xp <= 0) return;
    final before = level;
    _box.put('totalXP', totalXP + xp);
    final after = level;
    if (after > before) {
      LevelUpEvents.emit(before, after, dominantStat);
    }
  }

  // Setup
  static bool get isSetupDone => _box.get('setupDone', defaultValue: false) as bool;
  static void completeSetup() => _box.put('setupDone', true);

  // 6軸ステータス
  static double getStat(StatAxis axis) =>
      (_box.get('stat_${axis.name}', defaultValue: 0.0) as num).toDouble();
  static double getPeak(StatAxis axis) =>
      (_box.get('peak_${axis.name}', defaultValue: 0.0) as num).toDouble();

  static void addGain(StatAxis axis, double gain) {
    final newVal = getStat(axis) + gain;
    _box.put('stat_${axis.name}', newVal);
    if (newVal > getPeak(axis)) _box.put('peak_${axis.name}', newVal);
    if (gain > 0) _setLastTrainDate(axis);
    _setLastWorkoutDate();
  }

  // ── 最終ワークアウト日 ──────────────────────────────────
  static DateTime? get lastWorkoutDate {
    final iso = _box.get('lastWorkoutDate') as String?;
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  static void _setLastWorkoutDate() =>
      _box.put('lastWorkoutDate', DateTime.now().toIso8601String());

  // ── 部位別最終トレ日 ──────────────────────────────────
  static DateTime? lastTrainDate(StatAxis axis) {
    final iso = _box.get('lastTrain_${axis.name}') as String?;
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  static void _setLastTrainDate(StatAxis axis) =>
      _box.put('lastTrain_${axis.name}', DateTime.now().toIso8601String());

  // ── 体重記録 ──────────────────────────────────────────
  static void logBodyWeight(double kg) {
    final today = DateTime.now();
    final key =
        'bw_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _box.put(key, kg);
  }

  static List<MapEntry<DateTime, double>> get bodyWeightHistory {
    final entries = <MapEntry<DateTime, double>>[];
    for (final key in _box.keys) {
      final k = key.toString();
      if (k.startsWith('bw_')) {
        final dateStr = k.substring(3);
        final date = DateTime.tryParse(dateStr);
        final val = (_box.get(key) as num?)?.toDouble();
        if (date != null && val != null) {
          entries.add(MapEntry(date, val));
        }
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  static double? get latestBodyWeight => bodyWeightHistory.lastOrNull?.value;

  static List<double> get allStats =>
      StatAxis.values.map((a) => getStat(a)).toList();

  // Dominant stat（ペットタイプ用）
  static StatAxis get dominantStat {
    StatAxis dominant = StatAxis.chest;
    double max = -1;
    for (final axis in StatAxis.values) {
      final v = getStat(axis);
      if (v > max) {
        max = v;
        dominant = axis;
      }
    }
    return dominant;
  }

  // Level shortcuts
  static int get level => LevelSystem.level(totalXP);
  static double get levelProgress => LevelSystem.progress(totalXP);
  static String get avatar => PetEvolution.emoji(level, dominantStat);
  static String get levelTitle => LevelSystem.title(level);

  // Reset
  static Future<void> reset() async {
    await _box.clear();
  }
}

// MARK: - WorkoutSession

class WorkoutSession {
  final String exerciseName;
  final String exerciseIcon;
  final int targetSeconds;
  final int actualSeconds;
  final bool completed;
  final int earnedXP;
  final DateTime date;
  final int? sets;
  final int? reps;
  final double? weight;
  final Map<String, double> statGains;
  final List<Map<String, dynamic>> setDetails;

  WorkoutSession({
    required this.exerciseName,
    required this.exerciseIcon,
    required this.targetSeconds,
    required this.actualSeconds,
    required this.completed,
    required this.earnedXP,
    required this.date,
    this.sets,
    this.reps,
    this.weight,
    Map<String, double>? statGains,
    List<Map<String, dynamic>>? setDetails,
  })  : statGains = statGains ?? {},
        setDetails = setDetails ?? [];

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        'exerciseIcon': exerciseIcon,
        'targetSeconds': targetSeconds,
        'actualSeconds': actualSeconds,
        'completed': completed,
        'earnedXP': earnedXP,
        'date': date.toIso8601String(),
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        'statGains': statGains,
        'setDetails': setDetails,
      };

  factory WorkoutSession.fromMap(Map map) => WorkoutSession(
        exerciseName: map['exerciseName'] as String,
        exerciseIcon: map['exerciseIcon'] as String,
        targetSeconds: map['targetSeconds'] as int,
        actualSeconds: map['actualSeconds'] as int,
        completed: map['completed'] as bool,
        earnedXP: map['earnedXP'] as int,
        date: DateTime.parse(map['date'] as String),
        sets: map['sets'] as int?,
        reps: map['reps'] as int?,
        weight: (map['weight'] as num?)?.toDouble(),
        statGains: map['statGains'] != null
            ? Map<String, double>.from(
                (map['statGains'] as Map)
                    .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
            : {},
        setDetails: (map['setDetails'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
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

  static void save(WorkoutSession session) => _box.add(session.toMap());

  static List<WorkoutSession> last7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return all.where((s) => s.date.isAfter(cutoff)).toList();
  }

  static Set<String> workoutDateKeys() {
    return all
        .map((s) => '${s.date.year}-${s.date.month}-${s.date.day}')
        .toSet();
  }

  static List<WorkoutSession> forExercise(String name) {
    return all
        .where((s) => s.exerciseName == name)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<WorkoutSession> thisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    return all.where((s) => s.date.isAfter(startOfWeek)).toList();
  }
}

// MARK: - ExerciseCategory

enum ExerciseCategory {
  strength('筋トレ'),
  move('有酸素'),
  stretch('ストレッチ'),
  walk('散歩');

  const ExerciseCategory(this.label);
  final String label;
}

// MARK: - Exercise

class Exercise {
  final String name;
  final String icon;
  final ExerciseCategory category;
  final int defaultSeconds;
  bool isActive;
  final List<double> gainRates; // [chest, back, shoulder, arms, legs, abs]
  Exercise({
    required this.name,
    required this.icon,
    required this.category,
    required this.defaultSeconds,
    this.isActive = true,
    List<double>? gainRates,
  }) : gainRates = gainRates ?? List.filled(6, 0.0);

  double gainFor(StatAxis axis) => gainRates[axis.index];

  // 上位3軸を返す
  List<MapEntry<StatAxis, double>> get topGains {
    final entries = StatAxis.values
        .map((a) => MapEntry(a, gainRates[a.index]))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }
}

class ExerciseStore {
  static const _boxName = 'exercises';
  static Box get _box => Hive.box(_boxName);

  static List<Exercise> get all {
    if (_box.isEmpty) _seed();
    return _box.values.map(_fromMap).toList();
  }

  static Exercise _fromMap(dynamic raw) {
    final m = raw as Map;
    return Exercise(
      name: m['name'] as String,
      icon: m['icon'] as String,
      category: ExerciseCategory.values.firstWhere((c) => c.name == m['category']),
      defaultSeconds: m['defaultSeconds'] as int,
      isActive: m['isActive'] as bool? ?? true,
      gainRates: m['gainRates'] != null
          ? List<double>.from(
              (m['gainRates'] as List).map((v) => (v as num).toDouble()))
          : List.filled(6, 0.0),
    );
  }

  static Map<String, dynamic> _toMap(Exercise e) => {
        'name': e.name,
        'icon': e.icon,
        'category': e.category.name,
        'defaultSeconds': e.defaultSeconds,
        'isActive': e.isActive,
        'gainRates': e.gainRates,
      };

  static void _seed() {
    for (final e in ExerciseDatabase.all) {
      _box.add(_toMap(e));
    }
  }

  static void toggle(int index, bool val) {
    final map = Map<String, dynamic>.from(_box.getAt(index) as Map);
    map['isActive'] = val;
    _box.putAt(index, map);
  }

  static List<Exercise> get active => all.where((e) => e.isActive).toList();

  static Exercise? findByName(String name) {
    try {
      return all.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  /// カスタム種目を追加
  static void addCustom(Exercise e) => _box.add(_toMap(e));


  // データ移行: gainRates がない古いデータを再シード
  static void migrateIfNeeded() {
    if (_box.isEmpty) return;
    final first = _box.getAt(0) as Map?;
    if (first != null && !first.containsKey('gainRates')) {
      _box.clear();
      _seed();
    }
  }
}

// MARK: - WorkoutPlan

class WorkoutPlanExercise {
  final String exerciseName;
  int targetSets;
  int targetReps;
  double targetWeight;

  WorkoutPlanExercise({
    required this.exerciseName,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
  });

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
      };

  factory WorkoutPlanExercise.fromMap(Map map) => WorkoutPlanExercise(
        exerciseName: map['exerciseName'] as String,
        targetSets: map['targetSets'] as int? ?? 3,
        targetReps: map['targetReps'] as int? ?? 10,
        targetWeight: (map['targetWeight'] as num?)?.toDouble() ?? 0,
      );
}

class WorkoutPlan {
  String name;
  String icon;
  List<WorkoutPlanExercise> exercises;
  final DateTime createdAt;

  WorkoutPlan({
    required this.name,
    this.icon = '🏋️',
    List<WorkoutPlanExercise>? exercises,
    DateTime? createdAt,
  })  : exercises = exercises ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutPlan.fromMap(Map map) => WorkoutPlan(
        name: map['name'] as String,
        icon: map['icon'] as String? ?? '🏋️',
        exercises: (map['exercises'] as List?)
                ?.map((e) => WorkoutPlanExercise.fromMap(e as Map))
                .toList() ??
            [],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}

class WorkoutPlanStore {
  static const _boxName = 'plans';
  static Box get _box => Hive.box(_boxName);

  static List<WorkoutPlan> get all =>
      _box.values.map((e) => WorkoutPlan.fromMap(e as Map)).toList();

  static void add(WorkoutPlan plan) => _box.add(plan.toMap());

  static void update(int index, WorkoutPlan plan) =>
      _box.putAt(index, plan.toMap());

  static void delete(int index) => _box.deleteAt(index);
}

// MARK: - VideoEntry

class VideoEntry {
  final String id;
  String url;
  String title;
  List<String> exerciseNames;

  VideoEntry({
    required this.id,
    required this.url,
    String? title,
    List<String>? exerciseNames,
  })  : title = title ?? '',
        exerciseNames = exerciseNames ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'title': title,
        'exerciseNames': exerciseNames,
      };

  factory VideoEntry.fromMap(Map m) => VideoEntry(
        id: m['id'] as String,
        url: m['url'] as String,
        title: m['title'] as String? ?? '',
        exerciseNames:
            List<String>.from(m['exerciseNames'] as List? ?? []),
      );
}

class VideoStore {
  static const _boxName = 'videos';
  static Box get _box => Hive.box(_boxName);

  static List<VideoEntry> get all =>
      _box.values.map((e) => VideoEntry.fromMap(e as Map)).toList();

  static void save(VideoEntry v) => _box.put(v.id, v.toMap());
  static void delete(String id) => _box.delete(id);

  static List<VideoEntry> forExercise(String name) =>
      all.where((v) => v.exerciseNames.contains(name)).toList();

  /// 種目をビデオに紐づける（なければ追加、あれば更新）
  static void linkExercise(String videoId, String exerciseName) {
    final v = all.firstWhere((e) => e.id == videoId,
        orElse: () => throw StateError('not found'));
    if (!v.exerciseNames.contains(exerciseName)) {
      v.exerciseNames.add(exerciseName);
      save(v);
    }
  }

  /// 種目のリンクを解除
  static void unlinkExercise(String videoId, String exerciseName) {
    final v = all.firstWhere((e) => e.id == videoId,
        orElse: () => throw StateError('not found'));
    v.exerciseNames.remove(exerciseName);
    save(v);
  }
}
