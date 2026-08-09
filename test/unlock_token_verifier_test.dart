import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:ying/services/unlock_token_verifier.dart';

void main() {
  test('verifies a valid ECDSA P-256 token and rejects tampering', () {
    final pair = _generateKeyPair();
    final publicKey = pair.publicKey as ECPublicKey;
    final privateKey = pair.privateKey as ECPrivateKey;
    final publicRaw = _publicRaw(publicKey);

    final payload = jsonEncode({
      'v': 1,
      'keyHash': 'a' * 64,
      'plan': 'r5',
      'deviceHash': 'b' * 64,
      'iat': 1,
    });
    final payloadBytes = Uint8List.fromList(utf8.encode(payload));
    final signature = _sign(privateKey, payloadBytes);
    final token =
        '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature)}';

    final verifier = UnlockTokenVerifier(publicRaw);
    final parsed = verifier.verifyToken(token);
    expect(parsed, isNotNull);
    expect(parsed!.keyHash, 'a' * 64);
    expect(parsed.plan, 'r5');
    expect(parsed.deviceHash, 'b' * 64);

    final tampered = '${token.substring(0, token.length - 2)}AA';
    expect(verifier.verifyToken(tampered), isNull);
    expect(verifier.verifyToken('garbage'), isNull);
  });
}

AsymmetricKeyPair<PublicKey, PrivateKey> _generateKeyPair() {
  final domain = ECCurve_prime256v1();
  final random = Random.secure();
  final seed = Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
  final rng = FortunaRandom()..seed(KeyParameter(seed));
  final generator = ECKeyGenerator()
    ..init(
      ParametersWithRandom(ECKeyGeneratorParameters(domain), rng),
    );
  return generator.generateKeyPair();
}

Uint8List _publicRaw(ECPublicKey publicKey) {
  final x = publicKey.Q!.x!.toBigInteger()!;
  final y = publicKey.Q!.y!.toBigInteger()!;
  return Uint8List.fromList(
    [0x04, ..._fixedBytes(x, 32), ..._fixedBytes(y, 32)],
  );
}

Uint8List _sign(ECPrivateKey privateKey, Uint8List message) {
  final random = Random.secure();
  final seed = Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
  final rng = FortunaRandom()..seed(KeyParameter(seed));
  final signer = ECDSASigner(SHA256Digest())
    ..init(
      true,
      ParametersWithRandom(PrivateKeyParameter<PrivateKey>(privateKey), rng),
    );
  final signature = signer.generateSignature(message) as ECSignature;
  return Uint8List.fromList([
    ..._fixedBytes(signature.r, 32),
    ..._fixedBytes(signature.s, 32),
  ]);
}

List<int> _fixedBytes(BigInt value, int length) {
  final hex = value.toRadixString(16).padLeft(length * 2, '0');
  return List.generate(
    length,
    (index) => int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
  );
}
