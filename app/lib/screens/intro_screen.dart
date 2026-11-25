import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// شاشة الترحيب مثل نظام IraqMax: شعار + "مرحباً بك في Blue VIP"
/// + التاغلاين + زر "دخول التطبيق والاستمتاع" + زر قناة التلغرام الرسمية.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  Future<void> _openTelegram(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final BvAppConfig cfg = ApiService.instance.config ?? const BvAppConfig();
    return Scaffold(
      backgroundColor: BvColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF152238), BvColors.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // الشعار داخل إطار متوهج
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: BvColors.blue.withOpacity(.55),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BvColors.blue.withOpacity(.25),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/brand/blue_vip_badge.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'مرحباً بك في ${cfg.appName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BvColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cfg.tagline.isNotEmpty
                      ? cfg.tagline
                      : 'تجربة المشاهدة الترفيهية الفائقة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BvColors.blueLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تطبيق البث المباشر والأفلام والمسلسلات الفائق السرعة '
                  'مع دعم قوائم تشغيل متعددة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BvColors.muted,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const Spacer(flex: 2),
                // زر الدخول الرئيسي
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        'دخول التطبيق والاستمتاع',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: BvColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // زر التلغرام الرسمي
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final String url = cfg.telegramUrl.isNotEmpty
                          ? cfg.telegramUrl
                          : 'https://t.me/bluevip';
                      _openTelegram(url);
                    },
                    icon: const Icon(Icons.telegram_rounded, size: 20),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'الانضمام لقناة التلغرام الرسمية',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BvColors.blueLight,
                      side: const BorderSide(color: BvColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
