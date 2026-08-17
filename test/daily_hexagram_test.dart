import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/iching/iching_calculator.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';
import 'package:whoami/presentation/pages/daily/daily_hexagram_page.dart';
import 'package:whoami/presentation/theme/app_theme.dart';

void main() {
  setUp(() {
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
      HexagramDetail(
        id: 2,
        name: '坤为地',
        code: '000000',
        upperTrigram: '坤',
        lowerTrigram: '坤',
        element: '土',
        fortuneTier: '上吉卦',
        fortuneDesc: '含弘光大 · 厚德载物',
        guaci: '元亨，利牝马之贞。',
        tuan: '至哉坤元。',
        xiang: '地势坤。',
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
  });

  test('IChingCalculator.calculatePersonalizedDailyHexagram 能够正确推算本命专属流日卦与运势', () {
    final result = IChingCalculator.calculatePersonalizedDailyHexagram(
      targetDate: DateTime(2026, 8, 15),
      birthDate: DateTime(1995, 8, 18),
      birthHourIndex: 6,
      profileName: '张先生',
      longitude: 104.1, // 成渝
      birthCity: '成渝 (104.1°E)',
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

  test('真太阳时经度校正影响时辰与今日卦象推算', () {
    // 假设在晚上 23:00 (子时边缘) 出生：
    // 北京 (116.4°E) 偏离不大，仍为子时；
    // 乌鲁木齐 (87.6°E) 偏差 -130分钟，真太阳时落入亥时 (20:50)
    final beijingResult = IChingCalculator.calculatePersonalizedDailyHexagram(
      targetDate: DateTime(2026, 8, 15),
      birthDate: DateTime(1995, 8, 18),
      birthHourIndex: 0, // 子时
      longitude: 116.4,
    );

    final urumqiResult = IChingCalculator.calculatePersonalizedDailyHexagram(
      targetDate: DateTime(2026, 8, 15),
      birthDate: DateTime(1995, 8, 18),
      birthHourIndex: 0, // 子时
      longitude: 87.6, // 乌鲁木齐
    );

    // 经度校正后时支不同（北京与乌鲁木齐相差130分钟跨时辰），流日卦或动爻发生精准校准差异
    expect(
      beijingResult.todayNatalHexagram.id != urumqiResult.todayNatalHexagram.id ||
          beijingResult.changingYaoIndex != urumqiResult.changingYaoIndex ||
          beijingResult.birthMainHexagram.id != urumqiResult.birthMainHexagram.id,
      isTrue,
    );
  });

  testWidgets('DailyHexagramPage 页面渲染与前一日/后一日切换测试', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

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
