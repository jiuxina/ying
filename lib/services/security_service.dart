import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// 安全服务 - 管理生物识别验证和应用锁定
/// 
/// 功能：
/// - 生物识别验证（指纹/Face ID）
/// - 应用锁定状态管理
/// - PIN 码备用验证
/// - 验证超时设置
/// ============================================================================

/// 验证结果
enum AuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
  lockedOut,
  permanentlyLockedOut,
  error,
}

/// 安全服务类
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 状态
  bool _isAppLocked = false;
  bool _isPrivateUnlocked = false;
  DateTime? _lastAuthTime;
  String? _hashedPin;
  
  // 配置
  int _authTimeoutMinutes = 5; // 默认5分钟
  bool _biometricEnabled = false;
  bool _pinEnabled = false;

  // Getters
  bool get isAppLocked => _isAppLocked;
  bool get isPrivateUnlocked => _isPrivateUnlocked;
  bool get biometricEnabled => _biometricEnabled;
  bool get pinEnabled => _pinEnabled;
  int get authTimeoutMinutes => _authTimeoutMinutes;
  
  /// 是否需要验证（超时检查）
  bool get needsAuthentication {
    if (!_biometricEnabled && !_pinEnabled) return false;
    if (_lastAuthTime == null) return true;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastAuthTime!);
    return elapsed.inMinutes >= _authTimeoutMinutes;
  }

  /// 初始化服务
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _pinEnabled = prefs.getBool('pin_enabled') ?? false;
    _authTimeoutMinutes = prefs.getInt('auth_timeout_minutes') ?? 5;
    
    // 加载 PIN 码哈希
    _hashedPin = await _secureStorage.read(key: 'pin_hash');
    
    // 如果启用了生物识别，应用默认锁定
    if (_biometricEnabled || _pinEnabled) {
      _isAppLocked = true;
    }
  }

  /// 检查设备是否支持生物识别
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// 生物识别验证
  Future<AuthResult> authenticateWithBiometric({
    String localizedReason = '请验证身份以继续',
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return AuthResult.notAvailable;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _lastAuthTime = DateTime.now();
        _isAppLocked = false;
        _isPrivateUnlocked = true;
        return AuthResult.success;
      } else {
        return AuthResult.failed;
      }
    } on PlatformException catch (e) {
      debugPrint('生物识别验证错误: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case auth_error.lockedOut:
          return AuthResult.lockedOut;
        case auth_error.permanentlyLockedOut:
          return AuthResult.permanentlyLockedOut;
        case auth_error.notAvailable:
          return AuthResult.notAvailable;
        case auth_error.notEnrolled:
          return AuthResult.notAvailable;
        default:
          return AuthResult.error;
      }
    }
  }

  /// 设置 PIN 码
  Future<bool> setPin(String pin) async {
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      return false;
    }
    
    // 哈希 PIN 码
    final hash = _hashPin(pin);
    await _secureStorage.write(key: 'pin_hash', value: hash);
    _hashedPin = hash;
    
    // 启用 PIN
    _pinEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_enabled', true);
    
    return true;
  }

  /// 验证 PIN 码
  Future<bool> verifyPin(String pin) async {
    if (_hashedPin == null) return false;
    
    final hash = _hashPin(pin);
    final isValid = hash == _hashedPin;
    
    if (isValid) {
      _lastAuthTime = DateTime.now();
      _isAppLocked = false;
      _isPrivateUnlocked = true;
    }
    
    return isValid;
  }

  /// 移除 PIN 码
  Future<void> removePin() async {
    await _secureStorage.delete(key: 'pin_hash');
    _hashedPin = null;
    _pinEnabled = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_enabled', false);
  }

  /// 启用/禁用生物识别
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    
    if (enabled) {
      _isAppLocked = true;
    }
  }

  /// 设置验证超时（分钟）
  Future<void> setAuthTimeout(int minutes) async {
    _authTimeoutMinutes = minutes.clamp(1, 60);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auth_timeout_minutes', _authTimeoutMinutes);
  }

  /// 锁定应用
  void lockApp() {
    _isAppLocked = true;
    _isPrivateUnlocked = false;
    _lastAuthTime = null;
  }

  /// 解锁私密内容
  void unlockPrivate() {
    _isPrivateUnlocked = true;
    _lastAuthTime = DateTime.now();
  }

  /// 锁定私密内容
  void lockPrivate() {
    _isPrivateUnlocked = false;
  }

  /// 验证身份（优先生物识别，失败则使用 PIN）
  Future<AuthResult> authenticate({
    String localizedReason = '请验证身份以继续',
    bool preferBiometric = true,
  }) async {
    // 如果启用生物识别且优先使用
    if (preferBiometric && _biometricEnabled) {
      final result = await authenticateWithBiometric(
        localizedReason: localizedReason,
      );
      
      if (result == AuthResult.success) {
        return result;
      }
      
      // 如果生物识别不可用或被锁定，但 PIN 启用，继续尝试 PIN
      if (result == AuthResult.notAvailable || 
          result == AuthResult.lockedOut ||
          result == AuthResult.permanentlyLockedOut) {
        if (_pinEnabled) {
          // 返回特殊状态，表示需要 PIN 验证
          return AuthResult.notAvailable;
        }
      }
      
      return result;
    }
    
    // 使用 PIN 验证
    if (_pinEnabled) {
      return AuthResult.notAvailable; // 需要调用方显示 PIN 输入界面
    }
    
    return AuthResult.notAvailable;
  }

  /// 哈希 PIN 码（使用 SHA-256）
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'ying_salt_2024'); // 添加盐值
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 重置安全设置
  Future<void> resetSecurity() async {
    await removePin();
    await setBiometricEnabled(false);
    _authTimeoutMinutes = 5;
    _isAppLocked = false;
    _isPrivateUnlocked = false;
    _lastAuthTime = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auth_timeout_minutes', 5);
  }

  /// 获取生物识别类型描述
  Future<String> getBiometricTypeDescription() async {
    final types = await getAvailableBiometrics();
    
    if (types.isEmpty) {
      return '未检测到生物识别';
    }
    
    if (types.contains(BiometricType.face)) {
      return '面部识别';
    }
    
    if (types.contains(BiometricType.fingerprint)) {
      return '指纹识别';
    }
    
    if (types.contains(BiometricType.iris)) {
      return '虹膜识别';
    }
    
    if (types.contains(BiometricType.strong)) {
      return '强生物识别';
    }
    
    if (types.contains(BiometricType.weak)) {
      return '弱生物识别';
    }
    
    return '生物识别';
  }
}

/// 加密工具类
class CryptoUtils {
  /// 简单加密（用于敏感数据存储）
  static String encrypt(String plainText, String key) {
    final keyBytes = utf8.encode(key);
    final plainBytes = utf8.encode(plainText);
    
    final encrypted = <int>[];
    for (var i = 0; i < plainBytes.length; i++) {
      encrypted.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64Encode(encrypted);
  }

  /// 简单解密
  static String decrypt(String encryptedText, String key) {
    final keyBytes = utf8.encode(key);
    final encryptedBytes = base64Decode(encryptedText);
    
    final decrypted = <int>[];
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decrypted);
  }
}
