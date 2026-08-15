import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/updater/app_updater_service.dart';
import 'package:whoami/presentation/pages/about/about_page.dart';
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
  });

  group('AboutPage 关于与设置页面 Widget 测试', () {
    testWidgets('正常渲染品牌、系统配置与检查更新卡片', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AboutPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证品牌与出处
      expect(find.text('弥纶 · MiLun'), findsOneWidget);
      expect(find.textContaining('易与天地准，故能弥纶天地之道'), findsOneWidget);
      expect(find.textContaining('当前版本:'), findsOneWidget);

      // 验证 DeepSeek 系统配置入口
      expect(find.text('DeepSeek 认知智能配置'), findsOneWidget);

      // 验证版本检查与更新入口
      expect(find.text('版本检查与加速分发'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
    });
  });
}
