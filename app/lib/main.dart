import 'package:flutter/material.dart';

import 'services/activation_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/intro_screen.dart';

/// Blue VIP — تطبيق البث المباشر والأفلام والمسلسلات والمباريات.
/// يدخل على شاشة الترحيب مباشرة ويجيب الإعدادات والكتالوج بالخلفية.
void main() {
  runApp(const BlueVipApp());
}

class BlueVipApp extends StatelessWidget {
  const BlueVipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blue VIP',
      debugShowCheckedModeBanner: false,
      theme: buildBvTheme(),
      // واجهة عربية RTL كاملة مثل النظام الأصلي
      builder: (BuildContext context, Widget? child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const _Boot(),
    );
  }
}

/// تهيئة أولية: جلب الإعدادات + تفعيل الجهاز ثم شاشة الترحيب.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ActivationService.instance.load();
    await ApiService.instance.loadConfig();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _ready
          ? const IntroScreen(key: ValueKey<String>('intro'))
          : const _Splash(key: ValueKey<String>('splash')),
    );
  }
}

/// شاشة انطلاق سريعة أثناء جلب الإعدادات.
class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BvColors.blue.withOpacity(.5)),
                boxShadow: [
                  BoxShadow(color: BvColors.blue.withOpacity(.2), blurRadius: 30),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset('assets/brand/blue_vip_badge.png'),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Blue VIP',
              style: TextStyle(
                color: BvColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تجربة المشاهدة الترفيهية الفائقة',
              style: TextStyle(color: BvColors.blueLight, fontSize: 12.5),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: BvColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
