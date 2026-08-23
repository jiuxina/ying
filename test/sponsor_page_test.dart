import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/sponsor_page.dart';

void main() {
  testWidgets('entering any text triggers the confetti easter egg', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SponsorPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('sponsor-key-input')),
      'YING-anything',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('礼花绽放，感谢支持'), findsOneWidget);
    expect(find.text('YING-anything'), findsNothing);
  });

  testWidgets('empty input shows a hint instead of confetti', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SponsorPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sponsor-verify')));
    await tester.pump();
    expect(find.text('输入任意内容，礼花就会为你绽放'), findsOneWidget);
  });
}
