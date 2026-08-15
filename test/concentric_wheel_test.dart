import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/presentation/widgets/concentric_astrolabe_wheel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('浑天同心多环罗盘测试', () {
    testWidgets('正确渲染轮盘画布与操作指引，无多余顶部卡片', (WidgetTester tester) async {
      ConcentricAstrolabeState state = const ConcentricAstrolabeState(
        year: 1995,
        month: 8,
        day: 18,
        hourIndex: 6,
        isHourKnown: true,
        cityIndex: 0,
        gender: '乾 (男)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcentricAstrolabeWheel(
              initialState: state,
              onChanged: (newState) => state = newState,
            ),
          ),
        ),
      );

      // 验证操作指引文字
      expect(find.textContaining('顺时针转动值增大'), findsOneWidget);

      // 验证手势识别器正常存在
      expect(find.byKey(const Key('concentric_astrolabe_gesture')), findsOneWidget);
    });

    testWidgets('点击中心元神核心可在「乾 (男)」与「坤 (女)」之间切换', (WidgetTester tester) async {
      ConcentricAstrolabeState state = const ConcentricAstrolabeState(
        year: 1995,
        month: 8,
        day: 18,
        hourIndex: 6,
        isHourKnown: true,
        cityIndex: 0,
        gender: '乾 (男)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ConcentricAstrolabeWheel(
                  initialState: state,
                  onChanged: (newState) {
                    setState(() {
                      state = newState;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final wheelFinder = find.byKey(const Key('concentric_astrolabe_gesture'));
      final center = tester.getCenter(wheelFinder);

      // 点击中心元神核心（半径比例 < 0.22）
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(state.gender, equals('坤 (女)'));
    });

    testWidgets('拖拽外圈年份环可旋转并驱动年份更新', (WidgetTester tester) async {
      ConcentricAstrolabeState state = const ConcentricAstrolabeState(
        year: 1995,
        month: 8,
        day: 18,
        hourIndex: 6,
        isHourKnown: true,
        cityIndex: 0,
        gender: '乾 (男)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ConcentricAstrolabeWheel(
                  initialState: state,
                  onChanged: (newState) {
                    setState(() {
                      state = newState;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final wheelFinder = find.byKey(const Key('concentric_astrolabe_gesture'));
      final center = tester.getCenter(wheelFinder);

      // 外圈年份环（半径约 148px）
      final gesture = await tester.startGesture(Offset(center.dx, center.dy - 148));
      await gesture.moveTo(Offset(center.dx + 60, center.dy - 130));
      await gesture.moveTo(Offset(center.dx + 130, center.dy - 60));
      await gesture.up();
      await tester.pumpAndSettle();

      // 年份应发生更新
      expect(state.year, isNot(equals(1995)));
    });
  });
}
