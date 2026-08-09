import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ying/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('应用启动并显示首页', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('萤'), findsWidgets);
    expect(find.text('日历'), findsWidgets);
    expect(find.byTooltip('设置'), findsWidgets);
  });
}
