import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';

// ── プラン編集 ─────────────────────────────────────────────

class WorkoutPlanEditView extends StatefulWidget {
  final WorkoutPlan? plan;
  final int? index;

  const WorkoutPlanEditView({super.key, this.plan, this.index});

  @override
  State<WorkoutPlanEditView> createState() => _WorkoutPlanEditViewState();
}

class _WorkoutPlanEditViewState extends State<WorkoutPlanEditView> {
  late final TextEditingController _nameCtrl;
  late String _icon;
  late List<WorkoutPlanExercise> _exercises;

  static const _iconOptions = [
    '🏋️','💪','🦵','🔥','⚡️','🧘','🚴','🥊','🏃','🌀','🤸','🎯','🏆','💎','🐉',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.plan?.name ?? '新しいプラン');
    _icon = widget.plan?.icon ?? '🏋️';
    _exercises = widget.plan?.exercises
            .map((e) => WorkoutPlanExercise(
                  exerciseName: e.exerciseName,
                  targetSets: e.targetSets,
                  targetReps: e.targetReps,
                  targetWeight: e.targetWeight,
                ))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final plan = WorkoutPlan(
      name: _nameCtrl.text.trim().isEmpty ? '無名プラン' : _nameCtrl.text.trim(),
      icon: _icon,
      exercises: _exercises,
    );
    if (widget.index != null) {
      WorkoutPlanStore.update(widget.index!, plan);
    } else {
      WorkoutPlanStore.add(plan);
    }
    Navigator.pop(context);
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _iconOptions.map((ic) => GestureDetector(
            onTap: () {
              setState(() => _icon = ic);
              Navigator.pop(context);
            },
            child: Container(
              width: 56,
              height: 56,
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

  Future<void> _addExercise() async {
    final selected = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const _ExercisePickerView()),
    );
    if (selected != null) {
      setState(() {
        _exercises.add(WorkoutPlanExercise(
            exerciseName: selected.name));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.plan == null ? 'プランを作成' : 'プランを編集',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存',
                style: TextStyle(
                    color: AppColors.ignite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // アイコン選択ボタン
                GestureDetector(
                  onTap: () => _showIconPicker(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(_icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'プラン名',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
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
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) {
                final pe = _exercises[i];
                final ex = ExerciseStore.findByName(pe.exerciseName);
                return _PlanExerciseTile(
                  key: ValueKey('$i-${pe.exerciseName}'),
                  planExercise: pe,
                  exercise: ex,
                  onDelete: () => setState(() => _exercises.removeAt(i)),
                  onChanged: () => setState(() {}),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ignite,
                  side: const BorderSide(color: AppColors.ignite),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('種目を追加'),
                onPressed: _addExercise,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanExerciseTile extends StatelessWidget {
  final WorkoutPlanExercise planExercise;
  final Exercise? exercise;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _PlanExerciseTile({
    super.key,
    required this.planExercise,
    required this.exercise,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icon = exercise?.icon ?? '🏋️';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(planExercise.exerciseName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 18),
                onPressed: onDelete,
              ),
              const Icon(Icons.drag_handle_rounded,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SmallCounter(
                  label: 'セット',
                  value: planExercise.targetSets,
                  onDec: () {
                    planExercise.targetSets =
                        (planExercise.targetSets - 1).clamp(1, 20);
                    onChanged();
                  },
                  onInc: () {
                    planExercise.targetSets++;
                    onChanged();
                  }),
              const SizedBox(width: 12),
              _SmallCounter(
                  label: 'レップ',
                  value: planExercise.targetReps,
                  onDec: () {
                    planExercise.targetReps =
                        (planExercise.targetReps - 1).clamp(1, 100);
                    onChanged();
                  },
                  onInc: () {
                    planExercise.targetReps++;
                    onChanged();
                  }),
              const SizedBox(width: 12),
              _SmallWeight(
                  weight: planExercise.targetWeight,
                  onDec: () {
                    planExercise.targetWeight =
                        (planExercise.targetWeight - 2.5).clamp(0, 500);
                    onChanged();
                  },
                  onInc: () {
                    planExercise.targetWeight += 2.5;
                    onChanged();
                  }),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallCounter extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _SmallCounter({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
        Row(
          children: [
            GestureDetector(
              onTap: onDec,
              child: const Icon(Icons.remove_rounded,
                  color: AppColors.textSecondary, size: 16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$value',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
            ),
            GestureDetector(
              onTap: onInc,
              child: const Icon(Icons.add_rounded,
                  color: AppColors.ignite, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallWeight extends StatelessWidget {
  final double weight;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _SmallWeight({
    required this.weight,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('重量',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Row(
          children: [
            GestureDetector(
              onTap: onDec,
              child: const Icon(Icons.remove_rounded,
                  color: AppColors.textSecondary, size: 16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(weight > 0 ? '${weight}kg' : '自重',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            GestureDetector(
              onTap: onInc,
              child: const Icon(Icons.add_rounded,
                  color: AppColors.ignite, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 種目ピッカー ──────────────────────────────────────────

class _ExercisePickerView extends StatefulWidget {
  const _ExercisePickerView();

  @override
  State<_ExercisePickerView> createState() => _ExercisePickerViewState();
}

class _ExercisePickerViewState extends State<_ExercisePickerView> {
  ExerciseCategory? _cat;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseStore.all;
    final filtered = exercises.where((e) {
      if (_cat != null && e.category != _cat) return false;
      if (_query.isNotEmpty &&
          !e.name.contains(_query)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('種目を選ぶ',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: Column(
        children: [
          // 検索
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '種目を検索',
                hintStyle:
                    const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // カテゴリフィルター
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(
                    label: 'すべて',
                    selected: _cat == null,
                    onTap: () => setState(() => _cat = null)),
                ...ExerciseCategory.values.map((c) => _Chip(
                      label: c.label,
                      selected: _cat == c,
                      onTap: () =>
                          setState(() => _cat = _cat == c ? null : c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final e = filtered[i];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(e.icon,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(e.category.label,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        ...e.topGains.take(2).map((g) => Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ignite
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(g.key.label,
                                  style: const TextStyle(
                                      color: AppColors.ignite,
                                      fontSize: 10)),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

// ── プラン実行ビュー ──────────────────────────────────────

class WorkoutPlanRunView extends StatefulWidget {
  final WorkoutPlan plan;
  const WorkoutPlanRunView({super.key, required this.plan});

  @override
  State<WorkoutPlanRunView> createState() => _WorkoutPlanRunViewState();
}

class _WorkoutPlanRunViewState extends State<WorkoutPlanRunView> {
  int _currentIndex = 0;
  bool _planDone = false;

  @override
  Widget build(BuildContext context) {
    if (_planDone) return _PlanCompleteView(plan: widget.plan);

    final pe = widget.plan.exercises[_currentIndex];
    final exercise = ExerciseStore.findByName(pe.exerciseName) ??
        Exercise(
          name: pe.exerciseName,
          icon: '🏋️',
          category: ExerciseCategory.strength,
          defaultSeconds: 60,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.plan.name,
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // プログレス
              _PlanProgress(
                current: _currentIndex,
                total: widget.plan.exercises.length,
              ),
              const SizedBox(height: 16),

              // 現在の種目
              Expanded(
                child: _PlanExerciseRunner(
                  key: ValueKey(_currentIndex),
                  exercise: exercise,
                  planExercise: pe,
                  onDone: () {
                    if (_currentIndex < widget.plan.exercises.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      setState(() => _planDone = true);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanProgress extends StatelessWidget {
  final int current;
  final int total;

  const _PlanProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('${current + 1} / $total',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (current + 1) / total,
                backgroundColor: AppColors.background,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.ignite),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanExerciseRunner extends StatelessWidget {
  final Exercise exercise;
  final WorkoutPlanExercise planExercise;
  final VoidCallback onDone;

  const _PlanExerciseRunner({
    super.key,
    required this.exercise,
    required this.planExercise,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // タイムベースならTimerViewライクに、筋トレならStrengthViewライクに
    return exercise.category == ExerciseCategory.strength
        ? _PlanStrengthRunner(
            exercise: exercise,
            planExercise: planExercise,
            onDone: onDone,
          )
        : _PlanTimerRunner(
            exercise: exercise,
            onDone: onDone,
          );
  }
}

// ── プラン内タイマー実行 ──────────────────────────────────

class _PlanTimerRunner extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onDone;

  const _PlanTimerRunner({required this.exercise, required this.onDone});

  @override
  State<_PlanTimerRunner> createState() => _PlanTimerRunnerState();
}

class _PlanTimerRunnerState extends State<_PlanTimerRunner> {
  late int _remaining;
  int _elapsed = 0;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.exercise.defaultSeconds;
  }

  void _start() {
    setState(() => _started = true);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _done) return false;
      setState(() {
        _elapsed++;
        if (_remaining > 0) {
          _remaining--;
        } else {
          _done = true;
        }
      });
      if (_done) {
        _save(true);
        return false;
      }
      return true;
    });
  }

  void _save(bool completed) {
    final gains = <String, double>{};
    for (final axis in StatAxis.values) {
      final rate = widget.exercise.gainFor(axis);
      if (rate > 0) {
        gains[axis.name] = rate *
            (_elapsed / 60.0) *
            0.05;
      }
    }
    final gainsAxisMap = {
      for (final e in gains.entries)
        StatAxis.values.firstWhere((a) => a.name == e.key): e.value
    };
    final xp = LevelSystem.xpForGains(gainsAxisMap);
    SessionStore.save(WorkoutSession(
      exerciseName: widget.exercise.name,
      exerciseIcon: widget.exercise.icon,
      targetSeconds: widget.exercise.defaultSeconds,
      actualSeconds: _elapsed,
      completed: completed,
      earnedXP: xp,
      date: DateTime.now(),
      statGains: gains,
    ));
    BodyProfile.addXP(xp);
    gains.forEach((k, v) {
      final a = StatAxis.values.firstWhere((ax) => ax.name == k);
      BodyProfile.addGain(a, v);
    });
    WorkoutEvents.emitSet(gains, xp);
  }

  @override
  Widget build(BuildContext context) {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    final timeLabel =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final progress =
        1.0 - _remaining / widget.exercise.defaultSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.exercise.icon, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(widget.exercise.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _started ? progress : 0,
                strokeWidth: 10,
                backgroundColor: AppColors.card,
                valueColor: const AlwaysStoppedAnimation(AppColors.ignite),
              ),
              Text(timeLabel,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (!_started)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ignite,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _start,
            child: const Text('スタート',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else if (_done)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ignite,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: widget.onDone,
            child: const Text('次へ',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _done = true;
              _save(false);
              widget.onDone();
            },
            child: const Text('スキップ'),
          ),
      ],
    );
  }
}

// ── プラン内筋トレ実行 ─────────────────────────────────────

class _PlanStrengthRunner extends StatefulWidget {
  final Exercise exercise;
  final WorkoutPlanExercise planExercise;
  final VoidCallback onDone;

  const _PlanStrengthRunner({
    required this.exercise,
    required this.planExercise,
    required this.onDone,
  });

  @override
  State<_PlanStrengthRunner> createState() => _PlanStrengthRunnerState();
}

class _PlanStrengthRunnerState extends State<_PlanStrengthRunner> {
  late int _sets;
  late int _reps;
  late double _weight;
  int _completedSets = 0;
  String? _prTarget;

  @override
  void initState() {
    super.initState();
    // 前回セッションからプリセット
    final prev = SessionStore.all
        .where((s) => s.exerciseName == widget.exercise.name && s.completed && s.sets != null)
        .toList();
    if (prev.isNotEmpty) {
      final last = prev.first;
      _sets = last.sets ?? widget.planExercise.targetSets;
      _reps = last.reps ?? widget.planExercise.targetReps;
      _weight = last.weight ?? widget.planExercise.targetWeight;
      // PR目標ラベル
      if ((_weight) > 0) {
        _prTarget = '目標: ${_weight + 2.5}kg (+2.5kg)';
      } else if (_reps > 0) {
        _prTarget = '目標: ${_reps + 1}回 (+1回)';
      }
    } else {
      _sets = widget.planExercise.targetSets;
      _reps = widget.planExercise.targetReps;
      _weight = widget.planExercise.targetWeight;
    }
  }

  void _logSet() {
    _completedSets++;
    if (_completedSets >= _sets) {
      _save();
      widget.onDone();
    } else {
      setState(() {});
    }
  }

  void _save() {
    final gains = <String, double>{};
    for (final axis in StatAxis.values) {
      final rate = widget.exercise.gainFor(axis);
      if (rate > 0) {
        gains[axis.name] = rate *
            _completedSets *
            (_reps / 10.0) *
            (1.0 + _weight / 100.0) *
            0.1;
      }
    }
    final gainsAxisMap = {
      for (final e in gains.entries)
        StatAxis.values.firstWhere((a) => a.name == e.key): e.value
    };
    final xp = LevelSystem.xpForGains(gainsAxisMap);
    SessionStore.save(WorkoutSession(
      exerciseName: widget.exercise.name,
      exerciseIcon: widget.exercise.icon,
      targetSeconds: 0,
      actualSeconds: 0,
      completed: true,
      earnedXP: xp,
      date: DateTime.now(),
      sets: _completedSets,
      reps: _reps,
      weight: _weight,
      statGains: gains,
    ));
    BodyProfile.addXP(xp);
    gains.forEach((k, v) {
      final a = StatAxis.values.firstWhere((ax) => ax.name == k);
      BodyProfile.addGain(a, v);
    });
    WorkoutEvents.emitSet(gains, xp);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(widget.exercise.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(widget.exercise.name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // セット進捗
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _sets,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _completedSets
                      ? AppColors.ignite
                      : AppColors.background,
                  border: Border.all(
                      color: i < _completedSets
                          ? AppColors.ignite
                          : AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_completedSets / $_sets セット',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          Text('$_reps reps  ×  ${_weight > 0 ? '${_weight}kg' : '自重'}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          if (_prTarget != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ignite.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🎯 $_prTarget',
                style: const TextStyle(color: AppColors.ignite, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ignite,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _logSet,
            child: Text(
              _completedSets < _sets - 1
                  ? 'セット ${_completedSets + 1} 完了'
                  : '最終セット完了！',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── プラン完了画面 ────────────────────────────────────────

class _PlanCompleteView extends StatelessWidget {
  final WorkoutPlan plan;
  const _PlanCompleteView({required this.plan});

  @override
  Widget build(BuildContext context) {
    final todaySessions = SessionStore.all.where((s) {
      final now = DateTime.now();
      return s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;
    }).toList();
    final totalXP = todaySessions.fold(0, (s, e) => s + e.earnedXP);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'プラン完了！',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(plan.name,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              Text(
                '+$totalXP XP',
                style: const TextStyle(
                    color: AppColors.ignite,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lv.${BodyProfile.level}  ${BodyProfile.levelTitle}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ignite,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst || r.settings.name == '/'),
                  child: const Text('ホームへ',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
