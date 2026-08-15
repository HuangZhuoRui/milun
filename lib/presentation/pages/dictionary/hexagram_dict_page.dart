import 'package:flutter/material.dart';
import '../../../data/models/hexagram_detail.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hexagram_painter.dart';
import '../../widgets/semi_circle_filter_wheel.dart';
import '../hour_finder/hour_finder_page.dart';

class HexagramDictPage extends StatefulWidget {
  const HexagramDictPage({super.key});

  @override
  State<HexagramDictPage> createState() => _HexagramDictPageState();
}

class _HexagramDictPageState extends State<HexagramDictPage> {
  String _selectedTier = '全部等第';
  String _selectedElement = '全部五行';

  void _showHexagramDetailModal(HexagramDetail hex) {
    final tierColor = AppTheme.getTierColor(context, hex.fortuneTier);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final gold = AppTheme.getGoldColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getTextMuted(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      HexagramWidget(
                        code: hex.code,
                        width: 64,
                        height: 80,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '第 ${hex.id} 卦',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tierColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hex.fortuneTier,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tierColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hex.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hex.fortuneDesc,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tierColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '上卦: ${hex.upperTrigram} · 下卦: ${hex.lowerTrigram} · 五行: ${hex.element}',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildModalSection('【卦象全景白话】', hex.overview),
                  _buildModalSection('【东方人格特质】', hex.personality),
                  _buildModalSection('【事业与职场策略】', hex.career),
                  _buildModalSection('【财富与投资态度】', hex.wealth),
                  _buildModalSection('【情感与人际沟通】', hex.love),
                  _buildModalSection('【五行与身心养生】', hex.health),
                  _buildModalSection('【处世锦囊】', hex.advice),
                  const SizedBox(height: 8),
                  Text(
                    '【周易原典】',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gold),
                  ),
                  const SizedBox(height: 6),
                  Text('卦辞：${hex.guaci}', style: TextStyle(fontSize: 13, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('彖传：${hex.tuan}', style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 4),
                  Text('象传：${hex.xiang}', style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 16),
                  Text(
                    '【六爻详解】',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gold),
                  ),
                  const SizedBox(height: 8),
                  ...hex.yaos.reversed.map((y) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.getSubtleShadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                y.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: y.isYang ? gold : textPrimary,
                                ),
                              ),
                              Text(
                                y.isYang ? '阳爻' : '阴爻',
                                style: TextStyle(fontSize: 11, color: AppTheme.getTextMuted(context)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('【行事指引】${y.interpretation}', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.getGoldColor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: AppTheme.getTextPrimary(context), height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHexagrams = IChingRepository.instance.allHexagrams;
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final gold = AppTheme.getGoldColor(context);

    final filtered = allHexagrams.where((h) {
      bool matchesTier = (_selectedTier == '全部等第' || h.fortuneTier == _selectedTier);
      bool matchesElem = (_selectedElement == '全部五行' || h.element == _selectedElement);
      return matchesTier && matchesElem;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('易经六十四卦宝典'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HourFinderPage(),
                ),
              );
            },
            icon: Icon(Icons.access_time, size: 16, color: gold),
            label: Text('时辰表', style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 顶部：半圆同心双轨筛选罗盘（边缘模糊渐变自然消融）
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: SemiCircleFilterWheel(
              selectedTier: _selectedTier,
              selectedElement: _selectedElement,
              onTierChanged: (tier) {
                setState(() => _selectedTier = tier);
              },
              onElementChanged: (elem) {
                setState(() => _selectedElement = elem);
              },
            ),
          ),

          // 2. 状态统计微标条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '周易六十四卦全卷',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '匹配 ${filtered.length} 卦',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: gold,
                  ),
                ),
              ],
            ),
          ),

          // 3. 六十四卦九宫网格列表
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      '未找到匹配的卦象',
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.08,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final hex = filtered[index];
                      final tierColor = AppTheme.getTierColor(context, hex.fortuneTier);
                      final elemColor = AppTheme.getElementColor(context, hex.element);

                      return Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showHexagramDetailModal(hex),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: tierColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        hex.fortuneTier,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tierColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${hex.element} · 第${hex.id}卦',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: elemColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    HexagramWidget(
                                      code: hex.code,
                                      width: 36,
                                      height: 46,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hex.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${hex.upperTrigram}上${hex.lowerTrigram}下',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  hex.fortuneDesc,
                                  style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
