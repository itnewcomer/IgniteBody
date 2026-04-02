import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('exercises').listenable(),
      builder: (context, _, __) {
        final exercises = ExerciseStore.all;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('設定', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('種目のオン/オフ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                ...exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Text(e.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.name, style: const TextStyle(color: AppColors.textPrimary))),
                        Switch(
                          value: e.isActive,
                          activeThumbColor: AppColors.ignite,
                          onChanged: (val) {
                            final box = Hive.box('exercises');
                            final map = Map<String, dynamic>.from(box.getAt(i) as Map);
                            map['isActive'] = val;
                            box.putAt(i, map);
                          },
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('データをリセット', style: TextStyle(color: AppColors.textPrimary)),
                        content: const Text('全データが削除されます。', style: TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false),
                              child: const Text('キャンセル', style: TextStyle(color: AppColors.textSecondary))),
                          TextButton(onPressed: () => Navigator.pop(context, true),
                              child: const Text('リセット', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await Hive.box('profile').clear();
                      await Hive.box('sessions').clear();
                    }
                  },
                  child: const Text('データをリセット'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
