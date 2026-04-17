import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('profile').listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: Hive.box('exercises').listenable(),
          builder: (context, _, __) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('設定',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // ビルドタイプ
                    const Text('ビルドタイプ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _BuildTypeSelector(),
                    const SizedBox(height: 24),

                    // ステータス
                    const Text('現在のステータス',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _StatusCard(),
                    const SizedBox(height: 24),

                    // 種目オン/オフ
                    const Text('種目のオン/オフ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _ExerciseToggles(),
                    const SizedBox(height: 32),

                    // データリセット
                    _ResetButton(),
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

// ── ビルドタイプ選択 ──────────────────────────────────────

class _BuildTypeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = BodyProfile.buildType;
    return Column(
      children: BuildType.values.map((bt) {
        final isSelected = bt == current;
        return GestureDetector(
          onTap: () => BodyProfile.setBuildType(bt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.ignite.withValues(alpha: 0.12)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.ignite : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Text(bt.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bt.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.ignite
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bt.description,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.ignite, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── ステータスカード ──────────────────────────────────────

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = StatAxis.values.map((a) => BodyProfile.getStat(a)).toList();
    final peaks = StatAxis.values.map((a) => BodyProfile.getPeak(a)).toList();
    final maxVal = peaks.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: StatAxis.values.asMap().entries.map((entry) {
          final i = entry.key;
          final axis = entry.value;
          final val = stats[i];
          final peak = peaks[i];
          final ratio = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
          final peakRatio =
              maxVal > 0 ? (peak / maxVal).clamp(0.0, 1.0) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(axis.icon,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(axis.label,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                    const Spacer(),
                    Text(
                      val.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppColors.ignite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(' / ${peak.toStringAsFixed(1)} peak',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: peakRatio,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.textSecondary),
                        minHeight: 6,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.ignite),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 種目オン/オフ ─────────────────────────────────────────

class _ExerciseToggles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseStore.all;
    return Column(
      children: exercises.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Text(e.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                    Text(e.category.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: e.isActive,
                activeTrackColor: AppColors.ignite,
                activeThumbColor: Colors.white,
                onChanged: (val) => ExerciseStore.toggle(i, val),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── リセットボタン ────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.delete_forever_rounded),
        label: const Text('データをリセット'),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('データをリセット',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                  '全データ（XP・ステータス・セッション）が削除されます。\nこの操作は取り消せません。',
                  style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('キャンセル',
                        style: TextStyle(
                            color: AppColors.textSecondary))),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('リセット',
                        style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          );
          if (confirm == true) {
            await BodyProfile.reset();
            await Hive.box('sessions').clear();
          }
        },
      ),
    );
  }
}
