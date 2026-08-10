import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ying/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('应用启动并显示首页', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final finish = find.byKey(const ValueKey('onboarding-finish'));
    if (finish.evaluate().isNotEmpty) {
      expect(find.text('欢迎使用'), findsOneWidget);
      expect(find.text('完成基础配置'), findsOneWidget);
      await tester.tap(finish);
      await tester.pumpAndSettle();
    }

    expect(find.text('萤'), findsNothing);
    expect(find.text('日历'), findsWidgets);
    expect(find.byTooltip('设置'), findsWidgets);
    expect(find.byKey(const ValueKey('home-settings')), findsOneWidget);
  });
}
