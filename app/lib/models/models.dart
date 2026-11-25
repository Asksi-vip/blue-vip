/// نماذج بيانات Blue VIP — نفس بنية كتالوج IraqMax (أقسام ← قنوات بسيرفرات)
/// مع الأفلام والمسلسلات والمباريات.
library;

class BvCategory {
  const BvCategory({required this.id, required this.name, this.icon = ''});

  final String id;
  final String name;
  final String icon;

  factory BvCategory.fromJson(Map<String, dynamic> j) => BvCategory(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        icon: (j['icon'] ?? '').toString(),
      );
}

class ChannelServer {
  const ChannelServer({required this.name, required this.url, this.quality = 'HD'});

  final String name;
  final String url;
  final String quality;
}

class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.logo = '',
    this.url = '',
    this.backupUrl = '',
    this.servers = const <ChannelServer>[],
  });

  final String id;
  final String name;
  final String categoryId;
  final String logo;
  final String url;
  final String backupUrl;
  final List<ChannelServer> servers;

  /// أول رابط قابل للتشغيل (أساسي ← احتياطي ← سيرفرات)
  String get firstUrl {
    if (url.isNotEmpty) return url;
    if (backupUrl.isNotEmpty) return backupUrl;
    for (final ChannelServer s in servers) {
      if (s.url.isNotEmpty) return s.url;
    }
    return '';
  }

  /// كل الروابط المتاحة للتبديل بينها عند فشل التشغيل
  List<String> get allUrls {
    final List<String> out = <String>[];
    if (url.isNotEmpty) out.add(url);
    if (backupUrl.isNotEmpty && backupUrl != url) out.add(backupUrl);
    for (final ChannelServer s in servers) {
      if (s.url.isNotEmpty && !out.contains(s.url)) out.add(s.url);
    }
    return out;
  }

  factory Channel.fromJson(Map<String, dynamic> j) {
    final List<ChannelServer> servers = <ChannelServer>[];
    final raw = j['servers'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          servers.add(ChannelServer(
            name: (item['name'] ?? 'سيرفر').toString(),
            url: (item['url'] ?? '').toString(),
            quality: (item['quality'] ?? 'HD').toString(),
          ));
        }
      }
    }
    return Channel(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      categoryId: (j['category_id'] ?? '').toString(),
      logo: (j['logo'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      backupUrl: (j['backup_url'] ?? '').toString(),
      servers: servers,
    );
  }
}

class Episode {
  const Episode({
    required this.season,
    required this.number,
    required this.name,
    required this.url,
  });

  final int season;
  final int number;
  final String name;
  final String url;

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        season: (j['season'] is num) ? (j['season'] as num).toInt() : 1,
        number: (j['number'] is num) ? (j['number'] as num).toInt() : 1,
        name: (j['name'] ?? 'حلقة').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.type, // movie | series
    required this.name,
    this.category = '',
    this.poster = '',
    this.url = '',
    this.year = '',
    this.rating = 0,
    this.description = '',
    this.episodes = const <Episode>[],
  });

  final String id;
  final String type;
  final String name;
  final String category;
  final String poster;
  final String url;
  final String year;
  final double rating;
  final String description;
  final List<Episode> episodes;

  bool get isSeries => type == 'series';

  factory MediaItem.fromJson(Map<String, dynamic> j) {
    final List<Episode> eps = <Episode>[];
    final raw = j['episodes'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) eps.add(Episode.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return MediaItem(
      id: (j['id'] ?? '').toString(),
      type: (j['type'] ?? 'movie').toString(),
      name: (j['name'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      poster: (j['poster'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      year: (j['year'] ?? '').toString(),
      rating: (j['rating'] is num) ? (j['rating'] as num).toDouble() : 0,
      description: (j['description'] ?? '').toString(),
      episodes: eps,
    );
  }
}

class MatchServer {
  const MatchServer({required this.name, required this.url, this.quality = 'HD'});

  final String name;
  final String url;
  final String quality;

  factory MatchServer.fromJson(Map<String, dynamic> j) => MatchServer(
        name: (j['name'] ?? 'سيرفر').toString(),
        url: (j['url'] ?? '').toString(),
        quality: (j['quality'] ?? 'HD').toString(),
      );
}

class BvMatch {
  const BvMatch({
    required this.id,
    required this.title,
    required this.teamA,
    required this.teamB,
    required this.league,
    required this.startsAt,
    required this.status, // live | upcoming | finished
    this.servers = const <MatchServer>[],
  });

  final String id;
  final String title;
  final String teamA;
  final String teamB;
  final String league;
  final String startsAt;
  final String status;
  final List<MatchServer> servers;

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isFinished => status == 'finished';

  /// أول سيرفر له رابط بث فعلي
  String get firstStreamUrl {
    for (final MatchServer s in servers) {
      if (s.url.isNotEmpty) return s.url;
    }
    return '';
  }

  factory BvMatch.fromJson(Map<String, dynamic> j) {
    final List<MatchServer> srv = <MatchServer>[];
    final raw = j['servers'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) srv.add(MatchServer.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return BvMatch(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      teamA: (j['team_a'] ?? '').toString(),
      teamB: (j['team_b'] ?? '').toString(),
      league: (j['league'] ?? '').toString(),
      startsAt: (j['starts_at'] ?? '').toString(),
      status: (j['status'] ?? 'upcoming').toString(),
      servers: srv,
    );
  }
}

class BvAppConfig {
  const BvAppConfig({
    this.appName = 'Blue VIP',
    this.tagline = '',
    this.telegramUrl = '',
    this.latestVersion = '',
    this.latestApkUrl = '',
    this.requiresActivation = false,
    this.notice = '',
  });

  final String appName;
  final String tagline;
  final String telegramUrl;
  final String latestVersion;
  final String latestApkUrl;
  final bool requiresActivation;
  final String notice;

  factory BvAppConfig.fromJson(Map<String, dynamic> j) => BvAppConfig(
        appName: (j['app_name'] ?? 'Blue VIP').toString(),
        tagline: (j['tagline'] ?? '').toString(),
        telegramUrl: (j['telegram_url'] ?? '').toString(),
        latestVersion: (j['latest_version'] ?? '').toString(),
        latestApkUrl: (j['latest_apk_url'] ?? '').toString(),
        requiresActivation: j['requires_activation'] == true || j['requires_activation'] == 1,
        notice: (j['notice'] ?? '').toString(),
      );
}
