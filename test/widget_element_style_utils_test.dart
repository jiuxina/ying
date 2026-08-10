import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/widget_element_style.dart';
import 'package:ying/utils/widget_element_style_utils.dart';

void main() {
  const primary = Color(0xFF111111);
  const secondary = Color(0xFF222222);

  group('widget element style helpers', () {
    test('visibility follows tri-state', () {
      const settings = AppSettings(
        widgetElementStyles: {
          'title': WidgetElementStyle(visible: WidgetElementVisible.hide),
          'days': WidgetElementStyle(visible: WidgetElementVisible.show),
        },
      );
      expect(
        widgetElementVisible(settings, 'title', followDefault: true),
        isFalse,
      );
      expect(
        widgetElementVisible(settings, 'days', followDefault: false),
        isTrue,
      );
      expect(
        widgetElementVisible(settings, 'note', followDefault: true),
        isTrue,
      );
    });

    test('color prefers custom then override then role default', () {
      const settings = AppSettings(
        widgetElementStyles: {
          'title': WidgetElementStyle(
            colorMode: WidgetColorMode.custom,
            color: 0xFFE91E63,
          ),
          'unit': WidgetElementStyle(
            colorMode: WidgetColorMode.secondary,
          ),
        },
      );
      expect(
        widgetElementColor(
          settings,
          'title',
          primary: primary,
          secondary: secondary,
          defaultPrimary: true,
          override: const Color(0xFF00FF00),
        ),
        const Color(0xFFE91E63),
      );
      expect(
        widgetElementColor(
          settings,
          'unit',
          primary: primary,
          secondary: secondary,
          defaultPrimary: false,
          override: const Color(0xFF00FF00),
        ),
        const Color(0xFF00FF00),
      );
      expect(
        widgetElementColor(
          settings,
          'note',
          primary: primary,
          secondary: secondary,
          defaultPrimary: false,
        ),
        secondary,
      );
    });

    test('size scale and alignment map to multipliers and TextAlign', () {
      const settings = AppSettings(
        widgetElementStyles: {
          'title': WidgetElementStyle(
            size: WidgetElementSize.xlarge,
            align: WidgetAlign.end,
          ),
        },
      );
      expect(widgetElementSizeScale(settings, 'title'), 1.5);
      expect(widgetElementSizeScale(settings, 'note'), 1.0);
      expect(widgetElementAlign(settings, 'title'), TextAlign.end);
      expect(widgetElementAlign(settings, 'note'), TextAlign.start);
    });
  });
}
