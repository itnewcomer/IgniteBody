import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';
import 'workout_timer_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('profile').listenable(),
      builder: (context, _, __) {
        final xp = BodyProfile.totalXP;
        final level = BodyProfile.level;
        final progress = BodyProfile.levelProgress;
        final exercises = ExerciseStore.active;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アバターカード
                _AvatarCard(xp: xp, level: level, progress: progress),
                const SizedBox(height: 16),

                // ランダムスタートボタン
                if (exercises.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ignite,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Text('🎲', style: TextStyle(fontSize: 20)),
                      label: const Text('ランダムでやる', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final e = (exercises..shuffle()).first;
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WorkoutTimerView(exercise: e),
                        ));
                      },
                    ),
                  ),
                const SizedBox(height: 20),

                // 種目リスト
                Text('種目', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                ...exercises.map((e) => _ExerciseRow(exercise: e)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final int xp;
  final int level;
  final double progress;

  const _AvatarCard({required this.xp, required this.level, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(BodyProfile.avatar, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(BodyProfile.levelTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Lv.$level  |  $xp XP', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.ignite),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final mins = exercise.defaultSeconds ~/ 60;
    final secs = exercise.defaultSeconds % 60;
    final timeLabel = mins > 0
        ? (secs > 0 ? '${mins}分${secs}秒' : '${mins}分')
        : '${secs}秒';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => WorkoutTimerView(exercise: exercise),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(exercise.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(exercise.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            ),
            Text(timeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
