import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import '../../services/security_service.dart';

/// ============================================================================
/// 安全设置页面
/// 
/// 功能：
/// - 生物识别开关
/// - PIN 码设置
/// - 验证超时设置
/// ============================================================================

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  int _authTimeoutMinutes = 5;
  String _biometricType = '';
  bool _isLoading = true;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _securityService.initialize();
    
    setState(() {
      _biometricEnabled = _securityService.biometricEnabled;
      _pinEnabled = _securityService.pinEnabled;
      _authTimeoutMinutes = _securityService.authTimeoutMinutes;
      _isLoading = false;
    });
    
    // 检查生物识别可用性
    _isBiometricAvailable = await _securityService.isBiometricAvailable();
    _biometricType = await _securityService.getBiometricTypeDescription();
    
    if (mounted) setState(() {});
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      // 禁用生物识别
      await _securityService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已关闭生物识别验证')),
        );
      }
      return;
    }
    
    // 启用生物识别前先验证
    final result = await _securityService.authenticateWithBiometric(
      localizedReason: '请验证身份以启用生物识别解锁',
    );
    
    if (result == AuthResult.success) {
      await _securityService.setBiometricEnabled(true);
      setState(() => _biometricEnabled = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已启用 $_biometricType 验证')),
        );
      }
    } else if (result == AuthResult.notAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设备不支持生物识别或未设置')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，无法启用')),
        );
      }
    }
  }

  Future<void> _showSetPinDialog() async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    bool obscurePin = true;
    bool obscureConfirm = true;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('设置 PIN 码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                obscureText: obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '输入 6 位数字 PIN 码',
                  suffixIcon: IconButton(
                    icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscurePin = !obscurePin),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '确认 PIN 码',
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (pinController.text.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN 码必须是 6 位数字')),
                  );
                  return;
                }
                
                if (pinController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('两次输入的 PIN 码不一致')),
                  );
                  return;
                }
                
                final success = await _securityService.setPin(pinController.text);
                Navigator.pop(context);
                
                if (success) {
                  this.setState(() => _pinEnabled = true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN 码设置成功')),
                    );
                  }
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemovePinDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除 PIN 码'),
        content: const Text('确定要移除 PIN 码吗？移除后需要重新设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _securityService.removePin();
      setState(() => _pinEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN 码已移除')),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _showVerifyPinDialog() async {
    final TextEditingController pinController = TextEditingController();
    bool obscurePin = true;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('验证 PIN 码'),
          content: TextField(
            controller: pinController,
            obscureText: obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: '输入 PIN 码',
              suffixIcon: IconButton(
                icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => obscurePin = !obscurePin),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (pinController.text.length == 6) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('验证'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      final isValid = await _securityService.verifyPin(pinController.text);
      if (isValid && mounted) {
        Navigator.pop(this.context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('PIN 码错误')),
        );
      }
    }
  }

  void _showTimeoutOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '验证超时时间',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            _buildTimeoutOption(1, '1 分钟'),
            _buildTimeoutOption(5, '5 分钟（推荐）'),
            _buildTimeoutOption(15, '15 分钟'),
            _buildTimeoutOption(30, '30 分钟'),
            _buildTimeoutOption(60, '1 小时'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutOption(int minutes, String label) {
    final isSelected = _authTimeoutMinutes == minutes;
    
    return ListTile(
      title: Text(label),
      trailing: isSelected 
        ? const Icon(Icons.check, color: Colors.green) 
        : null,
      onTap: () async {
        await _securityService.setAuthTimeout(minutes);
        setState(() => _authTimeoutMinutes = minutes);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: AppBackground(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 生物识别设置
                    const SectionHeader(title: '生物识别', icon: Icons.fingerprint),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(_biometricType.isNotEmpty 
                              ? _biometricType 
                              : '生物识别解锁'),
                            subtitle: Text(
                              _isBiometricAvailable 
                                ? '使用 $_biometricType 解锁应用' 
                                : '设备不支持或未设置生物识别',
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.fingerprint,
                                color: Colors.purple,
                              ),
                            ),
                            value: _biometricEnabled,
                            onChanged: _isBiometricAvailable 
                              ? _toggleBiometric 
                              : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PIN 码设置
                    const SectionHeader(title: 'PIN 码备用', icon: Icons.pin),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.pin,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(_pinEnabled ? 'PIN 码已设置' : '设置 PIN 码'),
                            subtitle: Text(
                              _pinEnabled 
                                ? '点击更改或移除 PIN 码' 
                                : '作为生物识别的备用方案',
                            ),
                            trailing: _pinEnabled 
                              ? const Icon(Icons.chevron_right) 
                              : const Icon(Icons.add_circle_outline),
                            onTap: () {
                              if (_pinEnabled) {
                                _showRemovePinDialog();
                              } else {
                                _showSetPinDialog();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 超时设置
                    if (_biometricEnabled || _pinEnabled) ...[
                      const SectionHeader(title: '验证设置', icon: Icons.timer),
                      const SizedBox(height: 8),
                      GlassCard(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.timer,
                              color: Colors.orange,
                            ),
                          ),
                          title: const Text('验证超时'),
                          subtitle: Text('$_authTimeoutMinutes 分钟后需要重新验证'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showTimeoutOptions,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 说明
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '关于私密事件',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• 私密事件在主列表和小部件中隐藏\n'
                              '• 需要验证身份才能查看私密事件\n'
                              '• 搜索结果中不包含私密事件\n'
                              '• 导出数据时可选择是否包含私密事件',
                              style: TextStyle(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
            '安全设置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
