import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_config.dart';
import 'glass_ui.dart';

class SponsorPage extends StatefulWidget {
  const SponsorPage({super.key});

  @override
  State<SponsorPage> createState() => _SponsorPageState();
}

class _SponsorPageState extends State<SponsorPage> {
  final _keyController = TextEditingController();
  Timer? _celebrationTimer;
  int _celebrationEpoch = 0;

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openSponsorLink() async {
    await Clipboard.setData(ClipboardData(text: SponsorConfig.sponsorUrl));
    if (!mounted) return;
    _showMessage('爱发电链接已复制，请粘贴到浏览器打开');
  }

  void _celebrate() {
    final input = _keyController.text.trim();
    if (input.isEmpty) {
      _showMessage('输入任意内容，礼花就会为你绽放');
      return;
    }
    _keyController.clear();
    HapticFeedback.mediumImpact();
    if (reduceMotionOf(context)) {
      _showMessage('礼花绽放，感谢支持');
      return;
    }
    setState(() => _celebrationEpoch++);
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _celebrationEpoch = 0);
    });
    _showMessage('礼花绽放，感谢支持');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  Row(
                    children: [
                      GlassIconButton(
                        key: const ValueKey('sponsor-back'),
                        icon: Icons.arrow_back_rounded,
                        tooltip: '返回',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '赞助支持',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '软件完全免费并开源，赞助仅用于支持开发，不解锁任何功能。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  GlassSurface(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlassSectionTitle(title: '功能全部免费'),
                        const SizedBox(height: 10),
                        for (final benefit in _sponsorBenefits) ...[
                          _BenefitRow(
                            icon: benefit.$1,
                            title: benefit.$2,
                            subtitle: benefit.$3,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassSurface(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlassSectionTitle(title: '赞助支持'),
                        const SizedBox(height: 10),
                        Text(
                          '喜欢萤的话，可以在爱发电请开发者喝杯咖啡。\n'
                          '下面输入框是一个小彩蛋：输入任意内容，礼花就会绽放。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _openSponsorLink,
                          icon: const Icon(Icons.favorite_rounded, size: 18),
                          label: const Text('复制爱发电主页链接'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('sponsor-key-input'),
                          controller: _keyController,
                          maxLines: 1,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: '彩蛋输入框',
                            hintText: '输入任意内容，点“礼花绽放”',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste_rounded),
                              tooltip: '粘贴',
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                final text = data?.text?.trim();
                                if (text == null || text.isEmpty) {
                                  _showMessage('剪贴板中没有内容');
                                  return;
                                }
                                _keyController.text = text;
                              },
                            ),
                          ),
                          onSubmitted: (_) => _celebrate(),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('sponsor-verify'),
                            onPressed: _celebrate,
                            icon: const Icon(Icons.celebration_rounded),
                            label: const Text('礼花绽放'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '源码：${SponsorConfig.sourceRepoUrl}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_celebrationEpoch > 0)
              IgnorePointer(
                child: _ConfettiBurst(
                  key: ValueKey(_celebrationEpoch),
                  onFinished: () {
                    if (mounted && _celebrationEpoch > 0) {
                      setState(() => _celebrationEpoch = 0);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: _FireworksPainter(progress: _controller.value),
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(20260823);
    final burstCount = 5;
    final colors = [
      const Color(0xFF0F766E),
      const Color(0xFFDB2777),
      const Color(0xFFD97706),
      const Color(0xFF4F46E5),
      const Color(0xFF16A085),
    ];
    for (var burst = 0; burst < burstCount; burst++) {
      final center = Offset(
        size.width * (0.12 + random.nextDouble() * 0.76),
        size.height * (0.12 + random.nextDouble() * 0.42),
      );
      final delay = burst / burstCount;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final paint = Paint()
        ..color = colors[burst % colors.length]
        ..style = PaintingStyle.fill;
      for (var i = 0; i < 26; i++) {
        final angle = (i / 26) * math.pi * 2 + burst;
        final radius = 12 + local * (34 + burst * 10);
        final p = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        final fade = (1 - local) * (0.9 - burst * 0.08);
        canvas.drawCircle(
          p,
          2.2 * (1 - local * 0.6),
          paint..color = paint.color.withValues(alpha: fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

const _sponsorBenefits = <(IconData, String, String)>[
  (Icons.celebration_outlined, '节日皮肤', '节日自动换肤'),
  (Icons.wallpaper_rounded, '壁纸取色', '小部件跟随壁纸配色'),
  (Icons.format_quote_outlined, '每日一句', '小部件每日轮播一句话'),
  (Icons.visibility_off_outlined, '神秘模式', '隐藏数字与日期'),
  (Icons.folder_open_outlined, '本地字体导入', '导入 TTF/OTF 应用到小部件'),
  (Icons.border_color_outlined, '文字描边', '文字描边效果'),
];
