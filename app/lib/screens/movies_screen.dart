import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'activation_screen.dart';
import 'player_screen.dart';

/// شاشة أفلام: شبكة بوسترات من الخادم + حالات تحميل/فشل.
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  late Future<List<MediaItem>> _future = ApiService.instance.loadMovies();

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.instance.loadMovies();
    });
  }

  void _playMovie(MediaItem m) {
    if (!gateOrOpenActivation(context)) return;
    if (m.url.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('لم يُضف رابط تشغيل لهذا الفيلم بعد')),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: m.name,
          subtitle: [m.year, m.category].where((String s) => s.isNotEmpty).join(' · '),
          urls: <String>[m.url],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(
        title: const Text('الأفلام'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _future,
        builder: (context, AsyncSnapshot<List<MediaItem>> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 8),
                LoadingGrid(itemCount: 6, childAspectRatio: 0.62),
              ],
            );
          }
          final List<MediaItem> items = snap.data ?? const <MediaItem>[];
          if (items.isEmpty) {
            return StatusView(
              icon: Icons.smart_display_outlined,
              title: 'لا توجد أفلام بعد',
              message: 'أضف أفلامك من لوحة الإدارة لتظهر هنا فوراً',
              actionLabel: 'إعادة المحاولة',
              onAction: _reload,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            itemCount: items.length,
            itemBuilder: (context, int i) =>
                MediaCard(item: items[i], onTap: () => _playMovie(items[i])),
          );
        },
      ),
    );
  }
}
