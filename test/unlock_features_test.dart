import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/app_config.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/unlock_features.dart';
import 'package:ying/services/device_fingerprint.dart';
import 'package:ying/services/unlock_service.dart';

void main() {
  test('validates key format', () {
    final valid = 'YING-${'A' * 40}';
    expect(validateUnlockKey(valid), isNull);
    expect(validateUnlockKey('YING-${'a' * 39}'), isNotNull);
    expect(validateUnlockKey('SHORT'), isNotNull);
    expect(validateUnlockKey(''), isNotNull);
  });

  test('sanitizes sponsor settings when locked', () {
    final locked = const AppSettings(
      widgetStyle: WidgetStyle.envelope,
      widgetMysteryMode: true,
      widgetQuoteMode: true,
      widgetFontFamily: 'mono',
      widgetTextOutline: true,
      widgetWallpaperColor: 0xFF112233,
      widgetWallpaperDarkColor: 0xFF223344,
      widgetWallpaperTextColor: 0xFFFFFFFF,
    );
    final sanitized = sanitizeSponsorSettings(locked);
    expect(sanitized.widgetStyle, WidgetStyle.card);
    expect(sanitized.widgetMysteryMode, isFalse);
    expect(sanitized.widgetQuoteMode, isFalse);
    expect(sanitized.widgetFontFamily, 'system');
    expect(sanitized.widgetTextOutline, isFalse);
    expect(sanitized.widgetWallpaperColor, -1);
    expect(sanitized.widgetWallpaperDarkColor, -1);
    expect(sanitized.widgetWallpaperTextColor, -1);
  });

  test('keeps free settings untouched when locked', () {
    const free = AppSettings(
      widgetStyle: WidgetStyle.photo,
      widgetShowProgress: true,
      widgetBackgroundPath: '/tmp/a.png',
      widgetListMode: true,
    );
    expect(sanitizeSponsorSettings(free), free);
  });

  test('device hash is deterministic and salted', () {
    final hash = hashDeviceId('android-id-1');
    final expected = sha256
        .convert(utf8.encode('ying-sponsor-v1:android-id-1'))
        .toString();
    expect(hash, expected);
    expect(hash, hasLength(64));
    expect(hashDeviceId('android-id-1'), hash);
    expect(hashDeviceId('android-id-2'), isNot(hash));
  });

  test('key format matches production config', () {
    final key = '${UnlockConfig.keyPrefix}${'Z' * UnlockConfig.keyLength}';
    expect(validateUnlockKey(key), isNull);
  });
}
