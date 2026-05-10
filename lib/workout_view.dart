import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';
import 'pet_view.dart';
import 'workout_timer_view.dart';

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

  String _formatDate(DateTime d) {
    const wdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${d.month}/${d.day}(${wdays[d.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '記録',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              tabs: const [Tab(text: '今日'), Tab(text: '履歴')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [_TodayTab(), _HistoryTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 今日のタブ ─────────────────────────────────────────────

class _TodayTab extends StatefulWidget {
  const _TodayTab();

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  final List<String> _exerciseNames = [];

  @override
  void initState() {
    super.initState();
    _mergeFromHive();
  }

  void _mergeFromHive() {
    final today = DateTime.now();
    final sessions = SessionStore.all
        .where((s) =>
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final s in sessions) {
      if (!_exerciseNames.contains(s.exerciseName)) {
        _exerciseNames.add(s.exerciseName);
      }
    }
  }

  Future<void> _addExercise() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ExercisePickerSheet(),
    );
    if (exercise == null || !mounted) return;

    if (exercise.category != ExerciseCategory.strength) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkoutTimerView(exercise: exercise)),
      );
      if (mounted) setState(() => _mergeFromHive());
      return;
    }

    setState(() {
      if (!_exerciseNames.contains(exercise.name)) {
        _exerciseNames.add(exercise.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WorkoutPetHeader(),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box('sessions').listenable(),
            builder: (context, box, child) {
              // Hiveに今日のセッションが増えたら同期（他画面から記録された場合も対応）
              final today = DateTime.now();
              final todaySessions = SessionStore.all
                  .where((s) =>
                      s.date.year == today.year &&
                      s.date.month == today.month &&
                      s.date.day == today.day)
                  .toList();
              for (final s in todaySessions) {
                if (!_exerciseNames.contains(s.exerciseName)) {
                  _exerciseNames.add(s.exerciseName);
                }
              }

              return Stack(
                children: [
                  _exerciseNames.isEmpty
                      ? _EmptyTodayState(onAdd: _addExercise)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _exerciseNames.length,
                          itemBuilder: (_, i) {
                            final name = _exerciseNames[i];
                            final exercise = ExerciseStore.findByName(name);
                            if (exercise == null) return const SizedBox();
                            return _ExerciseLogCard(
                              key: ValueKey(name),
                              exercise: exercise,
                              onRemove: () => setState(
                                  () => _exerciseNames.remove(name)),
                            );
                          },
                        ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ignite,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('種目を追加',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _addExercise,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 空の状態 ──────────────────────────────────────────────

class _EmptyTodayState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTodayState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💪', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('今日のトレーニングを始めよう',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('下のボタンから種目を追加してセットを記録しよう',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── 種目ログカード ─────────────────────────────────────────

class _ExerciseLogCard extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onRemove;

  const _ExerciseLogCard(
      {super.key, required this.exercise, required this.onRemove});

  @override
  State<_ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends State<_ExerciseLogCard> {
  late int _reps;
  late double _weight;
  bool _resting = false;
  int _restRemaining = 90;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    final prev = SessionStore.all
        .where((s) =>
            s.exerciseName == widget.exercise.name && s.setDetails.isNotEmpty)
        .toList();
    if (prev.isNotEmpty) {
      final lastSet = prev.first.setDetails.last;
      _reps = (lastSet['reps'] as int?) ?? 10;
      _weight = (lastSet['weight'] as num?)?.toDouble() ?? 0;
    } else {
      _reps = 10;
      _weight = 0;
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _todaySets {
    final today = DateTime.now();
    final sessions = SessionStore.all
        .where((s) =>
            s.exerciseName == widget.exercise.name &&
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return sessions.expand((s) => s.setDetails).toList();
  }

  String? get _prLabel {
    double best = 0;
    for (final s in SessionStore.all
        .where((s) => s.exerciseName == widget.exercise.name)) {
      for (final set in s.setDetails) {
        final w = (set['weight'] as num?)?.toDouble() ?? 0;
        if (w > best) best = w;
      }
    }
    return best > 0 ? 'ベスト: ${best}kg' : null;
  }

  void _logSet() {
    final today = DateTime.now();
    final box = Hive.box('sessions');
    int? existingIdx;
    WorkoutSession? existing;

    for (int i = 0; i < box.length; i++) {
      final s = WorkoutSession.fromMap(box.getAt(i) as Map);
      if (s.exerciseName == widget.exercise.name &&
          s.date.year == today.year &&
          s.date.month == today.month &&
          s.date.day == today.day) {
        existingIdx = i;
        existing = s;
        break;
      }
    }

    final newSet = <String, dynamic>{'reps': _reps, 'weight': _weight};
    final allSets = [...?existing?.setDetails, newSet];
    // このセット単体のゲインを計算 → XPはゲイン合計から導出
    final setGains = _computeGains(1, _reps, _weight);
    final gainsAxisMap = {
      for (final e in setGains.entries)
        StatAxis.values.firstWhere((a) => a.name == e.key): e.value
    };
    final xp = LevelSystem.xpForGains(gainsAxisMap);
    // 永続化用：セッション全体の累積ゲインも計算
    final gains = _computeGains(allSets.length, _reps, _weight);

    final session = WorkoutSession(
      exerciseName: widget.exercise.name,
      exerciseIcon: widget.exercise.icon,
      targetSeconds: 0,
      actualSeconds: 0,
      completed: true,
      earnedXP: (existing?.earnedXP ?? 0) + xp,
      date: existing?.date ?? today,
      sets: allSets.length,
      reps: _reps,
      weight: _weight,
      statGains: gains,
      setDetails: allSets,
    );

    if (existingIdx != null) {
      box.putAt(existingIdx, session.toMap());
    } else {
      box.add(session.toMap());
    }

    BodyProfile.addXP(xp);
    // 加算するゲインは「このセット単体の差分」だけ（累積ではない）
    setGains.forEach((k, v) {
      final axis = StatAxis.values.firstWhere((a) => a.name == k);
      BodyProfile.addGain(axis, v);
    });
    WorkoutEvents.emitSet(setGains, xp);

    setState(() {
      _resting = true;
      _restRemaining = 90;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_restRemaining > 0) {
          _restRemaining--;
        } else {
          _resting = false;
          _restTimer?.cancel();
        }
      });
    });
  }

  Map<String, double> _computeGains(int sets, int reps, double weight) {
    final result = <String, double>{};
    for (final axis in StatAxis.values) {
      final rate = widget.exercise.gainFor(axis);
      if (rate > 0) {
        final g = rate *
            sets *
            (reps / 10.0) *
            (1.0 + weight / 100.0) *
            0.1;
        if (g > 0) result[axis.name] = g;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sets = _todaySets;
    final pr = _prLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Text(widget.exercise.icon,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.exercise.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      if (pr != null)
                        Text(pr,
                            style: const TextStyle(
                                color: AppColors.ignite, fontSize: 11)),
                    ],
                  ),
                ),
                // 部位バッジ
                ...widget.exercise.topGains.take(2).map((g) => Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.ignite.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(g.key.label,
                          style: const TextStyle(
                              color: AppColors.ignite, fontSize: 10)),
                    )),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // テーブルヘッダー
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text('SET',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(
                    child: Text('重量 (kg)',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('回数',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(width: 46),
              ],
            ),
          ),

          // ログ済みセット
          ...sets.asMap().entries.map((e) => _LoggedRow(
                setNum: e.key + 1,
                weight: (e.value['weight'] as num?)?.toDouble() ?? 0,
                reps: (e.value['reps'] as int?) ?? 0,
              )),

          // 休憩 or 入力行
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
            child: _resting
                ? _InlineRest(
                    remaining: _restRemaining,
                    onSkip: () {
                      _restTimer?.cancel();
                      setState(() => _resting = false);
                    },
                    onAdjust: (delta) => setState(() {
                      _restRemaining =
                          (_restRemaining + delta).clamp(0, 600);
                      if (_restRemaining == 0) {
                        _resting = false;
                        _restTimer?.cancel();
                      }
                    }),
                  )
                : _InputRow(
                    setNum: sets.length + 1,
                    reps: _reps,
                    weight: _weight,
                    onRepsChanged: (v) => setState(() => _reps = v),
                    onWeightChanged: (v) => setState(() => _weight = v),
                    onLog: _logSet,
                  ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── ログ済み行 ────────────────────────────────────────────

class _LoggedRow extends StatelessWidget {
  final int setNum;
  final double weight;
  final int reps;

  const _LoggedRow(
      {required this.setNum, required this.weight, required this.reps});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.ignite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text('$setNum',
                  style: const TextStyle(
                      color: AppColors.ignite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(weight > 0 ? weight.toStringAsFixed(1) : '自重',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(
              child: Text('$reps',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.ignite, size: 24),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

// ── 入力行 ────────────────────────────────────────────────

class _InputRow extends StatelessWidget {
  final int setNum;
  final int reps;
  final double weight;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onLog;

  const _InputRow({
    required this.setNum,
    required this.reps,
    required this.weight,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ignite.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text('$setNum',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(
            child: _Spinner(
              value: weight > 0 ? weight.toStringAsFixed(1) : '自重',
              onDec: () => onWeightChanged((weight - 2.5).clamp(0, 500)),
              onInc: () => onWeightChanged(weight + 2.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Spinner(
              value: '$reps',
              onDec: () => onRepsChanged((reps - 1).clamp(1, 999)),
              onInc: () => onRepsChanged(reps + 1),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onLog,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  color: AppColors.ignite,
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.check_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── スピナー ──────────────────────────────────────────────

class _Spinner extends StatelessWidget {
  final String value;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _Spinner(
      {required this.value, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDec,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.remove_rounded,
                color: AppColors.textSecondary, size: 16),
          ),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
        GestureDetector(
          onTap: onInc,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.add_rounded,
                color: AppColors.ignite, size: 16),
          ),
        ),
      ],
    );
  }
}

// ── インライン休憩タイマー ─────────────────────────────────

class _InlineRest extends StatelessWidget {
  final int remaining;
  final VoidCallback onSkip;
  final void Function(int) onAdjust;

  const _InlineRest(
      {required this.remaining,
      required this.onSkip,
      required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ignite.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ignite.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('💤', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onAdjust(-30),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('-30',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onAdjust(30),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('+30',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero),
            child: const Text('スキップ',
                style:
                    TextStyle(color: AppColors.ignite, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── 種目ピッカーシート ─────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
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
    final exercises = ExerciseStore.active;
    final filtered = exercises.where((e) {
      if (_cat != null && e.category != _cat) return false;
      if (_query.isNotEmpty && !e.name.contains(_query)) return false;
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('種目を選ぶ',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                    label: 'すべて',
                    selected: _cat == null,
                    onTap: () => setState(() => _cat = null)),
                ...ExerciseCategory.values.map((c) => _FilterChip(
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
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final e = filtered[i];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Text(e.icon,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(e.category.label,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ignite.withValues(alpha: 0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.ignite : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    selected ? AppColors.ignite : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal)),
      ),
    );
  }
}

// ── 履歴タブ ──────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sessions').listenable(),
      builder: (context, box, child) {
        final sessions = SessionStore.all;
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('まだ記録がありません',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        // 日付ごとにグループ化
        final Map<String, List<WorkoutSession>> byDate = {};
        for (final s in sessions) {
          final key =
              '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
          byDate.putIfAbsent(key, () => []).add(s);
        }

        // 同日・同種目は setDetails が最多のものだけ残す
        final dedupByDate = <String, List<WorkoutSession>>{};
        for (final entry in byDate.entries) {
          final map = <String, WorkoutSession>{};
          for (final s in entry.value) {
            final existing = map[s.exerciseName];
            if (existing == null ||
                s.setDetails.length > existing.setDetails.length) {
              map[s.exerciseName] = s;
            }
          }
          dedupByDate[entry.key] = map.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        }

        final dates = dedupByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: dates.length,
          itemBuilder: (_, i) => _WorkoutDayCard(
            dateKey: dates[i],
            sessions: dedupByDate[dates[i]]!,
          ),
        );
      },
    );
  }
}

class _WorkoutDayCard extends StatelessWidget {
  final String dateKey;
  final List<WorkoutSession> sessions;

  const _WorkoutDayCard(
      {required this.dateKey, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final label =
        '${date.month}/${date.day}(${weekdays[date.weekday - 1]})';
    final totalXP = sessions.fold(0, (s, e) => s + e.earnedXP);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('+$totalXP XP',
                  style: const TextStyle(
                      color: AppColors.ignite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${sessions.length}種目',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.background, height: 1),
          const SizedBox(height: 8),
          ...sessions.map((s) {
            final setsCount = s.setDetails.isNotEmpty
                ? s.setDetails.length
                : s.sets ?? 0;
            // 最大重量
            double bestW = 0;
            for (final set in s.setDetails) {
              final w = (set['weight'] as num?)?.toDouble() ?? 0;
              if (w > bestW) bestW = w;
            }
            if (bestW == 0 && s.weight != null) bestW = s.weight!;

            final detail = s.actualSeconds > 0
                ? '${(s.actualSeconds / 60).toStringAsFixed(0)}分'
                : setsCount > 0
                    ? '$setsCount セット${bestW > 0 ? '  ${bestW}kg' : ''}'
                    : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(s.exerciseIcon,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.exerciseName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  Text(detail,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
