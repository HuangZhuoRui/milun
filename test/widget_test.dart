import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';
import 'package:whoami/data/repositories/profile_repository.dart';
import 'package:whoami/main.dart';

void main() {
  testWidgets('应用启动能正常渲染 HomeNavPage 主导航与四大标签页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    // 初始化单元测试模拟卦象数据
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

    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 验证四大标签栏：今日卦象、本命排盘、易经宝典、亲友命簿
    expect(find.text('今日卦象'), findsWidgets);
    expect(find.text('本命排盘'), findsWidgets);
    expect(find.text('易经宝典'), findsWidgets);
    expect(find.text('亲友命簿'), findsWidgets);

    // 默认展示 Tab 0「今日专属流日卦」
    expect(find.text('今日专属流日卦'), findsOneWidget);
    expect(find.text('【本命与天时交感 · 今日专属卦】'), findsOneWidget);
  });

  testWidgets('从易经宝典右上角打开时辰表查阅时辰典籍信息', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 点击第三个标签页（易经宝典）
    await tester.tap(find.text('易经宝典'));
    await tester.pumpAndSettle();

    // 验证易经宝典页面与右上角「时辰表」入口
    expect(find.text('易经六十四卦宝典'), findsOneWidget);
    expect(find.text('时辰表'), findsOneWidget);

    // 点击「时辰表」进入十二时辰表
    await tester.tap(find.text('时辰表'));
    await tester.pumpAndSettle();

    // 验证时辰表页面正常显示并展示十二时辰信息
    expect(find.text('十二时辰表'), findsOneWidget);
    expect(find.text('子时 (23:00 - 01:00)'), findsOneWidget);
    expect(find.text('古称 · 夜半 / 三更'), findsOneWidget);
    expect(find.text('五行属水'), findsWidgets);
  });

  testWidgets('切换至本命排盘点击「命盘详批」在 360px 窄屏手机分辨率下正常渲染无溢出', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 切换至 Tab 1「本命排盘」
    await tester.tap(find.text('本命排盘'));
    await tester.pumpAndSettle();

    // 验证进入本命排盘页面
    expect(find.text('易经本命推算 · 浑天罗盘'), findsOneWidget);

    // 点击「命盘详批」按钮进入结果页
    await tester.ensureVisible(find.text('命盘详批'));
    await tester.tap(find.text('命盘详批'));
    await tester.pumpAndSettle();

    // 验证进入命盘详批结果页，并显示纯文本「四柱八字乾坤盘」
    expect(find.text('四柱八字乾坤盘'), findsOneWidget);

    // 验证专业参考书版块：体用生克权衡与五维搭配卦象演进全览无溢出正常渲染
    expect(find.text('【易理体用 · 五行生克权衡】'), findsOneWidget);
    expect(find.text('【周易五维 · 搭配卦象演进全览】'), findsOneWidget);

    // 验证右上角为星形收藏按钮
    final starButtonFinder = find.byIcon(Icons.star_border);
    expect(starButtonFinder, findsOneWidget);

    // 点击星形按钮弹出收藏对话框
    await tester.tap(starButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('收藏至亲友命簿'), findsOneWidget);
    expect(find.text('保存入库'), findsOneWidget);

    // 点击保存
    await tester.tap(find.text('保存入库'));
    await tester.pumpAndSettle();

    // 验证数据已存入持久化仓库
    final profiles = await ProfileRepository.instance.getAllProfiles();
    expect(profiles.length, equals(1));

    // 验证星形按钮点亮
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
