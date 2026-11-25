import 'package:flutter/material.dart';

import '../services/activation_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// بوابة المشاهدة: إن كان الإجبار مفعلاً والجهاز غير مفعّل →
/// فتح شاشة التفعيل وإيقاف التشغيل. تعرف على كل الشاشات.
bool gateOrOpenActivation(BuildContext context) {
  if (ActivationService.instance.canWatch) return true;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ActivationScreen()),
  );
  return false;
}

/// شاشة تفعيل VIP: إدخال كود الاشتراك وربطه بمعرف الجهاز.
/// نفس نظام تطبيقات VIP: كود واحد = جهاز واحد بمدة محددة.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ActivationService.instance.load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final String code = _codeCtrl.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final ActivationResult res =
        await ActivationService.instance.activateCode(code);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: BvColors.green,
          ),
        );
      Navigator.of(context).pop();
    } else {
      setState(() => _error = res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BvColors.bg,
      appBar: AppBar(title: const Text('تفعيل اشتراك VIP')),
      body: ListenableBuilder(
        listenable: ActivationService.instance,
        builder: (context, _) {
          final ActivationService act = ActivationService.instance;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // بطاقة الحالة الحالية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BvColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: act.active
                        ? BvColors.green.withOpacity(.5)
                        : BvColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      act.active
                          ? Icons.verified_rounded
                          : Icons.lock_clock_rounded,
                      color: act.active ? BvColors.green : BvColors.muted,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.active
                                ? 'اشتراكك مفعّل ✓'
                                : 'الجهاز غير مفعّل',
                            style: TextStyle(
                              color: act.active
                                  ? BvColors.green
                                  : BvColors.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            act.active && act.expiresAt.isNotEmpty
                                ? 'ينتهي في: ${act.expiresAt}'
                                : 'أدخل كود التفعيل للاستمتاع بكل المحتوى',
                            style: const TextStyle(
                              color: BvColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BvColors.red.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BvColors.red.withOpacity(.4)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: BvColors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'كود التفعيل',
                style: TextStyle(
                  color: BvColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: BvColors.text,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: 'BV-XXXX-XXXX',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _activate,
                  style: FilledButton.styleFrom(
                    backgroundColor: BvColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'تفعيل الاشتراك',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BvColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BvColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معرف جهازك (أرسله للدعم عند الحاجة)',
                      style: TextStyle(
                        color: BvColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act.deviceId,
                      style: const TextStyle(
                        color: BvColors.blueLight,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                      ),
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
