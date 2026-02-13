import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/settings_provider.dart';
import '../../services/webdav_service.dart';
import '../../services/cloud_sync_service.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isTesting = false;
  bool _isSyncing = false;
  String? _testResult;
  bool _isOffline = false;

  late WebDAVService _webdavService;
  late CloudSyncService _cloudSyncService;

  @override
  void initState() {
    super.initState();
    _webdavService = WebDAVService();
    _cloudSyncService = CloudSyncService(webdavService: _webdavService);
    _checkConnectivity();
    
    // 加载已保存的配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _urlController.text = settings.webdavUrl;
      _usernameController.text = settings.webdavUsername;
      _passwordController.text = settings.webdavPassword;
      
      // 初始化WebDAV客户端
      if (settings.isWebdavConfigured) {
        _webdavService.initialize(WebDAVConfig(
          url: settings.webdavUrl,
          username: settings.webdavUsername,
          password: settings.webdavPassword,
        ));
      }
    });
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (mounted) {
        setState(() => _isOffline = result.isEmpty || result.first.rawAddress.isEmpty);
      }
    } on SocketException catch (_) {
      if (mounted) {
        setState(() => _isOffline = true);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整的连接信息')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    _webdavService.initialize(WebDAVConfig(
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    ));

    final success = await _webdavService.testConnection();

    if (!mounted) return;
    
    setState(() {
      _isTesting = false;
      _testResult = success ? 'success' : 'failed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check : Icons.error, color: success ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(success ? '连接成功' : '连接失败'),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.saveWebdavCredentials(
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置已保存')),
    );
  }

  Future<void> _backup() async {
    if (!_isConfigValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置并测试连接'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    final result = await _cloudSyncService.backup();

    if (!mounted) return;

    setState(() => _isSyncing = false);

    if (result.success) {
      HapticFeedback.heavyImpact();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.updateLastSyncTime();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 备份成功'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ 备份失败: ${result.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _restore() async {
    if (!_isConfigValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置并测试连接'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 警告'),
        content: const Text(
          '恢复操作将覆盖本地所有数据，且无法撤销！\n\n建议在恢复前先执行备份操作。',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            child: const Text('确认覆盖恢复'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    final result = await _cloudSyncService.restore();

    if (!mounted) return;

    setState(() => _isSyncing = false);

    if (result.success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 恢复成功，请重启应用以应用更改'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ 恢复失败: ${result.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isConfigValid() {
    return _urlController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _testResult == 'success';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云同步'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: '保存配置',
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 离线提示
              if (_isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '当前无网络连接',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '同步功能需要网络连接才能使用',
                              style: TextStyle(fontSize: 12, color: Colors.orange.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: _checkConnectivity,
                        tooltip: '重新检测',
                      ),
                    ],
                  ),
                ),
              // 连接配置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          const Text('WebDAV 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '服务器地址',
                          hintText: 'https://dav.example.com',
                          prefixIcon: Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: _isTesting ? null : _testConnection,
                          child: _isTesting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.wifi_tethering),
                                    const SizedBox(width: 8),
                                    const Text('测试连接'),
                                    if (_testResult != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        _testResult == 'success' ? Icons.check_circle : Icons.error,
                                        color: _testResult == 'success' ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 同步操作
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sync, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          const Text('同步操作', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (settings.lastSyncTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '上次同步: ${DateFormat('yyyy-MM-dd HH:mm').format(settings.lastSyncTime!)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSyncing ? null : _backup,
                              icon: _isSyncing
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.cloud_upload),
                              label: const Text('备份到云端'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _isSyncing ? null : _restore,
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('从云端恢复'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 自动同步
              Card(
                child: SwitchListTile(
                  title: const Text('自动同步'),
                  subtitle: const Text('打开应用时自动同步'),
                  value: settings.autoSyncEnabled,
                  onChanged: (value) => settings.setAutoSyncEnabled(value),
                ),
              ),
              const SizedBox(height: 16),
              // 帮助说明
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('帮助', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '支持标准 WebDAV 协议的云存储服务，如：\n'
                        '• 坚果云\n'
                        '• Nextcloud\n'
                        '• Alist\n'
                        '• 其他 WebDAV 服务',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
