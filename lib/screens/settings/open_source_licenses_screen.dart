// ============================================================================
// 开放源代码许可页面
//
// 展示应用所使用的开源依赖及对应许可信息
// ============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';

class OpenSourceLicensesScreen extends StatelessWidget {
  const OpenSourceLicensesScreen({super.key});

  static const List<_LicenseItem> _flutterDependencies = [
    _LicenseItem('flutter', 'BSD-3-Clause', 'https://github.com/flutter/flutter'),
    _LicenseItem('flutter_localizations', 'BSD-3-Clause', 'https://github.com/flutter/flutter/tree/master/packages/flutter_localizations'),
    _LicenseItem('cupertino_icons', 'MIT', 'https://github.com/flutter/cupertino_icons'),
    _LicenseItem('provider', 'MIT', 'https://github.com/rrousselGit/provider'),
    _LicenseItem('sqflite', 'BSD-3-Clause', 'https://github.com/tekartik/sqflite'),
    _LicenseItem('path_provider', 'BSD-3-Clause', 'https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider'),
    _LicenseItem('shared_preferences', 'BSD-3-Clause', 'https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences'),
    _LicenseItem('intl', 'BSD-3-Clause', 'https://github.com/dart-lang/intl'),
    _LicenseItem('lunar', 'MIT', 'https://github.com/6tail/lunar-flutter'),
    _LicenseItem('path', 'BSD-3-Clause', 'https://github.com/dart-lang/path'),
    _LicenseItem('uuid', 'MIT', 'https://github.com/Daegalus/dart_uuid'),
    _LicenseItem('flutter_local_notifications', 'BSD-3-Clause', 'https://github.com/MaikuB/flutter_local_notifications'),
    _LicenseItem('timezone', 'BSD-3-Clause', 'https://github.com/srawlins/timezone'),
    _LicenseItem('home_widget', 'MIT', 'https://github.com/abhishek098/home_widget'),
    _LicenseItem('image_picker', 'BSD-3-Clause', 'https://github.com/flutter/packages/tree/main/packages/image_picker/image_picker'),
    _LicenseItem('url_launcher', 'BSD-3-Clause', 'https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher'),
    _LicenseItem('package_info_plus', 'BSD-3-Clause', 'https://github.com/fluttercommunity/plus_plugins/tree/main/packages/package_info_plus/package_info_plus'),
    _LicenseItem('vibration', 'MIT', 'https://github.com/benjamindean/flutter_vibration'),
    _LicenseItem('file_picker', 'Apache-2.0', 'https://github.com/miguelpruivo/flutter_file_picker'),
    _LicenseItem('google_fonts', 'Apache-2.0', 'https://github.com/material-foundation/flutter-packages/tree/main/packages/google_fonts/google_fonts'),
    _LicenseItem('gal', 'MIT', 'https://github.com/nickvdyck/gal'),
    _LicenseItem('permission_handler', 'MIT', 'https://github.com/Baseflow/flutter-permission-handler'),
    _LicenseItem('http', 'BSD-3-Clause', 'https://github.com/dart-lang/http'),
    _LicenseItem('flutter_markdown_plus', 'BSD-3-Clause', 'https://github.com/fzyzcjy/flutter_markdown'),
    _LicenseItem('webdav_client', 'MIT', 'https://github.com/xpwu/webdav_client'),
    _LicenseItem('flutter_secure_storage', 'BSD-3-Clause', 'https://github.com/juliansteenbakker/flutter_secure_storage'),
    _LicenseItem('table_calendar', 'Apache-2.0', 'https://github.com/alekhryfa/table_calendar'),
    _LicenseItem('share_plus', 'BSD-3-Clause', 'https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus/share_plus'),
    _LicenseItem('icalendar_parser', 'MIT', 'https://github.com/TesteurMankeke/icalendar_parser'),
    _LicenseItem('quick_actions', 'BSD-3-Clause', 'https://github.com/flutter/packages/tree/main/packages/quick_actions/quick_actions'),
    _LicenseItem('app_links', 'MIT', 'https://github.com/llfbandit/app_links'),
    _LicenseItem('confetti', 'MIT', 'https://github.com/fsh-cat/flutter_confetti'),
    _LicenseItem('image_cropper', 'MIT', 'https://github.com/hpoul/image_cropper'),
    _LicenseItem('flutter_overlay_window', 'MIT', 'https://github.com/X-Wei/flutter_overlay_window'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '本应用使用了多个开源项目。以下列表根据仓库依赖配置整理（pubspec.yaml）。详细条款请以各项目仓库内 LICENSE 文件为准。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Flutter / Dart 依赖', _flutterDependencies),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            '开放源代码许可',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_LicenseItem> items,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '${item.name} · ${item.license}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(item.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: SelectableText(
                        item.url,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LicenseItem {
  final String name;
  final String license;
  final String url;

  const _LicenseItem(this.name, this.license, this.url);
}
