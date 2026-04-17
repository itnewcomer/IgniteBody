import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'models.dart';

// ── メインエントリー ──────────────────────────────────────

class WorkoutTimerView extends StatelessWidget {
  final Exercise exercise;
  const WorkoutTimerView({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return exercise.category == ExerciseCategory.strength
        ? StrengthView(exercise: exercise)
        : TimerView(exercise: exercise);
  }
}

// ── TimerView（有酸素・ストレッチ・散歩） ───────────────────

class TimerView extends StatefulWidget {
  final Exercise exercise;
  const TimerView({super.key, required this.exercise});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late int _remaining;
  int _elapsed = 0;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.exercise.defaultSeconds;
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_remaining > 0) {
          _remaining--;
        } else {
          _finish(completed: true);
        }
      });
    });
  }

  void _finish({required bool completed}) {
    if (_finished) return;
    _timer?.cancel();
    _finished = true;

    final xp = LevelSystem.xpFor(_elapsed);
    final gains = _computeGains();
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
      final axis = StatAxis.values.firstWhere((a) => a.name == k);
      BodyProfile.addGain(axis, v);
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ResultDialog(
          xp: xp,
          completed: completed,
          gains: gains,
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  Map<String, double> _computeGains() {
    final result = <String, double>{};
    for (final axis in StatAxis.values) {
      final rate = widget.exercise.gainFor(axis);
      if (rate > 0) {
        final gain = rate *
            (_elapsed / 60.0) *
            BodyProfile.buildType.multiplierFor(axis) *
            0.05;
        if (gain > 0) result[axis.name] = gain;
      }
    }
    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1.0 - (_remaining / widget.exercise.defaultSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('${widget.exercise.icon} ${widget.exercise.name}',
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          _VideoButton(exerciseName: widget.exercise.name),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220, height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: AppColors.card,
                      valueColor: const AlwaysStoppedAnimation(AppColors.ignite),
                    ),
                    Text(_timeLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('+${LevelSystem.xpFor(_elapsed)} XP',
                  style: const TextStyle(
                      color: AppColors.ignite, fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              if (_elapsed >= 30 && !_finished)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _finish(completed: false),
                  child: const Text('もう十分！'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── StrengthView（一般的な筋トレアプリ風 UI） ─────────────

class StrengthView extends StatefulWidget {
  final Exercise exercise;
  const StrengthView({super.key, required this.exercise});

  @override
  State<StrengthView> createState() => _StrengthViewState();
}

class _StrengthViewState extends State<StrengthView> {
  int _targetSets = 3;
  int _targetReps = 10;
  double _weight = 0;

  // ログ済みセット
  final List<_SetLog> _logs = [];

  // 休憩タイマー
  bool _resting = false;
  int _restSeconds = 90;
  int _restRemaining = 0;
  Timer? _restTimer;

  // PR
  double? _prevBestVolume;
  double _prevBestWeight = 0;

  // レスト中XPプレビュー
  int _previewXP = 0;

  // 前回記録サマリー
  String? _prevSummary;

  @override
  void initState() {
    super.initState();
    final prev = SessionStore.all
        .where((s) => s.exerciseName == widget.exercise.name && s.sets != null)
        .toList();
    if (prev.isNotEmpty) {
      final last = prev.first;
      _targetSets = last.sets!;
      _targetReps = last.reps!;
      _weight = last.weight ?? 0;
      _prevBestVolume = prev
          .map((s) => (s.sets ?? 0) * (s.reps ?? 0) * (s.weight ?? 1.0))
          .fold<double>(0.0, (a, b) => a > b ? a : b);
      _prevBestWeight = prev
          .map((s) => s.weight ?? 0.0)
          .fold<double>(0.0, (a, b) => a > b ? a : b);
      final w = _weight > 0 ? ' @${_weight}kg' : ' 自重';
      _prevSummary = '前回  ${_targetSets}×${_targetReps}rep$w';
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _logSet(int reps, double weight) {
    setState(() => _logs.add(_SetLog(reps: reps, weight: weight)));
    if (_logs.length < _targetSets) {
      _computePreviewXP();
      _startRest();
    } else {
      _finishWorkout();
    }
  }

  void _computePreviewXP() {
    final gains = _computeGains(_logs.length, _logs.last.reps, _logs.last.weight);
    final gainsMap = {
      for (final e in gains.entries)
        StatAxis.values.firstWhere((a) => a.name == e.key): e.value
    };
    setState(() => _previewXP = LevelSystem.xpForGains(gainsMap));
  }

  void _startRest() {
    _resting = true;
    _restRemaining = _restSeconds;
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

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _resting = false);
  }

  void _finishWorkout() {
    _restTimer?.cancel();

    final completedSets = _logs.length;
    final avgWeight = _logs.isEmpty ? 0.0
        : _logs.map((l) => l.weight).reduce((a, b) => a + b) / _logs.length;
    final totalReps = _logs.fold(0, (s, l) => s + l.reps);
    final xp = LevelSystem.xpForVolume(completedSets, totalReps ~/ completedSets, avgWeight);
    final gains = _computeGains(completedSets, totalReps ~/ completedSets, avgWeight);
    final volume = completedSets * (totalReps ~/ completedSets) * (avgWeight > 0 ? avgWeight : 1.0);

    // PR判定：重量PR優先、次にボリュームPR
    String? prMsg;
    final maxLogWeight = _logs.map((l) => l.weight).fold<double>(0.0, (a, b) => a > b ? a : b);
    if (maxLogWeight > 0 && maxLogWeight > _prevBestWeight) {
      prMsg = '重量PR 🏆';
    } else if (_prevBestVolume != null && volume > _prevBestVolume!) {
      prMsg = 'ボリュームPR 🏆';
    }

    SessionStore.save(WorkoutSession(
      exerciseName: widget.exercise.name,
      exerciseIcon: widget.exercise.icon,
      targetSeconds: 0,
      actualSeconds: 0,
      completed: true,
      earnedXP: xp,
      date: DateTime.now(),
      sets: completedSets,
      reps: totalReps ~/ completedSets,
      weight: avgWeight,
      statGains: gains,
    ));
    BodyProfile.addXP(xp);
    gains.forEach((k, v) {
      final axis = StatAxis.values.firstWhere((a) => a.name == k);
      BodyProfile.addGain(axis, v);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StrengthResultDialog(
        xp: xp,
        sets: completedSets,
        reps: totalReps ~/ completedSets,
        weight: avgWeight,
        gains: gains,
        prMessage: prMsg,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  Map<String, double> _computeGains(int sets, int reps, double weight) {
    final result = <String, double>{};
    for (final axis in StatAxis.values) {
      final rate = widget.exercise.gainFor(axis);
      if (rate > 0) {
        final gain = rate *
            sets *
            (reps / 10.0) *
            (1.0 + weight / 100.0) *
            BodyProfile.buildType.multiplierFor(axis) *
            0.1;
        if (gain > 0) result[axis.name] = gain;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final nextSetNum = _logs.length + 1;
    final isLastSet = nextSetNum == _targetSets;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('${widget.exercise.icon} ${widget.exercise.name}',
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          _VideoButton(exerciseName: widget.exercise.name),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // セットログテーブル
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // ゲインプレビュー
                    if (widget.exercise.topGains.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GainBadges(exercise: widget.exercise),
                      ),

                    // 前回記録
                    if (_prevSummary != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              _prevSummary!,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    // 動画カード
                    _VideoCard(
                      exerciseName: widget.exercise.name,
                      onLinked: () => setState(() {}),
                    ),

                    // ── テーブルヘッダー ──
                    _TableHeader(),
                    const SizedBox(height: 6),

                    // ── ログ済みセット ──
                    ..._logs.asMap().entries.map((e) =>
                        _LoggedSetRow(
                          setNum: e.key + 1,
                          log: e.value,
                        )),

                    // ── 入力中セット ──
                    if (!_resting && _logs.length < _targetSets)
                      _ActiveSetRow(
                        setNum: nextSetNum,
                        totalSets: _targetSets,
                        initialReps: _targetReps,
                        initialWeight: _weight,
                        isLast: isLastSet,
                        onLog: (reps, weight) {
                          setState(() {
                            _targetReps = reps;
                            _weight = weight;
                          });
                          _logSet(reps, weight);
                        },
                      ),

                    // ── 休憩中 ──
                    if (_resting)
                      _RestCard(
                        remaining: _restRemaining,
                        total: _restSeconds,
                        previewXP: _previewXP,
                        onSkip: _skipRest,
                        onAdjust: (delta) => setState(() {
                          _restSeconds = (_restSeconds + delta).clamp(30, 600);
                          _restRemaining = (_restRemaining + delta).clamp(0, 600);
                        }),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // ── セット数調整バー（下部固定） ──
            _BottomBar(
              targetSets: _targetSets,
              completedSets: _logs.length,
              onSetsMinus: () => setState(() => _targetSets = (_targetSets - 1).clamp(_logs.length + 1, 20)),
              onSetsPlus: () => setState(() => _targetSets++),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetLog {
  final int reps;
  final double weight;
  _SetLog({required this.reps, required this.weight});
}

// ── テーブルヘッダー ──────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('SET', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(child: Text('重量 (kg)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 12),
          Expanded(child: Text('回数 (reps)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 48), // チェックボタン分
        ],
      ),
    );
  }
}

// ── ログ済みセット行 ──────────────────────────────────────

class _LoggedSetRow extends StatelessWidget {
  final int setNum;
  final _SetLog log;
  const _LoggedSetRow({required this.setNum, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                    fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              log.weight > 0 ? log.weight.toStringAsFixed(1) : '自重',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${log.reps}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check_circle_rounded, color: AppColors.ignite, size: 28),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── 入力中セット行 ────────────────────────────────────────

class _ActiveSetRow extends StatefulWidget {
  final int setNum;
  final int totalSets;
  final int initialReps;
  final double initialWeight;
  final bool isLast;
  final void Function(int reps, double weight) onLog;

  const _ActiveSetRow({
    required this.setNum,
    required this.totalSets,
    required this.initialReps,
    required this.initialWeight,
    required this.isLast,
    required this.onLog,
  });

  @override
  State<_ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<_ActiveSetRow> {
  late int _reps;
  late double _weight;

  @override
  void initState() {
    super.initState();
    _reps = widget.initialReps;
    _weight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ignite.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // セット番号
          SizedBox(
            width: 36,
            child: Text('${widget.setNum}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),

          // 重量スピナー
          Expanded(
            child: _Spinner(
              value: _weight > 0 ? _weight.toStringAsFixed(1) : '自重',
              onDec: () => setState(() => _weight = (_weight - 2.5).clamp(0, 500)),
              onInc: () => setState(() => _weight += 2.5),
            ),
          ),
          const SizedBox(width: 12),

          // 回数スピナー
          Expanded(
            child: _Spinner(
              value: '$_reps',
              onDec: () => setState(() => _reps = (_reps - 1).clamp(1, 999)),
              onInc: () => setState(() => _reps++),
            ),
          ),
          const SizedBox(width: 4),

          // 完了ボタン
          GestureDetector(
            onTap: () => widget.onLog(_reps, _weight),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.ignite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 4),
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
  const _Spinner({required this.value, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDec,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.remove_rounded, color: AppColors.textSecondary, size: 18),
          ),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        GestureDetector(
          onTap: onInc,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.ignite, size: 18),
          ),
        ),
      ],
    );
  }
}

// ── 休憩カード ────────────────────────────────────────────

class _RestCard extends StatelessWidget {
  final int remaining;
  final int total;
  final int previewXP;
  final VoidCallback onSkip;
  final void Function(int) onAdjust;

  const _RestCard({
    required this.remaining,
    required this.total,
    required this.previewXP,
    required this.onSkip,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    final label = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final ratio = total > 0 ? remaining / total : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('💤 休憩中',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              TextButton(
                onPressed: onSkip,
                child: const Text('スキップ →',
                    style: TextStyle(color: AppColors.ignite, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.ignite),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustBtn(label: '-30秒', onTap: () => onAdjust(-30)),
              const SizedBox(width: 12),
              _AdjustBtn(label: '+30秒', onTap: () => onAdjust(30)),
            ],
          ),
          if (previewXP > 0) ...[
            const SizedBox(height: 8),
            Text(
              'このまま終わると +$previewXP XP',
              style: const TextStyle(color: AppColors.ignite, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjustBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

// ── ゲインバッジ ──────────────────────────────────────────

class _GainBadges extends StatelessWidget {
  final Exercise exercise;
  const _GainBadges({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final top = exercise.topGains;
    return Row(
      children: [
        const Text('主なゲイン：',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ...top.map((g) => Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.ignite.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(g.key.label,
                  style: const TextStyle(color: AppColors.ignite, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }
}

// ── 下部バー（セット数調整） ──────────────────────────────

class _BottomBar extends StatelessWidget {
  final int targetSets;
  final int completedSets;
  final VoidCallback onSetsMinus;
  final VoidCallback onSetsPlus;

  const _BottomBar({
    required this.targetSets,
    required this.completedSets,
    required this.onSetsMinus,
    required this.onSetsPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('目標セット数：',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          GestureDetector(
            onTap: onSetsMinus,
            child: const Icon(Icons.remove_circle_outline_rounded,
                color: AppColors.textSecondary, size: 28),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$targetSets',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: onSetsPlus,
            child: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.ignite, size: 28),
          ),
          const SizedBox(width: 16),
          Text('（$completedSets 完了）',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── 結果ダイアログ（タイマー系） ──────────────────────────

class _ResultDialog extends StatelessWidget {
  final int xp;
  final bool completed;
  final Map<String, double> gains;
  final VoidCallback onDone;

  const _ResultDialog({
    required this.xp,
    required this.completed,
    required this.gains,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        completed ? '完了！🎉' : 'お疲れ様！💪',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+$xp XP',
              style: const TextStyle(
                  color: AppColors.ignite, fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lv.${BodyProfile.level}  ${BodyProfile.levelTitle}',
              style: const TextStyle(color: AppColors.textSecondary)),
          if (gains.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.background),
            ...gains.entries.map((e) {
              final axis = StatAxis.values.firstWhere((a) => a.name == e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${axis.icon} ${axis.label}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('+${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.ignite, fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDone,
          child: const Text('閉じる', style: TextStyle(color: AppColors.ignite)),
        ),
      ],
    );
  }
}

// ── 結果ダイアログ（筋トレ系） ────────────────────────────

class _StrengthResultDialog extends StatelessWidget {
  final int xp;
  final int sets;
  final int reps;
  final double weight;
  final Map<String, double> gains;
  final String? prMessage;
  final VoidCallback onDone;

  const _StrengthResultDialog({
    required this.xp,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.gains,
    required this.prMessage,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        prMessage != null ? '$prMessage' : 'ワークアウト完了！💪',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('+$xp XP',
                style: const TextStyle(
                    color: AppColors.ignite, fontSize: 36,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '$sets セット × $reps rep${weight > 0 ? '  @${weight}kg' : '  自重'}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          if (gains.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.background),
            ...gains.entries.map((e) {
              final axis = StatAxis.values.firstWhere((a) => a.name == e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${axis.icon} ${axis.label}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('+${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.ignite, fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDone,
          child: const Text('閉じる', style: TextStyle(color: AppColors.ignite)),
        ),
      ],
    );
  }
}

// ── 動画カード（セット画面内） ────────────────────────────────

class _VideoCard extends StatelessWidget {
  final String exerciseName;
  final VoidCallback onLinked;
  const _VideoCard({required this.exerciseName, required this.onLinked});

  void _addVideo(BuildContext context) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('動画を追加',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'URL',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'https://youtu.be/...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.textSecondary)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.ignite)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'タイトル（省略可）',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.textSecondary)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.ignite)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              final v = VideoEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: titleCtrl.text.trim().isEmpty
                    ? url
                    : titleCtrl.text.trim(),
                exerciseNames: [exerciseName],
              );
              VideoStore.save(v);
              onLinked();
              Navigator.pop(ctx);
            },
            child: const Text('追加',
                style: TextStyle(color: AppColors.ignite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = VideoStore.forExercise(exerciseName);

    if (videos.isEmpty) {
      // 動画なし：薄い追加ボタン
      return GestureDetector(
        onTap: () => _addVideo(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('▶', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              SizedBox(width: 6),
              Text('動画を追加',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    // 動画あり：各動画をタップで開けるチップ列
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: videos.map((v) => GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(v.url);
            if (uri != null) {
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.ignite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.ignite.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('▶',
                    style: TextStyle(
                        color: AppColors.ignite, fontSize: 11)),
                const SizedBox(width: 5),
                Text(
                  v.title,
                  style: const TextStyle(
                      color: AppColors.ignite, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ── 動画ボタン（1本 or 複数対応）────────────────────────────

class _VideoButton extends StatelessWidget {
  final String exerciseName;
  const _VideoButton({required this.exerciseName});

  Future<void> _open(BuildContext context) async {
    final videos = VideoStore.forExercise(exerciseName);
    if (videos.isEmpty) return;
    if (videos.length == 1) {
      final uri = Uri.tryParse(videos.first.url);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    // 複数あるときは選択シート
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('動画を選択',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...videos.map((v) => ListTile(
                  leading: const Text('▶',
                      style: TextStyle(
                          color: AppColors.ignite, fontSize: 18)),
                  title: Text(v.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: Text(v.url,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.tryParse(v.url);
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = VideoStore.forExercise(exerciseName);
    if (videos.isEmpty) return const SizedBox();
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Text('▶', style: TextStyle(fontSize: 13)),
      label: Text(
        videos.length > 1 ? '動画(${videos.length})' : '動画',
        style: const TextStyle(color: AppColors.ignite, fontSize: 13),
      ),
      style: TextButton.styleFrom(foregroundColor: AppColors.ignite),
    );
  }
}
