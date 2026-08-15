import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 五行（金木水火土）能量分布与占比可视化组件（深浅色自适应）
class FiveElementsBar extends StatelessWidget {
  /// 八字中各五行数量分布统计映射表
  final Map<String, int> elementsCount;

  /// 日元本命五行属性（金、木、水、火、土）
  final String dayMasterElement;

  const FiveElementsBar({
    super.key,
    required this.elementsCount,
    required this.dayMasterElement,
  });

  @override
  Widget build(BuildContext context) {
    int total = elementsCount.values.fold(0, (sum, count) => sum + count);
    if (total == 0) total = 1;

    final List<String> elements = ['金', '木', '水', '火', '土'];
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final dayColor = AppTheme.getElementColor(context, dayMasterElement);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '五行能量分布',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dayColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '日元本命五行 · $dayMasterElement',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dayColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 多段色彩能量比例条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: elements.map((elem) {
                    int count = elementsCount[elem] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: count,
                      child: Container(
                        color: AppTheme.getElementColor(context, elem),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // 各五行独立徽章与百分比展示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: elements.map((elem) {
                int count = elementsCount[elem] ?? 0;
                double pct = (count / total) * 100;
                Color color = AppTheme.getElementColor(context, elem);

                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        elem,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count个',
                      style: TextStyle(
                        fontSize: 11,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
