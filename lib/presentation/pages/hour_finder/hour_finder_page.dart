import 'package:flutter/material.dart';
import '../../../core/iching/hour_finder_helper.dart';
import '../../theme/app_theme.dart';

/// 十二时辰典籍信息对照展示页面（纯查阅参考）
class HourFinderPage extends StatelessWidget {
  const HourFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('十二时辰表'),
      ),
      body: Column(
        children: [
          // 顶部典籍指引横幅
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.getSubtleShadow(context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories, color: gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '十二时辰为中国古代干支纪时体系，一日分为十二时辰，一时辰合现代两个小时。每一时辰对应特定的地支、五行属性、古称、东方人格原型与经络养生节律。',
                    style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.45),
                  ),
                ),
              ],
            ),
          ),

          // 十二时辰详细信息卡片列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: HourFinderHelper.cards.length,
              itemBuilder: (context, index) {
                final card = HourFinderHelper.cards[index];
                final elemColor = AppTheme.getElementColor(context, card.element);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部时辰名称、地支徽标、古称与五行属性
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: elemColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    card.branch,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: elemColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '古称 · ${card.alias}',
                                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: elemColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '五行属${card.element}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: elemColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 人格原型标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: charcoal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '【原型】${card.archetype}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 气质特征
                        Text(
                          card.temperament,
                          style: TextStyle(fontSize: 13, color: textPrimary, height: 1.45),
                        ),
                        const SizedBox(height: 6),

                        // 体态与作息节律
                        Text(
                          '【节律调摄】${card.habitTrait}',
                          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                        ),
                        const SizedBox(height: 8),

                        // 标签意象
                        Text(
                          '意象：${card.tag}',
                          style: TextStyle(
                            fontSize: 11,
                            color: gold.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
