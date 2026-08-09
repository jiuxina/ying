import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/unlock_state.dart';
import 'package:ying/services/device_fingerprint.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/services/unlock_service.dart';
import 'package:ying/state/unlock_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('verifies a key and persists the unlock state', () async {
    final storage = StorageService();
    final controller = UnlockController(
      storage,
      gateway: const _FakeGateway(),
      fingerprint: _FakeFingerprint(),
    );

    final result = await controller.verifyKey('YING-${'A' * 40}');

    expect(result.deviceCount, 1);
    expect(controller.state.isUnlocked, isTrue);
    expect(controller.state.keyHash, 'key-hash');
    final restored = await storage.loadUnlockState();
    expect(restored.isUnlocked, isTrue);
  });

  test('loads persisted unlock state on startup', () async {
    final storage = StorageService();
    await storage.saveUnlockState(
      const UnlockState(
        unlocked: true,
        keyHash: 'saved-hash',
        unlockToken: 'saved-token',
        activatedAt: null,
      ),
    );
    final controller = UnlockController(
      storage,
      gateway: const _FakeGateway(),
      fingerprint: _FakeFingerprint(),
    );
    await controller.load();
    expect(controller.state.isUnlocked, isTrue);
    expect(controller.state.keyHash, 'saved-hash');
  });
}

class _FakeGateway implements UnlockGateway {
  const _FakeGateway();

  @override
  Future<UnlockResult> verify({
    required String key,
    required String deviceHash,
  }) async {
    return const UnlockResult(
      keyHash: 'key-hash',
      token: 'payload.sig',
      deviceCount: 1,
    );
  }
}

class _FakeFingerprint extends DeviceFingerprint {
  @override
  Future<String> hash() async => 'device-hash';
}
