import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/activation_service.dart';
import '../theme/app_theme.dart';
import 'activation_screen.dart';
import 'matches_screen.dart';

/// شاشة الإعدادات — حالة الاشتراك + قناة التلغرام + جدول المباريات
/// + الإشعارات + فحص التحديث + معلومات التطبيق.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    ActivationService.instance.load();
  }

  Future<void> _resync() async {
    await ActivationService.instance.syncWithServer();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تم مزامنة حالة الاشتراك مع الخادم')),
        );
    }
  }

  Future<void> _openTelegram() async {
    final BvAppConfig? cfg = ApiService.instance.config;
    final String url = (cfg?.telegramUrl.isNotEmpty == true)
        ? cfg!.telegramUrl
        : 'https://t.me/bluevip';
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListenableBuilder(
        listenable: ActivationService.instance,
        builder: (context, _) {
          final ActivationService act = ActivationService.instance;
          final BvAppConfig? cfg = ApiService.instance.config;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // بطاقة الاشتراك
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: act.active
                        ? [
                            BvColors.green.withOpacity(.12),
                            BvColors.card,
                          ]
                        : [
                            BvColors.blue.withOpacity(.12),
                            BvColors.card,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BvColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      act.active
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_person_rounded,
                      color: act.active ? BvColors.green : BvColors.blueLight,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.active
                                ? 'اشتراك VIP مفعّل ✓'
                                : 'لا يوجد اشتراك مفعّل',
                            style: const TextStyle(
                              color: BvColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (act.expiresAt.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'الانتهاء: ${act.expiresAt}',
                              style: const TextStyle(
                                color: BvColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!act.active)
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ActivationScreen()),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: BvColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('تفعيل'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // قائمة الخيارات
              _tile(
                icon: Icons.sports_soccer_rounded,
                title: 'جدول المباريات',
                subtitle: 'المباريات المباشرة والقادمة والمنتهية',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MatchesScreen()),
                  );
                },
              ),
              _tile(
                icon: Icons.telegram_rounded,
                title: 'قناة التلغرام الرسمية',
                subtitle: 'آخر التحديثات والأكواد والعروض',
                onTap: _openTelegram,
              ),
              _tile(
                icon: Icons.sync_rounded,
                title: 'مزامنة حالة الاشتراك',
                subtitle: 'فحص التفعيل من الخادم يدوياً',
                onTap: _resync,
              ),
              if ((cfg?.notice ?? '').isNotEmpty)
                _tile(
                  icon: Icons.notifications_active_rounded,
                  title: 'إشعار الإدارة',
                  subtitle: cfg!.notice,
                  onTap: null,
                ),
              _tile(
                icon: Icons.system_update_rounded,
                title: 'فحص التحديثات',
                subtitle:
                    'الإصدار الحالي 1.0.0 — الأحدث: ${cfg?.latestVersion.isEmpty == true ? "—" : cfg?.latestVersion}',
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('أنت تستخدم أحدث إصدار متاح ✓'),
                      ),
                    );
                },
              ),
              _tile(
                icon: Icons.fingerprint_rounded,
                title: 'معرف الجهاز',
                subtitle: act.deviceId,
                onTap: null,
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Blue VIP v1.0.0 — تجربة المشاهدة الترفيهية الفائقة',
                  style: TextStyle(color: BvColors.muted, fontSize: 11.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BvColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BvColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: BvColors.blueLight, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: BvColors.text,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: BvColors.muted, fontSize: 11),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_left_rounded, color: BvColors.muted)
            : null,
      ),
    );
  }
}
