import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/widget_config.dart';
import 'package:ying/providers/settings_provider.dart';

void main() {
  group('SettingsProvider - Widget Settings', () {
    late SettingsProvider provider;

    setUp(() {
      provider = SettingsProvider();
    });

    test('should have default widget type as standard', () {
      expect(provider.currentWidgetType, WidgetType.standard);
    });

    test('should return default config for current type', () {
      final config = provider.currentWidgetConfig;
      expect(config.type, WidgetType.standard);
      expect(config.style, WidgetStyle.standard);
    });

    test('should get config for specific widget type', () {
      final standardConfig = provider.getWidgetConfig(WidgetType.standard);
      expect(standardConfig.type, WidgetType.standard);
      
      final largeConfig = provider.getWidgetConfig(WidgetType.large);
      expect(largeConfig.type, WidgetType.large);
    });

    test('backward compatible getters should work', () {
      // 测试向后兼容的 getters
      expect(provider.widgetSize, isA<String>());
      expect(provider.widgetDisplayMode, isA<String>());
      expect(provider.widgetOpacity, isA<double>());
      expect(provider.widgetBackgroundColor, isNotNull);
    });

    test('widgetSize getter should map to correct type', () {
      // 默认是 standard -> 'small'
      expect(provider.widgetSize, 'small');
    });

    test('widgetDisplayMode getter should return single', () {
      // 简化版只支持 single 模式
      expect(provider.widgetDisplayMode, 'single');
    });

    test('widgetBlur getter should reflect glassmorphism style', () {
      // 默认 style = standard -> blur = false
      expect(provider.widgetBlur, false);
    });
  });

  group('SettingsProvider - Other Settings', () {
    late SettingsProvider provider;

    setUp(() {
      provider = SettingsProvider();
    });

    test('should have default sort order', () {
      expect(provider.sortOrder, 'daysAsc');
    });

    test('should have default font size', () {
      expect(provider.fontSize, 1.0);
    });

    test('should have default date format', () {
      expect(provider.dateFormat, 'yyyy年MM月dd日');
    });

    test('should have default progress settings', () {
      expect(provider.progressStyle, 'standard');
      expect(provider.progressCalculation, 'fixed');
      expect(provider.progressFixedDays, 30);
    });

    test('should have default background settings', () {
      expect(provider.backgroundImagePath, isNull);
      expect(provider.backgroundEffect, 'none');
      expect(provider.backgroundBlur, 10.0);
    });

    test('should have default cards expanded', () {
      expect(provider.cardsExpanded, true);
    });
  });
}
