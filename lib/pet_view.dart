import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';

// ── WalkingPetView（アニメーション） ──────────────────────

class WalkingPetView extends StatefulWidget {
  final String emoji;
  final double size;

  const WalkingPetView({super.key, required this.emoji, this.size = 72});

  @override
  State<WalkingPetView> createState() => _WalkingPetViewState();
}

class _WalkingPetViewState extends State<WalkingPetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;
  late final Animation<double> _sway;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _bounce = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _sway = Tween<double>(begin: -0.05, end: 0.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Transform.rotate(
          angle: _sway.value,
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size),
          ),
        ),
      ),
    );
  }
}

// ── EggWobbleView ─────────────────────────────────────────

class EggWobbleView extends StatefulWidget {
  const EggWobbleView({super.key});

  @override
  State<EggWobbleView> createState() => _EggWobbleViewState();
}

class _EggWobbleViewState extends State<EggWobbleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _wobble;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _wobble = Tween<double>(begin: -0.1, end: 0.1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _wobble.value,
        child: const Text('🥚', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}

// ── WorkoutPetHeader（記録タブ上部、セット記録のたびに反応） ──

class WorkoutPetHeader extends StatefulWidget {
  const WorkoutPetHeader({super.key});

  @override
  State<WorkoutPetHeader> createState() => _WorkoutPetHeaderState();
}

class _WorkoutPetHeaderState extends State<WorkoutPetHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  int _lastSeq = 0;
  WorkoutEvent? _shownEvent;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WorkoutEvents.lastEvent.addListener(_onEvent);
  }

  void _onEvent() {
    final e = WorkoutEvents.lastEvent.value;
    if (e == null || e.sequence == _lastSeq) return;
    _lastSeq = e.sequence;
    setState(() => _shownEvent = e);
    _bounceCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      // バブルが出ていない（新しいイベントが来ていない）場合のみクリア
      if (_shownEvent?.sequence == e.sequence) {
        setState(() => _shownEvent = null);
      }
    });
  }

  @override
  void dispose() {
    WorkoutEvents.lastEvent.removeListener(_onEvent);
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('profile').listenable(),
      builder: (context, _, __) {
        final level = BodyProfile.level;
        final dominant = BodyProfile.dominantStat;
        final emoji = PetEvolution.emoji(level, dominant);
        final name = PetEvolution.name(level, dominant);
        final xp = BodyProfile.totalXP;
        final progress = BodyProfile.levelProgress.clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.ignite.withValues(alpha: 0.25)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  // バウンスするペット
                  AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (_, __) {
                      final t = _bounceCtrl.value;
                      final pulse = math.sin(math.pi * t);
                      final scale = 1.0 + 0.3 * pulse;
                      final translateY = -14.0 * pulse;
                      final rotate = 0.08 * math.sin(math.pi * 2 * t);
                      return SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(0, translateY),
                            child: Transform.rotate(
                              angle: rotate,
                              child: Transform.scale(
                                scale: scale,
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 40)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text('Lv.$level  $xp XP',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.ignite),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ゲインバブル：ペットの上にポップして上に流れる
              if (_shownEvent != null)
                Positioned(
                  left: 0,
                  top: -4,
                  child: AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (_, __) {
                      final t = _bounceCtrl.value;
                      final opacity =
                          (1.0 - t * 1.1).clamp(0.0, 1.0).toDouble();
                      final dy = -20.0 * t;
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: _GainBubble(event: _shownEvent!),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GainBubble extends StatelessWidget {
  final WorkoutEvent event;
  const _GainBubble({required this.event});

  @override
  Widget build(BuildContext context) {
    final top = event.gains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(2).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ignite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ignite.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...shown.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${e.key.icon}+${e.value.toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              )),
          Text('+${event.xp} XP',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── EvolutionScreen（レベルアップ時のフルスクリーン演出） ──

class EvolutionScreen extends StatefulWidget {
  final LevelUpEvent event;
  const EvolutionScreen({super.key, required this.event});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _canDismiss = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _canDismiss = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final oldEmoji = PetEvolution.emoji(e.fromLevel, e.dominant);
    final newEmoji = PetEvolution.emoji(e.toLevel, e.dominant);
    final oldName = PetEvolution.name(e.fromLevel, e.dominant);
    final newName = PetEvolution.name(e.toLevel, e.dominant);
    final isStageChange = oldEmoji != newEmoji;
    final headline = isStageChange ? '進化！' : 'レベルアップ！';

    return GestureDetector(
      onTap: _canDismiss ? () => Navigator.of(context).pop() : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          const preEnd = 0.25;
          const flashEnd = 0.40;

          final darkOpacity = math.min(0.92, t * 4);
          final oldOpacity = t < preEnd
              ? 1.0
              : t < flashEnd
                  ? 1.0 - (t - preEnd) / (flashEnd - preEnd)
                  : 0.0;
          final oldPulse = t < preEnd
              ? 1.0 + 0.18 * math.sin(t / preEnd * math.pi * 3)
              : 1.0;
          final flashOpacity = t > preEnd && t < flashEnd + 0.05
              ? math.sin((t - preEnd) / (flashEnd - preEnd + 0.05) * math.pi)
              : 0.0;
          final newProg =
              t < flashEnd ? 0.0 : math.min(1.0, (t - flashEnd) / 0.35);
          final newScale = newProg;
          final newRot = (1 - newProg) * math.pi;
          final sparkleProg = t > flashEnd + 0.15
              ? math.min(1.0, (t - flashEnd - 0.15) / 0.5)
              : 0.0;

          return Container(
            color: Colors.black.withValues(alpha: darkOpacity),
            child: Stack(
              children: [
                // 放射状の光
                Center(
                  child: Opacity(
                    opacity: newProg,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.ignite.withValues(alpha: 0.5),
                            AppColors.ignite.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 上部：見出し
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: newProg,
                    child: Column(
                      children: [
                        Text(
                          headline,
                          style: const TextStyle(
                            color: AppColors.ignite,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lv.${e.fromLevel} → Lv.${e.toLevel}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ペット中央
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (oldOpacity > 0)
                        Opacity(
                          opacity: oldOpacity,
                          child: Transform.scale(
                            scale: oldPulse,
                            child: Text(oldEmoji,
                                style: const TextStyle(fontSize: 120)),
                          ),
                        ),
                      if (newProg > 0)
                        Transform.scale(
                          scale: newScale,
                          child: Transform.rotate(
                            angle: newRot,
                            child: Text(newEmoji,
                                style: const TextStyle(fontSize: 140)),
                          ),
                        ),
                      if (sparkleProg > 0) ..._buildSparkles(sparkleProg),
                    ],
                  ),
                ),
                // フラッシュ
                if (flashOpacity > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: flashOpacity),
                      ),
                    ),
                  ),
                // ペット名
                Positioned(
                  bottom: 140,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: newProg,
                    child: Column(
                      children: [
                        Text(
                          newName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isStageChange && oldName != newName) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$oldName より進化',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_canDismiss)
                  const Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '画面をタップして閉じる',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSparkles(double progress) {
    const count = 8;
    return List.generate(count, (i) {
      final angle = (i / count) * math.pi * 2;
      final radius = 80 + 80 * progress;
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final scale = 0.3 + 0.7 * progress;
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: const Text('✨', style: TextStyle(fontSize: 28)),
          ),
        ),
      );
    });
  }
}

// ── PetCard（ホームに表示するカード） ────────────────────

class PetCard extends StatelessWidget {
  const PetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final level = BodyProfile.level;
    final dominant = BodyProfile.dominantStat;
    final petEmoji = PetEvolution.emoji(level, dominant);
    final petName = PetEvolution.name(level, dominant);
    final msg = PetEvolution.message(level);
    final xp = BodyProfile.totalXP;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.ignite.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lv.$level  ${BodyProfile.levelTitle}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ignite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$xp XP',
                  style: const TextStyle(
                      color: AppColors.ignite,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          level == 0
              ? const EggWobbleView()
              : WalkingPetView(emoji: petEmoji),
          const SizedBox(height: 12),
          // 吹き出し
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              msg,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          // XPプログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: BodyProfile.levelProgress.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.ignite),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lv.$level',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text(
                level < LevelSystem.thresholds.length - 1
                    ? 'Lv.${level + 1} まで ${LevelSystem.thresholds[level + 1] - xp} XP'
                    : 'MAX LEVEL',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
