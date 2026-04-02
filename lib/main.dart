import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';
import 'home_view.dart';
import 'workout_view.dart';
import 'growth_view.dart';
import 'settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('profile');
  await Hive.openBox('sessions');
  await Hive.openBox('exercises');
  runApp(const IgniteBodyApp());
}

class IgniteBodyApp extends StatelessWidget {
  const IgniteBodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IgniteBody',
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
      home: const MainTabView(),
    );
  }
}

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedIndex = 0;

  final _tabs = const [
    HomeView(),
    WorkoutView(),
    GrowthView(),
    SettingsView(),
  ];

  final _labels = ['ホーム', '動く', '成長', '設定'];
  final _icons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.trending_up_rounded,
    Icons.settings_rounded,
  ];

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
