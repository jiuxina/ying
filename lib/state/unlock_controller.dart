import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unlock_state.dart';
import '../services/device_fingerprint.dart';
import '../services/storage_service.dart';
import '../services/unlock_service.dart';
import 'app_controller.dart';

class UnlockController extends StateNotifier<UnlockState> {
  UnlockController(
    this._storage, {
    UnlockGateway? gateway,
    DeviceFingerprint? fingerprint,
    UnlockState? initialState,
  }) : _gateway = gateway ?? UnlockService(),
       _fingerprint = fingerprint ?? DeviceFingerprint(),
       super(initialState ?? const UnlockState());

  final StorageService _storage;
  final UnlockGateway _gateway;
  final DeviceFingerprint _fingerprint;

  Future<void> load() async {
    state = await _storage.loadUnlockState();
  }

  Future<UnlockResult> verifyKey(String key) async {
    final error = validateUnlockKey(key);
    if (error != null) throw UnlockException('invalid_format', error);
    final deviceHash = await _fingerprint.hash();
    final result = await _gateway.verify(key: key, deviceHash: deviceHash);
    final next = UnlockState(
      unlocked: true,
      keyHash: result.keyHash,
      unlockToken: result.token,
      activatedAt: DateTime.now(),
    );
    await _storage.saveUnlockState(next);
    state = next;
    return result;
  }

  Future<void> resetForTesting() async {
    const next = UnlockState();
    await _storage.saveUnlockState(next);
    state = next;
  }
}

final unlockControllerProvider =
    StateNotifierProvider<UnlockController, UnlockState>(
      (ref) => UnlockController(ref.read(storageProvider)),
    );
