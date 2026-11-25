import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_service.dart';

/// خدمة تفعيل VIP: معرف جهاز ثابت + حالة الاشتراك + الكاش.
/// النظام مثل تطبيقات VIP: كود يُفعّل على جهاز واحد بمدة محددة.
class ActivationService extends ChangeNotifier {
  ActivationService._();
  static final ActivationService instance = ActivationService._();

  static late SharedPreferences storage;

  bool _loaded = false;
  bool _active = false;
  String _deviceId = '';
  String _expiresAt = '';
  bool _requiresActivation = false;

  bool get loaded => _loaded;
  bool get active => _active;
  String get deviceId => _deviceId;
  String get expiresAt => _expiresAt;
  bool get requiresActivation => _requiresActivation;

  /// هل الجهاز مسموح له بالمشاهدة؟ (بلا إجبار تفعيل = الكل مسموح)
  bool get canWatch => !_requiresActivation || _active;

  /// التهيئة: توليد معرف الجهاز + فحص التفعيل من الخادم.
  Future<void> load() async {
    if (_loaded) return;
    storage = await SharedPreferences.getInstance();

    _deviceId = storage.getString('bv_device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await storage.setString('bv_device_id', _deviceId);
    }

    _requiresActivation = storage.getBool('bv_requires_activation') ?? false;
    _expiresAt = storage.getString('bv_expires_at') ?? '';

    // فحص سريع محلي (يُحدَّث من الخادم لاحقاً)
    _active = storage.getBool('bv_active') ?? false;
    if (_active &&
        _expiresAt.isNotEmpty &&
        _expiresAt.compareTo(DateTime.now().toIso8601String()) < 0) {
      _active = false;
      await storage.setBool('bv_active', false);
    }

    _loaded = true;
    notifyListeners();

    // مزامنة مع الخادم (غير معطلة لو انقطع النت)
    await syncWithServer();
  }

  /// فحص الحالة من الخادم + تحديث شرط الإجبار من config.
  Future<void> syncWithServer() async {
    final BvAppConfig cfg = await ApiService.instance.loadConfig();
    _requiresActivation = cfg.requiresActivation;
    await storage.setBool('bv_requires_activation', _requiresActivation);

    final bool serverActive =
        await ApiService.instance.checkActivation(_deviceId);
    _active = serverActive;
    await storage.setBool('bv_active', _active);
    notifyListeners();
  }

  /// تفعيل كود VIP.
  Future<ActivationResult> activateCode(String code) async {
    final ActivationResult res =
        await ApiService.instance.activate(code.trim().toUpperCase(), _deviceId);
    if (res.ok) {
      _active = true;
      await storage.setBool('bv_active', true);
      notifyListeners();
    }
    return res;
  }

  /// معرف جهاز شبه عشوائي ثابت (UUID-مشتق بدون حزم خارجية).
  String _generateDeviceId() {
    final Random r = Random.secure();
    final String hex = List<String>.generate(
      32,
      (_) => r.nextInt(16).toRadixString(16),
    ).join();
    return 'bv-${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 24)}';
  }
}
