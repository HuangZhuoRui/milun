import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/presentation/widgets/semi_circle_filter_wheel.dart';

void main() {
  testWidgets('SemiCircleFilterWheel 半圆同心双轨罗盘渲染与触控测试', (WidgetTester tester) async {
    String currentTier = '全部等第';
    String currentElem = '全部五行';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SemiCircleFilterWheel(
            selectedTier: currentTier,
            selectedElement: currentElem,
            onTierChanged: (t) => currentTier = t,
            onElementChanged: (e) => currentElem = e,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证半圆轮盘正确渲染 CustomPaint 画布
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(ShaderMask), findsWidgets);

    // 验证微标条正常显示等第与五行状态
    expect(find.text('等第: 全部等第'), findsOneWidget);
    expect(find.text('五行: 全部'), findsOneWidget);

    // 点击切换到五行音轨
    await tester.tap(find.text('五行: 全部'));
    await tester.pumpAndSettle();

    // 进行水平滑动手势旋转轮盘
    await tester.drag(find.byType(CustomPaint).first, const Offset(-150, 0));
    await tester.pumpAndSettle();
  });
}
