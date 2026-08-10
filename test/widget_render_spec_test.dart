import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/widget_element_style.dart';
import 'package:ying/models/widget_render_spec.dart';
import 'package:ying/services/widget_service.dart';

void main() {
  const fixtureRoot = 'android/app/src/test/resources/widget_parity';
  const cases = ['empty_single', 'single_event', 'list_mode'];

  for (final name in cases) {
    test('$name render spec matches shared contract', () {
      final input =
          jsonDecode(
            File('$fixtureRoot/$name.input.json').readAsStringSync(),
          ) as Map<String, dynamic>;
      final expected =
          jsonDecode(
            File('$fixtureRoot/$name.spec.json').readAsStringSync(),
          ) as Map<String, dynamic>;
      final settings = AppSettings.fromMap(
        (input['settings'] as Map).cast<String, Object?>(),
      );
      final events = (input['events'] as List)
          .map(
            (value) => CountdownEvent.fromJson(
              (value as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
      final spec = resolveWidgetRenderSpec(
        events,
        settings,
        sponsorUnlocked: input['sponsorUnlocked'] as bool? ?? true,
        now: DateTime.parse(input['now'] as String),
      );
      expect(spec.toJson(), expected);
    });
  }

  test('protocol preference payload carries render spec', () {
    final values = widgetPreferenceValues(
      const AppSettings(),
      events: [
        CountdownEvent(
          id: 'spec-evt',
          title: '契约',
          targetDate: DateTime(2026, 8, 20),
          category: '生活',
          createdAt: DateTime(2026, 7, 1),
        ),
      ],
      now: DateTime(2026, 8, 8),
    );
    expect(values['widget_protocol_version'], 10);
    final raw = values['widget_render_spec'] as String;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['version'], 10);
    expect(decoded['eventOrder'], ['spec-evt']);
  });

  test('explicit size scale, weight and content margin enter render spec', () {
    final values = widgetPreferenceValues(
      const AppSettings(
        widgetContentMargin: 28,
        widgetElementStyles: {
          'title': WidgetElementStyle(sizeScale: 1.6, weight: 700),
        },
      ),
      now: DateTime(2026, 8, 8),
    );
    final decoded = jsonDecode(
      values['widget_render_spec'] as String,
    ) as Map<String, dynamic>;
    expect(decoded['contentMargin'], 28.0);
    final title = (decoded['full'] as Map<String, dynamic>)['elements']
        ['title'] as Map<String, dynamic>;
    expect(title['size'], 1.6);
    expect(title['weight'], 700);
  });
}
