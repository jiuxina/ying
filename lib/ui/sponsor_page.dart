import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config.dart';
import '../models/unlock_state.dart';
import '../services/unlock_service.dart';
import '../state/unlock_controller.dart';
import 'glass_ui.dart';

class SponsorPage extends ConsumerStatefulWidget {
  const SponsorPage({super.key});

  @override
  ConsumerState<SponsorPage> createState() => _SponsorPageState();
}

class _SponsorPageState extends ConsumerState<SponsorPage> {
  final _keyController = TextEditingController();
  bool _busy = false;
  String? _error;
  int? _deviceCount;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _pasteKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _showMessage('剪贴板中没有内容');
      return;
    }
    _keyController.text = text;
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(unlockControllerProvider.notifier)
          .verifyKey(_keyController.text);
      if (!mounted) return;
      setState(() => _deviceCount = result.deviceCount);
      _showMessage('赞助功能已解锁');
    } on UnlockException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '验证失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSponsorLink() async {
    await Clipboard.setData(ClipboardData(text: UnlockConfig.sponsorUrl));
    if (!mounted) return;
    _showMessage('爱发电链接已复制，请粘贴到浏览器打开');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unlockControllerProvider);
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
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
                '一次赞助 ¥5，解锁全部赞助功能；核心功能永久免费。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (state.isUnlocked) _UnlockedCard(state: state, count: _deviceCount),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassSectionTitle(title: '赞助解锁内容'),
                    const SizedBox(height: 10),
                    for (final benefit in _sponsorBenefits) ...[
                      _BenefitRow(icon: benefit.$1, title: benefit.$2, subtitle: benefit.$3),
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
                    const GlassSectionTitle(title: '如何解锁'),
                    const SizedBox(height: 10),
                    Text(
                      '1. 在爱发电完成 ¥5 赞助，平台会自动发送一把密钥。\n'
                      '2. 把密钥粘贴到下方输入框并验证。\n'
                      '3. 验证成功后离线可用；每把密钥最多绑定 2 台设备。',
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
                      enabled: !_busy,
                      maxLines: 1,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: '解锁密钥',
                        hintText: '粘贴爱发电发送的 YING- 密钥',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste_rounded),
                          tooltip: '粘贴',
                          onPressed: _busy ? null : _pasteKey,
                        ),
                      ),
                      onSubmitted: (_) => _busy ? null : _verify(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('sponsor-verify'),
                        onPressed: _busy ? null : _verify,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('验证解锁'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '卸载重装或换设备后，重新输入同一把密钥即可恢复，不需要再次赞助。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard({required this.state, required this.count});

  final UnlockState state;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF0F766E), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已解锁全部赞助功能',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '绑定设备：${count ?? 1} / ${UnlockConfig.maxDevices}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  (Icons.mail_outline, '整活样式', '神秘信封、时间胶囊、复古 CRT、霓虹灯牌、像素血条、镜像整活'),
  (Icons.celebration_outlined, '节日皮肤', '节日自动换肤'),
  (Icons.wallpaper_rounded, '壁纸取色', '小部件跟随壁纸配色'),
  (Icons.format_quote_outlined, '每日一句', '小部件每日轮播一句话'),
  (Icons.visibility_off_outlined, '神秘模式', '隐藏数字与日期'),
  (Icons.folder_open_outlined, '本地字体导入', '导入 TTF/OTF 应用到小部件'),
  (Icons.border_color_outlined, '文字描边', '文字描边效果'),
];
