import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 半圆同心双轨筛选罗盘组件 (Semi-Circular Rotary Dial Filter Wheel)
/// 特性：
/// 1. 外环吉凶等第、内环五行属性，支持顺畅滑动旋转与点按定位筛选；
/// 2. HitTestBehavior.opaque 保证全域灵敏触控响应，支持切向旋转拖拽与点击即切；
/// 3. 边缘使用 ShaderMask 双向渐变与径向透明度，两端完全融入背景，绝无生硬截断；
/// 4. 正中天心金针指示当前选定维度，触觉振动反馈与物理惯性回弹。
class SemiCircleFilterWheel extends StatefulWidget {
  final String selectedTier;
  final String selectedElement;
  final ValueChanged<String> onTierChanged;
  final ValueChanged<String> onElementChanged;

  const SemiCircleFilterWheel({
    super.key,
    required this.selectedTier,
    required this.selectedElement,
    required this.onTierChanged,
    required this.onElementChanged,
  });

  static const List<String> tiers = [
    '全部等第',
    '上上卦',
    '上吉卦',
    '中平卦',
    '磨砺卦',
    '潜修卦',
  ];

  static const List<String> elements = [
    '全部五行',
    '金',
    '木',
    '水',
    '火',
    '土',
  ];

  static const Map<String, String> elementGuaDesc = {
    '全部五行': '通览',
    '金': '乾兑',
    '木': '震巽',
    '水': '坎水',
    '火': '离火',
    '土': '艮坤',
  };

  @override
  State<SemiCircleFilterWheel> createState() => _SemiCircleFilterWheelState();
}

class _SemiCircleFilterWheelState extends State<SemiCircleFilterWheel>
    with TickerProviderStateMixin {
  // 当前拖拽的环层：0 为内环 (五行)，1 为外环 (等第)
  int _activeTrack = 1;

  double _tierDragAngle = 0.0;
  double _elementDragAngle = 0.0;
  double _lastTouchAngle = 0.0;

  late AnimationController _tierAnimController;
  late AnimationController _elemAnimController;
  late Animation<double> _tierAnimation;
  late Animation<double> _elemAnimation;

  final double _stepAngle = 0.44; // 每个项目相隔弧度 (约 25.2 度)

  @override
  void initState() {
    super.initState();
    _tierAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _elemAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _tierAnimController.dispose();
    _elemAnimController.dispose();
    super.dispose();
  }

  int get _tierIndex {
    final idx = SemiCircleFilterWheel.tiers.indexOf(widget.selectedTier);
    return idx >= 0 ? idx : 0;
  }

  int get _elementIndex {
    final idx = SemiCircleFilterWheel.elements.indexOf(widget.selectedElement);
    return idx >= 0 ? idx : 0;
  }

  void _handlePointerDown(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height + 12.0);
    final diff = localPos - center;
    final dist = diff.distance;

    _lastTouchAngle = math.atan2(diff.dy, diff.dx);

    // 判定触控属于外环还是内环 (外环半径 144，内环半径 94)
    if (dist > 115) {
      _activeTrack = 1; // 外环等第
    } else {
      _activeTrack = 0; // 内环五行
    }
  }

  void _handlePointerMove(Offset localPos, Size size, Offset delta) {
    final center = Offset(size.width / 2, size.height + 12.0);
    final diff = localPos - center;
    final currentAngle = math.atan2(diff.dy, diff.dx);

    // 计算角度增量（弧度）
    double angleDelta = currentAngle - _lastTouchAngle;
    if (angleDelta > math.pi) angleDelta -= 2 * math.pi;
    if (angleDelta < -math.pi) angleDelta += 2 * math.pi;

    // 兼顾水平线性拖拽位移
    final linearAngleDelta = (delta.dx / 120.0) * 0.75;
    final effectiveDelta = (angleDelta.abs() > 0.001) ? angleDelta : linearAngleDelta;

    _lastTouchAngle = currentAngle;

    setState(() {
      if (_activeTrack == 1) {
        _tierDragAngle += effectiveDelta;
      } else {
        _elementDragAngle += effectiveDelta;
      }
    });
  }

  void _handlePointerUp() {
    if (_activeTrack == 1) {
      // 外环等第结算
      final offsetSteps = (_tierDragAngle / _stepAngle).round();
      final targetIdx = (_tierIndex - offsetSteps).clamp(0, SemiCircleFilterWheel.tiers.length - 1);
      _animateTierToIndex(targetIdx);
    } else {
      // 内环五行结算
      final offsetSteps = (_elementDragAngle / _stepAngle).round();
      final targetIdx = (_elementIndex - offsetSteps).clamp(0, SemiCircleFilterWheel.elements.length - 1);
      _animateElementToIndex(targetIdx);
    }
  }

  void _handleTapUp(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height + 12.0);
    final diff = localPos - center;
    final dist = diff.distance;
    final tapAngle = math.atan2(diff.dy, diff.dx);

    // 顶点为 -pi/2
    final angleFromApex = tapAngle - (-math.pi / 2);

    if (dist > 115 && dist < 180) {
      // 点击外环：计算最近的等第项目
      final clickedOffsetSteps = (angleFromApex / _stepAngle).round();
      final targetIdx = (_tierIndex + clickedOffsetSteps).clamp(0, SemiCircleFilterWheel.tiers.length - 1);
      setState(() => _activeTrack = 1);
      _animateTierToIndex(targetIdx);
    } else if (dist >= 50 && dist <= 115) {
      // 点击内环：计算最近的五行项目
      final clickedOffsetSteps = (angleFromApex / _stepAngle).round();
      final targetIdx = (_elementIndex + clickedOffsetSteps).clamp(0, SemiCircleFilterWheel.elements.length - 1);
      setState(() => _activeTrack = 0);
      _animateElementToIndex(targetIdx);
    }
  }

  void _animateTierToIndex(int targetIndex) {
    final targetItem = SemiCircleFilterWheel.tiers[targetIndex];
    final startDrag = _tierDragAngle;
    final targetDrag = (_tierIndex - targetIndex) * _stepAngle;

    _tierAnimation = Tween<double>(begin: startDrag, end: targetDrag).animate(
      CurvedAnimation(parent: _tierAnimController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _tierDragAngle = _tierAnimation.value;
        });
      });

    _tierAnimController.forward(from: 0.0).then((_) {
      HapticFeedback.selectionClick();
      setState(() {
        _tierDragAngle = 0.0;
        widget.onTierChanged(targetItem);
      });
    });
  }

  void _animateElementToIndex(int targetIndex) {
    final targetItem = SemiCircleFilterWheel.elements[targetIndex];
    final startDrag = _elementDragAngle;
    final targetDrag = (_elementIndex - targetIndex) * _stepAngle;

    _elemAnimation = Tween<double>(begin: startDrag, end: targetDrag).animate(
      CurvedAnimation(parent: _elemAnimController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _elementDragAngle = _elemAnimation.value;
        });
      });

    _elemAnimController.forward(from: 0.0).then((_) {
      HapticFeedback.selectionClick();
      setState(() {
        _elementDragAngle = 0.0;
        widget.onElementChanged(targetItem);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const double wheelHeight = 158.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wheelSize = Size(width, wheelHeight);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 半圆轮盘主体（带 ShaderMask 渐变柔和虚化两端，绝不截断）
            SizedBox(
              width: width,
              height: wheelHeight,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  // 左右两端软边缘渐变虚化，结束处如烟雾般消融
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.14, 0.86, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    // 下沿自然淡出
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque, // 保证全区域接收触控事件
                    onPanStart: (d) => _handlePointerDown(d.localPosition, wheelSize),
                    onPanUpdate: (d) => _handlePointerMove(d.localPosition, wheelSize, d.delta),
                    onPanEnd: (_) => _handlePointerUp(),
                    onTapUp: (d) => _handleTapUp(d.localPosition, wheelSize),
                    child: CustomPaint(
                      size: wheelSize,
                      painter: _SemiCircleWheelPainter(
                        selectedTierIndex: _tierIndex,
                        selectedElementIndex: _elementIndex,
                        tierDragAngle: _tierDragAngle,
                        elementDragAngle: _elementDragAngle,
                        stepAngle: _stepAngle,
                        activeTrack: _activeTrack,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. 罗盘下方选中态微标胶囊与切换指引
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrackTab(
                    label: '等第: ${widget.selectedTier}',
                    isActive: _activeTrack == 1,
                    activeColor: AppTheme.getTierColor(context, widget.selectedTier),
                    onTap: () {
                      setState(() => _activeTrack = 1);
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildTrackTab(
                    label: '五行: ${widget.selectedElement == "全部五行" ? "全部" : "${widget.selectedElement}行 (${SemiCircleFilterWheel.elementGuaDesc[widget.selectedElement]})"}',
                    isActive: _activeTrack == 0,
                    activeColor: AppTheme.getElementColor(context, widget.selectedElement),
                    onTap: () {
                      setState(() => _activeTrack = 0);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackTab({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.18) : AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.getSubtleShadow(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}

/// 半圆同心双轨罗盘画笔
class _SemiCircleWheelPainter extends CustomPainter {
  final int selectedTierIndex;
  final int selectedElementIndex;
  final double tierDragAngle;
  final double elementDragAngle;
  final double stepAngle;
  final int activeTrack;
  final bool isDark;

  _SemiCircleWheelPainter({
    required this.selectedTierIndex,
    required this.selectedElementIndex,
    required this.tierDragAngle,
    required this.elementDragAngle,
    required this.stepAngle,
    required this.activeTrack,
    required this.isDark,
  });

  Color get _surfaceBorder => isDark ? AppTheme.surfaceBorder : AppTheme.lightSurfaceBorder;
  Color get _imperialGold => isDark ? AppTheme.imperialGold : AppTheme.lightImperialGold;
  Color get _textMistGrey => isDark ? AppTheme.textMistGrey : AppTheme.lightTextSecondary;
  Color get _textPaperWhite => isDark ? AppTheme.textPaperWhite : AppTheme.lightTextPrimary;
  Color get _textMutedDark => isDark ? AppTheme.textMutedDark : AppTheme.lightTextMuted;

  Map<String, Color> get _tierColors => isDark ? AppTheme.tierColors : AppTheme.lightTierColors;
  Map<String, Color> get _elementColors => isDark ? AppTheme.elementColors : AppTheme.lightElementColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height + 12.0);

    const double outerRadius = 144.0;
    const double innerRadius = 94.0;

    // 1. 绘制罗盘背景环轨
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _surfaceBorder.withValues(alpha: 0.55);

    // 外环轨道
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      math.pi * 0.95,
      math.pi * 1.1,
      false,
      trackPaint,
    );

    // 内环轨道
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      math.pi * 0.95,
      math.pi * 1.1,
      false,
      trackPaint,
    );

    // 2. 绘制正顶灵枢指示金针 (12 点钟方向顶点)
    final pointerPaint = Paint()
      ..color = _imperialGold
      ..style = PaintingStyle.fill;

    final pointerPath = Path()
      ..moveTo(center.dx, 1.0)
      ..lineTo(center.dx - 4.5, 9.0)
      ..lineTo(center.dx + 4.5, 9.0)
      ..close();
    canvas.drawPath(pointerPath, pointerPaint);

    // 3. 绘制外环等第项目
    for (int i = 0; i < SemiCircleFilterWheel.tiers.length; i++) {
      final tierName = SemiCircleFilterWheel.tiers[i];
      // 顶点基准角度为 -pi / 2 (即 270度 / 12 点钟)
      final double itemAngle = (-math.pi / 2) + (i - selectedTierIndex) * stepAngle + tierDragAngle;

      // 仅绘制在可视半圆范围内的文字 ( -pi ~ 0 )
      if (itemAngle < -math.pi * 1.08 || itemAngle > 0.08) continue;

      final double x = center.dx + outerRadius * math.cos(itemAngle);
      final double y = center.dy + outerRadius * math.sin(itemAngle);

      final double distFromApex = (itemAngle - (-math.pi / 2)).abs();
      final bool isApex = distFromApex < (stepAngle * 0.45);
      final Color tierColor = _tierColors[tierName] ?? _imperialGold;

      // 计算边缘渐隐透明度
      final double edgeFade = (1.0 - (distFromApex / 1.35)).clamp(0.0, 1.0);

      // 绘制等第小圆点
      final dotPaint = Paint()
        ..color = (isApex ? tierColor : _textMistGrey).withValues(alpha: edgeFade)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y - 10), isApex ? 2.5 : 1.5, dotPaint);

      // 绘制等第文字
      final textSpan = TextSpan(
        text: tierName,
        style: TextStyle(
          fontSize: isApex ? 12.5 : 11.0,
          fontWeight: isApex ? FontWeight.bold : FontWeight.normal,
          color: (isApex ? tierColor : _textPaperWhite).withValues(alpha: edgeFade),
          letterSpacing: isApex ? 0.6 : 0.2,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 6));
    }

    // 4. 绘制内环五行项目
    for (int i = 0; i < SemiCircleFilterWheel.elements.length; i++) {
      final elemName = SemiCircleFilterWheel.elements[i];
      final double itemAngle = (-math.pi / 2) + (i - selectedElementIndex) * stepAngle + elementDragAngle;

      if (itemAngle < -math.pi * 1.08 || itemAngle > 0.08) continue;

      final double x = center.dx + innerRadius * math.cos(itemAngle);
      final double y = center.dy + innerRadius * math.sin(itemAngle);

      final double distFromApex = (itemAngle - (-math.pi / 2)).abs();
      final bool isApex = distFromApex < (stepAngle * 0.45);
      final Color elemColor = _elementColors[elemName] ?? _imperialGold;
      final double edgeFade = (1.0 - (distFromApex / 1.35)).clamp(0.0, 1.0);

      final textSpan = TextSpan(
        text: elemName == '全部五行' ? '全部' : '$elemName行',
        style: TextStyle(
          fontSize: isApex ? 11.5 : 10.0,
          fontWeight: isApex ? FontWeight.bold : FontWeight.normal,
          color: (isApex ? elemColor : _textMutedDark).withValues(alpha: edgeFade),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleWheelPainter oldDelegate) {
    return oldDelegate.selectedTierIndex != selectedTierIndex ||
        oldDelegate.selectedElementIndex != selectedElementIndex ||
        oldDelegate.tierDragAngle != tierDragAngle ||
        oldDelegate.elementDragAngle != elementDragAngle ||
        oldDelegate.activeTrack != activeTrack ||
        oldDelegate.isDark != isDark;
  }
}
