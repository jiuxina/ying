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
        colorMode: WidgetColorMode.custom,
        color: 0xFF112233,
        align: WidgetAlign.end,
      );
      final decoded = decodeWidgetElementStyles(
        encodeWidgetElementStyles({'days': style}),
      );
      expect(decoded['days']?.visible, WidgetElementVisible.hide);
      expect(decoded['days']?.size, WidgetElementSize.xlarge);
      expect(decoded['days']?.colorMode, WidgetColorMode.custom);
      expect(decoded['days']?.color, 0xFF112233);
      expect(decoded['days']?.align, WidgetAlign.end);
    });

    test('partial json fills defaults', () {
      final decoded = decodeWidgetElementStyles('{"title":{"size":"large"}}');
      expect(decoded['title']?.visible, WidgetElementVisible.follow);
      expect(decoded['title']?.size, WidgetElementSize.large);
      expect(decoded['title']?.colorMode, WidgetColorMode.primary);
      expect(decoded['title']?.color, -1);
      expect(decoded['title']?.align, WidgetAlign.start);
    });

    test('invalid input falls back to empty map', () {
      expect(decodeWidgetElementStyles(null), isEmpty);
      expect(decodeWidgetElementStyles(''), isEmpty);
      expect(decodeWidgetElementStyles('[]'), isEmpty);
      expect(decodeWidgetElementStyles('{broken'), isEmpty);
    });
  });
}
