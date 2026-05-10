import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'home_view.dart';
import 'workout_view.dart';
import 'growth_view.dart';
import 'pet_view.dart';
import 'settings_view.dart';
import 'setup_view.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('profile');
  await Hive.openBox('sessions');
  await Hive.openBox('exercises');
  await Hive.openBox('plans');
  await Hive.openBox('videos');
  // 旧データの gainRates 移行
  ExerciseStore.migrateIfNeeded();
  runApp(const PetRepsApp());
}

class PetRepsApp extends StatelessWidget {
  const PetRepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Reps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.ignite,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        useMaterial3: true,
      ),
      home: const _RootView(),
    );
  }
}

class _RootView extends StatefulWidget {
  const _RootView();

  @override
  State<_RootView> createState() => _RootViewState();
}

class _RootViewState extends State<_RootView> {
  bool _setupDone = false;

  @override
  void initState() {
    super.initState();
    _setupDone = BodyProfile.isSetupDone;
  }

  @override
  Widget build(BuildContext context) {
    if (!_setupDone) {
      return SetupView(onComplete: () {
        setState(() => _setupDone = true);
      });
    }
    return const MainTabView();
  }
}

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedIndex = 0;
  int _lastLevelUpSeq = 0;

  final _tabs = const [
    HomeView(),
    WorkoutView(),
    GrowthView(),
    SettingsView(),
  ];

  final _labels = ['ホーム', '記録', '成長', '設定'];
  final _icons = [
    Icons.home_rounded,
    Icons.edit_note_rounded,
    Icons.trending_up_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    LevelUpEvents.lastEvent.addListener(_onLevelUp);
  }

  @override
  void dispose() {
    LevelUpEvents.lastEvent.removeListener(_onLevelUp);
    super.dispose();
  }

  void _onLevelUp() {
    final e = LevelUpEvents.lastEvent.value;
    if (e == null || e.sequence == _lastLevelUpSeq) return;
    _lastLevelUpSeq = e.sequence;
    // ゲインバブルが見える時間を少し残してから演出
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => EvolutionScreen(event: e),
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.ignite.withValues(alpha: 0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: List.generate(_tabs.length, (i) => NavigationDestination(
          icon: Icon(
            _icons[i],
            color: i == _selectedIndex ? AppColors.ignite : AppColors.textSecondary,
          ),
          label: _labels[i],
        )),
      ),
    );
  }
}
