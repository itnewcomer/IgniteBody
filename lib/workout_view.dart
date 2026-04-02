import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';
import 'workout_timer_view.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView({super.key});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  ExerciseCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseStore.active;
    final filtered = _selectedCategory == null
        ? exercises
        : exercises.where((e) => e.category == _selectedCategory).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('動く', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          ),

          // カテゴリチップ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryChip(label: 'すべて', selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null)),
                ...ExerciseCategory.values.map((c) => _CategoryChip(
                  label: c.label,
                  selected: _selectedCategory == c,
                  onTap: () => setState(() => _selectedCategory = c),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 種目グリッド
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ExerciseCard(exercise: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.ignite.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.ignite : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? AppColors.ignite : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final mins = exercise.defaultSeconds ~/ 60;
    final secs = exercise.defaultSeconds % 60;
    final timeLabel = mins > 0 ? (secs > 0 ? '${mins}分${secs}秒' : '${mins}分') : '${secs}秒';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => WorkoutTimerView(exercise: exercise),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(exercise.icon, style: const TextStyle(fontSize: 32)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(timeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
