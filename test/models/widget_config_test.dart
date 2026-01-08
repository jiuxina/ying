import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/widget_config.dart';

void main() {
  group('WidgetType', () {
    test('should have correct display names', () {
      expect(WidgetType.standard.displayName, '标准 (2×2)');
      expect(WidgetType.large.displayName, '大型 (4×2)');
    });

    test('should have correct provider names', () {
      expect(WidgetType.standard.providerName, 'CountdownWidgetReceiver');
      expect(WidgetType.large.providerName, 'CountdownLargeWidgetReceiver');
    });

    test('should have correct config prefix', () {
      expect(WidgetType.standard.configPrefix, 'widget_standard');
      expect(WidgetType.large.configPrefix, 'widget_large');
    });
  });

  group('WidgetStyle', () {
    test('should have correct display names', () {
      expect(WidgetStyle.standard.displayName, '纯色');
      expect(WidgetStyle.gradient.displayName, '渐变');
      expect(WidgetStyle.glassmorphism.displayName, '毛玻璃');
    });
  });

  group('WidgetConfig', () {
    test('should create default config for each type', () {
      final standardConfig = WidgetConfig.defaultFor(WidgetType.standard);
      expect(standardConfig.type, WidgetType.standard);
      expect(standardConfig.showDate, true);

      final largeConfig = WidgetConfig.defaultFor(WidgetType.large);
      expect(largeConfig.type, WidgetType.large);
      expect(largeConfig.showDate, true);
    });

    test('should copy with modifications', () {
      final config = WidgetConfig.defaultFor(WidgetType.standard);
      
      final modified = config.copyWith(
        opacity: 0.5,
        showDate: false,
      );
      
      expect(modified.opacity, 0.5);
      expect(modified.showDate, false);
      // Original unchanged
      expect(config.opacity, 1.0);
      expect(config.showDate, true);
    });

    test('should serialize to and from Map', () {
      final config = WidgetConfig(
        type: WidgetType.large,
        style: WidgetStyle.gradient,
        backgroundColor: 0xFF123456,
        gradientEndColor: 0xFF654321,
        opacity: 0.8,
        backgroundImage: '/path/to/image.jpg',
        showDate: true,
      );

      final map = config.toMap();
      final restored = WidgetConfig.fromMap(map);

      expect(restored.type, config.type);
      expect(restored.style, config.style);
      expect(restored.backgroundColor, config.backgroundColor);
      expect(restored.gradientEndColor, config.gradientEndColor);
      expect(restored.opacity, config.opacity);
      expect(restored.backgroundImage, config.backgroundImage);
      expect(restored.showDate, config.showDate);
    });

    test('should handle missing values in Map gracefully', () {
      final map = <String, dynamic>{
        'type': 'unknown',
        'style': 'invalid',
      };

      final config = WidgetConfig.fromMap(map);
      
      // Should use defaults for invalid values
      expect(config.type, WidgetType.standard);
      expect(config.style, WidgetStyle.standard);
      expect(config.backgroundColor, 0xFF6366F1);
      expect(config.opacity, 1.0);
    });

    test('should implement equality correctly', () {
      final config1 = WidgetConfig.defaultFor(WidgetType.standard);
      final config2 = WidgetConfig.defaultFor(WidgetType.standard);
      final config3 = WidgetConfig.defaultFor(WidgetType.large);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should provide color accessors', () {
      final config = WidgetConfig(
        type: WidgetType.standard,
        backgroundColor: 0xFF123456,
        gradientEndColor: 0xFF654321,
      );

      expect(config.color.toARGB32(), 0xFF123456);
      expect(config.gradientEnd?.toARGB32(), 0xFF654321);

      final configNoGradient = WidgetConfig.defaultFor(WidgetType.standard);
      expect(configNoGradient.gradientEnd, isNull);
    });
  });
}
