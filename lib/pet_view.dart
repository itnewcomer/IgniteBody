import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';

// ── ペットの進化段階 ─────────────────────────────────────

class PetEvolution {
  static String emoji(int level, StatAxis dominant) {
    if (level == 0) return '🥚';
    if (level == 1) return _stage1(dominant);
    if (level <= 3) return _stage2(dominant);
    if (level <= 5) return _stage3(dominant);
    if (level <= 7) return _stage4(dominant);
    return _stage5(dominant);
  }

  static String _stage1(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '🐣';
      case StatAxis.back: return '🐣';
      case StatAxis.shoulder: return '🐣';
      case StatAxis.arms: return '🐣';
      case StatAxis.legs: return '🐣';
      case StatAxis.abs: return '🐣';
    }
  }

  static String _stage2(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '🐥';
      case StatAxis.back: return '🐦';
      case StatAxis.shoulder: return '🦆';
      case StatAxis.arms: return '🦁';
      case StatAxis.legs: return '🐺';
      case StatAxis.abs: return '🐊';
    }
  }

  static String _stage3(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '🦅';
      case StatAxis.back: return '🦅';
      case StatAxis.shoulder: return '🦉';
      case StatAxis.arms: return '🐯';
      case StatAxis.legs: return '🐉';
      case StatAxis.abs: return '🦖';
    }
  }

  static String _stage4(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return '⚡';
      case StatAxis.back: return '🌩️';
      case StatAxis.shoulder: return '✨';
      case StatAxis.arms: return '🔥';
      case StatAxis.legs: return '💨';
      case StatAxis.abs: return '🌀';
    }
  }

  static String _stage5(StatAxis dominant) {
    return '🌟';
  }

  static String name(int level, StatAxis dominant) {
    if (level == 0) return '???';
    if (level == 1) return 'ベビー';
    if (level <= 3) {
      switch (dominant) {
        case StatAxis.chest: return 'チェスター';
        case StatAxis.back: return 'バッカー';
        case StatAxis.shoulder: return 'ショルダー';
        case StatAxis.arms: return 'アームズ';
        case StatAxis.legs: return 'レガシー';
        case StatAxis.abs: return 'コアラ';
      }
    }
    if (level <= 5) {
      switch (dominant) {
        case StatAxis.chest: return 'チェスタードラゴン';
        case StatAxis.back: return 'バックビースト';
        case StatAxis.shoulder: return 'ショルダーウィング';
        case StatAxis.arms: return 'アームタイガー';
        case StatAxis.legs: return 'レッグドレイク';
        case StatAxis.abs: return 'コアゴン';
      }
    }
    if (level <= 7) return '${_stage4Label(dominant)}・改';
    return 'IGNIS MAXIMUS';
  }

  static String _stage4Label(StatAxis dominant) {
    switch (dominant) {
      case StatAxis.chest: return 'サンダーバード';
      case StatAxis.back: return 'ストームレイヴン';
      case StatAxis.shoulder: return 'オーラフェニックス';
      case StatAxis.arms: return 'ブレイズタイガー';
      case StatAxis.legs: return 'テンペストウルフ';
      case StatAxis.abs: return 'サイクロンビースト';
    }
  }

  static String message(int level) {
    if (level == 0) return '...zzz';
    if (level == 1) return 'がんばってるね！';
    if (level <= 3) return '一緒に鍛えよう！';
    if (level <= 5) return '調子いいじゃないか！';
    if (level <= 7) return 'すごい成長だ！';
    return 'キミは本物のレジェンド！';
  }
}

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
