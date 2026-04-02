import 'dart:async';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';

class WorkoutTimerView extends StatefulWidget {
  final Exercise exercise;
  const WorkoutTimerView({super.key, required this.exercise});

  @override
  State<WorkoutTimerView> createState() => _WorkoutTimerViewState();
}

class _WorkoutTimerViewState extends State<WorkoutTimerView> {
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
    _timer?.cancel();
    _finished = true;

    final xp = LevelSystem.xpFor(_elapsed);
    final session = WorkoutSession(
      exerciseName: widget.exercise.name,
      exerciseIcon: widget.exercise.icon,
      targetSeconds: widget.exercise.defaultSeconds,
      actualSeconds: _elapsed,
      completed: completed,
      earnedXP: xp,
      date: DateTime.now(),
    );
    SessionStore.save(session);
    BodyProfile.addXP(xp);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ResultDialog(xp: xp, completed: completed, onDone: () {
          Navigator.pop(context); // dialog
          Navigator.pop(context); // timer view
        }),
      );
    }
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // プログレスリング
              SizedBox(
                width: 220,
                height: 220,
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
              const SizedBox(height: 48),

              // もう十分ボタン（30秒以上経過で表示）
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

class _ResultDialog extends StatelessWidget {
  final int xp;
  final bool completed;
  final VoidCallback onDone;

  const _ResultDialog({required this.xp, required this.completed, required this.onDone});

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
          Text(
            '+$xp XP',
            style: const TextStyle(color: AppColors.ignite, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Lv.${BodyProfile.level}  ${BodyProfile.levelTitle}',
              style: const TextStyle(color: AppColors.textSecondary)),
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
