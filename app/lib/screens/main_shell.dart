import 'package:flutter/material.dart';

import '../services/activation_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';
import 'live_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

/// الهيكل الرئيسي — 5 تبويبات سفلية بنظام IraqMax:
/// البث المباشر / الأفلام / المسلسلات / المفضلة / الإعدادات.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<IconData> _icons = [
    Icons.live_tv_rounded,
    Icons.smart_display_rounded,
    Icons.subscriptions_rounded,
    Icons.favorite_outline_rounded,
    Icons.settings_outlined,
  ];

  static const List<String> _labels = [
    'البث المباشر',
    'الأفلام',
    'المسلسلات',
    'المفضلة',
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.load();
    ActivationService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      body: IndexedStack(
        index: _index,
        children: const [
          LiveScreen(),
          MoviesScreen(),
          SeriesScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: BvColors.surface,
          border: Border(top: BorderSide(color: BvColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (int i = 0; i < _labels.length; i++) _tabItem(i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int i) {
    final bool selected = _index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _index = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? BvColors.blue.withOpacity(.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _icons[i],
                size: 22,
                color: selected ? BvColors.blueLight : BvColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _labels[i],
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? BvColors.blueLight : BvColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
