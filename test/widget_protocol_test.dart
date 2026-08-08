import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/widget_service.dart';

void main() {
  group('AppSettings widget protocol fields', () {
    test('defaults keep phase 0 appearance unchanged', () {
      final legacy = AppSettings.fromMap(const {});
      expect(legacy.widgetStyle, WidgetStyle.card);
      expect(legacy.widgetBackgroundPath, '');
      expect(legacy.widgetUnitText, '');
      expect(legacy.widgetShowIcon, isFalse);
      expect(legacy.widgetShowProgress, isFalse);
      expect(legacy.widgetShowPreciseTime, isFalse);
      expect(legacy.widgetMysteryMode, isFalse);
      expect(legacy.widgetQuoteMode, isFalse);
      expect(legacy.widgetFontFamily, 'system');
      expect(legacy.widgetTextOutline, isFalse);
      expect(legacy.widgetWallpaperColor, -1);
      expect(legacy.widgetWallpaperDarkColor, -1);
      expect(legacy.widgetWallpaperTextColor, -1);
    });

    test('unknown style falls back to card', () {
      final settings = AppSettings.fromMap(const {'widgetStyle': 'neon-v2'});
      expect(settings.widgetStyle, WidgetStyle.card);
    });

    test('round-trips every new field', () {
      final settings = const AppSettings(
        widgetStyle: WidgetStyle.glass,
        widgetBackgroundPath: '/tmp/background.jpg',
        widgetUnitText: '只剩',
        widgetShowIcon: true,
        widgetShowProgress: true,
        widgetShowPreciseTime: true,
        widgetMysteryMode: true,
        widgetQuoteMode: true,
        widgetFontFamily: 'mono',
        widgetTextOutline: true,
        widgetWallpaperColor: 0xFF102030,
        widgetWallpaperDarkColor: 0xFF0A0A0A,
        widgetWallpaperTextColor: 0xFFFFFFFF,
      );
      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.widgetStyle, WidgetStyle.glass);
      expect(restored.widgetBackgroundPath, '/tmp/background.jpg');
      expect(restored.widgetUnitText, '只剩');
      expect(restored.widgetShowIcon, isTrue);
      expect(restored.widgetShowProgress, isTrue);
      expect(restored.widgetShowPreciseTime, isTrue);
      expect(restored.widgetMysteryMode, isTrue);
      expect(restored.widgetQuoteMode, isTrue);
      expect(restored.widgetFontFamily, 'mono');
      expect(restored.widgetTextOutline, isTrue);
      expect(restored.widgetWallpaperColor, 0xFF102030);
      expect(restored.widgetWallpaperDarkColor, 0xFF0A0A0A);
      expect(restored.widgetWallpaperTextColor, 0xFFFFFFFF);
    });
  });

  group('CountdownEvent icon', () {
    test('serializes icon and createdAt', () {
      final event = CountdownEvent(
        id: 'evt-icon',
        title: '考试',
        targetDate: DateTime(2026, 8, 8),
        category: '学习',
        icon: 'cake',
        createdAt: DateTime(2026, 7, 1, 9, 30),
      );
      final restored = CountdownEvent.fromJson(
        jsonDecode(jsonEncode(event.toJson())) as Map<String, dynamic>,
      );
      expect(restored.icon, 'cake');
      expect(restored.createdAt, DateTime(2026, 7, 1, 9, 30));
    });

    test('legacy data falls back to empty icon', () {
      final legacy = CountdownEvent.fromJson({
        'id': 'legacy-icon',
        'title': '旧事件',
        'targetDate': '2026-08-08T00:00:00.000',
        'category': '学习',
        'createdAt': '2026-07-01T09:00:00.000',
      });
      expect(legacy.icon, '');
    });
  });

  group('WidgetService protocol v2 helpers', () {
    CountdownEvent event(
      String id, {
      String icon = '',
      bool completed = false,
      bool pinned = false,
      int days = 1,
    }) {
      final base = DateTime(2026, 8, 8);
      return CountdownEvent(
        id: id,
        title: id,
        targetDate: base.add(Duration(days: days)),
        category: '学习',
        icon: icon,
        isCompleted: completed,
        isPinned: pinned,
        createdAt: base.subtract(const Duration(days: 30)),
      );
    }

    test('encodes icon and createdAt per event', () {
      final createdAt = DateTime(2026, 7, 1, 9, 30);
      final decoded = jsonDecode(
        encodeWidgetEvents([
          CountdownEvent(
            id: 'encoded',
            title: '考试',
            targetDate: DateTime(2026, 8, 8),
            category: '学习',
            icon: 'cake',
            createdAt: createdAt,
          ),
        ]),
      ) as List<dynamic>;
      final encoded = decoded.single as Map<String, dynamic>;
      expect(encoded['icon'], 'cake');
      expect(encoded['createdAt'], createdAt.millisecondsSinceEpoch);
    });

    test('filters completed events and keeps pinned first', () {
      final decoded = jsonDecode(
        encodeWidgetEvents([
          event('done', completed: true, days: 0),
          event('pinned', pinned: true, days: 30),
          event('soon', days: 3),
        ]),
      ) as List<dynamic>;
      expect(
        decoded.map((value) => (value as Map<String, dynamic>)['id']),
        ['pinned', 'soon'],
      );
    });

    test('preference values include protocol version and every key', () {
      final values = widgetPreferenceValues(const AppSettings());
      expect(values['widget_protocol_version'], 3);
      expect(values['widget_color'], 'ff0f766e');
      expect(
        values.keys,
        containsAll([
          'widget_protocol_version',
          'widget_color',
          'widget_font_scale',
          'widget_show_note',
          'widget_show_category',
          'widget_style',
          'widget_background_path',
          'widget_unit_text',
          'widget_show_icon',
          'widget_show_progress',
          'widget_show_precise_time',
          'widget_mystery_mode',
          'widget_quote_mode',
          'widget_font_family',
          'widget_text_outline',
          'widget_wallpaper_color',
          'widget_wallpaper_dark_color',
          'widget_wallpaper_text_color',
          'widget_holiday',
        ]),
      );
    });

    test('preference values compute holiday for the given date', () {
      final values = widgetPreferenceValues(
        const AppSettings(),
        now: DateTime(2026, 12, 25),
      );
      expect(values['widget_holiday'], 'christmas');
    });

    test('preference values reflect custom settings', () {
      final values = widgetPreferenceValues(
        const AppSettings(
          widgetColor: 0xFF112233,
          widgetFontScale: 1.15,
          widgetStyle: WidgetStyle.sticker,
          widgetBackgroundPath: '/tmp/bg.png',
          widgetUnitText: '距离',
          widgetShowIcon: true,
          widgetMysteryMode: true,
          widgetWallpaperColor: 0xFF001122,
        ),
      );
      expect(values['widget_color'], 'ff112233');
      expect(values['widget_font_scale'], 1.15);
      expect(values['widget_style'], 'sticker');
      expect(values['widget_background_path'], '/tmp/bg.png');
      expect(values['widget_unit_text'], '距离');
      expect(values['widget_show_icon'], isTrue);
      expect(values['widget_mystery_mode'], isTrue);
      expect(values['widget_wallpaper_color'], 0xFF001122);
    });
  });
}
