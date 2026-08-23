import 'package:flutter/material.dart';

import 'glass_ui.dart';
import 'sponsor_page.dart';

Future<void> openSponsorPage(BuildContext context) {
  return Navigator.of(context).push<void>(
    GlassPageRoute(builder: (context) => const SponsorPage()),
  );
}
