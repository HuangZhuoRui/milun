import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 易经六十四卦卦象图形自定义绘制器
class HexagramPainter extends CustomPainter {
  /// 6 位二进制卦码（从初爻至上爻排列，例如 "111111" 代表乾卦）
  final String code;

  /// 动爻爻位（1 至 6，1 为初爻，6 为上爻；null 表示无动爻）
  final int? changingYaoIndex;

  /// 阳爻颜色（默认帝王金）
  final Color yangColor;

  /// 阴爻颜色（默认烟水灰）
  final Color changingColor;

  /// 动爻高亮颜色（默认朱砂红）
  final Color yinColor;

  HexagramPainter({
    required this.code,
    this.changingYaoIndex,
    this.yangColor = AppTheme.imperialGold,
    this.yinColor = AppTheme.textMistGrey,
    this.changingColor = AppTheme.cinnabarRed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (code.length < 6) return;

    double lineHeight = size.height / 11; // 6 爻高度 + 5 个间隙
    double gapHeight = lineHeight;
    double cornerRadius = lineHeight * 0.35;
    double centerGap = size.width * 0.18; // 阴爻中央断开断口间距

    Paint paint = Paint()..style = PaintingStyle.fill;

    // 视觉渲染顺序：从上爻（第6爻，索引5，位于画布顶部）至初爻（第1爻，索引0，位于画布底部）
    for (int i = 0; i < 6; i++) {
      int lineNum = i + 1; // 爻位序号：1 至 6（1 为初爻，位于底部）
      int visualIndexFromTop = 6 - lineNum; // 视觉纵向索引：6爻在顶(0)，1爻在底(5)
      double topY = visualIndexFromTop * (lineHeight + gapHeight);

      bool isYang = code[i] == '1';
      bool isChanging = (changingYaoIndex != null && changingYaoIndex == lineNum);

      paint.color = isChanging
          ? changingColor
          : (isYang ? yangColor : yinColor);

      if (isYang) {
        // 阳爻：连贯实线（—）
        RRect rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topY, size.width, lineHeight),
          Radius.circular(cornerRadius),
        );
        canvas.drawRRect(rrect, paint);
      } else {
        // 阴爻：两段式虚线（--），中央断开
        double segmentWidth = (size.width - centerGap) / 2;
        // 左半爻段
        RRect leftRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topY, segmentWidth, lineHeight),
          Radius.circular(cornerRadius),
        );
        // 右半爻段
        RRect rightRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(segmentWidth + centerGap, topY, segmentWidth, lineHeight),
          Radius.circular(cornerRadius),
        );
        canvas.drawRRect(leftRRect, paint);
        canvas.drawRRect(rightRRect, paint);
      }

      // 动爻特殊标示圆点
      if (isChanging) {
        Paint dotPaint = Paint()
          ..color = changingColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(size.width + 12, topY + lineHeight / 2),
          lineHeight * 0.45,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HexagramPainter oldDelegate) {
    return oldDelegate.code != code ||
        oldDelegate.changingYaoIndex != changingYaoIndex ||
        oldDelegate.yangColor != yangColor ||
        oldDelegate.yinColor != yinColor ||
        oldDelegate.changingColor != changingColor;
  }
}

/// 易经六十四卦卦象图形展示 Widget
class HexagramWidget extends StatelessWidget {
  final String code;
  final int? changingYaoIndex;
  final double width;
  final double height;
  final Color? yangColor;
  final Color? yinColor;
  final Color? changingColor;

  const HexagramWidget({
    super.key,
    required this.code,
    this.changingYaoIndex,
    this.width = 72,
    this.height = 88,
    this.yangColor,
    this.yinColor,
    this.changingColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultYang = AppTheme.getGoldColor(context);
    final defaultYin = isDark
        ? AppTheme.textMistGrey.withValues(alpha: 0.7)
        : AppTheme.lightTextMuted;
    final defaultChanging = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    return CustomPaint(
      size: Size(width, height),
      painter: HexagramPainter(
        code: code,
        changingYaoIndex: changingYaoIndex,
        yangColor: yangColor ?? defaultYang,
        yinColor: yinColor ?? defaultYin,
        changingColor: changingColor ?? defaultChanging,
      ),
    );
  }
}
