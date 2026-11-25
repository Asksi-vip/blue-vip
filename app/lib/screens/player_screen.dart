import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// مشغل Blue VIP بأسلوب تطبيقات IPTV: تحكم مخصص (تشغيل/إيقاف + شريط
/// + ملء الشاشة) + تبديل تلقائي للسيرفر الاحتياطي عند فشل التشغيل
/// (رسالة "تعذر تشغيل هذا الرابط حالياً من المصدر").
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.urls,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;
  final List<String> urls;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  int _urlIndex = 0;
  bool _initialized = false;
  bool _hasError = false;
  String _activeUrl = '';
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.urls.isNotEmpty ? widget.urls.first : '';
    _startPlayer();
  }

  Future<void> _startPlayer() async {
    if (_activeUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    _disposeController();
    setState(() {
      _initialized = false;
      _hasError = false;
    });
    try {
      final VideoPlayerController c =
          VideoPlayerController.networkUrl(Uri.parse(_activeUrl));
      _controller = c;
      await c.initialize();
      await c.play();
      if (!mounted) return;
      setState(() => _initialized = true);
      _scheduleHide();
    } catch (_) {
      if (!mounted) return;
      // فشل المصدر الحالي → جرّب التالي تلقائياً
      _tryNextSource();
    }
  }

  void _tryNextSource() {
    final int next = _urlIndex + 1;
    if (next < widget.urls.length) {
      setState(() {
        _urlIndex = next;
        _activeUrl = widget.urls[next];
      });
      _startPlayer();
    } else {
      setState(() => _hasError = true);
    }
  }

  void _disposeController() {
    _retryTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _retryTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _controlsVisible
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(.7),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  if (widget.subtitle.isNotEmpty)
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            )
          : null,
      body: Center(
        child: _hasError
            ? _errorView()
            : _initialized
                ? _playerView()
                : _loadingView(),
      ),
    );
  }

  Widget _loadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: BvColors.blue),
        const SizedBox(height: 16),
        Text(
          'جاري تشغيل البث من المصدر ${_urlIndex + 1}…',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: BvColors.red, size: 46),
          const SizedBox(height: 14),
          const Text(
            'تعذر تشغيل هذا الرابط حالياً من المصدر',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'جرّب سيرفر آخر أو تحقق من اتصال الإنترنت',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _urlIndex = 0;
                  _activeUrl = widget.urls.isNotEmpty ? widget.urls.first : '';
                  _startPlayer();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(.4)),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.urls.length > 1)
                OutlinedButton.icon(
                  onPressed: () {
                    _urlIndex = -1;
                    _tryNextSource();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('سيرفر آخر'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BvColors.blueLight,
                    side: const BorderSide(color: BvColors.blue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerView() {
    final VideoPlayerController c = _controller!;
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
              child: VideoPlayer(c),
            ),
          ),
          if (_controlsVisible) _buildControls(c),
        ],
      ),
    );
  }

  Widget _buildControls(VideoPlayerController c) {
    return Container(
      color: Colors.black.withOpacity(.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 8),
          // منطقة وسطى: تشغيل/إيقاف كبير
          Expanded(
            child: Center(
              child: IconButton(
                onPressed: () {
                  if (c.value.isPlaying) {
                    c.pause();
                  } else {
                    c.play();
                    _scheduleHide();
                  }
                  setState(() {});
                },
                icon: Icon(
                  c.value.isPlaying
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // شريط التقدم + الوقت
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                VideoProgressIndicator(
                  c,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: BvColors.blue,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  children: [
                    Text(
                      _fmt(c.value.position),
                      style: const TextStyle(color: Colors.white, fontSize: 11.5),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(c.value.duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // شريط سفلي: التبديل بين المصادر
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                if (widget.urls.length > 1)
                  TextButton.icon(
                    onPressed: () => _showSourceSheet(context, c),
                    icon: const Icon(Icons.dns_rounded, size: 16),
                    label: Text(
                      'المصدر ${_urlIndex + 1} من ${widget.urls.length}',
                      style: const TextStyle(color: BvColors.blueLight, fontSize: 12),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final double v = c.value.volume > 0 ? 0 : 1;
                    c.setVolume(v);
                    setState(() {});
                  },
                  icon: Icon(
                    c.value.volume > 0
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ورقة اختيار السيرفر مثل "اختر سيرفر البث".
  void _showSourceSheet(BuildContext context, VideoPlayerController c) {
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
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (int i = 0; i < widget.urls.length; i++)
                ListTile(
                  leading: Icon(
                    _urlIndex == i
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _urlIndex == i ? BvColors.blue : BvColors.muted,
                    size: 20,
                  ),
                  title: Text(
                    'سيرفر ${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    widget.urls[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BvColors.muted, fontSize: 10.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _urlIndex = i;
                      _activeUrl = widget.urls[i];
                    });
                    _startPlayer();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
