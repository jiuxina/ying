import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 已验签的解锁凭证内容。
class UnlockToken {
  const UnlockToken({
    required this.keyHash,
    required this.plan,
    required this.deviceHash,
    required this.iat,
  });

  final String keyHash;
  final String plan;
  final String deviceHash;
  final int iat;
}

/// 用内嵌的 ECDSA P-256 公钥验证 Worker 返回的解锁凭证签名。
class UnlockTokenVerifier {
  UnlockTokenVerifier(List<int> publicKeyBytes)
    : _publicKeyBytes = Uint8List.fromList(publicKeyBytes);

  final Uint8List _publicKeyBytes;

  UnlockToken? verifyToken(String token) {
    final parts = token.split('.');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) return null;
    try {
      final payloadBytes = _decodeBase64Url(parts[0]);
      final signatureBytes = _decodeBase64Url(parts[1]);
      if (signatureBytes.length != 64 || !_verify(payloadBytes, signatureBytes)) {
        return null;
      }
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map<String, dynamic>) return null;
      final keyHash = payload['keyHash'];
      final plan = payload['plan'];
      final deviceHash = payload['deviceHash'];
      final iat = payload['iat'];
      if (keyHash is! String || plan is! String || deviceHash is! String) {
        return null;
      }
      return UnlockToken(
        keyHash: keyHash,
        plan: plan,
        deviceHash: deviceHash,
        iat: iat is int ? iat : 0,
      );
    } catch (_) {
      return null;
    }
  }

  bool _verify(List<int> message, List<int> signatureBytes) {
    try {
      final domain = ECCurve_prime256v1();
      final point = domain.curve.decodePoint(_publicKeyBytes);
      final signer = ECDSASigner(SHA256Digest())
        ..init(false, PublicKeyParameter<PublicKey>(ECPublicKey(point, domain)));
      final signature = ECSignature(
        _bigIntFromBytes(signatureBytes.sublist(0, 32)),
        _bigIntFromBytes(signatureBytes.sublist(32, 64)),
      );
      return signer.verifySignature(Uint8List.fromList(message), signature);
    } catch (_) {
      return false;
    }
  }

  static BigInt _bigIntFromBytes(List<int> bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }
    return value;
  }

  static Uint8List _decodeBase64Url(String value) {
    final padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
    return base64Url.decode(padded);
  }
}
