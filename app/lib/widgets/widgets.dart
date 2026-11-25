import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

/// كرت قناة: شعار دائري + اسم + قلب مفضلة — مثل شبكة قنوات تطبيقات IPTV.
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.categoryName,
    required this.onTap,
  });

  final Channel channel;
  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final bool fav = FavoritesService.instance.contains(channel.id);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: BvColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BvColors.border),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: BvColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: channel.logo.isNotEmpty
                            ? Image.network(
                                channel.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _fallbackIcon(),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : _fallbackIcon(),
                              )
                            : _fallbackIcon(),
                      ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: GestureDetector(
                          onTap: () => FavoritesService.instance.toggle(channel.id),
                          child: Icon(
                            fav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: fav ? BvColors.red : BvColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BvColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: BvColors.muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BvColors.blue.withOpacity(.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.live_tv_rounded,
            color: BvColors.blueLight, size: 20),
      ),
    );
  }
}

/// كرت فيلم/مسلسل: بوستر عمودي + اسم + سنة + تقييم.
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final bool fav = FavoritesService.instance.contains(item.id);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: BvColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BvColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.poster.isNotEmpty
                          ? Image.network(
                              item.poster,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallback(),
                              loadingBuilder: (context, child, progress) =>
                                  progress == null ? child : _fallback(),
                            )
                          : _fallback(),
                      PositionedDirectional(
                        top: 6,
                        start: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFEAB308), size: 12),
                              const SizedBox(width: 3),
                              Text(
                                item.rating > 0
                                    ? item.rating.toStringAsFixed(1)
                                    : '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: GestureDetector(
                          onTap: () => FavoritesService.instance.toggle(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.55),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              fav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15,
                              color: fav ? BvColors.red : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BvColors.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [item.year, item.category]
                            .where((String s) => s.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: BvColors.muted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: BvColors.surface,
      child: Center(
        child: Icon(
          item.isSeries ? Icons.movie_filter_rounded : Icons.smart_display_rounded,
          color: BvColors.blue.withOpacity(.5),
          size: 34,
        ),
      ),
    );
  }
}

/// كرت مباراة: الشعارات الافتراضية + الوقت + شارة الحالة + زر مشاهدة.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onWatch,
  });

  final BvMatch match;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BvColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.isLive ? BvColors.red.withOpacity(.5) : BvColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.league,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: BvColors.muted, fontSize: 11.5),
              ),
              const Spacer(),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.teamA,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BvColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BvColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BvColors.border),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: BvColors.blueLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  match.teamB,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BvColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: BvColors.muted),
              const SizedBox(width: 5),
              Text(
                match.startsAt,
                style: const TextStyle(color: BvColors.muted, fontSize: 11.5),
              ),
              const Spacer(),
              if (match.firstStreamUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('مشاهدة المباراة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BvColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    if (match.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: BvColors.red.withOpacity(.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BvColors.red.withOpacity(.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle_rounded, size: 7, color: BvColors.red),
            SizedBox(width: 5),
            Text(
              'مباشر الآن',
              style: TextStyle(
                color: BvColors.red,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (match.isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: BvColors.blue.withOpacity(.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BvColors.blue.withOpacity(.5)),
        ),
        child: const Text(
          'لم تبدأ ⏳',
          style: TextStyle(
            color: BvColors.blueLight,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: BvColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BvColors.border),
      ),
      child: const Text(
        'انتهت ⚽',
        style: TextStyle(
          color: BvColors.muted,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// هيكل تحميل شبكي (هيكل عظمي).
class LoadingGrid extends StatelessWidget {
  const LoadingGrid({super.key, this.itemCount = 8, this.childAspectRatio = 0.85});

  final int itemCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, int i) => Container(
        decoration: BoxDecoration(
          color: BvColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BvColors.border),
        ),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: BvColors.blue.withOpacity(.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// حالات الحاوية: فارغ / خطأ مع إعادة محاولة.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: BvColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: BvColors.border),
              ),
              child: Icon(icon, color: BvColors.muted, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BvColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: BvColors.muted, fontSize: 13, height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: BvColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
