import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/presentation/widgets/rotary_date_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RotaryDatePickerDialog 浑天罗盘日期选择器测试', () {
    testWidgets('按年、月、日、时四步依次递进渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotaryDatePickerDialog(
              initialDate: DateTime(1995, 8, 18),
              initialHourIndex: 6,
              initialIsHourKnown: true,
            ),
          ),
        ),
      );

      // 验证初始状态处于选年
      expect(find.text('1995 年'), findsWidgets);
      expect(find.text('8 月'), findsWidgets);
      expect(find.text('18 日'), findsWidgets);
      expect(find.text('午时'), findsWidgets);
      expect(find.text('选年'), findsOneWidget);
      expect(find.text('选月'), findsOneWidget);
      expect(find.text('选日'), findsOneWidget);
      expect(find.text('选时(可选)'), findsOneWidget);
      expect(find.text('确认年份，进入选月'), findsOneWidget);
    });

    testWidgets('从 年 -> 月 -> 日 -> 时 逐步确认并输出包含时辰的结果', (WidgetTester tester) async {
      RotaryDateTimeResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    confirmedResult = await RotaryDatePickerDialog.show(
                      context,
                      initialDate: DateTime(2020, 5, 20),
                      initialHourIndex: 6, // 午时
                      initialIsHourKnown: true,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 第1步：确认年份
      expect(find.text('确认年份，进入选月'), findsOneWidget);
      await tester.tap(find.text('确认年份，进入选月'));
      await tester.pumpAndSettle();

      // 第2步：确认月份
      expect(find.text('确认月份，进入选日'), findsOneWidget);
      await tester.tap(find.text('确认月份，进入选日'));
      await tester.pumpAndSettle();

      // 第3步：确认日期
      expect(find.text('确认日期，进入选时'), findsOneWidget);
      await tester.tap(find.text('确认日期，进入选时'));
      await tester.pumpAndSettle();

      // 第4步：确认时辰 (午时)
      expect(find.text('确定生辰 (2020年5月20日 · 午时)'), findsOneWidget);
      await tester.tap(find.text('确定生辰 (2020年5月20日 · 午时)'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.date, equals(DateTime(2020, 5, 20)));
      expect(confirmedResult!.isHourKnown, isTrue);
      expect(confirmedResult!.hourIndex, equals(6));
    });

    testWidgets('罗盘选择器支持时辰不详（允许未知时辰）', (WidgetTester tester) async {
      RotaryDateTimeResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    confirmedResult = await RotaryDatePickerDialog.show(
                      context,
                      initialDate: DateTime(2020, 5, 20),
                      initialHourIndex: -1,
                      initialIsHourKnown: false,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 快速进入第4步
      await tester.tap(find.text('确认年份，进入选月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认月份，进入选日'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认日期，进入选时'));
      await tester.pumpAndSettle();

      expect(find.text('确定生辰 (2020年5月20日 · 时辰不详)'), findsOneWidget);
      await tester.tap(find.text('确定生辰 (2020年5月20日 · 时辰不详)'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.isHourKnown, isFalse);
      expect(confirmedResult!.hourIndex, equals(-1));
    });
  });
}
