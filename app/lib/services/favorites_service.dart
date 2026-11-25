import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مفضلة موحدة للقنوات والأفلام والمسلسلات — تخزين محلي بالمعرفات.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final Set<String> _ids = <String>{};
  bool _loaded = false;

  bool get loaded => _loaded;

  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    if (_loaded) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList('bv_favorites') ?? const <String>[]);
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (!_ids.add(id)) {
      _ids.remove(id);
    }
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bv_favorites', _ids.toList());
  }
}
