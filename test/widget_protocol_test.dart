import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/widget_element_style.dart';
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
      expect(legacy.widgetShowLunarWeek, isFalse);
      expect(legacy.widgetMysteryMode, isFalse);
      expect(legacy.widgetQuoteMode, isFalse);
      expect(legacy.widgetUrgentHighlight, isFalse);
      expect(legacy.widgetListMode, isFalse);
      expect(legacy.widgetFontFamily, 'system');
      expect(legacy.widgetTextOutline, isFalse);
      expect(legacy.widgetWallpaperColor, -1);
      expect(legacy.widgetWallpaperDarkColor, -1);
      expect(legacy.widgetWallpaperTextColor, -1);
      expect(legacy.widgetElementStyles, isEmpty);
      expect(legacy.widgetVerticalAlign, WidgetVerticalAlign.center);
    });

    test('unknown style falls back to card', () {
      final settings = AppSettings.fromMap(const {'widgetStyle': 'neon-v2'});
      expect(settings.widgetStyle, WidgetStyle.card);
    });

    test('phase 5 fun styles round-trip by name', () {
      for (final style in [
        WidgetStyle.envelope,
        WidgetStyle.capsule,
        WidgetStyle.crt,
        WidgetStyle.neonSign,
        WidgetStyle.pixelHealth,
        WidgetStyle.mirror,
      ]) {
        final restored = AppSettings.fromMap({'widgetStyle': style.name});
        expect(restored.widgetStyle, style);
        expect(AppSettings(widgetStyle: style).toMap()['widgetStyle'], style.name);
      }
    });

    test('round-trips every new field', () {
      final settings = const AppSettings(
        widgetStyle: WidgetStyle.glass,
        widgetBackgroundPath: '/tmp/background.jpg',
        widgetUnitText: '只剩',
        widgetShowIcon: true,
        widgetShowProgress: true,
        widgetShowPreciseTime: true,
        widgetShowLunarWeek: true,
        widgetMysteryMode: true,
        widgetQuoteMode: true,
        widgetUrgentHighlight: true,
        widgetListMode: true,
        widgetFontFamily: 'mono',
        widgetTextOutline: true,
        widgetWallpaperColor: 0xFF102030,
        widgetWallpaperDarkColor: 0xFF0A0A0A,
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
      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.widgetStyle, WidgetStyle.glass);
      expect(restored.widgetBackgroundPath, '/tmp/background.jpg');
      expect(restored.widgetUnitText, '只剩');
      expect(restored.widgetShowIcon, isTrue);
      expect(restored.widgetShowProgress, isTrue);
      expect(restored.widgetShowPreciseTime, isTrue);
      expect(restored.widgetShowLunarWeek, isTrue);
      expect(restored.widgetMysteryMode, isTrue);
      expect(restored.widgetQuoteMode, isTrue);
      expect(restored.widgetUrgentHighlight, isTrue);
      expect(restored.widgetListMode, isTrue);
      expect(restored.widgetFontFamily, 'mono');
      expect(restored.widgetTextOutline, isTrue);
      expect(restored.widgetWallpaperColor, 0xFF102030);
      expect(restored.widgetWallpaperDarkColor, 0xFF0A0A0A);
      expect(restored.widgetWallpaperTextColor, 0xFFFFFFFF);
      expect(restored.widgetElementStyles['title']?.visible,
          WidgetElementVisible.show);
      expect(restored.widgetElementStyles['title']?.size,
          WidgetElementSize.large);
      expect(restored.widgetElementStyles['title']?.colorMode,
          WidgetColorMode.custom);
      expect(restored.widgetElementStyles['title']?.color, 0xFFE91E63);
      expect(restored.widgetElementStyles['title']?.align,
          WidgetAlign.center);
      expect(restored.widgetElementStyles['prevButton']?.visible,
          WidgetElementVisible.hide);
      expect(restored.widgetVerticalAlign, WidgetVerticalAlign.bottom);
    });

    test('malformed element styles fall back to empty map', () {
      final settings = AppSettings.fromMap({
        'widgetElementStyles': '{broken',
        'widgetVerticalAlign': 'unknown',
      });
      expect(settings.widgetElementStyles, isEmpty);
      expect(settings.widgetVerticalAlign, WidgetVerticalAlign.center);
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

  group('WidgetService protocol v4 helpers', () {
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
      expect(
        encoded['targetTime'],
        DateTime(2026, 8, 8).millisecondsSinceEpoch,
      );
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
      expect(values['widget_protocol_version'], 8);
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
          'widget_show_lunar_week',
          'widget_mystery_mode',
          'widget_quote_mode',
          'widget_urgent_highlight',
          'widget_list_mode',
          'widget_font_family',
          'widget_text_outline',
          'widget_wallpaper_color',
          'widget_wallpaper_dark_color',
          'widget_wallpaper_text_color',
          'widget_element_styles',
          'widget_vertical_align',
          'widget_holiday',
          'widget_date_info',
          'widget_render_spec',
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
          widgetUrgentHighlight: true,
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
      expect(values['widget_urgent_highlight'], isTrue);
      expect(values['widget_wallpaper_color'], 0xFF001122);
    });
  });
}
