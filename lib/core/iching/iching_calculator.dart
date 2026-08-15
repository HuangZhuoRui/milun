import 'package:lunar/lunar.dart';
import '../../core/calendar/bazi_engine.dart';
import '../../data/models/daily_hexagram_result.dart';
import '../../data/models/hexagram_detail.dart';
import '../../data/repositories/iching_repository.dart';

/// 易经起卦与全息命盘推算器
class IChingCalculator {
  /// 先天八卦数映射：1乾、2兑、3离、4震、5巽、6坎、7艮、8/0坤
  static const Map<int, String> _numberToTrigram = {
    1: '乾',
    2: '兑',
    3: '离',
    4: '震',
    5: '巽',
    6: '坎',
    7: '艮',
    8: '坤',
    0: '坤',
  };

  /// 八卦对应 3 位二进制（由初爻至上爻排列）
  static const Map<String, String> _trigramToBinary = {
    '乾': '111',
    '兑': '110',
    '离': '101',
    '震': '100',
    '巽': '011',
    '坎': '010',
    '艮': '001',
    '坤': '000',
  };

  /// 八卦五行属性映射
  static const Map<String, String> _trigramElements = {
    '乾': '金', '兑': '金',
    '离': '火',
    '震': '木', '巽': '木',
    '坎': '水',
    '艮': '土', '坤': '土',
  };

  /// 十二地支先天序数 (1..12)
  static const Map<String, int> _zhiNumber = {
    '子': 1, '丑': 2, '寅': 3, '卯': 4,
    '辰': 5, '巳': 6, '午': 7, '未': 8,
    '申': 9, '酉': 10, '戌': 11, '亥': 12,
  };

  /// 综合生辰干支起卦：计算本卦、互卦、变卦、错卦、综卦与流年卦
  static DivinationResult calculateHexagrams({
    required String name,
    required String gender,
    required DateTime solarDate,
    required int hourIndex, // 0..11 对应子时至亥时，-1 表示时辰未知
    required bool isHourKnown,
    required IChingRepository repository,
    required BaZiInfo bazi,
  }) {
    // 转换为农历以提取农历月日
    Solar solar = Solar.fromYmdHms(
      solarDate.year,
      solarDate.month,
      solarDate.day,
      isHourKnown && hourIndex >= 0 ? hourIndex * 2 : 12,
      0,
      0,
    );
    Lunar lunar = solar.getLunar();

    int lunarMonth = lunar.getMonth().abs();
    int lunarDay = lunar.getDay();
    String yearZhi = bazi.yearGanZhi.length >= 2 ? bazi.yearGanZhi.substring(1, 2) : '子';
    int yearZhiNum = _zhiNumber[yearZhi] ?? 1;

    String upperTrigramName;
    String lowerTrigramName;
    int? changingYaoIdx;

    if (isHourKnown && hourIndex >= 0) {
      // 完备大衍四柱起卦法（L2 精度 100%）
      String hourZhi = bazi.hourGanZhi.length >= 2 ? bazi.hourGanZhi.substring(1, 2) : '午';
      int hourZhiNum = _zhiNumber[hourZhi] ?? 7;

      int upperSum = yearZhiNum + lunarMonth + lunarDay;
      int lowerSum = yearZhiNum + lunarMonth + lunarDay + hourZhiNum;
      int yaoSum = yearZhiNum + lunarMonth + lunarDay + hourZhiNum;

      int upRemainder = upperSum % 8;
      int lowRemainder = lowerSum % 8;
      int yaoRemainder = yaoSum % 6;

      upperTrigramName = _numberToTrigram[upRemainder] ?? '乾';
      lowerTrigramName = _numberToTrigram[lowRemainder] ?? '坤';
      changingYaoIdx = yaoRemainder == 0 ? 6 : yaoRemainder;
    } else {
      // 时辰不详：年月日三柱先天元神卦（L1 精度 75%）
      int upperSum = yearZhiNum + lunarMonth;
      int lowerSum = lunarDay;

      int upRemainder = upperSum % 8;
      int lowRemainder = lowerSum % 8;

      upperTrigramName = _numberToTrigram[upRemainder] ?? '乾';
      lowerTrigramName = _numberToTrigram[lowRemainder] ?? '坤';
      changingYaoIdx = null;
    }

    // 组合成本卦 6 位二进制卦码（下卦 3 位 + 上卦 3 位，code[0]为初爻，code[5]为上爻）
    String lowBin = _trigramToBinary[lowerTrigramName] ?? '000';
    String upBin = _trigramToBinary[upperTrigramName] ?? '111';
    String mainCode = lowBin + upBin;

    // 从数据库中索引本命主卦
    HexagramDetail mainHex = repository.getByCode(mainCode) ?? repository.getById(1);

    // 计算互卦（下互：2、3、4爻；上互：3、4、5爻）
    String mutualLow = mainCode.substring(1, 4);
    String mutualUp = mainCode.substring(2, 5);
    String mutualCode = mutualLow + mutualUp;
    HexagramDetail mutualHex = repository.getByCode(mutualCode) ?? repository.getById(2);

    // 计算错卦（阴阳六爻全部取反反转）
    String oppCode = mainCode.split('').map((c) => c == '1' ? '0' : '1').join('');
    HexagramDetail oppositeHex = repository.getByCode(oppCode) ?? repository.getById(mainHex.id);

    // 计算综卦（上下颠倒翻转 / 倒卦）
    String invCode = mainCode.split('').reversed.join('');
    HexagramDetail inverseHex = repository.getByCode(invCode) ?? repository.getById(mainHex.id);

    // 计算变卦（若有明确动爻）
    HexagramDetail? transHex;
    YaoDetail? changingYao;
    if (changingYaoIdx != null && changingYaoIdx >= 1 && changingYaoIdx <= 6) {
      int bitIdx = changingYaoIdx - 1;
      List<String> bits = mainCode.split('');
      bits[bitIdx] = (bits[bitIdx] == '1') ? '0' : '1';
      String transCode = bits.join('');
      transHex = repository.getByCode(transCode);
      if (changingYaoIdx - 1 < mainHex.yaos.length) {
        changingYao = mainHex.yaos[changingYaoIdx - 1];
      }
    }

    // 计算当前流年卦（结合当前公历年份干支）
    int currentYear = DateTime.now().year;
    int curYearBranchNum = ((currentYear - 4) % 12) + 1; // 2024=辰(5), 2025=巳(6), 2026=午(7)
    int curYearUp = (mainHex.id + curYearBranchNum) % 8;
    int curYearLow = (mainHex.id + curYearBranchNum + 3) % 8;
    String curYearCode = (_trigramToBinary[_numberToTrigram[curYearLow]] ?? '111') +
        (_trigramToBinary[_numberToTrigram[curYearUp]] ?? '000');
    HexagramDetail? yearlyHex = repository.getByCode(curYearCode);

    String precision = isHourKnown
        ? 'L2 完备大衍全息盘 (100% 精度)'
        : 'L1 先天元神命盘 (75% 精度 · 时辰不详)';

    String summary = '${mainHex.name} · ${mainHex.upperTrigram}上${mainHex.lowerTrigram}下 · 五行属${mainHex.element}';

    return DivinationResult(
      name: name.isEmpty ? '本命求测者' : name,
      gender: gender,
      solarDate: solarDate,
      hourIndex: hourIndex,
      bazi: bazi,
      mainHexagram: mainHex,
      mutualHexagram: mutualHex,
      transformedHexagram: transHex,
      oppositeHexagram: oppositeHex,
      inverseHexagram: inverseHex,
      changingYaoIndex: changingYaoIdx,
      changingYao: changingYao,
      yearlyHexagram: yearlyHex,
      precisionLevel: precision,
      summaryTitle: summary,
    );
  }

  /// 依据邵雍《皇极经世·本命流日卦法》与《梅花易数》推算【命主专属今日流日运势卦】
  static DailyHexagramResult calculatePersonalizedDailyHexagram({
    required DateTime targetDate,
    required DateTime birthDate,
    required int birthHourIndex, // 0..11, -1 for unknown
    String profileName = '本命求测者',
    String gender = '乾 (男)',
    IChingRepository? repository,
  }) {
    final repo = repository ?? IChingRepository.instance;

    // 1. 推算命主先天本命全息盘
    final birthBaZi = BaZiEngine.calculate(
      solarDate: birthDate,
      hourIndex: birthHourIndex,
      isHourKnown: birthHourIndex >= 0,
    );
    final birthResult = calculateHexagrams(
      name: profileName,
      gender: gender,
      solarDate: birthDate,
      hourIndex: birthHourIndex,
      isHourKnown: birthHourIndex >= 0,
      repository: repo,
      bazi: birthBaZi,
    );

    final birthMainHex = birthResult.mainHexagram;
    final dayMasterElement = birthResult.bazi.dayMasterElement;
    final birthYearZhi = birthResult.bazi.yearGanZhi.length >= 2
        ? birthResult.bazi.yearGanZhi.substring(1, 2)
        : '子';
    final int birthYearZhiNum = _zhiNumber[birthYearZhi] ?? 1;
    final int birthHourNum = (birthHourIndex >= 0) ? (birthHourIndex + 1) : 7;

    // 2. 目标流日天象干支与农历信息
    Solar solar = Solar.fromYmdHms(targetDate.year, targetDate.month, targetDate.day, 12, 0, 0);
    Lunar lunar = solar.getLunar();

    String yearGanZhi = lunar.getYearInGanZhi();
    String monthGanZhi = lunar.getMonthInGanZhi();
    String dayGanZhi = lunar.getDayInGanZhi();

    String todayYearZhi = yearGanZhi.length >= 2 ? yearGanZhi.substring(1, 2) : '子';
    String todayDayZhi = dayGanZhi.length >= 2 ? dayGanZhi.substring(1, 2) : '子';

    int todayYearZhiNum = _zhiNumber[todayYearZhi] ?? 1;
    int todayDayZhiNum = _zhiNumber[todayDayZhi] ?? 1;
    int todayLunarMonth = lunar.getMonth().abs();
    int todayLunarDay = lunar.getDay();

    // 3. 本命与天时交感起卦 (Natal-Daily Interaction)
    // 上卦（外在天时机运 · 客用）：流年 + 流月 + 流日 + 本命年支
    int upSum = todayYearZhiNum + todayLunarMonth + todayLunarDay + birthYearZhiNum;
    int upRem = upSum % 8;
    String upTrigram = _numberToTrigram[upRem] ?? '乾';

    // 下卦（命主体性立身 · 主体）：本命卦数 + 流日日支 + 本命时辰数
    int lowSum = birthMainHex.id + todayDayZhiNum + birthHourNum;
    int lowRem = lowSum % 8;
    String lowTrigram = _numberToTrigram[lowRem] ?? '坤';

    // 动爻（今日吉凶转折与破局机微）：总数模 6
    int yaoSum = upSum + lowSum;
    int yaoRem = yaoSum % 6;
    int changingYaoIdx = yaoRem == 0 ? 6 : yaoRem;

    // 组成本命专属流日卦象
    String lowBin = _trigramToBinary[lowTrigram] ?? '000';
    String upBin = _trigramToBinary[upTrigram] ?? '111';
    String mainCode = lowBin + upBin;

    HexagramDetail todayNatalHex = repo.getByCode(mainCode) ?? repo.getById(1);

    // 变卦计算
    int bitIdx = changingYaoIdx - 1;
    List<String> bits = mainCode.split('');
    bits[bitIdx] = (bits[bitIdx] == '1') ? '0' : '1';
    String transCode = bits.join('');
    HexagramDetail transHex = repo.getByCode(transCode) ?? todayNatalHex;

    YaoDetail? changingYao;
    if (changingYaoIdx - 1 < todayNatalHex.yaos.length) {
      changingYao = todayNatalHex.yaos[changingYaoIdx - 1];
    }

    // 4. 体用五行生克与多维运势评分推算
    String lowElem = _trigramElements[lowTrigram] ?? '土';
    String upElem = _trigramElements[upTrigram] ?? '金';

    String energyRelation;
    String fortuneLevel;
    int baseScore;
    List<String> yiList;
    List<String> jiList;

    if (upElem == lowElem) {
      // 体用比和
      energyRelation = '【体用比和·吉】天时上卦$upTrigram($upElem) 与 命主体卦$lowTrigram($lowElem) 同气连枝。主客相协，内外和合，利于团队协同推进与维系关系。';
      fortuneLevel = '吉 · 主客相协诸事亨和';
      baseScore = 88;
      yiList = ['团队协作', '项目推进', '亲友聚会', '读书进修', '修整身心'];
      jiList = ['孤立行事', '偏激执拗', '无端猜忌'];
    } else if ((upElem == '木' && lowElem == '火') ||
        (upElem == '火' && lowElem == '土') ||
        (upElem == '土' && lowElem == '金') ||
        (upElem == '金' && lowElem == '水') ||
        (upElem == '水' && lowElem == '木')) {
      // 用生体
      energyRelation = '【用生体·大吉】天时上卦$upTrigram($upElem) 生助 命主体卦$lowTrigram($lowElem)。外境赋能，多得天时贵人照拂与良机襄助，大展宏图。';
      fortuneLevel = '大吉 · 贵人扶持亨通顺达';
      baseScore = 94;
      yiList = ['商务洽谈', '签署契约', '拜会贵人', '开拓新局', '求财投资'];
      jiList = ['犹疑不决', '固步自封', '错失良机'];
    } else if ((lowElem == '木' && upElem == '火') ||
        (lowElem == '火' && upElem == '土') ||
        (lowElem == '土' && upElem == '金') ||
        (lowElem == '金' && upElem == '水') ||
        (lowElem == '水' && upElem == '木')) {
      // 体生用
      energyRelation = '【体生用·泄秀】命主体卦$lowTrigram($lowElem) 滋养 天时上卦$upTrigram($upElem)。才华才思得以向外抒发展现，但精力耗费较大，需注意劳逸结合。';
      fortuneLevel = '中平 · 吐秀输出宜防虚耗';
      baseScore = 80;
      yiList = ['创意策划', '演讲汇报', '方案撰写', '学术钻研', '舒缓调理'];
      jiList = ['过度透支', '大包大揽', '冲动消费'];
    } else if ((lowElem == '金' && upElem == '木') ||
        (lowElem == '木' && upElem == '土') ||
        (lowElem == '土' && upElem == '水') ||
        (lowElem == '水' && upElem == '火') ||
        (lowElem == '火' && upElem == '金')) {
      // 体克用
      energyRelation = '【体克用·掌控】命主体卦$lowTrigram($lowElem) 克制 天时上卦$upTrigram($upElem)。命主掌控外境，求财图强，虽需付出心力攻坚，但终能掌控局势并见成效。';
      fortuneLevel = '小吉 · 劳碌求财掌控外境';
      baseScore = 84;
      yiList = ['攻坚克难', '制定规范', '整理账目', '业务督导', '把控全局'];
      jiList = ['急躁冒进', '盛气凌人', '轻敌大意'];
    } else {
      // 用克体
      energyRelation = '【用克体·磨砺】天时上卦$upTrigram($upElem) 克制 命主体卦$lowTrigram($lowElem)。外在环境多有考验规训与突发变数，宜低调沉潜、修德守正、避其锋芒。';
      fortuneLevel = '慎戒 · 规训磨砺守正自持';
      baseScore = 70;
      yiList = ['修德自省', '查漏补缺', '整理内务', '静心阅读', '稳健蓄力'];
      jiList = ['盲目冲动', '正面冲突', '大额借贷', '口舌争端'];
    }

    int tierBonus = (todayNatalHex.fortuneTier == '上上卦' || todayNatalHex.fortuneTier == '上吉卦') ? 3 : 0;
    int finalScore = (baseScore + tierBonus).clamp(60, 98);

    final fortuneAspects = {
      '综合运势': finalScore,
      '事功求谋': (finalScore + (todayNatalHex.fortuneTier == '上吉卦' ? 3 : -1)).clamp(60, 99),
      '财富运筹': (finalScore + (todayNatalHex.element == '金' || todayNatalHex.element == '水' ? 2 : -2)).clamp(60, 99),
      '情感人际': (finalScore + (lowElem == upElem ? 4 : -2)).clamp(60, 99),
      '身心状态': (finalScore + (lowElem == '土' || lowElem == '木' ? 2 : -3)).clamp(60, 99),
    };

    String jieQi = lunar.getJieQi();
    String solarTerm = jieQi.isNotEmpty ? jieQi : '时令平顺';
    String lunarString = '$yearGanZhi年 $monthGanZhi月 $dayGanZhi日 · 农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';

    String careerGuidance = todayNatalHex.career.isNotEmpty
        ? '${todayNatalHex.career} 今日行事宜：${yiList.take(2).join('、')}。'
        : '今日宜明确核心目标，行事果断且兼顾多方协同，避免因细枝末节延误时机。';

    String wealthGuidance = todayNatalHex.wealth.isNotEmpty
        ? '${todayNatalHex.wealth} 财务心态需稳健，切忌${jiList.take(2).join('、')}。'
        : '财运平稳，以守成储蓄与稳健理财为主，避免冲动消费与高风险投机。';

    String mindGuidance = todayNatalHex.health.isNotEmpty
        ? '${todayNatalHex.health} 调和身心，适度静心冥想或舒缓运动，保持从容不迫的精神风貌。'
        : '调和身心，适度静心冥想或舒缓运动，保持从容不迫的精神风貌。';

    String dailyQuote = '《周易·${todayNatalHex.name}》：${todayNatalHex.guaci} ${changingYao != null ? "【动爻】${changingYao.text}" : ""}';

    return DailyHexagramResult(
      profileName: profileName,
      birthDate: birthDate,
      birthHourIndex: birthHourIndex,
      birthMainHexagram: birthMainHex,
      dayMasterElement: dayMasterElement,
      solarDate: targetDate,
      lunarString: lunarString,
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      dayGanZhi: dayGanZhi,
      solarTerm: solarTerm,
      todayNatalHexagram: todayNatalHex,
      changingYaoIndex: changingYaoIdx,
      changingYao: changingYao,
      transformedHexagram: transHex,
      fortuneScore: finalScore,
      fortuneLevel: fortuneLevel,
      fortuneAspects: fortuneAspects,
      energyRelation: energyRelation,
      yiList: yiList,
      jiList: jiList,
      careerGuidance: careerGuidance,
      wealthGuidance: wealthGuidance,
      mindGuidance: mindGuidance,
      dailyQuote: dailyQuote,
    );
  }
}
