import 'hexagram_detail.dart';

/// 本命专属每日流日运势演化推算结果数据模型
class DailyHexagramResult {
  /// 命主姓名 / 称谓
  final String profileName;

  /// 命主出生公历日期
  final DateTime birthDate;

  /// 命主出生时辰序号（-1 表示时辰不详）
  final int birthHourIndex;

  /// 命主先天本命主卦
  final HexagramDetail birthMainHexagram;

  /// 命主日元本命五行（金木水火土）
  final String dayMasterElement;

  /// 查询的目标流日公历日期
  final DateTime solarDate;

  /// 目标流日农历全称（如：丙午年 丙申月 辛酉日 · 农历七月初三）
  final String lunarString;

  /// 农历流日年月日干支
  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;

  /// 今日二十四节气
  final String solarTerm;

  /// 本命与今日天时交感得出的【今日专属流日卦】
  final HexagramDetail todayNatalHexagram;

  /// 今日关键破局动爻（1..6）
  final int changingYaoIndex;

  /// 今日动爻详情
  final YaoDetail? changingYao;

  /// 今日后天演变变卦（趋向卦）
  final HexagramDetail transformedHexagram;

  /// 今日综合运势评分（60..98）
  final int fortuneScore;

  /// 今日运势等第评述（如：大吉 · 贵人扶持）
  final String fortuneLevel;

  /// 五维分项运势指数（事功求谋、财富运筹、情感人际、身心状态）
  final Map<String, int> fortuneAspects;

  /// 先天体卦与今日客卦的生克义理分析
  final String energyRelation;

  /// 今日宜（3~5 项行动建议）
  final List<String> yiList;

  /// 今日忌（3~4 项防范提示）
  final List<String> jiList;

  /// 今日事功与职场决策指南
  final String careerGuidance;

  /// 今日求财与投资运筹指南
  final String wealthGuidance;

  /// 今日心境情志与身心调和指南
  final String mindGuidance;

  /// 今日《周易》原典专属箴言
  final String dailyQuote;

  const DailyHexagramResult({
    required this.profileName,
    required this.birthDate,
    required this.birthHourIndex,
    required this.birthMainHexagram,
    required this.dayMasterElement,
    required this.solarDate,
    required this.lunarString,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.solarTerm,
    required this.todayNatalHexagram,
    required this.changingYaoIndex,
    required this.changingYao,
    required this.transformedHexagram,
    required this.fortuneScore,
    required this.fortuneLevel,
    required this.fortuneAspects,
    required this.energyRelation,
    required this.yiList,
    required this.jiList,
    required this.careerGuidance,
    required this.wealthGuidance,
    required this.mindGuidance,
    required this.dailyQuote,
  });
}
