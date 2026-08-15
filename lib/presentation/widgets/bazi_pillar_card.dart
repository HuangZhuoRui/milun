import 'package:flutter/material.dart';
import '../../data/models/hexagram_detail.dart';
import '../theme/app_theme.dart';

/// 四柱八字（年柱、月柱、日柱、时柱）乾坤盘卡片组件（深浅色自适应）
class BaZiPillarCard extends StatelessWidget {
  final BaZiInfo bazi;

  const BaZiPillarCard({super.key, required this.bazi});

  /// 构建单柱干支与纳音显示列
  Widget _buildPillarColumn(
    BuildContext context, {
    required String title,
    required String ganzhi,
    required String nayin,
    bool isDay = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);

    String gan = ganzhi.isNotEmpty ? ganzhi.substring(0, 1) : '-';
    String zhi = ganzhi.length >= 2 ? ganzhi.substring(1, 2) : '-';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDay ? gold.withValues(alpha: 0.12) : charcoal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDay
              ? [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDay ? gold : textSecondary,
                fontWeight: isDay ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isDay)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '日主',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? AppTheme.inkBlack : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 15),
            Text(
              gan,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              zhi,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                nayin,
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

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
                  '四柱八字乾坤盘',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  bazi.solarTerm.isNotEmpty ? '节气 · ${bazi.solarTerm}' : '',
                  style: TextStyle(fontSize: 12, color: gold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '公历: ${bazi.solarStr}  |  农历: ${bazi.lunarStr}',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildPillarColumn(
                  context,
                  title: '年柱',
                  ganzhi: bazi.yearGanZhi,
                  nayin: bazi.yearNaYin,
                ),
                const SizedBox(width: 6),
                _buildPillarColumn(
                  context,
                  title: '月柱',
                  ganzhi: bazi.monthGanZhi,
                  nayin: bazi.monthNaYin,
                ),
                const SizedBox(width: 6),
                _buildPillarColumn(
                  context,
                  title: '日柱 (本命)',
                  ganzhi: bazi.dayGanZhi,
                  nayin: bazi.dayNaYin,
                  isDay: true,
                ),
                const SizedBox(width: 6),
                _buildPillarColumn(
                  context,
                  title: '时柱',
                  ganzhi: bazi.isHourKnown ? bazi.hourGanZhi : '时辰未知',
                  nayin: bazi.isHourKnown ? bazi.hourNaYin : '未知',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
