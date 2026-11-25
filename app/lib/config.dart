/// إعدادات اتصال Blue VIP بالخادم.
///
/// ضع هنا رابط مجلد php المرفوع على استضافتك (ينتهي بمجلد php الذي
/// يحتوي api/ و admin/). مثال serv00:
///   https://username.serv00.net/bluevip/php
class AppConfig {
  AppConfig._();

  /// رابط الخادم — غيّره ليطابق استضافتك
  static const String apiBase = 'https://bluevip.serv00.net/php';

  /// أسماء الإجراءات في الـ API
  static const String configAction = '$apiBase/api/index.php?action=config';
  static const String catalogAction = '$apiBase/api/index.php?action=catalog';
  static const String moviesAction = '$apiBase/api/index.php?action=movies';
  static const String seriesAction = '$apiBase/api/index.php?action=series';
  static const String matchesAction = '$apiBase/api/index.php?action=matches';
  static const String statusAction = '$apiBase/api/index.php?action=status';
  static const String activateAction = '$apiBase/api/index.php?action=activate';
}
