import 'package:flutter/material.dart';
import '../../../core/calendar/bazi_engine.dart';
import '../../../core/iching/iching_calculator.dart';
import '../../../data/models/hexagram_detail.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_floating_button.dart';
import '../../widgets/bazi_pillar_card.dart';
import '../../widgets/deepseek_whale_icon.dart';
import '../../widgets/five_elements_bar.dart';
import '../../widgets/hexagram_painter.dart';
import '../../widgets/stacked_wisdom_deck.dart';
import '../ai/ai_analysis_page.dart';
import '../hour_finder/hour_finder_page.dart';

class DivinationResultPage extends StatefulWidget {
  final DivinationResult result;

  const DivinationResultPage({super.key, required this.result});

  @override
  State<DivinationResultPage> createState() => _DivinationResultPageState();
}

class _DivinationResultPageState extends State<DivinationResultPage> {
  late DivinationResult _currentResult;
  int _selectedHexIndex = 0; // 0:本卦, 1:互卦, 2:变卦, 3:错卦, 4:综卦
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
    ProfileRepository.instance.addListener(_onProfileRepoChanged);
    _isSaved = ProfileRepository.instance.isProfileSaved(
      name: _currentResult.name,
      solarDate: _currentResult.solarDate,
      hourIndex: _currentResult.hourIndex,
    );
  }

  @override
  void dispose() {
    ProfileRepository.instance.removeListener(_onProfileRepoChanged);
    super.dispose();
  }

  void _onProfileRepoChanged() {
    if (mounted) {
      final saved = ProfileRepository.instance.isProfileSaved(
        name: _currentResult.name,
        solarDate: _currentResult.solarDate,
        hourIndex: _currentResult.hourIndex,
      );
      if (saved != _isSaved) {
        setState(() {
          _isSaved = saved;
        });
      }
    }
  }

  Future<void> _onOpenHourFinder() async {
    final selectedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => const HourFinderPage()),
    );
    if (selectedIndex != null && mounted) {
      final bazi = BaZiEngine.calculate(
        solarDate: _currentResult.solarDate,
        hourIndex: selectedIndex,
        isHourKnown: true,
        longitude: _currentResult.longitude,
      );
      final newResult = IChingCalculator.calculateHexagrams(
        name: _currentResult.name,
        gender: _currentResult.gender,
        solarDate: _currentResult.solarDate,
        hourIndex: selectedIndex,
        isHourKnown: true,
        repository: IChingRepository.instance,
        bazi: bazi,
        birthCity: _currentResult.birthCity,
        longitude: _currentResult.longitude,
      );
      setState(() {
        _currentResult = newResult;
        _selectedHexIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已补全时辰，成功解锁「${newResult.mainHexagram.name}」完备大衍全息盘！'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen,
        ),
      );
    }
  }

  Future<void> _showSaveArchiveDialog() async {
    final defaultTitle = _currentResult.name.isNotEmpty && _currentResult.name != '本命求测者'
        ? _currentResult.name
        : '${_currentResult.mainHexagram.name} · ${_currentResult.solarDate.year}年';

    final nameController = TextEditingController(text: defaultTitle);
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final gold = AppTheme.getGoldColor(context);
        final textPrimary = AppTheme.getTextPrimary(context);
        final textSecondary = AppTheme.getTextSecondary(context);
        final cardBg = AppTheme.getCardColor(context);
        final charcoal = AppTheme.getCharcoalColor(context);

        return AlertDialog(
          backgroundColor: charcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.star, color: gold, size: 22),
              const SizedBox(width: 8),
              Text(
                '收藏至亲友命簿',
                style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 档案信息摘要卡片
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.getSubtleShadow(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currentResult.solarDate.year}年${_currentResult.solarDate.month}月${_currentResult.solarDate.day}日 · ${_currentResult.bazi.isHourKnown ? _currentResult.bazi.hourGanZhi : "时辰不详"}',
                        style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '本命卦：第${_currentResult.mainHexagram.id}卦 · ${_currentResult.mainHexagram.name} (${_currentResult.mainHexagram.fortuneTier})',
                        style: TextStyle(color: textPrimary, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '四柱：${_currentResult.bazi.yearGanZhi} ${_currentResult.bazi.monthGanZhi} ${_currentResult.bazi.dayGanZhi} ${_currentResult.bazi.hourGanZhi} · ${_currentResult.gender}',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: '姓名 / 档案昵称',
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                    hintText: '如：张先生 / 本人命盘',
                    hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: '备注说明 (选填)',
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                    hintText: '如：工作变动期测算',
                    hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('保存入库', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final profile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        gender: _currentResult.gender,
        solarDate: _currentResult.solarDate,
        isLunar: false,
        hourIndex: _currentResult.hourIndex,
        isHourKnown: _currentResult.bazi.isHourKnown,
        birthCity: _currentResult.birthCity,
        longitude: _currentResult.longitude,
        notes: notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ProfileRepository.instance.saveProfile(profile);

      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已成功收藏「${profile.name}」到亲友命簿'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen,
          ),
        );
      }
    }
  }

  HexagramDetail get _currentSelectedHexagram {
    switch (_selectedHexIndex) {
      case 0:
        return _currentResult.mainHexagram;
      case 1:
        return _currentResult.mutualHexagram;
      case 2:
        return _currentResult.transformedHexagram ?? _currentResult.mainHexagram;
      case 3:
        return _currentResult.oppositeHexagram;
      case 4:
        return _currentResult.inverseHexagram;
      default:
        return _currentResult.mainHexagram;
    }
  }

  String get _currentHexLabel {
    switch (_selectedHexIndex) {
      case 0:
        return '本命主卦 (先天根基)';
      case 1:
        return '互卦 (内在隐秘动因)';
      case 2:
        return '变卦 (后天发展趋向)';
      case 3:
        return '错卦 (反向镜鉴视角)';
      case 4:
        return '综卦 (颠倒逆境视角)';
      default:
        return '本命主卦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = _currentResult;
    final isHourKnown = r.bazi.isHourKnown;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;
    final currentTierColor = AppTheme.getTierColor(context, _currentSelectedHexagram.fortuneTier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${r.name} · 本命全息盘'),
        actions: [
          IconButton(
            icon: DeepSeekWhaleIcon(size: 20, color: gold),
            tooltip: 'DeepSeek AI 易学参详',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AiAnalysisPage(initialResult: r),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.star : Icons.star_border,
              color: gold,
            ),
            tooltip: _isSaved ? '已收藏至命簿' : '收藏至亲友命簿',
            onPressed: _showSaveArchiveDialog,
          ),
        ],
      ),
      floatingActionButton: AiFloatingButton(currentResult: r),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          children: [
            // 顶部大衍起卦精度提示横幅
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isHourKnown
                    ? gold.withValues(alpha: 0.12)
                    : cinnabar.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: Row(
                children: [
                  Icon(
                    isHourKnown ? Icons.verified : Icons.info_outline,
                    color: isHourKnown ? gold : cinnabar,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.precisionLevel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isHourKnown ? gold : cinnabar,
                      ),
                    ),
                  ),
                  if (!isHourKnown)
                    GestureDetector(
                      onTap: _onOpenHourFinder,
                      child: Text(
                        '反推时辰 >',
                        style: TextStyle(fontSize: 12, color: gold, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // 四柱八字干支与纳音乾坤盘
            BaZiPillarCard(bazi: r.bazi),

            // 五行能量平衡占比条
            FiveElementsBar(
              elementsCount: r.bazi.fiveElementsCount,
              dayMasterElement: r.bazi.dayMasterElement,
            ),

            // 易理体用与五行生克权衡参考卡片
            _buildShengKeAnalysisCard(r, _currentSelectedHexagram),

            // 卦象全息交互切换卡片（本卦/互卦/变卦/错卦/综卦）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 卦象类别切换选择标签
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildHexChip(0, '本卦 (本命)', isMain: true),
                          const SizedBox(width: 8),
                          _buildHexChip(1, '互卦 (内在)'),
                          const SizedBox(width: 8),
                          if (r.transformedHexagram != null) ...[
                            _buildHexChip(2, '变卦 (趋势)'),
                            const SizedBox(width: 8),
                          ],
                          _buildHexChip(3, '错卦 (镜鉴)'),
                          const SizedBox(width: 8),
                          _buildHexChip(4, '综卦 (逆境)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 主卦卦象图形与标题详情
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        HexagramWidget(
                          code: _currentSelectedHexagram.code,
                          changingYaoIndex: _selectedHexIndex == 0 ? r.changingYaoIndex : null,
                          width: 80,
                          height: 104,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getCharcoalColor(context),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _currentHexLabel,
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: currentTierColor.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _currentSelectedHexagram.fortuneTier,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: currentTierColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currentSelectedHexagram.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentSelectedHexagram.fortuneDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: currentTierColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '上卦: ${_currentSelectedHexagram.upperTrigram}(${_trigramElements[_currentSelectedHexagram.upperTrigram] ?? ""}) · 下卦: ${_currentSelectedHexagram.lowerTrigram}(${_trigramElements[_currentSelectedHexagram.lowerTrigram] ?? ""}) · 五行: ${_currentSelectedHexagram.element}',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getCharcoalColor(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentSelectedHexagram.overview,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 周易五维搭配卦象演进全览对照卡片
            _buildPairedHexagramsMatrix(r),

            // 动爻（关键转折点）核心高亮专区
            if (isHourKnown && r.changingYao != null) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cinnabar.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cinnabar,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '人生关键转折 · 【${r.changingYao!.name}】动爻',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: cinnabar,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cinnabar.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '第${r.changingYaoIndex}爻激活',
                              style: TextStyle(fontSize: 11, color: cinnabar),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.changingYao!.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.changingYao!.xiang,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.getCharcoalColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '【当下处境与破局指南】\n${r.changingYao!.interpretation}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!isHourKnown) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock, color: textSecondary, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '解锁动爻与后天变卦',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '输入出生时辰即可定位第1~6爻中的具体动爻与后半生变卦走向。',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _onOpenHourFinder,
                        style: TextButton.styleFrom(
                          foregroundColor: gold,
                        ),
                        child: const Text('去反推'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 底部 3D 层叠洗牌切牌文案典籍大观
            StackedWisdomDeck(
              items: [
                WisdomCardItem(
                  volume: '卷一',
                  title: '东方人格',
                  subtitle: '性格底色与潜能',
                  content: _currentSelectedHexagram.personality,
                  advice: _currentSelectedHexagram.advice,
                ),
                WisdomCardItem(
                  volume: '卷二',
                  title: '事业职场',
                  subtitle: '格局与行事策略',
                  content: _currentSelectedHexagram.career,
                ),
                WisdomCardItem(
                  volume: '卷三',
                  title: '财富投资',
                  subtitle: '风格与求财之道',
                  content: _currentSelectedHexagram.wealth,
                ),
                WisdomCardItem(
                  volume: '卷四',
                  title: '情感人际',
                  subtitle: '沟通与亲密关系',
                  content: _currentSelectedHexagram.love,
                ),
                WisdomCardItem(
                  volume: '卷五',
                  title: '五行调和',
                  subtitle: '脏腑与身心平衡',
                  content: _currentSelectedHexagram.health,
                ),
                WisdomCardItem(
                  volume: '卷六',
                  title: '周易原典',
                  subtitle: '卦辞彖象与爻辞',
                  content: '',
                  isClassic: true,
                  hexagram: _currentSelectedHexagram,
                ),
              ],
              cardHeight: 440,
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, String> _trigramElements = {
    '乾': '金', '兑': '金',
    '离': '火',
    '震': '木', '巽': '木',
    '坎': '水',
    '艮': '土', '坤': '土',
  };

  /// 计算上下卦（体用）五行生克关系
  String _calculateTrigramRelation(String upper, String lower) {
    final upElem = _trigramElements[upper] ?? '金';
    final lowElem = _trigramElements[lower] ?? '土';

    if (upElem == lowElem) {
      return '【体用比和】上卦$upper($upElem) 与 下卦$lower($lowElem) 同气连枝，主客相协，气场纯正稳固。';
    }

    if ((upElem == '木' && lowElem == '火') ||
        (upElem == '火' && lowElem == '土') ||
        (upElem == '土' && lowElem == '金') ||
        (upElem == '金' && lowElem == '水') ||
        (upElem == '水' && lowElem == '木')) {
      return '【用生体·大吉】上卦$upper($upElem) 生助 下卦$lower($lowElem)，外境生我，得天时地利与贵人扶持。';
    }

    if ((lowElem == '木' && upElem == '火') ||
        (lowElem == '火' && upElem == '土') ||
        (lowElem == '土' && upElem == '金') ||
        (lowElem == '金' && upElem == '水') ||
        (lowElem == '水' && upElem == '木')) {
      return '【体生用·泄秀】下卦$lower($lowElem) 滋养 上卦$upper($upElem)，主体向外输出才干，宜蓄力防耗。';
    }

    if ((lowElem == '金' && upElem == '木') ||
        (lowElem == '木' && upElem == '土') ||
        (lowElem == '土' && upElem == '水') ||
        (lowElem == '水' && upElem == '火') ||
        (lowElem == '火' && upElem == '金')) {
      return '【体克用·掌控】下卦$lower($lowElem) 克制 上卦$upper($upElem)，主体掌控客体，劳碌求财，多谋后动。';
    }

    return '【用克体·受制】上卦$upper($upElem) 克制 下卦$lower($lowElem)，外境规训磨砺，宜守正自持、修德避咎。';
  }

  /// 计算日主（日元）与当前卦象五行的十神生克意象
  String _calculateDayMasterRelation(String dayMasterElem, String hexElem) {
    if (dayMasterElem == hexElem) {
      return '【比肩同气】日元属$dayMasterElem，卦象五行同属$hexElem，身卦同气相求，气场中正亨和。';
    }

    if ((hexElem == '木' && dayMasterElem == '火') ||
        (hexElem == '火' && dayMasterElem == '土') ||
        (hexElem == '土' && dayMasterElem == '金') ||
        (hexElem == '金' && dayMasterElem == '水') ||
        (hexElem == '水' && dayMasterElem == '木')) {
      return '【印星生身】卦气$hexElem行 生助 日元$dayMasterElem，卦气化为印星涵养命主，得资粮护持。';
    }

    if ((dayMasterElem == '木' && hexElem == '火') ||
        (dayMasterElem == '火' && hexElem == '土') ||
        (dayMasterElem == '土' && hexElem == '金') ||
        (dayMasterElem == '金' && hexElem == '水') ||
        (dayMasterElem == '水' && hexElem == '木')) {
      return '【食伤吐秀】日元$dayMasterElem 滋生 卦气$hexElem行，命主才情灵感得以外化抒发，利创作成就。';
    }

    if ((dayMasterElem == '金' && hexElem == '木') ||
        (dayMasterElem == '木' && hexElem == '土') ||
        (dayMasterElem == '土' && hexElem == '水') ||
        (dayMasterElem == '水' && hexElem == '火') ||
        (dayMasterElem == '火' && hexElem == '金')) {
      return '【财星被制】日元$dayMasterElem 克制 卦气$hexElem行，命主求财图强，运筹帷幄而掌控资源。';
    }

    return '【官杀磨砺】卦气$hexElem行 克制 日元$dayMasterElem，命主受天时规训与责任淬炼，历经磨砺而成大器。';
  }

  Widget _buildShengKeAnalysisCard(DivinationResult r, HexagramDetail hex) {
    final upElem = _trigramElements[hex.upperTrigram] ?? '';
    final lowElem = _trigramElements[hex.lowerTrigram] ?? '';
    final trigramRel = _calculateTrigramRelation(hex.upperTrigram, hex.lowerTrigram);
    final dayMasterRel = _calculateDayMasterRelation(r.bazi.dayMasterElement, hex.element);
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '【易理体用 · 五行生克权衡】',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: gold,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: charcoal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '易经本义',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 上下卦体用生克条目
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '上卦(用·客): ${hex.upperTrigram}($upElem)  |  下卦(体·主): ${hex.lowerTrigram}($lowElem)',
                          style: TextStyle(fontSize: 11.5, color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trigramRel,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 日元与卦气生克条目
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '日元命主: ${r.bazi.dayMaster}(${r.bazi.dayMasterElement})  |  卦象五行: ${hex.element}',
                          style: TextStyle(fontSize: 11.5, color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayMasterRel,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairedHexagramsMatrix(DivinationResult r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);

    final List<Map<String, dynamic>> matrix = [
      {
        'index': 0,
        'tag': '本卦',
        'sub': '先天命体',
        'hex': r.mainHexagram,
        'role': '生命主基调与先天秉赋，为全盘立身根本。',
      },
      {
        'index': 1,
        'tag': '互卦',
        'sub': '内在机微',
        'hex': r.mutualHexagram,
        'role': '事物演化内在动因与潜意识隐秘脉络。',
      },
      if (r.transformedHexagram != null)
        {
          'index': 2,
          'tag': '变卦',
          'sub': '后天归宿',
          'hex': r.transformedHexagram!,
          'role': '动爻经历后天转化后的终局演进趋向。',
        },
      {
        'index': 3,
        'tag': '错卦',
        'sub': '对立镜鉴',
        'hex': r.oppositeHexagram,
        'role': '完全对立视角的镜像审视，用于明察盲区。',
      },
      {
        'index': 4,
        'tag': '综卦',
        'sub': '换位逆境',
        'hex': r.inverseHexagram,
        'role': '颠倒翻转视角，用于换位思考与逆境破局。',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '【周易五维 · 搭配卦象演进全览】',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: gold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '点击即时切盘',
                  style: TextStyle(
                    fontSize: 11,
                    color: gold.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...matrix.map((item) {
              final int idx = item['index'] as int;
              final String tag = item['tag'] as String;
              final String sub = item['sub'] as String;
              final HexagramDetail h = item['hex'] as HexagramDetail;
              final String role = item['role'] as String;
              final bool isSelected = _selectedHexIndex == idx;

              return GestureDetector(
                onTap: () => setState(() => _selectedHexIndex = idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? gold.withValues(alpha: 0.12)
                        : charcoal,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : AppTheme.getSubtleShadow(context),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? gold : cardBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$tag · $sub',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? (isDark ? AppTheme.inkBlack : Colors.white)
                                : gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(
                                  '第${h.id}卦 · ${h.name} (${h.fortuneTier})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '上${h.upperTrigram}下${h.lowerTrigram} · ${h.element}行',
                                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              role,
                              style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHexChip(int index, String label, {bool isMain = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final charcoal = AppTheme.getCharcoalColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final bool selected = _selectedHexIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedHexIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isMain ? gold : jade)
              : charcoal,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (isMain ? gold : jade).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppTheme.getSubtleShadow(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? (isDark ? AppTheme.inkBlack : Colors.white)
                : textPrimary,
          ),
        ),
      ),
    );
  }
}
