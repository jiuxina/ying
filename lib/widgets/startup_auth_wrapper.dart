import 'package:flutter/material.dart';
import '../services/security_service.dart';

/// 启动验证包装器
///
/// 在应用启动时检查生物识别锁，如果启用则要求用户验证
class StartupAuthWrapper extends StatefulWidget {
  final Widget child;

  const StartupAuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<StartupAuthWrapper> createState() => _StartupAuthWrapperState();
}

class _StartupAuthWrapperState extends State<StartupAuthWrapper> {
  final SecurityService _securityService = SecurityService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _biometricEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // 检查是否启用了生物识别锁
      final biometricEnabled = _securityService.biometricEnabled;

      if (!biometricEnabled) {
        // 未启用生物识别锁，直接进入应用
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _biometricEnabled = false;
        });
        return;
      }

      setState(() {
        _biometricEnabled = true;
      });

      // 检查是否需要验证（超时检查）
      final needsAuth = _securityService.needsAuthentication;
      if (!needsAuth) {
        // 未超时，无需验证
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }

      // 需要验证，尝试生物识别
      final result = await _securityService.authenticateWithBiometric(
        localizedReason: '验证身份以解锁应用',
      );

      if (result == AuthResult.success) {
        // 验证成功，更新最后验证时间
        await _securityService.setAuthTimeout(_securityService.authTimeoutMinutes);
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      } else {
        // 验证失败
        setState(() {
          _isLoading = false;
          _errorMessage = '验证失败，请重试';
        });
      }
    } catch (e) {
      debugPrint('启动验证失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '验证出错: $e';
      });
    }
  }

  Future<void> _retryAuthentication() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _checkAuthentication();
  }

  Future<void> _showPinDialog() async {
    final pin = await _showPinInputDialog();
    if (pin != null) {
      final valid = await _securityService.verifyPin(pin);
      if (valid) {
        await _securityService.setAuthTimeout(_securityService.authTimeoutMinutes);
        setState(() {
          _isAuthenticated = true;
        });
      } else {
        setState(() {
          _errorMessage = 'PIN 码错误';
        });
      }
    }
  }

  Future<String?> _showPinInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('输入 PIN 码'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入 6 位 PIN 码',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '正在验证身份...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // 已验证或未启用生物识别
    if (_isAuthenticated) {
      return widget.child;
    }

    // 验证失败，显示重试界面
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '需要验证',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
              // 生物识别按钮
              ElevatedButton.icon(
                onPressed: _retryAuthentication,
                icon: const Icon(Icons.fingerprint),
                label: const Text('生物识别验证'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              // PIN 码验证
              TextButton.icon(
                onPressed: _showPinDialog,
                icon: const Icon(Icons.pin),
                label: const Text('使用 PIN 码验证'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
