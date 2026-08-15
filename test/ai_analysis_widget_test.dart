import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/ai/deepseek_service.dart';
import 'package:whoami/data/repositories/ai_chat_repository.dart';
import 'package:whoami/data/repositories/iching_repository.dart';
import 'package:whoami/data/repositories/profile_repository.dart';
import 'package:whoami/main.dart';
import 'package:whoami/presentation/pages/ai/ai_analysis_page.dart';
import 'package:whoami/presentation/widgets/ai_floating_button.dart';
import 'package:whoami/presentation/widgets/deepseek_whale_icon.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await IChingRepository.instance.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'whoami_user_profiles_v1': '[{"id":"prof-1","name":"张三","gender":"乾 (男)","solarDate":"1995-05-15T00:00:00.000","isLunar":false,"hourIndex":5,"isHourKnown":true,"notes":"本人","createdAt":"2026-01-01T00:00:00.000"}]',
      'whoami_primary_profile_id_v1': 'prof-1',
      'deepseek_api_key': 'sk-test-key-valid',
      'deepseek_model': 'deepseek-v4-flash',
      'deepseek_enable_thinking': true,
    });
    await ProfileRepository.instance.init();
    await AiChatRepository.instance.init();
    await DeepSeekService.instance.init();
  });

  testWidgets('主界面点击 AI 悬浮按钮跳转至独立全屏 AI 易学参详页面，图标为 DeepSeek 鲸鱼', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 验证 AI 悬浮按钮存在且包含 DeepSeek 鲸鱼图标
    expect(find.byType(AiFloatingButton), findsOneWidget);
    expect(find.text('AI 参详'), findsOneWidget);
    expect(find.byType(DeepSeekWhaleIcon), findsWidgets);

    // 点击 AI 悬浮按钮
    await tester.tap(find.text('AI 参详'));
    await tester.pumpAndSettle();

    // 验证进入独立全屏页面
    expect(find.byType(AiAnalysisPage), findsOneWidget);
    expect(find.text('AI 易学参详明镜'), findsOneWidget);

    // 验证左上角为历史对话入口图标
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    // 验证右上角没有叉叉和加号，仅保留设置按钮
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.add_comment_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 验证左上角标题下方展示当前模型与深度思考状态
    expect(find.text('deepseek-v4-flash · 深度思考'), findsOneWidget);
  });

  testWidgets('点击左上角历史图标展开历史对话抽屉，支持新建草稿会话与发消息后才保存', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 进入 AI 参详页面
    await tester.tap(find.text('AI 参详'));
    await tester.pumpAndSettle();

    // 打开历史抽屉
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    // 验证抽屉展开
    expect(find.text('历史参详对话'), findsOneWidget);
    expect(find.text('开启新参详会话'), findsOneWidget);

    // 点击开启新参详会话
    await tester.tap(find.text('开启新参详会话'));
    await tester.pumpAndSettle();

    // 验证抽屉关闭，未发消息前会话列表为空（不生成无用空记录）
    expect(AiChatRepository.instance.sessions.isEmpty, true);

    // 在输入框中输入问题并发送
    final inputFinder = find.byKey(const ValueKey('ai_chat_input_field'));
    await tester.enterText(inputFinder, '请为我推演今年的事业发展');
    final sendButtonFinder = find.byKey(const ValueKey('ai_send_button'));
    await tester.tap(sendButtonFinder);
    await tester.pump();

    // 验证消息发出后才正式保存到 sessions
    expect(AiChatRepository.instance.sessions.length, 1);
    expect(AiChatRepository.instance.sessions.first.messages.isNotEmpty, true);
  });

  testWidgets('历史抽屉中删除对话需要弹出二次确认弹窗', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 进入 AI 参详页面
    await tester.tap(find.text('AI 参详'));
    await tester.pumpAndSettle();

    // 发送一条消息确保有历史会话
    final inputFinder = find.byKey(const ValueKey('ai_chat_input_field'));
    await tester.enterText(inputFinder, '测算财运');
    await tester.tap(find.byKey(const ValueKey('ai_send_button')));
    await tester.pump();

    // 打开历史抽屉
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    // 点击删除按钮
    final deleteBtnFinder = find.byIcon(Icons.delete_outline);
    expect(deleteBtnFinder, findsOneWidget);
    await tester.tap(deleteBtnFinder);
    await tester.pumpAndSettle();

    // 验证弹出确认删除对话框
    expect(find.text('删除参详记录'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认删除'), findsOneWidget);

    // 点击确认删除
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    // 验证会话已被删除，提示暂无历史记录
    expect(AiChatRepository.instance.sessions.isEmpty, true);
    expect(find.text('暂无历史对话记录'), findsOneWidget);
  });

  testWidgets('点击左上角模型可弹出模型切换列表，支持切换模型与开关深度思考', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoAmIApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 进入 AI 参详页面
    await tester.tap(find.text('AI 参详'));
    await tester.pumpAndSettle();

    // 点击左上角标题下方的当前模型标签
    await tester.tap(find.text('deepseek-v4-flash · 深度思考'));
    await tester.pumpAndSettle();

    // 验证弹出模型与思考模式底板
    expect(find.text('深度思考模式 (Thinking Mode)'), findsOneWidget);
    expect(find.text('选择 DeepSeek 模型'), findsOneWidget);
    expect(find.text('deepseek-v4-pro'), findsOneWidget);

    // 切换深度思考开关 (由开变关)
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(DeepSeekService.instance.enableThinking, false);

    // 点击切换至 deepseek-v4-pro
    await tester.tap(find.text('deepseek-v4-pro'));
    await tester.pumpAndSettle();

    // 验证当前模型已变为 deepseek-v4-pro 且模式为极速模式
    expect(DeepSeekService.instance.model, 'deepseek-v4-pro');
    expect(find.text('deepseek-v4-pro · 极速模式'), findsOneWidget);
  });
}
