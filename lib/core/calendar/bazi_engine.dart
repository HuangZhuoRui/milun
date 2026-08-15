import 'package:lunar/lunar.dart';
import '../../data/models/hexagram_detail.dart';

/// 八字排盘与五行计算引擎
class BaZiEngine {
  /// 十天干五行映射
  static const Map<String, String> _ganWuXing = {
    '甲': '木', '乙': '木',
    '丙': '火', '丁': '火',
    '戊': '土', '己': '土',
    '庚': '金', '辛': '金',
    '壬': '水', '癸': '水',
  };

  /// 十二地支五行映射
  static const Map<String, String> _zhiWuXing = {
    '子': '水', '丑': '土', '寅': '木', '卯': '木',
    '辰': '土', '巳': '火', '午': '火', '未': '土',
    '申': '金', '酉': '金', '戌': '土', '亥': '水',
  };

  /// 十二地支基础列表
  static const List<String> earthlyBranches = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
  ];

  /// 纯粹时辰名称列表
  static const List<String> pureShichenNames = [
    '子时', '丑时', '寅时', '卯时', '辰时', '巳时',
    '午时', '未时', '申时', '酉时', '戌时', '亥时'
  ];

  /// 十二时辰标准列表（包含对应公历时间区间）
  static const List<String> shichenNames = [
    '子时 (23:00-01:00)',
    '丑时 (01:00-03:00)',
    '寅时 (03:00-05:00)',
    '卯时 (05:00-07:00)',
    '辰时 (07:00-09:00)',
    '巳时 (09:00-11:00)',
    '午时 (11:00-13:00)',
    '未时 (13:00-15:00)',
    '申时 (15:00-17:00)',
    '酉时 (17:00-19:00)',
    '戌时 (19:00-21:00)',
    '亥时 (21:00-23:00)',
  ];

  /// 各时辰代表公历小时基准
  static const List<int> shichenHours = [
    0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
  ];

  /// 根据公历出生日期、时辰以及出生地经度，综合计算四柱八字、纳音与五行统计
  static BaZiInfo calculate({
    required DateTime solarDate,
    required int hourIndex, // 0..11 对应子时至亥时，-1 表示时辰未知
    required bool isHourKnown,
    double? longitude, // 出生地地理经度，用于真太阳时精准校准（例如北京为 116.4）
  }) {
    int hour = 12; // 时辰未知时默认采用正午（平气平中）
    int minute = 0;

    if (isHourKnown && hourIndex >= 0 && hourIndex < 12) {
      hour = shichenHours[hourIndex];
    }

    // 真太阳时校正算法：以东经 120° 为标准平太阳时基准，每偏离 1 度相差 4 分钟
    if (longitude != null) {
      double diffMinutes = (longitude - 120.0) * 4;
      int totalMinutes = hour * 60 + minute + diffMinutes.round();
      if (totalMinutes < 0) totalMinutes += 1440;
      totalMinutes = totalMinutes % 1440;
      hour = totalMinutes ~/ 60;
      minute = totalMinutes % 60;
    }

    Solar solar = Solar.fromYmdHms(
      solarDate.year,
      solarDate.month,
      solarDate.day,
      hour,
      minute,
      0,
    );
    Lunar lunar = solar.getLunar();
    EightChar eightChar = lunar.getEightChar();

    String yearGZ = eightChar.getYear();
    String monthGZ = eightChar.getMonth();
    String dayGZ = eightChar.getDay();
    String hourGZ = isHourKnown ? eightChar.getTime() : '未知';

    String yearNY = eightChar.getYearNaYin();
    String monthNY = eightChar.getMonthNaYin();
    String dayNY = eightChar.getDayNaYin();
    String hourNY = isHourKnown ? eightChar.getTimeNaYin() : '未知';

    String dayMaster = dayGZ.isNotEmpty ? dayGZ.substring(0, 1) : '甲';
    String dayMasterElem = _ganWuXing[dayMaster] ?? '木';

    // 统计全局五行个数分布
    Map<String, int> wuxing = {'金': 0, '木': 0, '水': 0, '火': 0, '土': 0};
    void countElem(String char, Map<String, String> map) {
      if (map.containsKey(char)) {
        String elem = map[char]!;
        wuxing[elem] = (wuxing[elem] ?? 0) + 1;
      }
    }

    if (yearGZ.length >= 2) {
      countElem(yearGZ[0], _ganWuXing);
      countElem(yearGZ[1], _zhiWuXing);
    }
    if (monthGZ.length >= 2) {
      countElem(monthGZ[0], _ganWuXing);
      countElem(monthGZ[1], _zhiWuXing);
    }
    if (dayGZ.length >= 2) {
      countElem(dayGZ[0], _ganWuXing);
      countElem(dayGZ[1], _zhiWuXing);
    }
    if (isHourKnown && hourGZ.length >= 2 && hourGZ != '未知') {
      countElem(hourGZ[0], _ganWuXing);
      countElem(hourGZ[1], _zhiWuXing);
    }

    // 节气计算
    String jieqi = lunar.getJieQi();
    if (jieqi.isEmpty) {
      jieqi = lunar.getPrevJieQi().getName();
    }

    String solarStr = '${solar.getYear()}年${solar.getMonth()}月${solar.getDay()}日';
    String lunarStr = '${lunar.getYearInChinese()}年 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';

    return BaZiInfo(
      yearGanZhi: yearGZ,
      monthGanZhi: monthGZ,
      dayGanZhi: dayGZ,
      hourGanZhi: hourGZ,
      yearNaYin: yearNY,
      monthNaYin: monthNY,
      dayNaYin: dayNY,
      hourNaYin: hourNY,
      solarStr: solarStr,
      lunarStr: lunarStr,
      solarTerm: jieqi,
      isHourKnown: isHourKnown,
      fiveElementsCount: wuxing,
      dayMaster: dayMaster,
      dayMasterElement: dayMasterElem,
    );
  }
}
