import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/presentation/widgets/stacked_wisdom_deck.dart';

void main() {
  testWidgets('StackedWisdomDeck 3D层叠洗牌切牌卡片组件测试', (WidgetTester tester) async {
    final items = [
      const WisdomCardItem(
        volume: '卷一',
        title: '东方人格',
        subtitle: '性格底色与潜能',
        content: '君子终日乾乾，夕惕若厉。',
        advice: '自强不息，守正不阿。',
      ),
      const WisdomCardItem(
        volume: '卷二',
        title: '事业职场',
        subtitle: '格局与行事策略',
        content: '乘时而起，龙跃在渊。',
      ),
      const WisdomCardItem(
        volume: '卷三',
        title: '财富投资',
        subtitle: '风格与求财之道',
        content: '利见大人，顺天应命。',
      ),
      WisdomCardItem(
        volume: '卷六',
        title: '周易原典',
        subtitle: '卦辞彖象与爻辞',
        content: '',
        isClassic: true,
        hexagram: HexagramDetail(
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
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StackedWisdomDeck(
              items: items,
              cardHeight: 450,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证首张卡片（东方人格）处于活跃最顶层，内嵌标题与精美文案
    expect(find.text('卷一 · 东方人格'), findsOneWidget);
    expect(find.text('君子终日乾乾，夕惕若厉。'), findsOneWidget);
    expect(find.text('【处世锦囊】'), findsOneWidget);

    // 测试向左手势拖拽切牌（向左滑出，切入下一张卷二）
    await tester.drag(find.text('卷一 · 东方人格'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    // 验证已切入卷二（事业职场）
    expect(find.text('卷二 · 事业职场'), findsOneWidget);
    expect(find.text('乘时而起，龙跃在渊。'), findsOneWidget);

    // 向右手势拖拽切牌（从左覆入，切回卷一）
    await tester.drag(find.text('卷二 · 事业职场'), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.text('卷一 · 东方人格'), findsOneWidget);
  });
}
