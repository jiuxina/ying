import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../app_version.dart';
import 'unlock_token_verifier.dart';

class UnlockResult {
  const UnlockResult({
    required this.keyHash,
    required this.token,
    required this.deviceCount,
  });

  final String keyHash;
  final String token;
  final int deviceCount;
}

class UnlockException implements Exception {
  const UnlockException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// 验证入口抽象，便于测试注入假的网关。
abstract class UnlockGateway {
  Future<UnlockResult> verify({
    required String key,
    required String deviceHash,
  });
}

class UnlockService implements UnlockGateway {
  UnlockService({
    String? baseUrl,
    http.Client? client,
    UnlockTokenVerifier? verifier,
  }) : _baseUrl = baseUrl ?? UnlockConfig.apiBaseUrl,
       _client = client ?? http.Client(),
       _verifier =
           verifier ??
           UnlockTokenVerifier(base64Decode(UnlockConfig.publicKeyRawBase64));

  final String _baseUrl;
  final http.Client _client;
  final UnlockTokenVerifier _verifier;

  @override
  Future<UnlockResult> verify({
    required String key,
    required String deviceHash,
  }) async {
    if (!UnlockConfig.isApiConfigured) {
      throw const UnlockException('not_configured', '验证服务尚未配置');
    }
    try {
      final response = await _client
          .post(
            Uri.parse('${_baseUrl.replaceAll(RegExp(r'/$'), '')}/v1/verify'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'key': key.trim(),
              'deviceHash': deviceHash,
              'appVersion': appVersion,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final Map<String, dynamic> body;
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        throw const UnlockException('bad_response', '服务返回异常，请稍后重试');
      }
      if (response.statusCode == 200 && body['ok'] == true) {
        final token = body['token'];
        final keyHash = body['keyHash'];
        if (token is! String || keyHash is! String) {
          throw const UnlockException('bad_response', '服务返回异常，请稍后重试');
        }
        final parsed = _verifier.verifyToken(token);
        if (parsed == null ||
            parsed.keyHash != keyHash ||
            parsed.deviceHash != deviceHash) {
          throw const UnlockException('bad_token', '验证凭证校验失败');
        }
        return UnlockResult(
          keyHash: keyHash,
          token: token,
          deviceCount: (body['deviceCount'] as num?)?.toInt() ?? 1,
        );
      }
      throw UnlockException(
        body['code'] as String? ?? 'unknown',
        body['message'] as String? ?? '验证失败，请稍后重试',
      );
    } on UnlockException {
      rethrow;
    } on TimeoutException {
      throw const UnlockException('timeout', '网络超时，请稍后重试');
    } catch (_) {
      throw const UnlockException('network', '网络错误，请检查网络后重试');
    }
  }
}

/// 校验用户输入的密钥格式，返回错误文案；合法时返回 null。
String? validateUnlockKey(String key) {
  final trimmed = key.trim();
  if (!trimmed.startsWith(UnlockConfig.keyPrefix)) return '密钥格式不正确';
  final body = trimmed.substring(UnlockConfig.keyPrefix.length);
  if (body.length != UnlockConfig.keyLength ||
      !RegExp(r'^[A-Za-z0-9]+$').hasMatch(body)) {
    return '密钥格式不正确';
  }
  return null;
}
