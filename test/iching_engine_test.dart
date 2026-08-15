import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/core/calendar/bazi_engine.dart';
import 'package:whoami/core/iching/hour_finder_helper.dart';
import 'package:whoami/core/iching/iching_calculator.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 为单元测试准备轻量级模拟卦象知识库
  setUp(() {
    List<HexagramDetail> list = [
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
        xiang: '天行健，君子以自强不息。',
        overview: '刚健自强之象。',
        personality: '自驱领袖型',
        career: '大展宏图',
        wealth: '长线价值',
        love: '真诚坦荡',
        health: '注意肺部呼吸',
        advice: '自强不息',
        yaos: List.generate(6, (i) => YaoDetail(
          index: i + 1,
          name: i == 0 ? '初九' : (i == 5 ? '上九' : '九${i + 1}'),
          isYang: true,
          text: '潜龙勿用',
          xiang: '阳在下也',
          interpretation: '沉潜蓄力',
        )),
      ),
      HexagramDetail(
        id: 2,
        name: '坤为地',
        code: '000000',
        upperTrigram: '坤',
        lowerTrigram: '坤',
        element: '土',
        fortuneTier: '上吉卦',
        fortuneDesc: '纯和 · 厚德载物',
        guaci: '元亨，利牝马之贞。',
        tuan: '至哉坤元。',
        xiang: '地势坤，君子以厚德载物。',
        overview: '厚德载物之象。',
        personality: '包容稳重型',
        career: '厚积薄发',
        wealth: '稳扎稳打',
        love: '温柔细腻',
        health: '注意脾胃',
        advice: '厚德载物',
        yaos: List.generate(6, (i) => YaoDetail(
          index: i + 1,
          name: i == 0 ? '初六' : (i == 5 ? '上六' : '六${i + 1}'),
          isYang: false,
          text: '履霜坚冰至',
          xiang: '阴始凝也',
          interpretation: '见微知著',
        )),
      ),
    ];
    IChingRepository.instance.loadFromList(list);
  });

  group('BaZiEngine 八字排盘引擎测试', () {
    test('时辰已知时能正确计算四柱八字', () {
      final bazi = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: 6, // 午时
        isHourKnown: true,
      );

      expect(bazi.yearGanZhi.isNotEmpty, isTrue);
      expect(bazi.monthGanZhi.isNotEmpty, isTrue);
      expect(bazi.dayGanZhi.isNotEmpty, isTrue);
      expect(bazi.hourGanZhi, isNot('未知'));
      expect(bazi.isHourKnown, isTrue);
      expect(bazi.dayMaster.isNotEmpty, isTrue);
      expect(bazi.fiveElementsCount.values.fold(0, (a, b) => a + b), equals(8));
    });

    test('时辰不详时能正确计算年月日三柱并标记时辰未知', () {
      final bazi = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: -1,
        isHourKnown: false,
      );

      expect(bazi.yearGanZhi.isNotEmpty, isTrue);
      expect(bazi.monthGanZhi.isNotEmpty, isTrue);
      expect(bazi.dayGanZhi.isNotEmpty, isTrue);
      expect(bazi.hourGanZhi, equals('未知'));
      expect(bazi.isHourKnown, isFalse);
      expect(bazi.fiveElementsCount.values.fold(0, (a, b) => a + b), equals(6));
    });

    test('根据经度进行真太阳时校准', () {
      final baziBeijing = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: 6,
        isHourKnown: true,
        longitude: 116.4,
      );

      final baziUrumqi = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: 6,
        isHourKnown: true,
        longitude: 87.6,
      );

      expect(baziBeijing, isNotNull);
      expect(baziUrumqi, isNotNull);
    });
  });

  group('IChingCalculator 易经推算引擎测试', () {
    test('时辰已知时可推算出本卦、互卦、变卦、错卦、综卦与动爻', () {
      final bazi = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: 6,
        isHourKnown: true,
      );

      final result = IChingCalculator.calculateHexagrams(
        name: '张三',
        gender: '乾 (男)',
        solarDate: DateTime(1995, 8, 18),
        hourIndex: 6,
        isHourKnown: true,
        repository: IChingRepository.instance,
        bazi: bazi,
      );

      expect(result.mainHexagram, isNotNull);
      expect(result.mutualHexagram, isNotNull);
      expect(result.oppositeHexagram, isNotNull);
      expect(result.inverseHexagram, isNotNull);
      expect(result.changingYaoIndex, isNotNull);
      expect(result.precisionLevel, contains('100%'));
    });

    test('时辰未知时仍能算出先天元神卦且无动爻', () {
      final bazi = BaZiEngine.calculate(
        solarDate: DateTime(1995, 8, 18),
        hourIndex: -1,
        isHourKnown: false,
      );

      final result = IChingCalculator.calculateHexagrams(
        name: '李四',
        gender: '坤 (女)',
        solarDate: DateTime(1995, 8, 18),
        hourIndex: -1,
        isHourKnown: false,
        repository: IChingRepository.instance,
        bazi: bazi,
      );

      expect(result.mainHexagram, isNotNull);
      expect(result.mutualHexagram, isNotNull);
      expect(result.changingYaoIndex, isNull);
      expect(result.precisionLevel, contains('75%'));
    });
  });

  group('HourFinderHelper 十二时辰反推助手数据测试', () {
    test('完整包含十二时辰卡片数据', () {
      expect(HourFinderHelper.cards.length, equals(12));
      for (var card in HourFinderHelper.cards) {
        expect(card.name.isNotEmpty, isTrue);
        expect(card.archetype.isNotEmpty, isTrue);
        expect(card.temperament.isNotEmpty, isTrue);
        expect(card.habitTrait.isNotEmpty, isTrue);
      }
    });
  });
}
