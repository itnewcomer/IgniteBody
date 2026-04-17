import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';

class SetupView extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupView({super.key, required this.onComplete});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  int _step = 0;
  BuildType _selectedBuildType = BuildType.standard;

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      BodyProfile.setBuildType(_selectedBuildType);
      BodyProfile.completeSetup();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ステップインジケーター
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _step ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _step ? AppColors.ignite : AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: 40),

              Expanded(child: _buildStep()),

              const SizedBox(height: 24),
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
                  onPressed: _next,
                  child: Text(
                    _step < 3 ? '次へ' : 'はじめる！',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepIntro();
      case 1:
        return _StepAxes();
      case 2:
        return _StepBuildType(
          selected: _selectedBuildType,
          onSelect: (bt) => setState(() => _selectedBuildType = bt),
        );
      case 3:
        return _StepEgg(buildType: _selectedBuildType);
      default:
        return const SizedBox();
    }
  }
}

// ── Step 0: イントロ ────────────────────────────────────

class _StepIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'IgniteBody へようこそ！',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // 博士キャラ + 吹き出し
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 博士アイコン
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/mr_boost.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // 吹き出し
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'わたしは博士じゃ。\nキミの体を6つの軸で分析し、\n運動するたびに成長する\nバーチャルボディを育てよう！',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                  ),
                  // 吹き出しのしっぽ（左側）
                  Positioned(
                    left: -8,
                    bottom: 16,
                    child: CustomPaint(
                      size: const Size(10, 14),
                      painter: _BubbleTailPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '✅ 筋トレ・有酸素・ストレッチを記録\n'
            '✅ 6軸のステータスが育っていく\n'
            '✅ レベルアップでペットが進化！',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.8),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E1E2E); // AppColors.card
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}

// ── Step 1: 6軸説明 ────────────────────────────────────

class _StepAxes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '6つの軸',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '運動すると対応する部位のステータスが上がります',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...StatAxis.values.map((a) => _AxisRow(axis: a)),
      ],
    );
  }
}

class _AxisRow extends StatelessWidget {
  final StatAxis axis;
  const _AxisRow({required this.axis});

  String get _description {
    switch (axis) {
      case StatAxis.chest: return '胸・大胸筋の強さ';
      case StatAxis.back: return '背中・広背筋の強さ';
      case StatAxis.shoulder: return '肩・三角筋の強さ';
      case StatAxis.arms: return '腕・上腕の強さ';
      case StatAxis.legs: return '脚・大腿四頭筋の強さ';
      case StatAxis.abs: return '腹筋・体幹の強さ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(axis.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(axis.label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                Text(_description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: ビルドタイプ選択 ────────────────────────────

class _StepBuildType extends StatelessWidget {
  final BuildType selected;
  final ValueChanged<BuildType> onSelect;

  const _StepBuildType({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ビルドタイプを選ぼう',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'あなたの目標に合ったスタイルを選ぶと\n対応する部位のゲインがアップします',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: BuildType.values.map((bt) {
              final isSelected = bt == selected;
              return GestureDetector(
                onTap: () => onSelect(bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.ignite.withValues(alpha: 0.15)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.ignite
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(bt.icon,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bt.label,
                                style: TextStyle(
                                    color: isSelected
                                        ? AppColors.ignite
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(bt.description,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.ignite),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: 卵プレビュー ────────────────────────────────

class _StepEgg extends StatelessWidget {
  final BuildType buildType;
  const _StepEgg({required this.buildType});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🥚', style: TextStyle(fontSize: 100)),
        const SizedBox(height: 24),
        const Text(
          'キミのパートナー誕生！',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'この卵は運動するたびに成長し\nやがて進化していくぞ！',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 16, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(buildType.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                buildType.label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
