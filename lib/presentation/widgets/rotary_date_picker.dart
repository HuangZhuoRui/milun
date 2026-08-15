import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum RotaryDateStep {
  year,
  month,
  day,
  hour,
}

class RotaryDateTimeResult {
  final DateTime date;
  final int hourIndex; // 0..11 for 子..亥, or -1 if unknown
  final bool isHourKnown;

  const RotaryDateTimeResult({
    required this.date,
    required this.hourIndex,
    required this.isHourKnown,
  });
}

class RotaryDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final int initialHourIndex;
  final bool initialIsHourKnown;
  final int minYear;
  final int maxYear;

  const RotaryDatePickerDialog({
    super.key,
    required this.initialDate,
    this.initialHourIndex = 6, // 午时
    this.initialIsHourKnown = true,
    this.minYear = 1920,
    this.maxYear = 2050,
  });

  static Future<RotaryDateTimeResult?> show(
    BuildContext context, {
    required DateTime initialDate,
    int initialHourIndex = 6,
    bool initialIsHourKnown = true,
    int minYear = 1920,
    int maxYear = 2050,
  }) {
    return showModalBottomSheet<RotaryDateTimeResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => RotaryDatePickerDialog(
        initialDate: initialDate,
        initialHourIndex: initialHourIndex,
        initialIsHourKnown: initialIsHourKnown,
        minYear: minYear,
        maxYear: maxYear,
      ),
    );
  }

  @override
  State<RotaryDatePickerDialog> createState() => _RotaryDatePickerDialogState();
}

class _RotaryDatePickerDialogState extends State<RotaryDatePickerDialog>
    with SingleTickerProviderStateMixin {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHourIndex; // -1 for unknown, 0..11 for 子..亥

  RotaryDateStep _currentStep = RotaryDateStep.year;
  bool _yearConfirmed = false;
  bool _monthConfirmed = false;
  bool _dayConfirmed = false;

  // 当前选择步骤的旋转状态与增量累加器
  double _currentAngle = 0.0;
  double? _lastTouchAngle;
  double _accumulatedDelta = 0.0;

  static const List<Map<String, dynamic>> _shichenList = [
    {'index': -1, 'branch': '未知', 'name': '时辰不详', 'time': '不限具体时间', 'desc': '按年月日排先天元神盘'},
    {'index': 0, 'branch': '子', 'name': '子时', 'time': '23:00 - 01:00', 'desc': '夜半 · 灵动智谋'},
    {'index': 1, 'branch': '丑', 'name': '丑时', 'time': '01:00 - 03:00', 'desc': '鸡鸣 · 坚毅沉稳'},
    {'index': 2, 'branch': '寅', 'name': '寅时', 'time': '03:00 - 05:00', 'desc': '平旦 · 开拓进取'},
    {'index': 3, 'branch': '卯', 'name': '卯时', 'time': '05:00 - 07:00', 'desc': '日出 · 温润雅致'},
    {'index': 4, 'branch': '辰', 'name': '辰时', 'time': '07:00 - 09:00', 'desc': '食时 · 宏达远见'},
    {'index': 5, 'branch': '巳', 'name': '巳时', 'time': '09:00 - 11:00', 'desc': '隅中 · 洞察敏锐'},
    {'index': 6, 'branch': '午', 'name': '午时', 'time': '11:00 - 13:00', 'desc': '日中 · 热情旷达'},
    {'index': 7, 'branch': '未', 'name': '未时', 'time': '13:00 - 15:00', 'desc': '日昳 · 细腻体贴'},
    {'index': 8, 'branch': '申', 'name': '申时', 'time': '15:00 - 17:00', 'desc': '哺时 · 敏捷精明'},
    {'index': 9, 'branch': '酉', 'name': '酉时', 'time': '17:00 - 19:00', 'desc': '日入 · 审美严谨'},
    {'index': 10, 'branch': '戌', 'name': '戌时', 'time': '19:00 - 21:00', 'desc': '黄昏 · 忠诚笃定'},
    {'index': 11, 'branch': '亥', 'name': '亥时', 'time': '21:00 - 23:00', 'desc': '人定 · 豁达从容'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
    _selectedHourIndex = widget.initialIsHourKnown ? widget.initialHourIndex : -1;
  }

  int _maxDaysInMonth(int year, int month) {
    if (month == 2) {
      bool isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  void _adjustValue(int steps) {
    if (steps == 0) return;
    HapticFeedback.selectionClick();

    setState(() {
      switch (_currentStep) {
        case RotaryDateStep.year:
          int newYear = (_selectedYear + steps).clamp(widget.minYear, widget.maxYear);
          _selectedYear = newYear;
          int maxD = _maxDaysInMonth(_selectedYear, _selectedMonth);
          if (_selectedDay > maxD) _selectedDay = maxD;
          break;
        case RotaryDateStep.month:
          int newMonth = _selectedMonth + steps;
          while (newMonth < 1) {
            newMonth += 12;
          }
          while (newMonth > 12) {
            newMonth -= 12;
          }
          _selectedMonth = newMonth;
          int maxD = _maxDaysInMonth(_selectedYear, _selectedMonth);
          if (_selectedDay > maxD) _selectedDay = maxD;
          break;
        case RotaryDateStep.day:
          int maxD = _maxDaysInMonth(_selectedYear, _selectedMonth);
          int newDay = _selectedDay + steps;
          while (newDay < 1) {
            newDay += maxD;
          }
          while (newDay > maxD) {
            newDay -= maxD;
          }
          _selectedDay = newDay;
          break;
        case RotaryDateStep.hour:
          // _selectedHourIndex 为 -1..11，共13个状态（映射到 0..12）
          int currentPos = _selectedHourIndex + 1; // 0..12
          int newPos = (currentPos + steps) % 13;
          if (newPos < 0) newPos += 13;
          _selectedHourIndex = newPos - 1;
          break;
      }
    });
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPos = details.localPosition;
    _lastTouchAngle = math.atan2(touchPos.dy - center.dy, touchPos.dx - center.dx);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPos = details.localPosition;
    final currentTouchAngle = math.atan2(touchPos.dy - center.dy, touchPos.dx - center.dx);

    if (_lastTouchAngle == null) {
      _lastTouchAngle = currentTouchAngle;
      return;
    }

    double delta = currentTouchAngle - _lastTouchAngle!;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _lastTouchAngle = currentTouchAngle;
    _accumulatedDelta += delta;
    _currentAngle += delta;

    double stepThreshold = _currentStep == RotaryDateStep.month
        ? 0.26
        : (_currentStep == RotaryDateStep.day
            ? 0.16
            : (_currentStep == RotaryDateStep.hour ? 0.24 : 0.12));

    if (_accumulatedDelta.abs() >= stepThreshold) {
      int steps = (_accumulatedDelta / stepThreshold).truncate();
      _accumulatedDelta -= steps * stepThreshold;
      _adjustValue(steps);
    } else {
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastTouchAngle = null;
    _accumulatedDelta = 0.0;
  }

  void _onStepTap(RotaryDateStep step) {
    if (step == RotaryDateStep.month && !_yearConfirmed) return;
    if (step == RotaryDateStep.day && (!_yearConfirmed || !_monthConfirmed)) return;
    if (step == RotaryDateStep.hour && (!_yearConfirmed || !_monthConfirmed || !_dayConfirmed)) return;
    setState(() {
      _currentStep = step;
    });
  }

  void _onNextOrConfirm() {
    if (_currentStep == RotaryDateStep.year) {
      setState(() {
        _yearConfirmed = true;
        _currentStep = RotaryDateStep.month;
      });
    } else if (_currentStep == RotaryDateStep.month) {
      setState(() {
        _monthConfirmed = true;
        _currentStep = RotaryDateStep.day;
      });
    } else if (_currentStep == RotaryDateStep.day) {
      setState(() {
        _dayConfirmed = true;
        _currentStep = RotaryDateStep.hour;
      });
    } else {
      // 4步全部选定完成！
      final finalDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
      final result = RotaryDateTimeResult(
        date: finalDate,
        hourIndex: _selectedHourIndex >= 0 ? _selectedHourIndex : -1,
        isHourKnown: _selectedHourIndex >= 0,
      );
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _maxDaysInMonth(_selectedYear, _selectedMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);

    return Container(
      decoration: BoxDecoration(
        color: charcoal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽手柄
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getTextMuted(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 顶部标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '天象罗盘 · 生辰日晷轮盘',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '顺时针转动增加，逆时针转动减少 · 正上方中轴为选中值',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4-Step Breadcrumbs Progression Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.getSubtleShadow(context),
            ),
            child: Row(
              children: [
                _buildStepTab(
                  step: RotaryDateStep.year,
                  title: '$_selectedYear 年',
                  subtitle: '选年',
                  isActive: _currentStep == RotaryDateStep.year,
                  isCompleted: _yearConfirmed,
                  isLocked: false,
                ),
                _buildStepTab(
                  step: RotaryDateStep.month,
                  title: '$_selectedMonth 月',
                  subtitle: '选月',
                  isActive: _currentStep == RotaryDateStep.month,
                  isCompleted: _monthConfirmed,
                  isLocked: !_yearConfirmed,
                ),
                _buildStepTab(
                  step: RotaryDateStep.day,
                  title: '$_selectedDay 日',
                  subtitle: '选日',
                  isActive: _currentStep == RotaryDateStep.day,
                  isCompleted: _dayConfirmed,
                  isLocked: !_yearConfirmed || !_monthConfirmed,
                ),
                _buildStepTab(
                  step: RotaryDateStep.hour,
                  title: _selectedHourIndex == -1
                      ? '时辰未知'
                      : '${_shichenList[_selectedHourIndex + 1]['branch']}时',
                  subtitle: '选时(可选)',
                  isActive: _currentStep == RotaryDateStep.hour,
                  isCompleted: false,
                  isLocked: !_yearConfirmed || !_monthConfirmed || !_dayConfirmed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 纯粹浑天罗盘转盘交互区
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxAvailable = constraints.maxWidth;
              final double wheelSize = maxAvailable.clamp(180.0, 240.0);
              final double centerHubSize = (wheelSize * 0.50).clamp(90.0, 120.0);

              return Center(
                child: SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: GestureDetector(
                    key: const Key('rotary_wheel_gesture'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onPanStart(d, Size(wheelSize, wheelSize)),
                    onPanUpdate: (d) => _onPanUpdate(d, Size(wheelSize, wheelSize)),
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: Size(wheelSize, wheelSize),
                      painter: _RotaryWheelPainter(
                        step: _currentStep,
                        currentYear: _selectedYear,
                        currentMonth: _selectedMonth,
                        currentDay: _selectedDay,
                        currentHourPos: _selectedHourIndex + 1,
                        maxDays: maxDays,
                        rotationAngle: _currentAngle,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: IgnorePointer(
                          child: Container(
                            width: centerHubSize,
                            height: centerHubSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: charcoal,
                              border: Border.all(color: gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withValues(alpha: isDark ? 0.15 : 0.10),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getStepLabel(),
                                  style: TextStyle(
                                    fontSize: centerHubSize < 100 ? 10 : 11,
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getCenterDisplayValue(),
                                  style: TextStyle(
                                    fontSize: centerHubSize < 100
                                        ? (_currentStep == RotaryDateStep.hour ? 18 : 20)
                                        : (_currentStep == RotaryDateStep.hour ? 21 : 23),
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _getHelperDescription(),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: centerHubSize < 100 ? 9 : 10,
                                      color: _selectedHourIndex == -1 && _currentStep == RotaryDateStep.hour
                                          ? (isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed)
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 底部操作确认按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onNextOrConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _getButtonLabel(),
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTab({
    required RotaryDateStep step,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required bool isLocked,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textMuted = AppTheme.getTextMuted(context);

    return Expanded(
      child: GestureDetector(
        onTap: isLocked ? null : () => _onStepTap(step),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? gold.withValues(alpha: 0.18)
                : (isCompleted ? jade.withValues(alpha: 0.12) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isLocked
                      ? textMuted
                      : (isActive ? gold : textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isLocked ? textMuted : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepLabel() {
    switch (_currentStep) {
      case RotaryDateStep.year:
        return '【出生年份】';
      case RotaryDateStep.month:
        return '【出生月份】';
      case RotaryDateStep.day:
        return '【出生日期】';
      case RotaryDateStep.hour:
        return '【出生时辰】';
    }
  }

  String _getCenterDisplayValue() {
    switch (_currentStep) {
      case RotaryDateStep.year:
        return '$_selectedYear 年';
      case RotaryDateStep.month:
        return '$_selectedMonth 月';
      case RotaryDateStep.day:
        return '$_selectedDay 日';
      case RotaryDateStep.hour:
        return _selectedHourIndex == -1
            ? '时辰不详'
            : '${_shichenList[_selectedHourIndex + 1]['branch']}时';
    }
  }

  String _getHelperDescription() {
    switch (_currentStep) {
      case RotaryDateStep.year:
        return '转动轮盘调节年份';
      case RotaryDateStep.month:
        return '本月共 ${_maxDaysInMonth(_selectedYear, _selectedMonth)} 天';
      case RotaryDateStep.day:
        return '共 ${_maxDaysInMonth(_selectedYear, _selectedMonth)} 天可选';
      case RotaryDateStep.hour:
        return _selectedHourIndex == -1
            ? '可选不填 · 算L1元神卦'
            : _shichenList[_selectedHourIndex + 1]['time'] as String;
    }
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case RotaryDateStep.year:
        return '确认年份，进入选月';
      case RotaryDateStep.month:
        return '确认月份，进入选日';
      case RotaryDateStep.day:
        return '确认日期，进入选时';
      case RotaryDateStep.hour:
        final shichenText = _selectedHourIndex == -1
            ? '时辰不详'
            : '${_shichenList[_selectedHourIndex + 1]['branch']}时';
        return '确定生辰 ($_selectedYear年$_selectedMonth月$_selectedDay日 · $shichenText)';
    }
  }
}

/// 浑天罗盘单步日期选择器 Canvas 绘制器
class _RotaryWheelPainter extends CustomPainter {
  final RotaryDateStep step;
  final int currentYear;
  final int currentMonth;
  final int currentDay;
  final int currentHourPos; // 0..12
  final int maxDays;
  final double rotationAngle;
  final bool isDark;

  _RotaryWheelPainter({
    required this.step,
    required this.currentYear,
    required this.currentMonth,
    required this.currentDay,
    required this.currentHourPos,
    required this.maxDays,
    required this.rotationAngle,
    required this.isDark,
  });

  Color get _surfaceCard => isDark ? AppTheme.surfaceCard : AppTheme.lightSurfaceCard;
  Color get _surfaceBorder => isDark ? AppTheme.surfaceBorder : AppTheme.lightSurfaceBorder;
  Color get _imperialGold => isDark ? AppTheme.imperialGold : AppTheme.lightImperialGold;
  Color get _textMistGrey => isDark ? AppTheme.textMistGrey : AppTheme.lightTextSecondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 1. 绘制外层星盘轮盘基底与同心金圈
    final ringPaint = Paint()
      ..color = _surfaceCard
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    final borderPaint = Paint()
      ..color = _imperialGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    final innerBorderPaint = Paint()
      ..color = _surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 20, innerBorderPaint);

    // 2. 绘制顶部 12 点钟指针
    final pointerPaint = Paint()
      ..color = _imperialGold
      ..style = PaintingStyle.fill;
    final pointerPath = Path()
      ..moveTo(center.dx, center.dy - radius - 6)
      ..lineTo(center.dx - 6, center.dy - radius + 5)
      ..lineTo(center.dx + 6, center.dy - radius + 5)
      ..close();
    canvas.drawPath(pointerPath, pointerPaint);

    // 3. 根据当前步骤绘制刻度与数字
    int count = 12;
    switch (step) {
      case RotaryDateStep.year:
        count = 24;
        break;
      case RotaryDateStep.month:
        count = 12;
        break;
      case RotaryDateStep.day:
        count = maxDays;
        break;
      case RotaryDateStep.hour:
        count = 13;
        break;
    }

    final double stepAngle = 2 * math.pi / count;

    for (int i = 0; i < count; i++) {
      double angle = i * stepAngle + rotationAngle - (math.pi / 2);

      // 绘制刻度线
      final tickOuter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final tickInner = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = _imperialGold.withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(tickOuter, tickInner, tickPaint);

      // 绘制周边文字
      String label = '';
      switch (step) {
        case RotaryDateStep.year:
          int y = currentYear + (i < count / 2 ? i : i - count);
          if (i % 2 == 0) label = '${y % 100}';
          break;
        case RotaryDateStep.month:
          int m = ((currentMonth - 1 + i) % 12) + 1;
          label = '$m月';
          break;
        case RotaryDateStep.day:
          int d = ((currentDay - 1 + i) % maxDays) + 1;
          if (maxDays > 20 && d % 2 != 0 && d != 1) {
            label = '';
          } else {
            label = '$d';
          }
          break;
        case RotaryDateStep.hour:
          int pos = (currentHourPos + i) % 13;
          label = _RotaryDatePickerDialogState._shichenList[pos]['branch'] as String;
          break;
      }

      if (label.isNotEmpty) {
        final textRadius = radius - 14;
        final textPos = Offset(
          center.dx + textRadius * math.cos(angle),
          center.dy + textRadius * math.sin(angle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 8.5,
              color: i == 0 ? _imperialGold : _textMistGrey.withValues(alpha: 0.7),
              fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          textPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RotaryWheelPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.currentYear != currentYear ||
        oldDelegate.currentMonth != currentMonth ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.currentHourPos != currentHourPos ||
        oldDelegate.maxDays != maxDays ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark;
  }
}
