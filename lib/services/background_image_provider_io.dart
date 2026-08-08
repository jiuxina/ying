import 'dart:io';

import 'package:flutter/painting.dart';

ImageProvider? widgetBackgroundImage(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}
