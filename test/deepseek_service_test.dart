import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/core/ai/deepseek_service.dart';
import 'package:whoami/data/models/user_profile.dart';
import 'package:whoami/data/repositories/iching_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await IChingRepository.instance.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'deepseek_api_key': 'test-key-123',
      'deepseek_model': 'deepseek-v4-flash',
      'deepseek_base_url': 'https://api.deepseek.com',
      'deepseek_temperature': 0.7,
      'deepseek_enable_thinking': true,
    });
    await DeepSeekService.instance.init();
  });

  group('DeepSeekService 易学系统提示词与数据载荷构建测试', () {
    test('System Prompt 必须包含权威经典出处、五维卦象与体用生克规则', () {
      final prompt = DeepSeekService.instance.buildSystemPrompt();

      expect(prompt, contains('《周易》'));
      expect(prompt, contains('文王六十四卦'));
      expect(prompt, contains('《十翼》'));
      expect(prompt, contains('【本卦】'));
      expect(prompt, contains('【互卦】'));
      expect(prompt, contains('【变卦】'));
      expect(prompt, contains('体用生克'));
      expect(prompt, contains('Markdown'));
    });

    test('buildUserDataPayload 精炼紧凑地标注【核心命主】与【对比合盘对象】关键数据', () {
      final primaryProfile = UserProfile(
        id: 'primary-1',
        name: '王小明',
        gender: '乾 (男)',
        solarDate: DateTime(1995, 8, 18, 14, 0),
        isLunar: false,
        hourIndex: 7, // 未时
        isHourKnown: true,
        notes: '本人',
        createdAt: DateTime.now(),
      );

      final comparedProfile = UserProfile(
        id: 'friend-1',
        name: '李小红',
        gender: '坤 (女)',
        solarDate: DateTime(1996, 5, 20, 10, 0),
        isLunar: false,
        hourIndex: 5, // 巳时
        isHourKnown: true,
        notes: '合伙人',
        createdAt: DateTime.now(),
      );

      final primaryResult = DeepSeekService.calculateResultForProfile(primaryProfile);
      final comparedResult = DeepSeekService.calculateResultForProfile(comparedProfile);

      final payload = DeepSeekService.instance.buildUserDataPayload(
        primaryProfile: primaryProfile,
        primaryResult: primaryResult,
        comparedProfiles: [comparedProfile],
        comparedResults: [comparedResult],
        userQuestion: '我们两个人适合合伙创业做传统文化项目吗？',
      );

      // 验证核心命主标记
      expect(payload, contains('【核心命主 / 本人 (主生辰)】:'));
      expect(payload, contains('姓名: 王小明 | 性别: 乾 (男)'));
      expect(payload, contains('本命卦:'));
      expect(payload, contains('互卦'));

      // 验证对比对象标记
      expect(payload, contains('【对比合盘对象】:'));
      expect(payload, contains('李小红 (合伙人, 坤 (女))'));

      // 验证用户提问
      expect(payload, contains('我们两个人适合合伙创业做传统文化项目吗？'));
    });

    test('配置保存、深度思考开关与模型切换持久化正确', () async {
      await DeepSeekService.instance.saveSettings(
        apiKey: 'sk-new-key-888',
        baseUrl: 'https://api.deepseek.com',
        temperature: 0.9,
      );
      await DeepSeekService.instance.setModel('deepseek-v4-pro');
      await DeepSeekService.instance.setThinkingEnabled(false);

      expect(DeepSeekService.instance.apiKey, 'sk-new-key-888');
      expect(DeepSeekService.instance.model, 'deepseek-v4-pro');
      expect(DeepSeekService.instance.enableThinking, false);
      expect(DeepSeekService.instance.temperature, 0.9);
    });
  });
}
