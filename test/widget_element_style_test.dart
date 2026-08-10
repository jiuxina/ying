import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/widget_element_style.dart';

void main() {
  group('WidgetElementStyle protocol', () {
    test('size tiers expose stable multipliers', () {
      expect(WidgetElementSize.small.multiplier, 0.8);
      expect(WidgetElementSize.normal.multiplier, 1.0);
      expect(WidgetElementSize.large.multiplier, 1.25);
      expect(WidgetElementSize.xlarge.multiplier, 1.5);
    });

    test('encodes and decodes every field', () {
      const style = WidgetElementStyle(
        visible: WidgetElementVisible.hide,
        size: WidgetElementSize.xlarge,
        sizeScale: 1.8,
        weight: 700,
        colorMode: WidgetColorMode.custom,
        color: 0xFF112233,
        align: WidgetAlign.end,
      );
      final decoded = decodeWidgetElementStyles(
        encodeWidgetElementStyles({'days': style}),
      );
      expect(decoded['days']?.visible, WidgetElementVisible.hide);
      expect(decoded['days']?.size, WidgetElementSize.xlarge);
      expect(decoded['days']?.sizeScale, 1.8);
      expect(decoded['days']?.weight, 700);
      expect(decoded['days']?.colorMode, WidgetColorMode.custom);
      expect(decoded['days']?.color, 0xFF112233);
      expect(decoded['days']?.align, WidgetAlign.end);
    });

    test('partial json fills defaults', () {
      final decoded = decodeWidgetElementStyles('{"title":{"size":"large"}}');
      expect(decoded['title']?.visible, WidgetElementVisible.follow);
      expect(decoded['title']?.size, WidgetElementSize.large);
      expect(decoded['title']?.sizeScale, 1.25);
      expect(decoded['title']?.weight, 0);
      expect(decoded['title']?.colorMode, WidgetColorMode.primary);
      expect(decoded['title']?.color, -1);
      expect(decoded['title']?.align, WidgetAlign.start);
    });

    test('legacy size tier is converted to sizeScale', () {
      final decoded = decodeWidgetElementStyles(
        '{"days":{"size":"xlarge","weight":900}}',
      );
      expect(decoded['days']?.sizeScale, 1.5);
      expect(decoded['days']?.weight, 900);
    });

    test('out of range weight clamps to supported range', () {
      final decoded = decodeWidgetElementStyles(
        '{"title":{"weight":1200}}',
      );
      expect(decoded['title']?.weight, 900);
    });

    test('invalid input falls back to empty map', () {
      expect(decodeWidgetElementStyles(null), isEmpty);
      expect(decodeWidgetElementStyles(''), isEmpty);
      expect(decodeWidgetElementStyles('[]'), isEmpty);
      expect(decodeWidgetElementStyles('{broken'), isEmpty);
    });
  });
}
