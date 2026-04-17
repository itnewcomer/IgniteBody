import 'package:flutter_test/flutter_test.dart';
import 'package:ignite_body/models.dart';
import 'package:ignite_body/exercise_database.dart';

void main() {
  // ── LevelSystem ───────────────────────────────────────

  group('LevelSystem', () {
    test('XP 0 は Lv0', () {
      expect(LevelSystem.level(0), 0);
    });

    test('XP 199 は Lv0', () {
      expect(LevelSystem.level(199), 0);
    });

    test('XP 200 は Lv1', () {
      expect(LevelSystem.level(200), 1);
    });

    test('XP 800 は Lv2', () {
      expect(LevelSystem.level(800), 2);
    });

    test('XP 80000 は Lv9（最大）', () {
      expect(LevelSystem.level(80000), 9);
    });

    test('XP が thresholds を超えても Lv9 にクランプ', () {
      expect(LevelSystem.level(999999), 9);
    });

    test('progress は 0〜1 の範囲内', () {
      for (final xp in [0, 100, 500, 5000, 80000]) {
        final p = LevelSystem.progress(xp);
        expect(p, greaterThanOrEqualTo(0.0));
        expect(p, lessThanOrEqualTo(1.0));
      }
    });

    test('progress Lv0 中間（XP=100）は 0〜1', () {
      final p = LevelSystem.progress(100); // 100/200 = 0.5
      expect(p, closeTo(0.5, 0.01));
    });

    // xpFor: base = (seconds / 30).floor() + bonus(300秒以上で+5)
    test('30秒 → 1 XP', () {
      expect(LevelSystem.xpFor(30), 1);
    });

    test('60秒 → 2 XP', () {
      expect(LevelSystem.xpFor(60), 2);
    });

    test('300秒（5分）→ 15 XP (10 + 5bonus)', () {
      expect(LevelSystem.xpFor(300), 15);
    });

    test('299秒 → 9 XP (bonus なし)', () {
      expect(LevelSystem.xpFor(299), 9);
    });

    test('avatar は 10段階', () {
      for (int i = 0; i <= 9; i++) {
        expect(LevelSystem.avatar(i), isNotEmpty);
      }
    });

    test('title は 10段階', () {
      for (int i = 0; i <= 9; i++) {
        expect(LevelSystem.title(i), isNotEmpty);
      }
    });

    // xpForVolume: sets * reps * (1 + weight/50)
    test('xpForVolume: 3×10 自重 → 30 XP', () {
      expect(LevelSystem.xpForVolume(3, 10, 0), 30);
    });

    test('xpForVolume: 3×10 @50kg → 60 XP (weight bonus ×2)', () {
      expect(LevelSystem.xpForVolume(3, 10, 50), 60);
    });
  });

  // ── BuildType ─────────────────────────────────────────

  group('BuildType', () {
    test('standard は全軸が 1.0', () {
      for (final axis in StatAxis.values) {
        expect(BuildType.standard.multiplierFor(axis), 1.0);
      }
    });

    test('lower は legs の multiplier が最大', () {
      final legsMultiplier = BuildType.lower.multiplierFor(StatAxis.legs);
      for (final axis in StatAxis.values) {
        expect(legsMultiplier,
            greaterThanOrEqualTo(BuildType.lower.multiplierFor(axis)));
      }
    });

    test('upper は chest の multiplier が高い', () {
      expect(BuildType.upper.multiplierFor(StatAxis.chest),
          greaterThan(BuildType.upper.multiplierFor(StatAxis.legs)));
    });

    test('全 BuildType に label と icon がある', () {
      for (final bt in BuildType.values) {
        expect(bt.label, isNotEmpty);
        expect(bt.icon, isNotEmpty);
        expect(bt.description, isNotEmpty);
      }
    });

    test('multipliers の長さは StatAxis.values の長さと一致', () {
      for (final bt in BuildType.values) {
        expect(bt.multipliers.length, StatAxis.values.length);
      }
    });
  });

  // ── StatAxis ──────────────────────────────────────────

  group('StatAxis', () {
    test('全軸に label と icon がある', () {
      for (final axis in StatAxis.values) {
        expect(axis.label, isNotEmpty);
        expect(axis.icon, isNotEmpty);
      }
    });

    test('index は 0〜5 の連番', () {
      for (int i = 0; i < StatAxis.values.length; i++) {
        expect(StatAxis.values[i].index, i);
      }
    });
  });

  // ── WorkoutSession ────────────────────────────────────

  group('WorkoutSession', () {
    test('toMap / fromMap ラウンドトリップ（タイマー系）', () {
      final original = WorkoutSession(
        exerciseName: 'プランク',
        exerciseIcon: '🌀',
        targetSeconds: 60,
        actualSeconds: 55,
        completed: true,
        earnedXP: 2,
        date: DateTime(2026, 4, 9, 12, 0),
        statGains: {'abs': 0.15, 'legs': 0.05},
      );
      final restored = WorkoutSession.fromMap(original.toMap());

      expect(restored.exerciseName, original.exerciseName);
      expect(restored.exerciseIcon, original.exerciseIcon);
      expect(restored.targetSeconds, original.targetSeconds);
      expect(restored.actualSeconds, original.actualSeconds);
      expect(restored.completed, original.completed);
      expect(restored.earnedXP, original.earnedXP);
      expect(restored.date, original.date);
      expect(restored.statGains['abs'], closeTo(0.15, 0.001));
      expect(restored.statGains['legs'], closeTo(0.05, 0.001));
    });

    test('toMap / fromMap ラウンドトリップ（筋トレ系）', () {
      final original = WorkoutSession(
        exerciseName: 'スクワット',
        exerciseIcon: '🦵',
        targetSeconds: 0,
        actualSeconds: 0,
        completed: true,
        earnedXP: 60,
        date: DateTime(2026, 4, 9),
        sets: 3,
        reps: 10,
        weight: 60.0,
        statGains: {'legs': 0.8},
      );
      final restored = WorkoutSession.fromMap(original.toMap());

      expect(restored.sets, 3);
      expect(restored.reps, 10);
      expect(restored.weight, 60.0);
    });

    test('statGains 省略時は空 Map', () {
      final session = WorkoutSession(
        exerciseName: 'test',
        exerciseIcon: '🏃',
        targetSeconds: 60,
        actualSeconds: 60,
        completed: true,
        earnedXP: 2,
        date: DateTime.now(),
      );
      expect(session.statGains, isEmpty);
    });
  });

  // ── WorkoutPlan ───────────────────────────────────────

  group('WorkoutPlan', () {
    test('toMap / fromMap ラウンドトリップ', () {
      final original = WorkoutPlan(
        name: ' 胸の日',
        exercises: [
          WorkoutPlanExercise(
              exerciseName: '腕立て伏せ',
              targetSets: 4,
              targetReps: 12,
              targetWeight: 0),
          WorkoutPlanExercise(
              exerciseName: 'ダンベルフライ',
              targetSets: 3,
              targetReps: 10,
              targetWeight: 10.0),
        ],
      );
      final restored = WorkoutPlan.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.exercises.length, 2);
      expect(restored.exercises[0].exerciseName, '腕立て伏せ');
      expect(restored.exercises[0].targetSets, 4);
      expect(restored.exercises[1].targetWeight, 10.0);
    });

    test('空のプランは exercises が空リスト', () {
      final plan = WorkoutPlan(name: 'empty');
      expect(plan.exercises, isEmpty);
    });
  });

  // ── ExerciseDatabase ──────────────────────────────────

  group('ExerciseDatabase', () {
    test('全種目の gainRates は長さ 6', () {
      for (final e in ExerciseDatabase.all) {
        expect(e.gainRates.length, 6,
            reason: '${e.name} の gainRates の長さが不正');
      }
    });

    test('全種目の gainRates はすべて 0 以上', () {
      for (final e in ExerciseDatabase.all) {
        for (final rate in e.gainRates) {
          expect(rate, greaterThanOrEqualTo(0.0),
              reason: '${e.name} に負のゲインレート');
        }
      }
    });

    test('strength 種目は少なくとも 1 軸で gain > 0', () {
      final strengthExercises = ExerciseDatabase.all
          .where((e) => e.category == ExerciseCategory.strength);
      for (final e in strengthExercises) {
        final hasGain = e.gainRates.any((r) => r > 0);
        expect(hasGain, isTrue,
            reason: '${e.name} は strength なのに全軸 gain = 0');
      }
    });

    test('Exercise.topGains は最大 3 件で降順', () {
      for (final e in ExerciseDatabase.all) {
        final top = e.topGains;
        expect(top.length, lessThanOrEqualTo(3));
        for (int i = 0; i < top.length - 1; i++) {
          expect(top[i].value, greaterThanOrEqualTo(top[i + 1].value));
        }
      }
    });

    test('種目数が十分にある（50種目以上）', () {
      expect(ExerciseDatabase.all.length, greaterThanOrEqualTo(50));
    });

    test('名前の重複がない', () {
      final names = ExerciseDatabase.all.map((e) => e.name).toList();
      final unique = names.toSet();
      expect(names.length, unique.length,
          reason: '重複した種目名が存在する');
    });
  });

  // ── Exercise.gainFor ──────────────────────────────────

  group('Exercise.gainFor', () {
    test('gainFor は正しい軸の値を返す', () {
      final e = Exercise(
        name: 'test',
        icon: '🏋️',
        category: ExerciseCategory.strength,
        defaultSeconds: 60,
        gainRates: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
      );
      expect(e.gainFor(StatAxis.chest), 1.0);
      expect(e.gainFor(StatAxis.back), 2.0);
      expect(e.gainFor(StatAxis.shoulder), 3.0);
      expect(e.gainFor(StatAxis.arms), 4.0);
      expect(e.gainFor(StatAxis.legs), 5.0);
      expect(e.gainFor(StatAxis.abs), 6.0);
    });

    test('gainRates 省略時は全軸 0.0', () {
      final e = Exercise(
        name: 'test',
        icon: '🏃',
        category: ExerciseCategory.move,
        defaultSeconds: 60,
      );
      for (final axis in StatAxis.values) {
        expect(e.gainFor(axis), 0.0);
      }
    });
  });
}
