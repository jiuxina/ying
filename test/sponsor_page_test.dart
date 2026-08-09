import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/services/device_fingerprint.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/services/unlock_service.dart';
import 'package:ying/state/unlock_controller.dart';
import 'package:ying/ui/sponsor_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('verifies a pasted key and shows unlocked state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unlockControllerProvider.overrideWith(
            (ref) => UnlockController(
              StorageService(),
              gateway: const _FakeGateway(),
              fingerprint: _FakeFingerprint(),
            ),
          ),
        ],
        child: const MaterialApp(home: SponsorPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('sponsor-key-input')),
      'YING-${'A' * 40}',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('已解锁全部赞助功能'), findsOneWidget);
    expect(find.text('绑定设备：1 / 2'), findsOneWidget);
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
