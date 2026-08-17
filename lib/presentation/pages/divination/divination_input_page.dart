import 'package:flutter/material.dart';
import '../../../core/calendar/bazi_engine.dart';
import '../../../core/iching/iching_calculator.dart';
import '../../../data/models/hexagram_detail.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/concentric_astrolabe_wheel.dart';
import '../../widgets/slidable_archive_card.dart';
import 'divination_result_page.dart';

class DivinationInputPage extends StatefulWidget {
  final UserProfile? initialProfile;
  final int? initialHourIndex;

  const DivinationInputPage({
    super.key,
    this.initialProfile,
    this.initialHourIndex,
  });

  @override
  State<DivinationInputPage> createState() => _DivinationInputPageState();
}

class _DivinationInputPageState extends State<DivinationInputPage> {
  late ConcentricAstrolabeState _astrolabeState;
  late DivinationResult _currentResult;

  int _previousHexagramId = 15;
  bool _isTransitionForward = true;

  @override
  void initState() {
    super.initState();

    // 从档案中载入初始状态或采用默认配置
    if (widget.initialProfile != null) {
      final p = widget.initialProfile!;
      _astrolabeState = ConcentricAstrolabeState(
        year: p.solarDate.year,
        month: p.solarDate.month,
        day: p.solarDate.day,
        hourIndex: p.hourIndex >= 0 ? p.hourIndex : 6,
        isHourKnown: p.isHourKnown,
        cityIndex: 0,
        gender: p.gender,
      );
    } else {
      // 默认初始生辰配置：对应第15卦「地山谦」（上上卦 · 大吉 · 易经唯一六爻皆吉之卦）
      _astrolabeState = ConcentricAstrolabeState(
        year: 2000,
        month: 8,
        day: 11,
        hourIndex: widget.initialHourIndex ?? 6,
        isHourKnown: widget.initialHourIndex != null ? true : true,
        cityIndex: 0,
        gender: '乾 (男)',
      );
    }

    _calculateRealtime(isInitial: true);
  }

  void _calculateRealtime({bool isInitial = false}) {
    final city = ConcentricAstrolabeWheel.cities[_astrolabeState.cityIndex];
    final double longitude = (city['lon'] as num).toDouble();
    final String cityName = city['name'] as String;

    final bazi = BaZiEngine.calculate(
      solarDate: _astrolabeState.solarDate,
      hourIndex: _astrolabeState.hourIndex,
      isHourKnown: _astrolabeState.isHourKnown,
      longitude: longitude,
    );

    _currentResult = IChingCalculator.calculateHexagrams(
      name: '',
      gender: _astrolabeState.gender,
      solarDate: _astrolabeState.solarDate,
      hourIndex: _astrolabeState.hourIndex,
      isHourKnown: _astrolabeState.isHourKnown,
      repository: IChingRepository.instance,
      bazi: bazi,
      birthCity: cityName,
      longitude: longitude,
    );

    final newHexId = _currentResult.mainHexagram.id;
    if (!isInitial && newHexId != _previousHexagramId) {
      _isTransitionForward = newHexId > _previousHexagramId;
    }
    _previousHexagramId = newHexId;
  }

  void _onAstrolabeChanged(ConcentricAstrolabeState newState) {
    setState(() {
      _astrolabeState = newState;
      _calculateRealtime();
    });
  }

  void _onOpenResultPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DivinationResultPage(result: _currentResult),
      ),
    );
  }

  void _onSetPrimary(BuildContext context, UserProfile p) {
    ProfileRepository.instance.setPrimaryProfileId(p.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将「${p.name}」设为主生辰并置顶'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.jadeGreen
            : AppTheme.lightJadeGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onDeleteProfile(BuildContext context, UserProfile p) async {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cinnabar = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.cinnabarRed
        : AppTheme.lightCinnabarRed;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: charcoal,
        title: Text('删除档案', style: TextStyle(color: textPrimary)),
        content: Text('确定要删除「${p.name}」的排盘档案吗？', style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: cinnabar)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ProfileRepository.instance.deleteProfile(p.id);
    }
  }

  Future<void> _showLoadFromArchiveModal() async {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);
    final gold = AppTheme.getGoldColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: ProfileRepository.instance,
          builder: (sheetContext, _) {
            final profiles = ProfileRepository.instance.profiles;
            final primaryId = ProfileRepository.instance.primaryProfileId;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '从亲友命簿载入生辰',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '向左滑动卡片可删除或设为主生辰',
                            style: TextStyle(fontSize: 11, color: AppTheme.getTextMuted(context)),
                          ),
                        ],
                      ),
                      if (profiles.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${profiles.length} 位亲友',
                            style: TextStyle(fontSize: 11, color: gold, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (profiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 40, color: AppTheme.getTextMuted(context)),
                          const SizedBox(height: 10),
                          Text(
                            '命簿暂无记录',
                            style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '排盘后点击右上角星形按钮存入亲友档案',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.getTextMuted(context)),
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.52,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        itemBuilder: (sheetContext, index) {
                          final p = profiles[index];
                          final bool isPrimary = (primaryId == p.id) || (primaryId == null && index == 0);

                          return SlidableArchiveCard(
                            key: ValueKey(p.id),
                            profile: p,
                            isPrimary: isPrimary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              int resolvedCityIndex = _astrolabeState.cityIndex;
                              if (p.birthCity != null) {
                                final idx = ConcentricAstrolabeWheel.cities.indexWhere(
                                  (c) => c['name'] == p.birthCity || c['short'] == p.birthCity,
                                );
                                if (idx != -1) resolvedCityIndex = idx;
                              }

                              setState(() {
                                _astrolabeState = ConcentricAstrolabeState(
                                  year: p.solarDate.year,
                                  month: p.solarDate.month,
                                  day: p.solarDate.day,
                                  hourIndex: p.hourIndex >= 0 ? p.hourIndex : 6,
                                  isHourKnown: p.isHourKnown,
                                  cityIndex: resolvedCityIndex,
                                  gender: p.gender,
                                );
                                _calculateRealtime();
                              });
                            },
                            onSetPrimary: () => _onSetPrimary(context, p),
                            onDelete: () => _onDeleteProfile(context, p),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 支持在卦象卡片上手势左右滑动切换日期/卦象
  void _onCardHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      // 向左滑 -> 日期+1天
      final nextDate = _astrolabeState.solarDate.add(const Duration(days: 1));
      setState(() {
        _isTransitionForward = true;
        _astrolabeState = _astrolabeState.copyWith(
          year: nextDate.year,
          month: nextDate.month,
          day: nextDate.day,
        );
        _calculateRealtime();
      });
    } else if (velocity > 300) {
      // 向右滑 -> 日期-1天
      final prevDate = _astrolabeState.solarDate.subtract(const Duration(days: 1));
      setState(() {
        _isTransitionForward = false;
        _astrolabeState = _astrolabeState.copyWith(
          year: prevDate.year,
          month: prevDate.month,
          day: prevDate.day,
        );
        _calculateRealtime();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchedHexagram = _currentResult.mainHexagram;
    final bazi = _currentResult.bazi;
    final tierColor = AppTheme.getTierColor(context, matchedHexagram.fortuneTier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('易经本命推算 · 浑天罗盘'),
        actions: [
          ListenableBuilder(
            listenable: ProfileRepository.instance,
            builder: (context, _) {
              final profiles = ProfileRepository.instance.profiles;
              if (profiles.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.people_outline, color: AppTheme.getGoldColor(context)),
                tooltip: '从命簿载入生辰',
                onPressed: _showLoadFromArchiveModal,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),

              // 1. 顶部：优雅左右切换动画的卦象卡片舞台
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onHorizontalDragEnd: _onCardHorizontalSwipe,
                  child: SizedBox(
                    height: 185,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final isIncoming = (child.key as ValueKey<int>).value == matchedHexagram.id;

                        final inOffset = Tween<Offset>(
                          begin: Offset(_isTransitionForward ? 0.38 : -0.38, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ));

                        final outOffset = Tween<Offset>(
                          begin: Offset(_isTransitionForward ? -0.38 : 0.38, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInCubic,
                        ));

                        final scale = Tween<double>(begin: 0.93, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        );

                        return SlideTransition(
                          position: isIncoming ? inOffset : outOffset,
                          child: ScaleTransition(
                            scale: scale,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(matchedHexagram.id),
                        child: _buildHexagramCard(matchedHexagram),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 2. 中部：四柱八字乾坤盘天干地支条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.getCardShadow(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPillarChip('年柱', bazi.yearGanZhi, bazi.yearNaYin),
                          _buildPillarChip('月柱', bazi.monthGanZhi, bazi.monthNaYin),
                          _buildPillarChip('日柱', bazi.dayGanZhi, bazi.dayNaYin),
                          _buildPillarChip(
                            '时柱',
                            bazi.isHourKnown ? bazi.hourGanZhi : '未知',
                            bazi.isHourKnown ? bazi.hourNaYin : '元神',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tierColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_astrolabeState.year}年${_astrolabeState.month}月${_astrolabeState.day}日 · ${_astrolabeState.isHourKnown ? BaZiEngine.pureShichenNames[_astrolabeState.hourIndex] : "时辰未知"}',
                                style: TextStyle(fontSize: 11, color: AppTheme.getTextPrimary(context)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _astrolabeState.isHourKnown
                                  ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen).withValues(alpha: 0.15)
                                  : (Theme.of(context).brightness == Brightness.dark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _astrolabeState.isHourKnown ? '四柱完备 · 100%精研' : '三柱元神 · 75%精度',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _astrolabeState.isHourKnown
                                    ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen)
                                    : (Theme.of(context).brightness == Brightness.dark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. 核心：浑天同心多环罗盘
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RepaintBoundary(
                  child: ConcentricAstrolabeWheel(
                    initialState: _astrolabeState,
                    onChanged: _onAstrolabeChanged,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. 底部核心操作按钮（宽度与文字长度保持一致）
              Center(
                child: ElevatedButton(
                  onPressed: _onOpenResultPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getGoldColor(context),
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.inkBlack : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 2,
                  ),
                  child: const Text(
                    '命盘详批',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHexagramCard(HexagramDetail hexagram) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierColor = AppTheme.getTierColor(context, hexagram.fortuneTier);

    return GestureDetector(
      onTap: _onOpenResultPage,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.getGlowShadow(context, tierColor, alpha: 0.16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 顶部：吉凶等第徽章与当前本命卦标签
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hexagram.fortuneTier,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '第${hexagram.id}卦',
                      style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.getGoldColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '当前本命卦',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.inkBlack : Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // 中部：六爻图形 + 卦名与卦辞概览
            Row(
              children: [
                _buildGuaLines(hexagram.code),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hexagram.name,
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hexagram.guaci,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.getTextSecondary(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 底部：五行属性与等第总评
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '上${hexagram.upperTrigram}下${hexagram.lowerTrigram} · 五行属${hexagram.element}',
                  style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                ),
                Text(
                  hexagram.fortuneDesc,
                  style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaLines(String binaryCode) {
    final gold = AppTheme.getGoldColor(context);
    final lines = binaryCode.split('');

    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      decoration: BoxDecoration(
        color: AppTheme.getCharcoalColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: lines.reversed.map((bit) {
          if (bit == '1') {
            // 阳爻：连贯实线
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 1.4),
              height: 3.5,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          } else {
            // 阴爻：两段断开虚线
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 1.4),
              height: 3.5,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildPillarChip(String label, String ganZhi, String naYin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getCharcoalColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 2),
          Text(
            ganZhi,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            naYin,
            style: TextStyle(fontSize: 9.5, color: AppTheme.getGoldColor(context)),
          ),
        ],
      ),
    );
  }
}
