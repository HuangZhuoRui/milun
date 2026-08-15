/// 单爻详细解读模型
class YaoDetail {
  /// 爻位序号：1 至 6（初爻至上爻）
  final int index;

  /// 爻位称谓：例如「初九」、「六二」、「九五」
  final String name;

  /// 是否为阳爻（true 为阳爻，false 为阴爻）
  final bool isYang;

  /// 周易原文爻辞
  final String text;

  /// 象传（小象传注解）
  final String xiang;

  /// 现代工作与生活行动指南
  final String interpretation;

  const YaoDetail({
    required this.index,
    required this.name,
    required this.isYang,
    required this.text,
    required this.xiang,
    required this.interpretation,
  });

  factory YaoDetail.fromJson(Map<String, dynamic> json) {
    return YaoDetail(
      index: json['index'] as int,
      name: json['name'] as String,
      isYang: json['isYang'] as bool? ?? (json['name'] as String? ?? '').contains('九'),
      text: json['text'] as String,
      xiang: json['xiang'] as String,
      interpretation: json['interpretation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'isYang': isYang,
        'text': text,
        'xiang': xiang,
        'interpretation': interpretation,
      };
}

/// 易经六十四卦详情模型
class HexagramDetail {
  /// 卦序：1 至 64（例如 1 代表乾为天）
  final int id;

  /// 卦名：例如「乾为天」、「水雷屯」
  final String name;

  /// 6 位二进制卦码：从初爻到上爻排列，'1' 代表阳爻，'0' 代表阴爻
  final String code;

  /// 上卦（外卦）：例如「乾」、「坎」
  final String upperTrigram;

  /// 下卦（内卦）：例如「乾」、「震」
  final String lowerTrigram;

  /// 五行属性：例如「金」、「木」、「水」、「火」、「土」
  final String element;

  /// 吉凶等第：例如「上上卦」、「上吉卦」、「中平卦」、「磨砺卦」、「潜修卦」
  final String fortuneTier;

  /// 等第总评描述：例如「大吉 · 万物亨通」
  final String fortuneDesc;

  /// 卦辞原文
  final String guaci;

  /// 彖传注解
  final String tuan;

  /// 大象传注解
  final String xiang;

  /// 现代人生总览
  final String personality;

  /// 东方人格画像
  final String overview;

  /// 事业与职场指引
  final String career;

  /// 财富与投资指引
  final String wealth;

  /// 情感与人际指引
  final String love;

  /// 五行养生与健康建议
  final String health;

  /// 处世哲学与行动锦囊
  final String advice;

  /// 六爻详细列表（从初爻至上爻共 6 条）
  final List<YaoDetail> yaos;

  const HexagramDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.upperTrigram,
    required this.lowerTrigram,
    required this.element,
    required this.fortuneTier,
    required this.fortuneDesc,
    required this.guaci,
    required this.tuan,
    required this.xiang,
    required this.overview,
    required this.personality,
    required this.career,
    required this.wealth,
    required this.love,
    required this.health,
    required this.advice,
    required this.yaos,
  });

  factory HexagramDetail.fromJson(Map<String, dynamic> json) {
    var yaosJson = json['yaos'] as List<dynamic>? ?? [];
    return HexagramDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      upperTrigram: json['upperTrigram'] as String,
      lowerTrigram: json['lowerTrigram'] as String,
      element: json['element'] as String,
      fortuneTier: json['fortuneTier'] as String? ?? '中平卦',
      fortuneDesc: json['fortuneDesc'] as String? ?? '中平 · 守正待时',
      guaci: json['guaci'] as String,
      tuan: json['tuan'] as String,
      xiang: json['xiang'] as String,
      overview: json['overview'] as String,
      personality: json['personality'] as String,
      career: json['career'] as String,
      wealth: json['wealth'] as String,
      love: json['love'] as String,
      health: json['health'] as String,
      advice: json['advice'] as String,
      yaos: yaosJson.map((e) => YaoDetail.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'upperTrigram': upperTrigram,
        'lowerTrigram': lowerTrigram,
        'element': element,
        'fortuneTier': fortuneTier,
        'fortuneDesc': fortuneDesc,
        'guaci': guaci,
        'tuan': tuan,
        'xiang': xiang,
        'overview': overview,
        'personality': personality,
        'career': career,
        'wealth': wealth,
        'love': love,
        'health': health,
        'advice': advice,
        'yaos': yaos.map((e) => e.toJson()).toList(),
      };
}

/// 生辰八字干支与纳音信息实体
class BaZiInfo {
  /// 年柱干支（例如「乙亥」）
  final String yearGanZhi;

  /// 月柱干支（例如「甲申」）
  final String monthGanZhi;

  /// 日柱干支（例如「丙午」）
  final String dayGanZhi;

  /// 时柱干支（例如「甲午」，未知时显示「时辰不详」）
  final String hourGanZhi;

  /// 年柱纳音五行（例如「山头火」）
  final String yearNaYin;

  /// 月柱纳音五行（例如「泉中水」）
  final String monthNaYin;

  /// 日柱纳音五行（例如「天河水」）
  final String dayNaYin;

  /// 时柱纳音五行（例如「沙中金」）
  final String hourNaYin;

  /// 公历日期字符串
  final String solarStr;

  /// 农历日期字符串
  final String lunarStr;

  /// 当前节气名称
  final String solarTerm;

  /// 是否已知时辰
  final bool isHourKnown;

  /// 八字五行个数统计（金、木、水、火、土）
  final Map<String, int> fiveElementsCount;

  /// 日元/日主天干（例如「丙」）
  final String dayMaster;

  /// 日元五行属性（例如「火」）
  final String dayMasterElement;

  const BaZiInfo({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.yearNaYin,
    required this.monthNaYin,
    required this.dayNaYin,
    required this.hourNaYin,
    required this.solarStr,
    required this.lunarStr,
    required this.solarTerm,
    required this.isHourKnown,
    required this.fiveElementsCount,
    required this.dayMaster,
    required this.dayMasterElement,
  });
}

/// 易经本命推算全息结果实体
class DivinationResult {
  /// 测算对象称谓
  final String name;

  /// 性别（乾造 ♂ / 坤造 ♀）
  final String gender;

  /// 公历出生日期
  final DateTime solarDate;

  /// 时辰序号
  final int hourIndex;

  /// 八字干支与纳音信息
  final BaZiInfo bazi;

  /// 本命主卦（大衍起卦所得之本卦）
  final HexagramDetail mainHexagram;

  /// 互卦（事物内部发展机理）
  final HexagramDetail mutualHexagram;

  /// 变卦（时辰已知且有动爻时的事态演进方向）
  final HexagramDetail? transformedHexagram;

  /// 错卦（站在对立面的思维镜像，全反转）
  final HexagramDetail oppositeHexagram;

  /// 综卦（换位思考的全局视角，上下翻转）
  final HexagramDetail inverseHexagram;

  /// 动爻爻位（1 至 6，若时辰未知则为 null）
  final int? changingYaoIndex;

  /// 动爻具体爻辞与解读
  final YaoDetail? changingYao;

  /// 当年流年流月对应之流年卦
  final HexagramDetail? yearlyHexagram;

  /// 排盘完备精度级别描述
  final String precisionLevel;

  /// 一句话人生主旋律概括
  final String summaryTitle;

  const DivinationResult({
    required this.name,
    required this.gender,
    required this.solarDate,
    required this.hourIndex,
    required this.bazi,
    required this.mainHexagram,
    required this.mutualHexagram,
    this.transformedHexagram,
    required this.oppositeHexagram,
    required this.inverseHexagram,
    this.changingYaoIndex,
    this.changingYao,
    this.yearlyHexagram,
    required this.precisionLevel,
    required this.summaryTitle,
  });
}
