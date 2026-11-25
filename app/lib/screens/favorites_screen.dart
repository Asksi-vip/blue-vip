import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'activation_screen.dart';
import 'player_screen.dart';

/// شاشة المفضلة — كل القنوات والأفلام والمسلسلات المفضلة في مكان واحد.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _openChannel(BuildContext context, Channel c, String catName) {
    if (!gateOrOpenActivation(context)) return;
    if (c.allUrls.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('لم تُضف روابط بث لهذه القناة بعد')),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: c.name,
          subtitle: catName,
          urls: c.allUrls,
        ),
      ),
    );
  }

  void _openMedia(BuildContext context, MediaItem m) {
    if (!gateOrOpenActivation(context)) return;
    if (m.url.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('لم يُضف رابط تشغيل لهذا العنصر بعد')),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(title: m.name, urls: <String>[m.url]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(title: const Text('المفضلة')),
      body: ListenableBuilder(
        listenable: FavoritesService.instance,
        builder: (context, _) {
          final FavoritesService favs = FavoritesService.instance;
          final ApiService api = ApiService.instance;
          final List<Channel> channels = api.channels
              .where((Channel c) => favs.contains(c.id))
              .toList();

          if (channels.isEmpty) {
            return StatusView(
              icon: Icons.favorite_outline_rounded,
              title: 'لا توجد مفضلات بعد',
              message: 'اضغط القلب على أي قناة أو فيلم لتحفظه هنا',
            );
          }

          String catName(String catId) {
            for (final BvCategory c in api.categories) {
              if (c.id == catId) return c.name;
            }
            return 'قنوات';
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              for (int i = 0; i < channels.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BvColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BvColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: BvColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: BvColors.blueLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channels[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BvColors.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catName(channels[i].categoryId),
                              style: const TextStyle(
                                  color: BvColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            FavoritesService.instance.toggle(channels[i].id),
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: BvColors.red,
                          size: 20,
                        ),
                        tooltip: 'إزالة من المفضلة',
                      ),
                      IconButton(
                        onPressed: () => _openChannel(
                            context, channels[i], catName(channels[i].categoryId)),
                        icon: const Icon(
                          Icons.play_circle_rounded,
                          color: BvColors.blueLight,
                          size: 26,
                        ),
                        tooltip: 'مشاهدة',
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
