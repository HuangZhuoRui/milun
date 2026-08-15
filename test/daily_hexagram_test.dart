import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/iching/iching_calculator.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';
import 'package:whoami/presentation/pages/daily/daily_hexagram_page.dart';
import 'package:whoami/presentation/theme/app_theme.dart';

void main() {
  test('IChingCalculator.calculatePersonalizedDailyHexagram 能够正确推算本命专属流日卦与运势', () {
    IChingRepository.instance.loadFromList([
      HexagramDetail(
        id: 1,
        name: '乾为天',
        code: '111111',
        upperTrigram: '乾',
        lowerTrigram: '乾',
        element: '金',
        fortuneTier: '上吉卦',
        fortuneDesc: '大亨 · 刚健中正',
        guaci: '元亨利贞。',
        tuan: '大哉乾元。',
        xiang: '天行健。',
        overview: '总览',
        personality: '性格',
        career: '事业',
        wealth: '财富',
        love: '情感',
        health: '养生',
        advice: '建议',
        yaos: [],
      ),
    ]);

    final result = IChingCalculator.calculatePersonalizedDailyHexagram(
      targetDate: DateTime(2026, 8, 15),
      birthDate: DateTime(1995, 8, 18),
      birthHourIndex: 6,
      profileName: '张先生',
    );
    expect(result.solarDate.year, equals(2026));
    expect(result.birthMainHexagram, isNotNull);
    expect(result.todayNatalHexagram, isNotNull);
    expect(result.changingYaoIndex, inInclusiveRange(1, 6));
    expect(result.fortuneScore, inInclusiveRange(60, 99));
    expect(result.yiList, isNotEmpty);
    expect(result.jiList, isNotEmpty);
    expect(result.energyRelation, isNotEmpty);
  });

  testWidgets('DailyHexagramPage 页面渲染与前一日/后一日切换测试', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    IChingRepository.instance.loadFromList([
      HexagramDetail(
        id: 1,
        name: '乾为天',
        code: '111111',
        upperTrigram: '乾',
        lowerTrigram: '乾',
        element: '金',
        fortuneTier: '上吉卦',
        fortuneDesc: '大亨 · 刚健中正',
        guaci: '元亨利贞。',
        tuan: '大哉乾元。',
        xiang: '天行健。',
        overview: '总览',
        personality: '性格',
        career: '事业',
        wealth: '财富',
        love: '情感',
        health: '养生',
        advice: '建议',
        yaos: [],
      ),
    ]);

    bool navigated = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: DailyHexagramPage(
          onNavigateToNatal: () => navigated = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证核心组件
    expect(find.text('今日专属流日卦'), findsOneWidget);
    expect(find.text('【本命与天时交感 · 今日专属卦】'), findsOneWidget);
    expect(find.text('【流日吉凶 · 行事宜忌指南】'), findsOneWidget);
    expect(find.text('【五维运势 · 能量指标全览】'), findsOneWidget);

    // 点击「前一日」按钮
    await tester.tap(find.byTooltip('前一日'));
    await tester.pumpAndSettle();

    // 验证出现「回今日」按钮并点击它
    expect(find.text('回今日'), findsOneWidget);
    await tester.tap(find.text('回今日'));
    await tester.pumpAndSettle();

    // 验证点击底部重排本命盘按钮
    await tester.ensureVisible(find.text('重排本命盘'));
    await tester.tap(find.text('重排本命盘'));
    await tester.pumpAndSettle();
    expect(navigated, isTrue);
  });
}
