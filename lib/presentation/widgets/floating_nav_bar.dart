import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 底部悬浮导航项数据结构
class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 雅秋立体光影风格 · 悬浮圆角底部导航栏组件
class FloatingNavBar extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textMuted = AppTheme.getTextMuted(context);
    final cardBg = isDark
        ? const Color(0xE61E1A16) // 沉墨半透磨砂
        : const Color(0xF2FDFBF7); // 素宣凝脂半透

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // 获取实时跟随手指拖动的连续页面坐标（0.0 ~ items.length - 1）
        double pageValue = currentIndex.toDouble();
        if (controller.hasClients &&
            controller.position.haveDimensions &&
            controller.page != null) {
          pageValue = controller.page!;
        }

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              ...AppTheme.getCardShadow(context),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double horizontalPadding = 6.0;
                  const double verticalPadding = 6.0;
                  final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                  final double itemWidth = availableWidth / items.length;
                  final double pillWidth = itemWidth;

                  // 限制浮标滑动范围，防止过界
                  final double clampedPage = pageValue.clamp(0.0, (items.length - 1).toDouble());
                  final double indicatorLeft = horizontalPadding + (clampedPage * itemWidth);

                  return Stack(
                    children: [
                      // 1. 随手势或页面切换连贯滑动的选中浮标（Pill Indicator）
                      Positioned(
                        left: indicatorLeft,
                        top: verticalPadding,
                        bottom: verticalPadding,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: isDark ? 0.20 : 0.14),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withValues(alpha: isDark ? 0.15 : 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. 导航项图标与文本标签（根据 proximity 连续平滑过渡）
                      Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          // 计算当前项与页面滑动进度的接近度（0.0 ~ 1.0）
                          final double distance = (pageValue - index).abs();
                          final double proximity = (1.0 - distance).clamp(0.0, 1.0);

                          final Color activeColor = Color.lerp(textMuted, gold, proximity)!;
                          final double iconScale = 1.0 + (proximity * 0.08);

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(index);
                              },
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: iconScale,
                                      child: Icon(
                                        proximity > 0.5 ? item.activeIcon : item.icon,
                                        color: activeColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: proximity > 0.5
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: activeColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
