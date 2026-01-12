import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../utils/constants.dart';
import '../../services/update_service.dart';
import '../common/ui_helpers.dart';

class AboutCard extends StatefulWidget {
  final String version;

  const AboutCard({
    super.key,
    required this.version,
  });

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard> {
  bool _isCheckingUpdate = false;

  Future<void> _launchUrl(String urlString) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    
    try {
      final updateInfo = await UpdateService.checkForUpdate(AppConstants.appVersion);
      
      if (!mounted) return;
      
      if (updateInfo != null && updateInfo.hasUpdate) {
        _showUpdateDialog(updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check, color: Colors.green),
                SizedBox(width: 12),
                Text('已是最新版本'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查更新失败: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.update, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Flexible(child: Text('发现新版本')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('v${info.latestVersion} 已发布，是否立即更新？'),
              const SizedBox(height: 12),
              ConstrainedBox(
                 constraints: const BoxConstraints(maxHeight: 200),
                 child: Markdown(
                   data: info.changelog,
                   shrinkWrap: true,
                   padding: EdgeInsets.zero,
                   styleSheet: MarkdownStyleSheet(
                     p: Theme.of(context).textTheme.bodySmall,
                     h1: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                     h2: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                     listBullet: Theme.of(context).textTheme.bodySmall,
                   ),
                 ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (info.downloadUrl.isNotEmpty) {
                _startDownload(info);
              } else {
                 _launchUrl(AppConstants.githubUrl);
              }
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload(UpdateInfo info) async {
    final progressNotifier = ValueNotifier<double>(0.0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('正在下载更新'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: value),
                      const SizedBox(height: 8),
                      Text('${(value * 100).toStringAsFixed(1)}%'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('优先使用镜像加速下载...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await UpdateService.downloadAndInstallUpdate(
        info.downloadUrl, 
        'update_${info.latestVersion}.apk',
        onProgress: (progress) {
          progressNotifier.value = progress;
        },
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载或安装失败，建议手动下载')),
        );
        _launchUrl(info.downloadUrl);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新出错: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '关于', icon: Icons.info),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'app.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('版本 ${widget.version}'),
              ),
              const Divider(height: 1),
              // 检查更新
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isCheckingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update, color: Colors.green),
                ),
                title: const Text('检查更新'),
                subtitle: const Text('检查是否有新版本'),
                trailing: TextButton(
                  onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                  child: const Text('检查'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const IconBox(icon: Icons.person, color: Colors.teal),
                title: const Text('作者'),
                subtitle: const Text(AppConstants.author),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const IconBox(icon: Icons.code, color: Colors.blue),
                title: const Text('GitHub 开源仓库'),
                subtitle: const Text('查看源代码和提交反馈'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launchUrl(AppConstants.githubUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const IconBox(icon: Icons.mail, color: Colors.red),
                title: const Text('反馈建议'),
                subtitle: const Text(AppConstants.feedbackEmail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launchUrl('mailto:${AppConstants.feedbackEmail}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

