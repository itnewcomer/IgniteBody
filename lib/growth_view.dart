import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_colors.dart';
import 'models.dart';

class GrowthView extends StatelessWidget {
  const GrowthView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sessions').listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: Hive.box('profile').listenable(),
          builder: (context, _, __) {
            final totalXP = BodyProfile.totalXP;
            final level = BodyProfile.level;
            final sessions = SessionStore.all;
            final last7 = SessionStore.last7Days();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('成長',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // レベルカード
                    _LevelCard(level: level, totalXP: totalXP,
                        totalSessions: sessions.length),
                    const SizedBox(height: 16),

                    // 筋疲労・回復
                    const _MuscleRecoveryCard(),
                    const SizedBox(height: 16),

                    // 体重記録
                    const _BodyWeightCard(),
                    const SizedBox(height: 16),

                    // レーダーチャート（6軸）
                    const _RadarCard(),
                    const SizedBox(height: 16),

                    // 今週のボリューム
                    const _WeeklyVolumeCard(),
                    const SizedBox(height: 16),

                    // 7日間XPバーチャート
                    _WeekChart(sessions: last7),
                    const SizedBox(height: 16),

                    // ワークアウトカレンダー（10週）
                    _WorkoutCalendar(dateKeys: SessionStore.workoutDateKeys()),
                    const SizedBox(height: 16),

                    // 最近のセッション
                    if (sessions.isNotEmpty) ...[
                      const Text('最近のワークアウト',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...sessions.take(10).map((s) => _SessionRow(session: s)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── レベルカード ──────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final int level;
  final int totalXP;
  final int totalSessions;

  const _LevelCard({
    required this.level,
    required this.totalXP,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final nextLevel =
        level < LevelSystem.thresholds.length - 1 ? level + 1 : null;
    final nextXP =
        nextLevel != null ? LevelSystem.thresholds[nextLevel] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(BodyProfile.avatar, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$level  ${BodyProfile.levelTitle}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '累計 $totalXP XP  ·  $totalSessions 回',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                if (nextXP != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: BodyProfile.levelProgress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.background,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.ignite),
                      minHeight: 6,
                    ),
                  ),
                  Text(
                    '次のレベルまで ${nextXP - totalXP} XP',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── レーダーチャート ──────────────────────────────────────

class _RadarCard extends StatelessWidget {
  const _RadarCard();

  @override
  Widget build(BuildContext context) {
    final stats = StatAxis.values.map((a) => BodyProfile.getStat(a)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('6軸ステータス',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: stats
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                    fillColor: AppColors.ignite.withValues(alpha: 0.2),
                    borderColor: AppColors.ignite,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                  // ピーク
                  RadarDataSet(
                    dataEntries: StatAxis.values
                        .map((a) => RadarEntry(value: BodyProfile.getPeak(a)))
                        .toList(),
                    fillColor: Colors.transparent,
                    borderColor: AppColors.ignite.withValues(alpha: 0.3),
                    borderWidth: 1,
                    entryRadius: 0,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(
                    color: AppColors.textSecondary, width: 0.5),
                titleTextStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
                getTitle: (index, angle) {
                  final axis = StatAxis.values[index];
                  return RadarChartTitle(text: axis.label);
                },
                tickCount: 3,
                ticksTextStyle: const TextStyle(
                    color: Colors.transparent, fontSize: 0),
                tickBorderData: const BorderSide(
                    color: AppColors.textSecondary, width: 0.3),
                gridBorderData: const BorderSide(
                    color: AppColors.textSecondary, width: 0.3),
                radarShape: RadarShape.polygon,
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
            ),
          ),
          // 数値一覧
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: StatAxis.values.map((a) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${a.label} ${BodyProfile.getStat(a).toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            )).toList(),
          ),

          // デトレーニング警告
          _DetrainWarning(),
        ],
      ),
    );
  }
}

class _DetrainWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final last = BodyProfile.lastWorkoutDate;
    if (last == null) return const SizedBox();
    final days = DateTime.now().difference(last).inDays;
    if (days < 3) return const SizedBox();

    final isSerious = days >= 7;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSerious
              ? Colors.yellow.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(isSerious ? '🍖' : '🕐', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSerious
                    ? '$days日サボり中。ペットがお腹を空かせているよ'
                    : '最後のワークアウトから$days日。そろそろ動こう',
                style: TextStyle(
                  color: isSerious ? Colors.yellow : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7日間XPバーチャート ───────────────────────────────────

class _WeekChart extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _WeekChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final xpByDay = {for (final d in days) _dateKey(d): 0};
    for (final s in sessions) {
      final key = _dateKey(s.date);
      if (xpByDay.containsKey(key)) xpByDay[key] = xpByDay[key]! + s.earnedXP;
    }
    final maxXP = xpByDay.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7日間のXP',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final xp = xpByDay[_dateKey(d)] ?? 0;
                final ratio = maxXP > 0 ? xp / maxXP : 0.0;
                final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
                final label = weekdays[d.weekday - 1];
                final isToday = _dateKey(d) == _dateKey(now);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.04, 1.0),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: xp > 0
                                    ? AppColors.ignite
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: isToday
                              ? AppColors.ignite
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

// ── ワークアウトカレンダー ─────────────────────────────────

class _WorkoutCalendar extends StatelessWidget {
  final Set<String> dateKeys;
  const _WorkoutCalendar({required this.dateKeys});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = 10;
    final startDay = now.subtract(Duration(days: weeks * 7 - 1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ワークアウト履歴',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (w) {
                return Column(
                  children: List.generate(7, (d) {
                    final day = startDay.add(Duration(days: w * 7 + d));
                    final key =
                        '${day.year}-${day.month}-${day.day}';
                    final hasWorkout = dateKeys.contains(key);
                    final isToday = key ==
                        '${now.year}-${now.month}-${now.day}';
                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: hasWorkout
                            ? AppColors.ignite
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(2),
                        border: isToday
                            ? Border.all(color: AppColors.ignite, width: 1)
                            : null,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── セッション行 ──────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;
  const _SessionRow({required this.session});

  String get _summary {
    if (session.sets != null) {
      final w = session.weight != null && session.weight! > 0
          ? ' @${session.weight}kg'
          : ' 自重';
      return '${session.sets}×${session.reps}rep$w';
    }
    final mins = session.actualSeconds ~/ 60;
    final secs = session.actualSeconds % 60;
    return mins > 0 ? '${mins}分${secs}秒' : '${secs}秒';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (_) => _ExerciseHistorySheet(
          exerciseName: session.exerciseName,
          exerciseIcon: session.exerciseIcon,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(session.exerciseIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.exerciseName,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  Text(_summary,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text('+${session.earnedXP}XP',
                style: const TextStyle(
                    color: AppColors.ignite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── 筋疲労・回復カード ─────────────────────────────────────

class _MuscleRecoveryCard extends StatelessWidget {
  const _MuscleRecoveryCard();

  static const Map<StatAxis, int> _recoveryHours = {
    StatAxis.chest: 48,
    StatAxis.back: 48,
    StatAxis.shoulder: 48,
    StatAxis.arms: 48,
    StatAxis.legs: 72,
    StatAxis.abs: 36,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rows = StatAxis.values.map((axis) {
      final last = BodyProfile.lastTrainDate(axis);
      if (last == null) return null;
      final hours = now.difference(last).inHours;
      final threshold = _recoveryHours[axis]!;
      final progress = (hours / threshold).clamp(0.0, 1.0);
      final Color color;
      final String status;
      if (hours < threshold ~/ 2) {
        color = const Color(0xFFFF5722);
        status = '疲労中';
      } else if (hours < threshold) {
        color = Colors.orange;
        status = '回復中';
      } else {
        color = const Color(0xFF4CAF50);
        status = '準備OK';
      }
      return _RecoveryRow(axis: axis, progress: progress, color: color, status: status);
    }).whereType<_RecoveryRow>().toList();

    if (rows.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('筋疲労・回復',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final StatAxis axis;
  final double progress;
  final Color color;
  final String status;
  const _RecoveryRow({
    required this.axis,
    required this.progress,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(axis.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(axis.label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(status,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── 今週のボリュームカード ─────────────────────────────────

class _WeeklyVolumeCard extends StatelessWidget {
  const _WeeklyVolumeCard();

  @override
  Widget build(BuildContext context) {
    final sessions = SessionStore.thisWeek();
    final sets = <StatAxis, int>{};

    for (final s in sessions) {
      if (s.sets == null) continue;
      final ex = ExerciseStore.findByName(s.exerciseName);
      if (ex == null || ex.topGains.isEmpty) continue;
      final axis = ex.topGains.first.key;
      sets[axis] = (sets[axis] ?? 0) + s.sets!;
    }

    if (sets.isEmpty) return const SizedBox();

    final sorted = sets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今週のボリューム',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Text('目標: 各部位 10〜20セット/週',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final axis = entry.key;
            final count = entry.value;
            final ratio = (count / 20.0).clamp(0.0, 1.0);
            final Color color;
            if (count > 20) {
              color = Colors.orange;
            } else if (count >= 10) {
              color = const Color(0xFF4CAF50);
            } else {
              color = AppColors.ignite;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(axis.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34,
                    child: Text(axis.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count sets',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 体重記録カード ─────────────────────────────────────────

class _BodyWeightCard extends StatefulWidget {
  const _BodyWeightCard();

  @override
  State<_BodyWeightCard> createState() => _BodyWeightCardState();
}

class _BodyWeightCardState extends State<_BodyWeightCard> {
  void _showInput() {
    final latest = BodyProfile.latestBodyWeight;
    final controller = TextEditingController(
      text: latest != null ? latest.toStringAsFixed(1) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('体重を記録',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            suffixText: 'kg',
            suffixStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.ignite),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final kg = double.tryParse(controller.text);
              if (kg != null && kg > 0) {
                BodyProfile.logBodyWeight(kg);
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('記録',
                style: TextStyle(color: AppColors.ignite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = BodyProfile.bodyWeightHistory;
    final latest = history.isNotEmpty ? history.last.value : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('体重',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _showInput,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ignite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('＋ 記録',
                      style:
                          TextStyle(color: AppColors.ignite, fontSize: 12)),
                ),
              ),
            ],
          ),
          if (latest == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text('体重を記録してみよう',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 4),
                  child: Text('kg',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
                const Spacer(),
                if (history.length > 1)
                  _WeightDelta(
                      first: history.first.value, last: history.last.value),
              ],
            ),
            if (history.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: history
                            .asMap()
                            .entries
                            .map((e) =>
                                FlSpot(e.key.toDouble(), e.value.value))
                            .toList(),
                        isCurved: true,
                        color: AppColors.ignite,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.ignite.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: (history.length - 1).toDouble(),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeightDelta extends StatelessWidget {
  final double first;
  final double last;
  const _WeightDelta({required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    final delta = last - first;
    final isUp = delta > 0;
    final color = isUp ? Colors.orange : const Color(0xFF4CAF50);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}kg',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

// ── 種目別履歴シート ────────────────────────────────────────

class _ExerciseHistorySheet extends StatelessWidget {
  final String exerciseName;
  final String exerciseIcon;
  const _ExerciseHistorySheet(
      {required this.exerciseName, required this.exerciseIcon});

  @override
  Widget build(BuildContext context) {
    final sessions = SessionStore.forExercise(exerciseName);
    final hasWeight =
        sessions.any((s) => s.weight != null && s.weight! > 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('$exerciseIcon $exerciseName',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (hasWeight && sessions.length >= 2) ...[
              const Text('重量推移',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.toInt()}kg',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9),
                          ),
                          reservedSize: 36,
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sessions
                            .asMap()
                            .entries
                            .where((e) =>
                                e.value.weight != null &&
                                e.value.weight! > 0)
                            .map((e) =>
                                FlSpot(e.key.toDouble(), e.value.weight!))
                            .toList(),
                        isCurved: true,
                        color: AppColors.ignite,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.ignite,
                            strokeWidth: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text('記録',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            ...sessions.reversed.take(20).map((s) => _HistoryRow(session: s)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WorkoutSession session;
  const _HistoryRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final d = session.date;
    final dateStr = '${d.month}/${d.day}';

    final String detail;
    if (session.sets != null) {
      final w = session.weight != null && session.weight! > 0
          ? ' @${session.weight}kg'
          : ' 自重';
      detail = '${session.sets}×${session.reps}rep$w';
    } else {
      final mins = session.actualSeconds ~/ 60;
      detail = mins > 0 ? '$mins分' : '${session.actualSeconds}秒';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(dateStr,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(detail,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Text('+${session.earnedXP}XP',
              style: const TextStyle(
                  color: AppColors.ignite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
