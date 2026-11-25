import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'activation_screen.dart';
import 'player_screen.dart';

/// شاشة جدول المباريات (نفس MatchesActivity في النظام الأصلي):
/// فلاتر (الكل / مباشر الآن 🔴 / القادمة ⏳ / المنتهية ⚽) + كروت مباريات
/// + ورقة "اختر سيرفر البث" عند الضغط على مشاهدة.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _filter = 'all'; // all | live | upcoming | finished
  late Future<List<BvMatch>> _future = ApiService.instance.loadMatches();

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.instance.loadMatches();
    });
  }

  List<BvMatch> _applyFilter(List<BvMatch> list) {
    if (_filter == 'all') return list;
    return list.where((BvMatch m) => m.status == _filter).toList();
  }

  void _watch(BvMatch m) {
    if (!gateOrOpenActivation(context)) return;
    final List<MatchServer> withUrl = m.servers
        .where((MatchServer s) => s.url.isNotEmpty)
        .toList();
    if (withUrl.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('لم يبدأ البث المباشر لهذه المباراة بعد'),
          ),
        );
      return;
    }
    if (withUrl.length == 1) {
      _play(m, withUrl.first);
      return;
    }
    // أكثر من سيرفر → ورقة اختيار "اختر سيرفر البث"
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BvColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'اختر سيرفر البث',
                  style: TextStyle(
                    color: BvColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final MatchServer s in withUrl)
                ListTile(
                  leading: const Icon(
                    Icons.dns_rounded,
                    color: BvColors.blueLight,
                    size: 20,
                  ),
                  title: Text(
                    s.name,
                    style: const TextStyle(
                        color: BvColors.text, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    s.quality,
                    style: const TextStyle(
                        color: BvColors.muted, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _play(m, s);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _play(BvMatch m, MatchServer s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: m.title,
          subtitle: m.league,
          urls: <String>[s.url],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(title: const Text('جدول المباريات')),
      body: FutureBuilder<List<BvMatch>>(
        future: _future,
        builder: (context, AsyncSnapshot<List<BvMatch>> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'جاري تحميل جدول المباريات...',
                    style: TextStyle(color: BvColors.muted, fontSize: 13),
                  ),
                ),
                SizedBox(height: 20),
                LoadingGrid(itemCount: 4, childAspectRatio: 1.6),
              ],
            );
          }
          if (snap.hasError) {
            return StatusView(
              icon: Icons.wifi_off_rounded,
              title: 'تعذر جلب المباريات',
              message: 'تحقق من اتصال الإنترنت وأعد المحاولة',
              actionLabel: 'إعادة المحاولة',
              onAction: _reload,
            );
          }
          final List<BvMatch> list = _applyFilter(snap.data ?? const <BvMatch>[]);
          return Column(
            children: [
              // فلاتر الحالة بنصوص النظام الأصلي
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, int i) {
                    final List<(String, String)> opts = [
                      ('all', 'الكل'),
                      ('live', 'مباشر الآن 🔴'),
                      ('upcoming', 'القادمة ⏳'),
                      ('finished', 'المنتهية ⚽'),
                    ];
                    final bool selected = _filter == opts[i].$1;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = opts[i].$1),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
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
                          opts[i].$2,
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
              Expanded(
                child: list.isEmpty
                    ? StatusView(
                        icon: Icons.sports_soccer_outlined,
                        title: 'لا توجد مباريات مجدولة اليوم',
                        message: 'راجع الجدول لاحقاً أو أضف مباريات من اللوحة',
                        actionLabel: 'إعادة المحاولة',
                        onAction: _reload,
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        children: [
                          for (final BvMatch m in list)
                            MatchCard(
                              match: m,
                              onWatch: () => _watch(m),
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
