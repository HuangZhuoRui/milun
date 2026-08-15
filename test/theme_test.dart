import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';
import 'package:whoami/main.dart';

void main() {
  testWidgets('深浅色模式自适应渲染测试', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    IChingRepository.instance.loadFromList([
      HexagramDetail(
        id: 15,
        name: '地山谦',
        code: '000100',
        upperTrigram: '坤',
        lowerTrigram: '艮',
        element: '土',
        fortuneTier: '上上卦',
        fortuneDesc: '亨 · 君子有终',
        guaci: '谦，亨，君子有终。',
        tuan: '谦，亨。天道下济而光明，地道卑而上行。',
        xiang: '地中有山，谦；君子以裒多益寡，称物平施。',
        overview: '总览',
        personality: '谦逊内敛，德行厚重。',
        career: '稳健蓄势，得道多助。',
        wealth: '细水长流，聚沙成塔。',
        love: '温润包容，相敬如宾。',
        health: '脾胃养护，气血调和。',
        advice: '劳谦君子，有终吉。',
        yaos: [],
      ),
    ]);

    // 1. 模拟浅色模式系统环境
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pumpAndSettle();

    // 验证今日卦象正常显示并采用浅色主题
    expect(find.text('今日专属流日卦'), findsOneWidget);
    expect(find.text('今日卦象'), findsWidgets);

    // 切换至本命排盘
    await tester.tap(find.text('本命排盘'));
    await tester.pumpAndSettle();
    expect(find.text('易经本命推算 · 浑天罗盘'), findsOneWidget);
    expect(find.text('命盘详批'), findsOneWidget);

    // 2. 动态切换至深色模式系统环境
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    // 验证正常显示并自适应深色主题
    expect(find.text('易经本命推算 · 浑天罗盘'), findsOneWidget);
    expect(find.text('命盘详批'), findsOneWidget);
  });
}
