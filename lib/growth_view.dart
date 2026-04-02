import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';

class GrowthView extends StatelessWidget {
  const GrowthView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sessions').listenable(),
      builder: (context, _, __) {
        final sessions = SessionStore.last7Days();
        final totalXP = BodyProfile.totalXP;
        final level = BodyProfile.level;
        final totalSessions = SessionStore.all.length;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('成長', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // レベルカード
                _LevelCard(level: level, totalXP: totalXP, totalSessions: totalSessions),
                const SizedBox(height: 16),

                // 7日間バーチャート
                _WeekChart(sessions: sessions),
                const SizedBox(height: 16),

                // 最近のセッション
                if (sessions.isNotEmpty) ...[
                  const Text('最近のワークアウト',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...sessions.take(10).map((s) => _SessionRow(session: s)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final int totalXP;
  final int totalSessions;

  const _LevelCard({required this.level, required this.totalXP, required this.totalSessions});

  @override
  Widget build(BuildContext context) {
    final nextLevel = level < LevelSystem.thresholds.length - 1 ? level + 1 : null;
    final nextXP = nextLevel != null ? LevelSystem.thresholds[nextLevel] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(BodyProfile.avatar, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lv.$level  ${BodyProfile.levelTitle}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('累計 $totalXP XP  ·  $totalSessions 回',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (nextXP != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: BodyProfile.levelProgress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.ignite),
                      minHeight: 6,
                    ),
                  ),
                  Text('次のレベルまで ${nextXP - totalXP} XP',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7日間のXP', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.05, 1.0),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: xp > 0 ? AppColors.ignite : AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final mins = session.actualSeconds ~/ 60;
    final secs = session.actualSeconds % 60;
    final timeLabel = mins > 0 ? '${mins}分${secs}秒' : '${secs}秒';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(session.exerciseIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(session.exerciseName,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
          Text(timeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Text('+${session.earnedXP}XP', style: const TextStyle(color: AppColors.ignite, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
