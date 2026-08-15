import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whoami/data/models/user_profile.dart';
import 'package:whoami/data/repositories/profile_repository.dart';
import 'package:whoami/presentation/pages/archive/archive_list_page.dart';
import 'package:whoami/presentation/pages/daily/daily_hexagram_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileRepository 唯一数据源 (Single Source of Truth) 响应式测试', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ProfileRepository.instance.loadFromList([]);
    });

    test('新增首个档案设为主生辰并固定在第一个，后续新增档案不顶替既有主生辰', () async {
      final p1 = UserProfile(
        id: 'test_1',
        name: '张三',
        gender: '乾 (男)',
        solarDate: DateTime(1990, 5, 20),
        isLunar: false,
        hourIndex: 6,
        isHourKnown: true,
        notes: '好友测试',
        createdAt: DateTime.now(),
      );

      await ProfileRepository.instance.saveProfile(p1);
      expect(ProfileRepository.instance.primaryProfile?.name, '张三');
      expect(ProfileRepository.instance.profiles.first.name, '张三');

      // 后续新增档案李四
      final p2 = UserProfile(
        id: 'test_2',
        name: '李四',
        gender: '坤 (女)',
        solarDate: DateTime(1995, 8, 18),
        isLunar: false,
        hourIndex: 2,
        isHourKnown: true,
        notes: '知己',
        createdAt: DateTime.now(),
      );

      await ProfileRepository.instance.saveProfile(p2);

      // 主生辰仍然是张三，且固定排在第一个；李四排在第二
      expect(ProfileRepository.instance.primaryProfile?.name, '张三');
      expect(ProfileRepository.instance.profiles[0].name, '张三');
      expect(ProfileRepository.instance.profiles[1].name, '李四');

      // 手动切换李四为主生辰，李四立刻固定在第一个
      await ProfileRepository.instance.setPrimaryProfileId('test_2');
      expect(ProfileRepository.instance.primaryProfile?.name, '李四');
      expect(ProfileRepository.instance.profiles[0].name, '李四');
      expect(ProfileRepository.instance.profiles[1].name, '张三');

      // 再次新增档案王五，李四依然固定在第一个，王五排在第二
      final p3 = UserProfile(
        id: 'test_3',
        name: '王五',
        gender: '乾 (男)',
        solarDate: DateTime(2000, 1, 1),
        isLunar: false,
        hourIndex: 0,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      await ProfileRepository.instance.saveProfile(p3);
      expect(ProfileRepository.instance.primaryProfile?.name, '李四');
      expect(ProfileRepository.instance.profiles[0].name, '李四');
      expect(ProfileRepository.instance.profiles[1].name, '王五');
      expect(ProfileRepository.instance.profiles[2].name, '张三');
    });

    test('切换主生辰即时更新 primaryProfile 并通知全部依赖', () async {
      final p1 = UserProfile(
        id: 'p_1',
        name: '张三',
        gender: '乾 (男)',
        solarDate: DateTime(1990, 5, 20),
        isLunar: false,
        hourIndex: 6,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );
      final p2 = UserProfile(
        id: 'p_2',
        name: '李四',
        gender: '坤 (女)',
        solarDate: DateTime(1995, 8, 18),
        isLunar: false,
        hourIndex: 2,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      ProfileRepository.instance.loadFromList([p1, p2], primaryId: 'p_1');
      expect(ProfileRepository.instance.primaryProfile?.name, '张三');

      int notifyCount = 0;
      ProfileRepository.instance.addListener(() => notifyCount++);

      await ProfileRepository.instance.setPrimaryProfileId('p_2');
      expect(notifyCount, 1);
      expect(ProfileRepository.instance.primaryProfile?.name, '李四');
      expect(ProfileRepository.instance.profiles.first.name, '李四');
    });

    test('删除档案即时同步清理并维持合法主生辰', () async {
      final p1 = UserProfile(
        id: 'p_1',
        name: '张三',
        gender: '乾 (男)',
        solarDate: DateTime(1990, 5, 20),
        isLunar: false,
        hourIndex: 6,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );
      final p2 = UserProfile(
        id: 'p_2',
        name: '李四',
        gender: '坤 (女)',
        solarDate: DateTime(1995, 8, 18),
        isLunar: false,
        hourIndex: 2,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      ProfileRepository.instance.loadFromList([p1, p2], primaryId: 'p_1');

      await ProfileRepository.instance.deleteProfile('p_1');
      expect(ProfileRepository.instance.profiles.length, 1);
      expect(ProfileRepository.instance.profiles.first.name, '李四');
      expect(ProfileRepository.instance.primaryProfile?.name, '李四');
    });

    testWidgets('ArchiveListPage 向左滑动卡片显现操作，设为主生辰无需确认即刻置顶', (tester) async {
      final p1 = UserProfile(
        id: 'user_1',
        name: '张三',
        gender: '乾 (男)',
        solarDate: DateTime(1990, 5, 20),
        isLunar: false,
        hourIndex: 6,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );
      final p2 = UserProfile(
        id: 'user_2',
        name: '李四',
        gender: '坤 (女)',
        solarDate: DateTime(1995, 8, 18),
        isLunar: false,
        hourIndex: 2,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      ProfileRepository.instance.loadFromList([p1, p2], primaryId: 'user_1');

      await tester.pumpWidget(
        const MaterialApp(
          home: ArchiveListPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证张三固定在第一位，是主生辰
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('李四'), findsOneWidget);
      expect(find.text('主生辰'), findsOneWidget);

      // 向左滑动李四的卡片
      await tester.drag(find.text('李四'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // 确认露出「设为主生辰」与「删除」按钮
      expect(find.text('设为主生辰'), findsOneWidget);
      expect(find.text('删除'), findsWidgets);

      // 点击「设为主生辰」，无需确认直接置顶
      await tester.tap(find.text('设为主生辰'));
      await tester.pumpAndSettle();

      // 验证李四已成为主生辰并固定在首位
      expect(ProfileRepository.instance.primaryProfileId, 'user_2');
      expect(ProfileRepository.instance.profiles.first.name, '李四');
    });

    testWidgets('DailyHexagramPage 响应式实时联动：主生辰变更，今日运势实时自动重算', (tester) async {
      final p1 = UserProfile(
        id: 'p_a',
        name: '赵六',
        gender: '乾 (男)',
        solarDate: DateTime(1992, 3, 15),
        isLunar: false,
        hourIndex: 6,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      ProfileRepository.instance.loadFromList([p1], primaryId: 'p_a');

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyHexagramPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证当前显示赵六的生辰流日
      expect(find.textContaining('赵六'), findsWidgets);

      // 新增并切换到新主生辰「孙七」
      final p2 = UserProfile(
        id: 'p_b',
        name: '孙七',
        gender: '坤 (女)',
        solarDate: DateTime(2001, 10, 25),
        isLunar: false,
        hourIndex: 8,
        isHourKnown: true,
        notes: '',
        createdAt: DateTime.now(),
      );

      await ProfileRepository.instance.saveProfile(p2);
      await ProfileRepository.instance.setPrimaryProfileId('p_b');
      await tester.pumpAndSettle();

      // 验证今日卦象页面自动即时刷新为孙七
      expect(find.textContaining('孙七'), findsWidgets);
    });
  });
}
