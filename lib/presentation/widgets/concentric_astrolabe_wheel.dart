import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 专用于轮盘画布的即时手势竞争识别器（解决与外层页面上下滑动的竞技冲突）
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// 浑天同心多环罗盘环带层级枚举（由外至内排列）
enum AstrolabeRing {
  year,     // 第1圈：年份环（1920..2050）
  month,    // 第2圈：月份环（1..12）
  day,      // 第3圈：日期环（1..28/29/30/31）
  hour,     // 第4圈：时辰环（13个时段，含时辰未知）
  location, // 第5圈：经度/城市环（9大代表经度区域）
  gender,   // 第6圈：中心元神核心（乾造/坤造）
}

/// 浑天罗盘实时交互状态实体
class ConcentricAstrolabeState {
  final int year;
  final int month;
  final int day;
  final int hourIndex; // -1 表示未知，0..11 对应子时至亥时
  final bool isHourKnown;
  final int cityIndex;
  final String gender; // '乾 (男)' 或 '坤 (女)'

  DateTime get solarDate => DateTime(year, month, day);

  const ConcentricAstrolabeState({
    required this.year,
    required this.month,
    required this.day,
    required this.hourIndex,
    required this.isHourKnown,
    required this.cityIndex,
    required this.gender,
  });

  ConcentricAstrolabeState copyWith({
    int? year,
    int? month,
    int? day,
    int? hourIndex,
    bool? isHourKnown,
    int? cityIndex,
    String? gender,
  }) {
    return ConcentricAstrolabeState(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      hourIndex: hourIndex ?? this.hourIndex,
      isHourKnown: isHourKnown ?? this.isHourKnown,
      cityIndex: cityIndex ?? this.cityIndex,
      gender: gender ?? this.gender,
    );
  }
}

/// 浑天同心多环罗盘组件（支持全环 360° 顺时针递增滚动、中线固定读数视窗与无限循环）
class ConcentricAstrolabeWheel extends StatefulWidget {
  final ConcentricAstrolabeState initialState;
  final ValueChanged<ConcentricAstrolabeState> onChanged;
  final int minYear;
  final int maxYear;

  /// 代表性经度城市常量列表
  static const List<Map<String, dynamic>> cities = [
    {'name': '北京 (116.4°E)', 'short': '北京', 'lon': 116.4},
    {'name': '上海 (121.5°E)', 'short': '上海', 'lon': 121.5},
    {'name': '广深 (113.3°E)', 'short': '广深', 'lon': 113.3},
    {'name': '成渝 (104.1°E)', 'short': '成渝', 'lon': 104.1},
    {'name': '西安 (108.9°E)', 'short': '西安', 'lon': 108.9},
    {'name': '武汉 (114.3°E)', 'short': '武汉', 'lon': 114.3},
    {'name': '哈尔滨 (126.6°E)', 'short': '哈市', 'lon': 126.6},
    {'name': '乌市 (87.6°E)', 'short': '乌市', 'lon': 87.6},
    {'name': '台港 (121.5°E)', 'short': '台港', 'lon': 121.5},
  ];

  /// 十二时辰及未知时辰常量列表
  static const List<Map<String, dynamic>> shichens = [
    {'index': -1, 'branch': '未知', 'name': '未知', 'time': '不限'},
    {'index': 0, 'branch': '子', 'name': '子时', 'time': '23-01'},
    {'index': 1, 'branch': '丑', 'name': '丑时', 'time': '01-03'},
    {'index': 2, 'branch': '寅', 'name': '寅时', 'time': '03-05'},
    {'index': 3, 'branch': '卯', 'name': '卯时', 'time': '05-07'},
    {'index': 4, 'branch': '辰', 'name': '辰时', 'time': '07-09'},
    {'index': 5, 'branch': '巳', 'name': '巳时', 'time': '09-11'},
    {'index': 6, 'branch': '午', 'name': '午时', 'time': '11-13'},
    {'index': 7, 'branch': '未', 'name': '未时', 'time': '13-15'},
    {'index': 8, 'branch': '申', 'name': '申时', 'time': '15-17'},
    {'index': 9, 'branch': '酉', 'name': '酉时', 'time': '17-19'},
    {'index': 10, 'branch': '戌', 'name': '戌时', 'time': '19-21'},
    {'index': 11, 'branch': '亥', 'name': '亥时', 'time': '21-23'},
  ];

  const ConcentricAstrolabeWheel({
    super.key,
    required this.initialState,
    required this.onChanged,
    this.minYear = 1920,
    this.maxYear = 2050,
  });

  @override
  State<ConcentricAstrolabeWheel> createState() => _ConcentricAstrolabeWheelState();
}

class _ConcentricAstrolabeWheelState extends State<ConcentricAstrolabeWheel> {
  late ConcentricAstrolabeState _state;

  AstrolabeRing _activeRing = AstrolabeRing.year;
  double? _lastTouchAngle;
  double _accumulatedDelta = 0.0;

  /// 各同心环平滑旋转偏移角度映射表
  final Map<AstrolabeRing, double> _ringAngles = {
    AstrolabeRing.year: 0.0,
    AstrolabeRing.month: 0.0,
    AstrolabeRing.day: 0.0,
    AstrolabeRing.hour: 0.0,
    AstrolabeRing.location: 0.0,
    AstrolabeRing.gender: 0.0,
  };

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _correctDayIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ConcentricAstrolabeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialState != widget.initialState) {
      _state = widget.initialState;
      _correctDayIfNeeded();
    }
  }

  /// 获取指定年份与月份的最大天数
  int _maxDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) {
      return 30;
    }
    return 31;
  }

  /// 校验并纠正当前日期的合法性（例如闰年2月或小月月末自适应截断）
  void _correctDayIfNeeded() {
    final maxDays = _maxDaysInMonth(_state.year, _state.month);
    if (_state.day > maxDays) {
      _state = _state.copyWith(day: maxDays);
    } else if (_state.day < 1) {
      _state = _state.copyWith(day: 1);
    }
  }

  /// 根据触摸点距离罗盘中心的物理半径，识别当前触控的目标同心环
  AstrolabeRing _detectRingFromRadius(double r, double maxRadius) {
    final ratio = r / maxRadius;
    if (ratio < 0.22) {
      return AstrolabeRing.gender;
    } else if (ratio < 0.38) {
      return AstrolabeRing.location;
    } else if (ratio < 0.54) {
      return AstrolabeRing.hour;
    } else if (ratio < 0.70) {
      return AstrolabeRing.day;
    } else if (ratio < 0.85) {
      return AstrolabeRing.month;
    } else {
      return AstrolabeRing.year;
    }
  }

  /// 执行各环数值步进与无限循环滚动计算
  void _adjustRingValue(AstrolabeRing ring, int steps) {
    setState(() {
      switch (ring) {
        case AstrolabeRing.year:
          int totalYears = widget.maxYear - widget.minYear + 1; // 131 年
          int base = _state.year - widget.minYear;
          int newBase = ((base + steps) % totalYears + totalYears) % totalYears;
          int newYear = widget.minYear + newBase;
          _state = _state.copyWith(year: newYear);
          _correctDayIfNeeded();
          break;

        case AstrolabeRing.month:
          int base = _state.month - 1;
          int newBase = ((base + steps) % 12 + 12) % 12;
          int newMonth = newBase + 1;
          _state = _state.copyWith(month: newMonth);
          _correctDayIfNeeded();
          break;

        case AstrolabeRing.day:
          int maxDays = _maxDaysInMonth(_state.year, _state.month);
          int base = _state.day - 1;
          int newBase = ((base + steps) % maxDays + maxDays) % maxDays;
          int newDay = newBase + 1;
          _state = _state.copyWith(day: newDay);
          break;

        case AstrolabeRing.hour:
          int currentPos = _state.hourIndex + 1; // 0..12
          int newPos = ((currentPos + steps) % 13 + 13) % 13;
          int newHourIndex = newPos - 1;
          _state = _state.copyWith(
            hourIndex: newHourIndex,
            isHourKnown: newHourIndex >= 0,
          );
          break;

        case AstrolabeRing.location:
          int count = ConcentricAstrolabeWheel.cities.length;
          int newCity = ((_state.cityIndex + steps) % count + count) % count;
          _state = _state.copyWith(cityIndex: newCity);
          break;

        case AstrolabeRing.gender:
          String newGender = _state.gender.contains('男') ? '坤 (女)' : '乾 (男)';
          _state = _state.copyWith(gender: newGender);
          break;
      }
    });

    HapticFeedback.selectionClick();
    widget.onChanged(_state);
  }

  /// 触摸开始：锁定当前操作的同心环并初始化角度基准
  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touch = details.localPosition;
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;
    final r = math.sqrt(dx * dx + dy * dy);
    final maxRadius = size.width / 2;

    _activeRing = _detectRingFromRadius(r, maxRadius);
    _lastTouchAngle = math.atan2(dy, dx);
    _accumulatedDelta = 0.0;
    _ringAngles[_activeRing] = 0.0;

    // 若点击中心元神核，则直接触发乾坤性别切换
    if (_activeRing == AstrolabeRing.gender) {
      _adjustRingValue(AstrolabeRing.gender, 1);
    }
  }

  /// 触摸拖拽：计算角位移增量，驱动盘面旋转并触发刻度步进
  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_lastTouchAngle == null || _activeRing == AstrolabeRing.gender) return;

    final center = Offset(size.width / 2, size.height / 2);
    final touch = details.localPosition;
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;
    final newAngle = math.atan2(dy, dx);

    double delta = newAngle - _lastTouchAngle!;
    // 跨越 -pi 到 +pi 接缝的连续性归一化处理
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _lastTouchAngle = newAngle;
    _accumulatedDelta += delta;
    _ringAngles[_activeRing] = _accumulatedDelta;

    // 计算各环步进阈值（角度制转动间隔）
    double threshold;
    switch (_activeRing) {
      case AstrolabeRing.year:
        threshold = 2 * math.pi / 24; // 15度/年
        break;
      case AstrolabeRing.month:
        threshold = 2 * math.pi / 12; // 30度/月
        break;
      case AstrolabeRing.day:
        threshold = 2 * math.pi / _maxDaysInMonth(_state.year, _state.month);
        break;
      case AstrolabeRing.hour:
        threshold = 2 * math.pi / 13;
        break;
      case AstrolabeRing.location:
        threshold = 2 * math.pi / 9; // 40度/城市
        break;
      case AstrolabeRing.gender:
        threshold = 0.35;
        break;
    }

    if (_accumulatedDelta.abs() >= threshold) {
      int steps = (_accumulatedDelta / threshold).truncate();
      _accumulatedDelta -= steps * threshold;
      _ringAngles[_activeRing] = _accumulatedDelta;
      _adjustRingValue(_activeRing, steps);
    } else {
      setState(() {});
    }
  }

  /// 触摸结束：释放拖拽状态并复位角度增量
  void _onPanEnd(DragEndDetails details) {
    _lastTouchAngle = null;
    _accumulatedDelta = 0.0;
    _ringAngles[_activeRing] = 0.0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final wheelDiameter = availableWidth.clamp(280.0, 330.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 浑天多环同心罗盘主画布
            Center(
              child: SizedBox(
                width: wheelDiameter,
                height: wheelDiameter,
                child: RawGestureDetector(
                  key: const Key('concentric_astrolabe_gesture'),
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
                      () => _EagerPanGestureRecognizer(),
                      (_EagerPanGestureRecognizer instance) {
                        instance.onStart = (d) {
                          _onPanStart(d, Size(wheelDiameter, wheelDiameter));
                        };
                        instance.onUpdate = (d) {
                          _onPanUpdate(d, Size(wheelDiameter, wheelDiameter));
                        };
                        instance.onEnd = _onPanEnd;
                      },
                    ),
                  },
                  child: CustomPaint(
                    size: Size(wheelDiameter, wheelDiameter),
                    painter: _ConcentricAstrolabePainter(
                      state: _state,
                      activeRing: _activeRing,
                      ringAngles: _ringAngles,
                      maxDays: _maxDaysInMonth(_state.year, _state.month),
                      minYear: widget.minYear,
                      maxYear: widget.maxYear,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 底部操作指引提示（精致极简排版）
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '顺时针转动值增大 · 顶部中线固定当前选定值 · 循环滚动',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMutedDark,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 浑天同心五环多层罗盘 Canvas 自定义绘制器
class _ConcentricAstrolabePainter extends CustomPainter {
  final ConcentricAstrolabeState state;
  final AstrolabeRing activeRing;
  final Map<AstrolabeRing, double> ringAngles;
  final int maxDays;
  final int minYear;
  final int maxYear;
  final bool isDark;

  _ConcentricAstrolabePainter({
    required this.state,
    required this.activeRing,
    required this.ringAngles,
    required this.maxDays,
    required this.minYear,
    required this.maxYear,
    required this.isDark,
  });

  Color get _surfaceCharcoal => isDark ? AppTheme.surfaceCharcoal : AppTheme.lightSurfaceCharcoal;
  Color get _surfaceCard => isDark ? AppTheme.surfaceCard : AppTheme.lightSurfaceCard;
  Color get _surfaceBorder => isDark ? AppTheme.surfaceBorder : AppTheme.lightSurfaceBorder;
  Color get _textPaperWhite => isDark ? AppTheme.textPaperWhite : AppTheme.lightTextPrimary;
  Color get _textMistGrey => isDark ? AppTheme.textMistGrey : AppTheme.lightTextSecondary;
  Color get _textMutedDark => isDark ? AppTheme.textMutedDark : AppTheme.lightTextMuted;
  Color get _imperialGold => isDark ? AppTheme.imperialGold : AppTheme.lightImperialGold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 3;

    // 各同心环半径划分（由外至内：年份 -> 月份 -> 日期 -> 时辰 -> 经度 -> 性别元神核）
    final rYear = maxRadius;
    final rMonth = maxRadius * 0.85;
    final rDay = maxRadius * 0.70;
    final rHour = maxRadius * 0.54;
    final rLocation = maxRadius * 0.38;
    final rGender = maxRadius * 0.22;

    final midRYear = (rYear + rMonth) / 2;
    final midRMonth = (rMonth + rDay) / 2;
    final midRDay = (rDay + rHour) / 2;
    final midRHour = (rHour + rLocation) / 2;
    final midRLocation = (rLocation + rGender) / 2;

    // 1. 绘制底层罗盘基座圆盘
    final bgPaint = Paint()..color = _surfaceCharcoal;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // 2. 绘制各同心环环带（由外向内渲染）
    _drawRingBand(canvas, center, rMonth, rYear, AstrolabeRing.year);
    _drawRingBand(canvas, center, rDay, rMonth, AstrolabeRing.month);
    _drawRingBand(canvas, center, rHour, rDay, AstrolabeRing.day);
    _drawRingBand(canvas, center, rLocation, rHour, AstrolabeRing.hour);
    _drawRingBand(canvas, center, rGender, rLocation, AstrolabeRing.location);

    // 3. 绘制各同心环精密分度刻度线
    _drawTicks(canvas, center, rYear, rMonth, 24, ringAngles[AstrolabeRing.year] ?? 0.0, AstrolabeRing.year);
    _drawTicks(canvas, center, rMonth, rDay, 12, ringAngles[AstrolabeRing.month] ?? 0.0, AstrolabeRing.month);
    _drawTicks(canvas, center, rDay, rHour, maxDays, ringAngles[AstrolabeRing.day] ?? 0.0, AstrolabeRing.day);
    _drawTicks(canvas, center, rHour, rLocation, 13, ringAngles[AstrolabeRing.hour] ?? 0.0, AstrolabeRing.hour);
    _drawTicks(canvas, center, rLocation, rGender, 9, ringAngles[AstrolabeRing.location] ?? 0.0, AstrolabeRing.location);

    // 4. 绘制环周旋转次要刻度数值
    _drawYearLabels(canvas, center, midRYear);
    _drawMonthLabels(canvas, center, midRMonth);
    _drawDayLabels(canvas, center, midRDay);
    _drawHourLabels(canvas, center, midRHour);
    _drawLocationLabels(canvas, center, midRLocation);

    // 5. 绘制顶部 12 点钟中线位置永久锚定的金色高亮选定值徽章
    _drawFixedMidlineSelectedLabel(canvas, center, midRYear, '${state.year}年', AstrolabeRing.year, fontSize: 10.2);
    _drawFixedMidlineSelectedLabel(canvas, center, midRMonth, '${state.month}月', AstrolabeRing.month, fontSize: 10.2);
    _drawFixedMidlineSelectedLabel(canvas, center, midRDay, '${state.day}日', AstrolabeRing.day, fontSize: 10.2);
    _drawFixedMidlineSelectedLabel(
      canvas,
      center,
      midRHour,
      state.hourIndex == -1 ? '未知' : '${ConcentricAstrolabeWheel.shichens[state.hourIndex + 1]['branch']}时',
      AstrolabeRing.hour,
      fontSize: 9.8,
    );
    _drawFixedMidlineSelectedLabel(
      canvas,
      center,
      midRLocation,
      ConcentricAstrolabeWheel.cities[state.cityIndex]['short'],
      AstrolabeRing.location,
      fontSize: 9.8,
    );

    // 6. 绘制中心元神核心（乾坤太极阴阳核）
    final genderActive = activeRing == AstrolabeRing.gender;
    final corePaint = Paint()
      ..color = genderActive
          ? _imperialGold.withValues(alpha: 0.30)
          : _surfaceCard
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rGender, corePaint);

    final coreBorder = Paint()
      ..color = _imperialGold
      ..strokeWidth = genderActive ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, rGender, coreBorder);

    // 绘制中心性别文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: state.gender.contains('男') ? '乾造\n阳' : '坤造\n阴',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: _imperialGold,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  /// 绘制环带背景底色与同心金边
  void _drawRingBand(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    AstrolabeRing ring,
  ) {
    final bool isActive = activeRing == ring;

    final bandPaint = Paint()
      ..color = isActive
          ? _imperialGold.withValues(alpha: 0.18)
          : ((ring.index % 2 == 0)
              ? _surfaceCard
              : _surfaceCard.withValues(alpha: isDark ? 0.7 : 0.85))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR))
      ..addOval(Rect.fromCircle(center: center, radius: innerR))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bandPaint);

    final borderPaint = Paint()
      ..color = isActive
          ? _imperialGold.withValues(alpha: 0.85)
          : _surfaceBorder
      ..strokeWidth = isActive ? 1.8 : 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerR, borderPaint);
    canvas.drawCircle(center, innerR, borderPaint);
  }

  /// 绘制环带上的分度细刻度线
  void _drawTicks(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    int count,
    double rotationAngle,
    AstrolabeRing ring,
  ) {
    final bool isActive = activeRing == ring;
    final tickLength = (outerR - innerR) * (isActive ? 0.35 : 0.25);

    for (int i = 0; i < count; i++) {
      double angle = (2 * math.pi / count) * i + rotationAngle - (math.pi / 2);

      final tickOuter = Offset(
        center.dx + (outerR - 1) * math.cos(angle),
        center.dy + (outerR - 1) * math.sin(angle),
      );
      final tickInner = Offset(
        center.dx + (outerR - 1 - tickLength) * math.cos(angle),
        center.dy + (outerR - 1 - tickLength) * math.sin(angle),
      );

      final isMajor = i % (count > 12 ? 3 : 1) == 0;
      final tickPaint = Paint()
        ..color = isMajor
            ? (isActive ? _imperialGold : _imperialGold.withValues(alpha: 0.5))
            : (isActive ? _imperialGold.withValues(alpha: 0.3) : _textMutedDark.withValues(alpha: 0.4))
        ..strokeWidth = isMajor ? (isActive ? 1.5 : 1.0) : 0.6;

      canvas.drawLine(tickOuter, tickInner, tickPaint);
    }
  }

  /// 绘制顶部 12 点钟中线固定读数金框与金色加粗选定值
  void _drawFixedMidlineSelectedLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    AstrolabeRing ring, {
    double fontSize = 10.2,
  }) {
    final bool isActive = activeRing == ring;
    final pos = Offset(center.dx, center.dy - radius);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _imperialGold,
          letterSpacing: 0.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + 10,
      height: textPainter.height + 4,
    );

    // 半透明金芒底托背景
    final bgPaint = Paint()
      ..color = isActive
          ? _imperialGold.withValues(alpha: 0.28)
          : _surfaceCharcoal.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)), bgPaint);

    // 激活状态金色微光边框
    final borderPaint = Paint()
      ..color = isActive ? _imperialGold : _imperialGold.withValues(alpha: 0.5)
      ..strokeWidth = isActive ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)), borderPaint);

    // 绘制金色文字
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  /// 在指定圆周角位置绘制切向对齐文字
  void _drawLabelAtAngle(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text, {
    required bool isRingActive,
    double fontSize = 8.0,
  }) {
    canvas.save();
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    canvas.translate(x, y);

    // 沿圆周切线旋转文字
    double textRotation = angle + math.pi / 2;
    if (angle > 0 && angle < math.pi) {
      textRotation += math.pi;
    }
    canvas.rotate(textRotation);

    final color = isRingActive
        ? _textPaperWhite
        : _textMistGrey.withValues(alpha: 0.75);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  // --- 第 1 圈：年份环（1920..2050，360° 均匀闭合排布） ---
  void _drawYearLabels(Canvas canvas, Offset center, double radius) {
    const totalSlots = 24;
    final angleStep = (2 * math.pi) / totalSlots;
    final isRingActive = activeRing == AstrolabeRing.year;
    final angleOffset = ringAngles[AstrolabeRing.year] ?? 0.0;
    final totalYears = maxYear - minYear + 1;

    for (int k = 1; k < totalSlots; k++) {
      double angle = -math.pi / 2 + k * angleStep + angleOffset;

      double distToMid = (angle - (-math.pi / 2)).abs();
      while (distToMid > math.pi) {
        distToMid = (distToMid - 2 * math.pi).abs();
      }
      if (distToMid < angleStep * 0.45) continue;

      final base = state.year - minYear;
      final year = minYear + (((base - k) % totalYears + totalYears) % totalYears);
      String text = "'${(year % 100).toString().padLeft(2, '0')}";

      _drawLabelAtAngle(
        canvas,
        center,
        radius,
        angle,
        text,
        isRingActive: isRingActive,
        fontSize: 7.8,
      );
    }
  }

  // --- 第 2 圈：月份环（1..12月，360° 均匀闭合排布） ---
  void _drawMonthLabels(Canvas canvas, Offset center, double radius) {
    final angleStep = (2 * math.pi) / 12;
    final isRingActive = activeRing == AstrolabeRing.month;
    final angleOffset = ringAngles[AstrolabeRing.month] ?? 0.0;

    for (int k = 1; k < 12; k++) {
      double angle = -math.pi / 2 + k * angleStep + angleOffset;

      double distToMid = (angle - (-math.pi / 2)).abs();
      while (distToMid > math.pi) {
        distToMid = (distToMid - 2 * math.pi).abs();
      }
      if (distToMid < angleStep * 0.45) continue;

      final base = state.month - 1;
      final month = 1 + (((base - k) % 12 + 12) % 12);
      String text = '$month月';

      _drawLabelAtAngle(
        canvas,
        center,
        radius,
        angle,
        text,
        isRingActive: isRingActive,
        fontSize: 7.8,
      );
    }
  }

  // --- 第 3 圈：日期环（1..maxDays，360° 均匀闭合排布） ---
  void _drawDayLabels(Canvas canvas, Offset center, double radius) {
    final angleStep = (2 * math.pi) / maxDays;
    final isRingActive = activeRing == AstrolabeRing.day;
    final angleOffset = ringAngles[AstrolabeRing.day] ?? 0.0;

    for (int k = 1; k < maxDays; k++) {
      double angle = -math.pi / 2 + k * angleStep + angleOffset;

      double distToMid = (angle - (-math.pi / 2)).abs();
      while (distToMid > math.pi) {
        distToMid = (distToMid - 2 * math.pi).abs();
      }
      if (distToMid < angleStep * 0.45) continue;

      final base = state.day - 1;
      final day = 1 + (((base - k) % maxDays + maxDays) % maxDays);
      String text = '$day';

      _drawLabelAtAngle(
        canvas,
        center,
        radius,
        angle,
        text,
        isRingActive: isRingActive,
        fontSize: 7.8,
      );
    }
  }

  // --- 第 4 圈：时辰环（13 个位置，360° 均匀闭合排布） ---
  void _drawHourLabels(Canvas canvas, Offset center, double radius) {
    final angleStep = (2 * math.pi) / 13;
    final isRingActive = activeRing == AstrolabeRing.hour;
    final angleOffset = ringAngles[AstrolabeRing.hour] ?? 0.0;
    final currentPos = state.hourIndex + 1; // 0..12

    for (int k = 1; k < 13; k++) {
      double angle = -math.pi / 2 + k * angleStep + angleOffset;

      double distToMid = (angle - (-math.pi / 2)).abs();
      while (distToMid > math.pi) {
        distToMid = (distToMid - 2 * math.pi).abs();
      }
      if (distToMid < angleStep * 0.45) continue;

      final pos = (((currentPos - k) % 13 + 13) % 13);
      String text = ConcentricAstrolabeWheel.shichens[pos]['name'] as String;

      _drawLabelAtAngle(
        canvas,
        center,
        radius,
        angle,
        text,
        isRingActive: isRingActive,
        fontSize: 7.6,
      );
    }
  }

  // --- 第 5 圈：经度/城市环（9 个代表城市，360° 均匀闭合排布） ---
  void _drawLocationLabels(Canvas canvas, Offset center, double radius) {
    final angleStep = (2 * math.pi) / 9;
    final isRingActive = activeRing == AstrolabeRing.location;
    final angleOffset = ringAngles[AstrolabeRing.location] ?? 0.0;

    for (int k = 1; k < 9; k++) {
      double angle = -math.pi / 2 + k * angleStep + angleOffset;

      double distToMid = (angle - (-math.pi / 2)).abs();
      while (distToMid > math.pi) {
        distToMid = (distToMid - 2 * math.pi).abs();
      }
      if (distToMid < angleStep * 0.45) continue;

      final cityIdx = (((state.cityIndex - k) % 9 + 9) % 9);
      String text = ConcentricAstrolabeWheel.cities[cityIdx]['short'] as String;

      _drawLabelAtAngle(
        canvas,
        center,
        radius,
        angle,
        text,
        isRingActive: isRingActive,
        fontSize: 7.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricAstrolabePainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.activeRing != activeRing ||
        oldDelegate.ringAngles != ringAngles ||
        oldDelegate.maxDays != maxDays;
  }
}
