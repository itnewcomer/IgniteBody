import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';
import 'workout_timer_view.dart';
import 'workout_plan_view.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView({super.key});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '動く',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // カスタム種目作成ボタン
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.ignite),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('種目'),
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.background,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const _CustomExerciseSheet(),
                        );
                        setState(() {});
                      },
                    ),
                    // プラン作成ボタン
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.ignite),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('プラン'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WorkoutPlanEditView()),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // タブ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppColors.ignite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.ignite,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'プラン'),
                Tab(text: '種目'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _PlansTab(),
                _ExercisesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── プランタブ ────────────────────────────────────────────

class _PlansTab extends StatefulWidget {
  const _PlansTab();

  @override
  State<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<_PlansTab> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('plans').listenable(),
      builder: (context, _, __) {
        final plans = WorkoutPlanStore.all;
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('プランがまだありません',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ignite,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('プランを作る'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkoutPlanEditView()),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: plans.length,
          itemBuilder: (_, i) => _PlanCard(
            plan: plans[i],
            index: i,
            onDeleted: () => setState(() {}),
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final int index;
  final VoidCallback onDeleted;

  const _PlanCard(
      {required this.plan, required this.index, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(plan.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.textSecondary, size: 18),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          WorkoutPlanEditView(plan: plan, index: index)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 18),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('プランを削除',
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: Text('「${plan.name}」を削除しますか？',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル',
                                style: TextStyle(
                                    color: AppColors.textSecondary))),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('削除',
                                style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    WorkoutPlanStore.delete(index);
                    onDeleted();
                  }
                },
              ),
            ],
          ),
          if (plan.exercises.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.exercises.map((e) => e.exerciseName).join(' · '),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ignite,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WorkoutPlanRunView(plan: plan)),
              ),
              child: const Text('スタート',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 種目タブ ──────────────────────────────────────────────

class _ExercisesTab extends StatefulWidget {
  const _ExercisesTab();

  @override
  State<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<_ExercisesTab> {
  ExerciseCategory? _cat;
  StatAxis? _axis;

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseStore.active;
    final filtered = exercises.where((e) {
      if (_cat != null && e.category != _cat) return false;
      if (_axis != null && e.gainFor(_axis!) <= 0) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // カテゴリフィルター
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Chip(
                  label: 'すべて',
                  selected: _cat == null && _axis == null,
                  onTap: () => setState(() {
                        _cat = null;
                        _axis = null;
                      })),
              ...ExerciseCategory.values.map((c) => _Chip(
                    label: c.label,
                    selected: _cat == c,
                    onTap: () => setState(() {
                      _cat = _cat == c ? null : c;
                      _axis = null;
                    }),
                  )),
              const SizedBox(width: 8),
              ...StatAxis.values.map((a) => _Chip(
                    label: a.label,
                    selected: _axis == a,
                    onTap: () => setState(() {
                      _axis = _axis == a ? null : a;
                      _cat = null;
                    }),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // グリッド
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _ExerciseCard(exercise: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WorkoutTimerView(exercise: exercise)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(exercise.icon, style: const TextStyle(fontSize: 28)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise.category.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // トップゲイン
            Wrap(
              spacing: 4,
              children: exercise.topGains.take(2).map((g) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ignite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(g.key.label,
                        style: const TextStyle(
                            color: AppColors.ignite, fontSize: 10)),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── カスタム種目作成シート ────────────────────────────────

class _CustomExerciseSheet extends StatefulWidget {
  const _CustomExerciseSheet();

  @override
  State<_CustomExerciseSheet> createState() => _CustomExerciseSheetState();
}

class _CustomExerciseSheetState extends State<_CustomExerciseSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '⚡️';
  ExerciseCategory _category = ExerciseCategory.strength;
  final List<double> _gainRates = List.filled(6, 0.0); // [chest,back,shoulder,arms,legs,abs]

  static const _iconOptions = [
    '⚡️','💪','🦵','🌀','🏃','🧘','🚶','🔥','🎯','⬆️','🔄','🤸','🏋️','🥊','🚴',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ExerciseStore.addCustom(Exercise(
      name: name,
      icon: _icon,
      category: _category,
      defaultSeconds: 60,
      gainRates: List.from(_gainRates),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('カスタム種目',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _save,
                  child: const Text('追加',
                      style: TextStyle(
                          color: AppColors.ignite, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 名前 + アイコン
            Row(
              children: [
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(_icon, style: const TextStyle(fontSize: 28))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '種目名（例: ハンマーカール）',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // カテゴリ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExerciseCategory.values.map((c) => GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _category == c
                          ? AppColors.ignite.withValues(alpha: 0.2)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _category == c ? AppColors.ignite : Colors.transparent),
                    ),
                    child: Text(c.label,
                        style: TextStyle(
                          color: _category == c ? AppColors.ignite : AppColors.textSecondary,
                          fontSize: 13,
                        )),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // ゲインスライダー
            const Text('ステータス寄与',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            ...StatAxis.values.map((axis) {
              final i = axis.index;
              return Column(
                children: [
                  Row(
                    children: [
                      Text('${axis.icon} ${axis.label}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      const Spacer(),
                      Text(
                        _gainRates[i] > 0
                            ? _gainRates[i].toStringAsFixed(1)
                            : 'なし',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  Slider(
                    value: _gainRates[i],
                    min: 0, max: 3.0, divisions: 30,
                    activeColor: AppColors.ignite,
                    inactiveColor: AppColors.card,
                    onChanged: (v) => setState(() => _gainRates[i] = v),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _pickIcon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12, runSpacing: 12,
          children: _iconOptions.map((ic) => GestureDetector(
            onTap: () {
              setState(() => _icon = ic);
              Navigator.pop(context);
            },
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: ic == _icon
                    ? AppColors.ignite.withValues(alpha: 0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ic == _icon ? AppColors.ignite : Colors.transparent),
              ),
              child: Center(child: Text(ic, style: const TextStyle(fontSize: 28))),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ignite.withValues(alpha: 0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.ignite : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.ignite : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
