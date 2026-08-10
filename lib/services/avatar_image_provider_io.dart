import 'dart:io';

import 'package:flutter/painting.dart';

ImageProvider? avatarImage(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}
