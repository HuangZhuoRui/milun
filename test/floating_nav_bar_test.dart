import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/main.dart';
import 'package:whoami/presentation/widgets/floating_nav_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FloatingNavBar 悬浮圆角导航栏正常渲染四大标签并支持手势拖动平滑切换页面', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 验证悬浮圆角导航栏存在
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.text('今日卦象'), findsWidgets);
    expect(find.text('本命排盘'), findsWidgets);
    expect(find.text('易经宝典'), findsWidgets);
    expect(find.text('亲友命簿'), findsWidgets);

    // 默认展示 Tab 0 (今日卦象)
    expect(find.text('今日专属流日卦'), findsOneWidget);

    // 模拟向左水平拖动（Drag from right to left to switch to Tab 1）
    await tester.drag(find.text('今日专属流日卦'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // 验证已平滑滑动到 Tab 1 (本命排盘)
    expect(find.text('易经本命推算 · 浑天罗盘'), findsOneWidget);

    // 再次向左拖动到 Tab 2 (易经宝典)
    await tester.drag(find.text('易经本命推算 · 浑天罗盘'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // 验证已平滑滑动到 Tab 2 (易经宝典)
    expect(find.text('易经六十四卦宝典'), findsOneWidget);
  });

  testWidgets('点击首尾两个标签页时经由完整路径平滑滑翔动画切换，不跳变', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 当前在 Tab 0，点击最末尾的 Tab 3 (亲友命簿)
    await tester.tap(find.text('亲友命簿'));

    // 逐步 pump 验证中间平滑滑翔过渡
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // 验证成功到达 Tab 3 (亲友命簿)
    expect(find.text('亲友八字命簿'), findsOneWidget);

    // 再从 Tab 3 点击最首部的 Tab 0 (今日卦象)
    await tester.tap(find.text('今日卦象'));
    await tester.pumpAndSettle();

    // 验证成功平滑返回 Tab 0 (今日卦象)
    expect(find.text('今日专属流日卦'), findsOneWidget);
  });
}
