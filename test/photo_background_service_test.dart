import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ying/services/photo_background_service_io.dart';

void main() {
  test('processWidgetBackgroundBytes applies brightness', () async {
    final source = img.Image(width: 8, height: 8);
    img.fill(
      source,
      color: img.ColorRgba8(120, 120, 120, 255),
    );
    final input = Uint8List.fromList(img.encodePng(source));
    final output = await processWidgetBackgroundBytes(
      input,
      brightness: 0.5,
      maxDimension: 8,
    );
    final decoded = img.decodeImage(output);
    expect(decoded, isNotNull);
    final pixel = decoded!.getPixel(1, 1);
    expect(pixel.r, lessThan(120));
    expect(pixel.g, lessThan(120));
    expect(pixel.b, lessThan(120));
  });

  test('processWidgetBackgroundBytes supports gaussian blur', () async {
    final source = img.Image(width: 8, height: 8);
    img.fill(
      source,
      color: img.ColorRgba8(200, 200, 200, 255),
    );
    final input = Uint8List.fromList(img.encodePng(source));
    final output = await processWidgetBackgroundBytes(
      input,
      brightness: 1.0,
      blur: 3,
      maxDimension: 8,
    );
    expect(output, isNotEmpty);
    expect(img.decodeImage(output), isNotNull);
  });
}
