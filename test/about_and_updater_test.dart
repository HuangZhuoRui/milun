import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/updater/app_updater_service.dart';
import 'package:whoami/presentation/pages/about/about_page.dart';
import 'package:whoami/presentation/pages/about/update_history_page.dart';
import 'package:whoami/presentation/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppUpdaterService 逻辑单元测试', () {
    test('版本号对比算法 isNewerVersion 正确识别新旧版本', () {
      final updater = AppUpdaterService.instance;

      // 新版本高于当前
      expect(updater.isNewerVersion('v1.0.1', '1.0.0'), isTrue);
      expect(updater.isNewerVersion('v1.1.0', '1.0.0'), isTrue);
      expect(updater.isNewerVersion('v2.0.0', '1.0.0'), isTrue);
      expect(updater.isNewerVersion('v1.0.0+2', '1.0.0'), isFalse);
      expect(updater.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
      expect(updater.isNewerVersion('v0.9.9', '1.0.0'), isFalse);
    });

    test('自建服务器加速下载链接转换正确', () {
      final updater = AppUpdaterService.instance;
      const originalUrl = 'https://github.com/HuangZhuoRui/milun/releases/download/v1.0.0/milun-v1.0.0.apk';
      final accelerated = updater.getAcceleratedDownloadUrl(originalUrl);

      expect(accelerated, 'https://update.vincenthzr.org:8443/download/HuangZhuoRui/milun/releases/download/v1.0.0/milun-v1.0.0.apk');
    });

    test('ParsedChangelog 正确将 feat 与 fix 分离并分类', () {
      const rawChangelog = '''
### 弥纶 Android v1.0.0 更新内容
- feat: 新增关于与设置页面
- feat 支持自建加速节点
- fix: 修复深色模式边框问题
- fix 修复时辰表显示异常
- chore: 优化构建配置
''';

      final parsed = ParsedChangelog.parse(rawChangelog);

      expect(parsed.hasCategorized, isTrue);
      expect(parsed.features.length, 2);
      expect(parsed.features[0], '新增关于与设置页面');
      expect(parsed.features[1], '支持自建加速节点');

      expect(parsed.fixes.length, 2);
      expect(parsed.fixes[0], '修复深色模式边框问题');
      expect(parsed.fixes[1], '修复时辰表显示异常');

      expect(parsed.others.length, 1);
      expect(parsed.others[0], 'chore: 优化构建配置');
    });
  });

  group('AboutPage 关于与设置页面 Widget 测试', () {
    testWidgets('正常渲染纯文字品牌 Header、系统配置与更新入口，并支持跳转到独立更新页面', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AboutPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证品牌纯文字与出处
      expect(find.text('弥纶 · MiLun'), findsOneWidget);
      expect(find.textContaining('易与天地准，故能弥纶天地之道'), findsOneWidget);
      expect(find.text('当前版本: v1.0.0'), findsOneWidget);

      // 验证 DeepSeek 系统配置入口
      expect(find.text('DeepSeek 认知智能配置'), findsOneWidget);

      // 验证独立检查更新入口
      expect(find.text('软件更新'), findsOneWidget);
      expect(find.text('检查新版本与浏览历史更新'), findsOneWidget);

      // 点击跳转至独立更新页面
      await tester.tap(find.text('软件更新'));
      await tester.pumpAndSettle();

      // 验证已到达 UpdateHistoryPage
      expect(find.byType(UpdateHistoryPage), findsOneWidget);
      expect(find.text('当前版本'), findsOneWidget);
      expect(find.text('历史更新'), findsOneWidget);
    });
  });

  group('UpdateHistoryPage 独立更新与历史发布页面测试', () {
    testWidgets('正常渲染当前版本卡片、检查更新按钮与历史更新标题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const UpdateHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('软件更新'), findsOneWidget);
      expect(find.text('当前版本'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('历史更新'), findsOneWidget);
    });
  });
}
