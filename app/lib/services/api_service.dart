import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/models.dart';

/// خدمة الـ API — تجيب المحتوى من الخادم وتكاشيه محلياً
/// وترجع للكتالوج المدمج (assets) عند فشل الاتصال مثل نظام IraqMax.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  BvAppConfig? _config;
  List<BvCategory> _categories = <BvCategory>[];
  List<Channel> _channels = <Channel>[];

  BvAppConfig? get config => _config;
  List<BvCategory> get categories => List.unmodifiable(_categories);
  List<Channel> get channels => List.unmodifiable(_channels);

  http.Client _client() => http.Client();

  Map<String, dynamic> _decode(http.Response r) {
    final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
    if (j is Map<String, dynamic>) return j;
    throw const FormatException('استجابة غير صالحة من الخادم');
  }

  /// إعدادات التطبيق (تلغرام، تحديث، إشعار، إجبار تفعيل) — فشلها غير قاتل.
  Future<BvAppConfig> loadConfig() async {
    try {
      final http.Response r =
          await _client().get(Uri.parse(AppConfig.configAction)).timeout(
                const Duration(seconds: 12),
              );
      if (r.statusCode == 200) {
        _config = BvAppConfig.fromJson(_decode(r));
      }
    } catch (_) {
      _config ??= const BvAppConfig();
    }
    return _config ?? const BvAppConfig();
  }

  /// الكتالوج: أقسام + قنوات. المحاولة: كاش ← API ← المدمج.
  Future<void> loadCatalog() async {
    // 1) الكاش المحلي الأخير
    final cached = await _cachedCatalog();
    if (cached != null) {
      _applyCatalog(cached);
    } else {
      final bundled = await _bundledCatalog();
      _applyCatalog(bundled);
    }

    // 2) التحديث من الخادم إن توفر اتصال
    try {
      final http.Response r =
          await _client().get(Uri.parse(AppConfig.catalogAction)).timeout(
                const Duration(seconds: 15),
              );
      if (r.statusCode == 200) {
        final Map<String, dynamic> data = _decode(r);
        final rawCats = data['categories'];
        final rawChs = data['channels'];
        if (rawCats is List && rawChs is List) {
          await _persistCatalog(
            rawCats.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList(),
            rawChs.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList(),
          );
          _applyCatalog(data);
        }
      }
    } catch (_) {
      // البقاء على الكاش/المدمج (وضع offline)
    }
  }

  void _applyCatalog(Map<String, dynamic> data) {
    final rawCats = data['categories'];
    final rawChs = data['channels'];
    _categories = <BvCategory>[];
    _channels = <Channel>[];
    if (rawCats is List) {
      for (final dynamic e in rawCats) {
        if (e is Map) _categories.add(BvCategory.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    if (rawChs is List) {
      for (final dynamic e in rawChs) {
        if (e is Map) _channels.add(Channel.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }

  Future<Map<String, dynamic>?> _cachedCatalog() async {
    try {
      // الكاش يُخزن محلياً في SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('bv_catalog_cache');
      if (raw == null || raw.isEmpty) return null;
      final dynamic j = jsonDecode(raw);
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistCatalog(
    List<Map<String, dynamic>> cats,
    List<Map<String, dynamic>> chs,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String payload = jsonEncode(
      <String, dynamic>{'categories': cats, 'channels': chs},
    );
    await prefs.setString('bv_catalog_cache', payload);
  }

  /// الكتالوج المدمج داخل الـ APK (assets/data/catalog.json).
  Future<Map<String, dynamic>> _bundledCatalog() async {
    final String raw = await rootBundle.loadString('assets/data/catalog.json');
    final dynamic j = jsonDecode(raw);
    if (j is Map<String, dynamic>) return j;
    return <String, dynamic>{'categories': <dynamic>[], 'channels': <dynamic>[]};
  }

  /// الأفلام من الخادم — عند الفشل قائمة فارغة.
  Future<List<MediaItem>> loadMovies() async {
    return _loadMedia(AppConfig.moviesAction);
  }

  /// المسلسلات (مع الحلقات).
  Future<List<MediaItem>> loadSeries() async {
    return _loadMedia(AppConfig.seriesAction);
  }

  Future<List<MediaItem>> _loadMedia(String url) async {
    try {
      final http.Response r =
          await _client().get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final Map<String, dynamic> data = _decode(r);
        final raw = data['items'];
        final List<MediaItem> out = <MediaItem>[];
        if (raw is List) {
          for (final dynamic e in raw) {
            if (e is Map) out.add(MediaItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        return out;
      }
    } catch (_) {}
    return <MediaItem>[];
  }

  /// جدول المباريات مع السيرفرات.
  Future<List<BvMatch>> loadMatches() async {
    try {
      final http.Response r =
          await _client().get(Uri.parse(AppConfig.matchesAction)).timeout(
                const Duration(seconds: 15),
              );
      if (r.statusCode == 200) {
        final Map<String, dynamic> data = _decode(r);
        final raw = data['matches'];
        final List<BvMatch> out = <BvMatch>[];
        if (raw is List) {
          for (final dynamic e in raw) {
            if (e is Map) out.add(BvMatch.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        return out;
      }
    } catch (_) {}
    return <BvMatch>[];
  }

  /// حالة تفعيل جهاز.
  Future<bool> checkActivation(String deviceId) async {
    try {
      final Uri uri = Uri.parse(
        '${AppConfig.statusAction}&device_id=${Uri.encodeComponent(deviceId)}',
      );
      final http.Response r =
          await _client().get(uri).timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        return _decode(r)['active'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// تفعيل كود VIP على الجهاز.
  Future<ActivationResult> activate(String code, String deviceId) async {
    try {
      final http.Response r = await _client()
          .post(
            Uri.parse(AppConfig.activateAction),
            body: <String, String>{'code': code, 'device_id': deviceId},
          )
          .timeout(const Duration(seconds: 15));
      final Map<String, dynamic> data = _decode(r);
      return ActivationResult(
        ok: data['ok'] == true,
        message: (data['message'] ?? data['error'] ?? 'خطأ غير متوقع').toString(),
      );
    } catch (_) {
      return const ActivationResult(
        ok: false,
        message: 'تعذر الاتصال بالخادم — تحقق من الإنترنت وأعد المحاولة',
      );
    }
  }
}

class ActivationResult {
  const ActivationResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
