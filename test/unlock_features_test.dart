import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/app_config.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/unlock_features.dart';
import 'package:ying/models/widget_element_style.dart';
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
      widgetElementStyles: {
        'title': WidgetElementStyle(
          visible: WidgetElementVisible.show,
          size: WidgetElementSize.large,
          colorMode: WidgetColorMode.custom,
          color: 0xFFE91E63,
          align: WidgetAlign.center,
        ),
        'prevButton': WidgetElementStyle(
          visible: WidgetElementVisible.hide,
        ),
      },
      widgetVerticalAlign: WidgetVerticalAlign.bottom,
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
    expect(
      sanitized.widgetElementStyles['title']?.visible,
      WidgetElementVisible.follow,
    );
    expect(
      sanitized.widgetElementStyles['prevButton']?.visible,
      WidgetElementVisible.follow,
    );
    expect(
      sanitized.widgetElementStyles['title']?.size,
      WidgetElementSize.large,
    );
    expect(
      sanitized.widgetElementStyles['title']?.colorMode,
      WidgetColorMode.custom,
    );
    expect(
      sanitized.widgetElementStyles['title']?.color,
      0xFFE91E63,
    );
    expect(
      sanitized.widgetElementStyles['title']?.align,
      WidgetAlign.center,
    );
    expect(sanitized.widgetVerticalAlign, WidgetVerticalAlign.bottom);
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

  test('embedded public key is a valid P-256 raw point', () {
    final bytes = base64Decode(UnlockConfig.publicKeyRawBase64);
    expect(bytes, hasLength(65));
    expect(bytes.first, 0x04);
  });
}
