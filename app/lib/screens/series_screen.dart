import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'activation_screen.dart';
import 'player_screen.dart';

/// شاشة مسلسلات: شبكة بوسترات + bottom sheet لاختيار الحلقة
/// (موسم ← حلقة) بنمط تطبيقات IPTV.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late Future<List<MediaItem>> _future = ApiService.instance.loadSeries();

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.instance.loadSeries();
    });
  }

  void _openSeries(MediaItem s) {
    if (!gateOrOpenActivation(context)) return;
    if (s.episodes.isEmpty) {
      if (s.url.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
                content: Text('لم تُضف حلقات لهذا المسلسل بعد')),
          );
        return;
      }
      // مسلسل برابط واحد فقط (عرض مباشر)
      _play(s, s.url, 'الحلقة 1');
      return;
    }
    _showEpisodesSheet(s);
  }

  void _play(MediaItem s, String url, String epName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: s.name,
          subtitle: epName,
          urls: <String>[url],
        ),
      ),
    );
  }

  /// ورقة الحلقات مجمعة بالموسم مع اختيار مباشر.
  void _showEpisodesSheet(MediaItem s) {
    final Map<int, List<Episode>> bySeason = <int, List<Episode>>{};
    for (final Episode e in s.episodes) {
      bySeason.putIfAbsent(e.season, () => <Episode>[]).add(e);
    }
    final List<int> seasons = (bySeason.keys.toList()..sort());
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BvColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BvColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'اختر الحلقة',
                    style: TextStyle(color: BvColors.muted, fontSize: 12),
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final int season in seasons) ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 4),
                          child: Text(
                            'الموسم $season',
                            style: const TextStyle(
                              color: BvColors.blueLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (final Episode e in bySeason[season]!)
                          ListTile(
                            dense: true,
                            leading: Container(
                              width: 40,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: BvColors.card,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: BvColors.border),
                              ),
                              child: Text(
                                '${e.number}',
                                style: const TextStyle(
                                  color: BvColors.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              e.name.isNotEmpty
                                  ? e.name
                                  : 'الحلقة ${e.number}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BvColors.text,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              if (e.url.isEmpty) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'رابط هذه الحلقة غير متوفر')),
                                  );
                                return;
                              }
                              _play(s, e.url,
                                  'م$season ه${e.number} — ${e.name}');
                            },
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(
        title: const Text('المسلسلات'),
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
              icon: Icons.subscriptions_outlined,
              title: 'لا توجد مسلسلات بعد',
              message: 'أضف مسلسلاتك وحلقاتها من لوحة الإدارة',
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
                MediaCard(item: items[i], onTap: () => _openSeries(items[i])),
          );
        },
      ),
    );
  }
}
