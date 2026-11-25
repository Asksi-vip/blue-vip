import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/activation_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'activation_screen.dart';
import 'player_screen.dart';

/// بوابة المشاهدة: إن كان الإجبار مفعلاً والجهاز غير مفعّل →
/// فتح شاشة التفعيل وإيقاف التشغيل.
bool gateOrOpenActivation(BuildContext context) {
  if (ActivationService.instance.canWatch) return true;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ActivationScreen()),
  );
  return false;
}

/// شاشة البث المباشر — نفس بنية كتالوج IraqMax:
/// بحث علوي + شرائح أقسام أفقية + شبكة قنوات متجاوبة + حالات تحميل/فشل.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  String? _selectedCat;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await ApiService.instance.loadCatalog();
    if (mounted) setState(() => _loading = false);
  }

  String _categoryName(String catId) {
    for (final BvCategory c in ApiService.instance.categories) {
      if (c.id == catId) return c.name;
    }
    return 'قنوات';
  }

  List<Channel> get _filtered {
    final ApiService api = ApiService.instance;
    List<Channel> list = api.channels;
    if (_selectedCat != null) {
      list = list
          .where((Channel c) => c.categoryId == _selectedCat)
          .toList();
    }
    if (_query.trim().isNotEmpty) {
      final String q = _query.trim().toLowerCase();
      list = list
          .where((Channel c) => c.name.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _playChannel(Channel c) {
    if (!gateOrOpenActivation(context)) return;
    final List<String> urls = c.allUrls;
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('لم تُضف روابط بث لهذه القناة بعد'),
          ),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: c.name,
          subtitle: _categoryName(c.categoryId),
          urls: urls,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(
        title: const Text('البث المباشر'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 8),
                LoadingGrid(itemCount: 6),
              ],
            )
          : Column(
              children: [
                // حقل البحث بنص الحالة الأصلي
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    onChanged: (String v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن قناة، فيلم، مسلسل...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: BvColors.muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // شرائح الأقسام الأفقية
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        ApiService.instance.categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, int i) {
                      final bool all = i == 0;
                      final BvCategory? cat = all
                          ? null
                          : ApiService.instance.categories[i - 1];
                      final bool selected = all
                          ? _selectedCat == null
                          : _selectedCat == cat!.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCat = all ? null : cat!.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? BvColors.blue
                                : BvColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? BvColors.blue
                                  : BvColors.border,
                            ),
                          ),
                          child: Text(
                            all ? 'الكل' : cat!.name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : BvColors.muted,
                              fontSize: 12.5,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // شبكة القنوات
                Expanded(
                  child: _buildGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildGrid() {
    final List<Channel> list = _filtered;
    if (list.isEmpty) {
      return StatusView(
        icon: _query.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.live_tv_outlined,
        title: _query.isNotEmpty
            ? 'لا توجد نتائج لـ "${_query.trim()}"'
            : 'لا توجد قنوات بعد',
        message: _query.isNotEmpty
            ? 'تحقق من الهجاء أو جرّب كلمة أخرى'
            : 'أضف قنوات من لوحة الإدارة أو تحقق من اتصال الخادم',
        actionLabel: 'إعادة المحاولة',
        onAction: _load,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemCount: list.length,
      itemBuilder: (context, int i) {
        return ChannelCard(
          channel: list[i],
          categoryName: _categoryName(list[i].categoryId),
          onTap: () => _playChannel(list[i]),
        );
      },
    );
  }
}
