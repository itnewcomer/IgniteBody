import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'models.dart';
import 'pet_view.dart';
import 'workout_timer_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('profile').listenable(),
      builder: (context, _, __) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pet Reps',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ペットカード
                const PetCard(),
                const SizedBox(height: 16),

                // 6軸ミニステータス
                const _MiniStats(),
                const SizedBox(height: 16),

                // 今日のサマリー
                const _TodaySummary(),
                const SizedBox(height: 16),

                // クイックスタート
                const Text(
                  'クイックスタート',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const _QuickStartButtons(),
                const SizedBox(height: 16),

                // よく使う種目
                const _FrequentExercises(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── ミニ6軸ステータス ─────────────────────────────────────

class _MiniStats extends StatelessWidget {
  const _MiniStats();

  @override
  Widget build(BuildContext context) {
    final stats = StatAxis.values.map((a) => BodyProfile.getStat(a)).toList();
    final maxStat = stats.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ステータス',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          ...StatAxis.values.asMap().entries.map((entry) {
            final axis = entry.value;
            final val = stats[entry.key];
            final ratio = maxStat > 0 ? (val / maxStat).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(axis.icon,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(axis.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.background,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.ignite),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      val.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 今日のサマリー ────────────────────────────────────────

class _TodaySummary extends StatelessWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sessions').listenable(),
      builder: (context, _, __) {
        final today = DateTime.now();
        final todaySessions = SessionStore.all.where((s) {
          final d = s.date;
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).toList();

        if (todaySessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('💤', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text('今日はまだ動いていない',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        final totalXP = todaySessions.fold(0, (s, e) => s + e.earnedXP);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('今日のワークアウト',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Text('+$totalXP XP',
                      style: const TextStyle(
                          color: AppColors.ignite,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ...todaySessions.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(s.exerciseIcon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.exerciseName,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13)),
                        ),
                        Text('+${s.earnedXP}XP',
                            style: const TextStyle(
                                color: AppColors.ignite, fontSize: 12)),
                      ],
                    ),
                  )),
              if (todaySessions.length > 3)
                Text('他 ${todaySessions.length - 3} 件',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

// ── クイックスタートボタン ─────────────────────────────────

class _QuickStartButtons extends StatelessWidget {
  const _QuickStartButtons();

  @override
  Widget build(BuildContext context) {
    final active = ExerciseStore.active;
    if (active.isEmpty) return const SizedBox();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ignite,
          side: const BorderSide(color: AppColors.ignite),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.list_rounded),
        label: const Text('種目を選ぶ'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
          );
        },
      ),
    );
  }
}

// ── よく使う種目 ──────────────────────────────────────────

class _FrequentExercises extends StatelessWidget {
  const _FrequentExercises();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sessions').listenable(),
      builder: (context, _, __) {
        final sessions = SessionStore.all;
        if (sessions.isEmpty) return const SizedBox();

        // 使用回数集計
        final counts = <String, int>{};
        for (final s in sessions) {
          counts[s.exerciseName] = (counts[s.exerciseName] ?? 0) + 1;
        }
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topNames = sorted.take(4).map((e) => e.key).toList();
        final exercises = topNames
            .map((n) => ExerciseStore.findByName(n))
            .whereType<Exercise>()
            .toList();

        if (exercises.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('よく使う種目',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: exercises.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          WorkoutTimerView(exercise: exercises[i])),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(exercises[i].icon,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercises[i].name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 種目ピッカーページ（ホームから種目選択） ─────────────────

class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  void _showVideoUrlSheet(BuildContext context, Exercise e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExerciseVideoSheet(
        exercise: e,
        onChanged: () => setState(() {}),
      ),
    );
  }

  /// 筋トレは部位（StatAxis）別、それ以外はカテゴリ別にグループ化
  List<_Section> _buildSections(List<Exercise> exercises) {
    final sections = <_Section>[];

    // 筋トレ：部位別
    for (final axis in StatAxis.values) {
      final items = exercises
          .where((e) =>
              e.category == ExerciseCategory.strength &&
              e.topGains.isNotEmpty &&
              e.topGains.first.key == axis)
          .toList();
      if (items.isNotEmpty) {
        sections.add(_Section('${axis.icon} ${axis.label}', items));
      }
    }

    // 筋トレ以外：カテゴリ別
    for (final cat in ExerciseCategory.values) {
      if (cat == ExerciseCategory.strength) continue;
      final items = exercises.where((e) => e.category == cat).toList();
      if (items.isNotEmpty) {
        sections.add(_Section(cat.label, items));
      }
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseStore.active;
    final sections = _buildSections(exercises);

    // フラット化してインデックス管理
    final items = <Object>[];
    for (final s in sections) {
      items.add(s.title);        // String → セクションヘッダー
      items.addAll(s.exercises); // Exercise → セルアイテム
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('種目を選ぶ',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item is String) {
            // セクションヘッダー
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                item,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            );
          }
          final e = item as Exercise;
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WorkoutTimerView(exercise: e)),
              );
            },
            onLongPress: () => _showVideoUrlSheet(context, e),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(e.icon, style: const TextStyle(fontSize: 24)),
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
                        if (VideoStore.forExercise(e.name).isNotEmpty)
                          const Text('▶ 動画あり',
                              style: TextStyle(
                                  color: AppColors.ignite, fontSize: 10)),
                      ],
                    ),
                  ),
                  ...e.topGains.take(2).map((g) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ignite.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(g.key.label,
                            style: const TextStyle(
                                color: AppColors.ignite, fontSize: 10)),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section {
  final String title;
  final List<Exercise> exercises;
  const _Section(this.title, this.exercises);
}

// ── 種目に動画を紐づけるシート ────────────────────────────

class _ExerciseVideoSheet extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onChanged;
  const _ExerciseVideoSheet(
      {required this.exercise, required this.onChanged});

  @override
  State<_ExerciseVideoSheet> createState() => _ExerciseVideoSheetState();
}

class _ExerciseVideoSheetState extends State<_ExerciseVideoSheet> {
  List<VideoEntry> _videos = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _videos = VideoStore.all);

  bool _isLinked(VideoEntry v) =>
      v.exerciseNames.contains(widget.exercise.name);

  void _toggle(VideoEntry v) {
    if (_isLinked(v)) {
      VideoStore.unlinkExercise(v.id, widget.exercise.name);
    } else {
      VideoStore.linkExercise(v.id, widget.exercise.name);
    }
    _reload();
    widget.onChanged();
  }

  void _addNew() {
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
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
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
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
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
                exerciseNames: [widget.exercise.name],
              );
              VideoStore.save(v);
              _reload();
              widget.onChanged();
              Navigator.pop(ctx);
            },
            child: const Text('追加',
                style: TextStyle(color: AppColors.ignite)),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(VideoEntry v) {
    VideoStore.delete(v.id);
    _reload();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final linked = _videos.where(_isLinked).toList();
    final others = _videos.where((v) => !_isLinked(v)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('${widget.exercise.icon} ${widget.exercise.name}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('動画を紐づけ / 解除',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),

              // 紐づき済み
              if (linked.isNotEmpty) ...[
                const Text('紐づき済み',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                ...linked.map((v) => _VideoTile(
                      video: v,
                      isLinked: true,
                      onToggle: () => _toggle(v),
                      onDelete: () => _deleteVideo(v),
                    )),
                const SizedBox(height: 12),
              ],

              // その他の動画
              if (others.isNotEmpty) ...[
                const Text('他の動画に紐づける',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                ...others.map((v) => _VideoTile(
                      video: v,
                      isLinked: false,
                      onToggle: () => _toggle(v),
                      onDelete: () => _deleteVideo(v),
                    )),
                const SizedBox(height: 12),
              ],

              // 新規追加
              GestureDetector(
                onTap: _addNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ignite.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.ignite.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.ignite, size: 18),
                      SizedBox(width: 6),
                      Text('新しい動画を追加',
                          style: TextStyle(
                              color: AppColors.ignite, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final VideoEntry video;
  final bool isLinked;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _VideoTile({
    required this.video,
    required this.isLinked,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLinked
              ? AppColors.ignite.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const Text('▶', style: TextStyle(color: AppColors.ignite, fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(video.url,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (video.exerciseNames.isNotEmpty)
                  Text('${video.exerciseNames.length}種目に紐づき',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isLinked ? Icons.link_off : Icons.link,
              color: isLinked ? Colors.redAccent : AppColors.ignite,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
