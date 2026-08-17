import 'package:flutter/material.dart';
import '../../../core/calendar/bazi_engine.dart';
import '../../../core/iching/iching_calculator.dart';
import '../../../data/models/daily_hexagram_result.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hexagram_painter.dart';
import '../../widgets/rotary_date_picker.dart';
import '../../widgets/stacked_wisdom_deck.dart';
import '../divination/divination_result_page.dart';

/// 今日专属本命流日运势推演看板页面
class DailyHexagramPage extends StatefulWidget {
  final VoidCallback? onNavigateToNatal;

  const DailyHexagramPage({super.key, this.onNavigateToNatal});

  @override
  State<DailyHexagramPage> createState() => _DailyHexagramPageState();
}

class _DailyHexagramPageState extends State<DailyHexagramPage> {
  DateTime _currentDate = DateTime.now();

  // 当前命主档案状态（默认为本人）
  UserProfile? _currentProfile;
  DateTime _birthDate = DateTime(1995, 8, 18);
  int _birthHourIndex = 6; // 默认午时
  String _profileName = '本命求测者';
  String _gender = '乾 (男)';
  String? _birthCity;
  double? _longitude;

  late DailyHexagramResult _dailyResult;

  @override
  void initState() {
    super.initState();
    ProfileRepository.instance.addListener(_onProfileRepositoryUpdated);
    _syncWithPrimaryProfile(isInitial: true);
  }

  @override
  void dispose() {
    ProfileRepository.instance.removeListener(_onProfileRepositoryUpdated);
    super.dispose();
  }

  void _onProfileRepositoryUpdated() {
    _syncWithPrimaryProfile();
  }

  void _syncWithPrimaryProfile({bool isInitial = false}) {
    final primary = ProfileRepository.instance.primaryProfile;
    if (primary != null) {
      _currentProfile = primary;
      _birthDate = primary.solarDate;
      _birthHourIndex = primary.isHourKnown ? primary.hourIndex : -1;
      _profileName = primary.name.isNotEmpty ? primary.name : '本命求测者';
      _gender = primary.gender;
      _birthCity = primary.birthCity;
      _longitude = primary.longitude;
    }
    if (isInitial) {
      _recalculateSync();
    } else if (mounted) {
      setState(() {
        _recalculateSync();
      });
    }
  }

  void _recalculateSync() {
    _dailyResult = IChingCalculator.calculatePersonalizedDailyHexagram(
      targetDate: _currentDate,
      birthDate: _birthDate,
      birthHourIndex: _birthHourIndex,
      profileName: _profileName,
      gender: _gender,
      birthCity: _birthCity,
      longitude: _longitude,
    );
  }

  void _recalculate() {
    setState(() {
      _recalculateSync();
    });
  }

  void _onPreviousDay() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
      _recalculate();
    });
  }

  void _onNextDay() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 1));
      _recalculate();
    });
  }

  void _onResetToToday() {
    setState(() {
      _currentDate = DateTime.now();
      _recalculate();
    });
  }

  Future<void> _onPickDate() async {
    final result = await RotaryDatePickerDialog.show(
      context,
      initialDate: _currentDate,
      initialIsHourKnown: false,
    );
    if (result != null && mounted) {
      setState(() {
        _currentDate = result.date;
        _recalculate();
      });
    }
  }

  Future<void> _showProfileSelectorModal() async {
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: ProfileRepository.instance,
          builder: (context, _) {
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
                      Text(
                        '切换测算命主生辰',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await RotaryDatePickerDialog.show(
                            context,
                            initialDate: _birthDate,
                            initialHourIndex: _birthHourIndex >= 0 ? _birthHourIndex : 6,
                            initialIsHourKnown: _birthHourIndex >= 0,
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _birthDate = result.date;
                              _birthHourIndex = result.isHourKnown ? result.hourIndex : -1;
                              _currentProfile = null;
                              _profileName = '自定生辰';
                              _recalculate();
                            });
                          }
                        },
                        icon: Icon(Icons.edit_calendar, size: 16, color: gold),
                        label: Text('自定生辰', style: TextStyle(color: gold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (profiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.getSubtleShadow(context),
                      ),
                      child: Text(
                        '当前使用默认生辰 (${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日)。在「亲友命簿」收藏档案后，可在此一键切换不同亲友的专属每日运势！',
                        style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          final bool isSelected = (primaryId == p.id) ||
                              (_currentProfile?.id == p.id) ||
                              (primaryId == null && index == 0);
                          String shichenText = p.isHourKnown && p.hourIndex >= 0
                              ? '${BaZiEngine.earthlyBranches[p.hourIndex]}时'
                              : '时辰不详';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? gold.withValues(alpha: 0.15)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? gold : textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.solarDate.year}年${p.solarDate.month}月${p.solarDate.day}日 · $shichenText · ${p.gender}',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: gold, size: 20)
                                    : null,
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  await ProfileRepository.instance.setPrimaryProfileId(p.id);
                                  navigator.pop();
                                },
                              ),
                            ),
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

  void _onOpenNatalDetails() {
    final bazi = BaZiEngine.calculate(
      solarDate: _birthDate,
      hourIndex: _birthHourIndex,
      isHourKnown: _birthHourIndex >= 0,
      longitude: _longitude,
    );
    final result = IChingCalculator.calculateHexagrams(
      name: _profileName,
      gender: _gender,
      solarDate: _birthDate,
      hourIndex: _birthHourIndex,
      isHourKnown: _birthHourIndex >= 0,
      repository: IChingRepository.instance,
      bazi: bazi,
      birthCity: _birthCity,
      longitude: _longitude,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DivinationResultPage(result: result)),
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _currentDate.year == now.year &&
        _currentDate.month == now.month &&
        _currentDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;
    final r = _dailyResult;
    final tierColor = AppTheme.getTierColor(context, r.todayNatalHexagram.fortuneTier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日专属流日卦'),
        actions: [
          if (!_isToday)
            TextButton.icon(
              onPressed: _onResetToToday,
              icon: Icon(Icons.today, size: 16, color: gold),
              label: Text('回今日', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: gold),
            tooltip: '日晷选日',
            onPressed: _onPickDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          children: [
            // 1. 顶部命主身份与本命卦基座卡片（支持切换生辰档案）
            InkWell(
              onTap: _showProfileSelectorModal,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: charcoal,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.getSubtleShadow(context),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gold.withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _profileName.isNotEmpty ? _profileName.substring(0, 1) : '命',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _profileName,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '本命卦 · ${r.birthMainHexagram.name}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日 · ${_birthCity != null ? "$_birthCity · " : ""}日元${r.dayMasterElement}行 · 本命体卦',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '切换 >',
                      style: TextStyle(fontSize: 12, color: gold, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // 2. 目标流日公历与农历时间横幅
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: textSecondary, size: 22),
                    onPressed: _onPreviousDay,
                    visualDensity: VisualDensity.compact,
                    tooltip: '前一日',
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _onPickDate,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                '${_currentDate.year}年${_currentDate.month}月${_currentDate.day}日',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: gold.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '今日流日',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: gold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.lunarString} · ${r.solarTerm}',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: textSecondary, size: 22),
                    onPressed: _onNextDay,
                    visualDensity: VisualDensity.compact,
                    tooltip: '后一日',
                  ),
                ],
              ),
            ),

            // 3. 今日专属本命流日运势核心卡片
            Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 运势总览与吉凶评分徽章
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '【本命与天时交感 · 今日专属卦】',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.fortuneLevel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: tierColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${r.fortuneScore}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '运势指数',
                                style: TextStyle(fontSize: 9, color: gold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 卦象图样与详细演变
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        HexagramWidget(
                          code: r.todayNatalHexagram.code,
                          changingYaoIndex: r.changingYaoIndex,
                          width: 76,
                          height: 98,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '第${r.todayNatalHexagram.id}卦 · ${r.todayNatalHexagram.name}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                r.todayNatalHexagram.fortuneDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tierColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '上卦: ${r.todayNatalHexagram.upperTrigram} · 下卦: ${r.todayNatalHexagram.lowerTrigram} · 五行: ${r.todayNatalHexagram.element}行',
                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cinnabar.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '今日破局动爻: 第${r.changingYaoIndex}爻 · 变卦: ${r.transformedHexagram.name}',
                                  style: TextStyle(fontSize: 10.5, color: cinnabar, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 体用生克权衡阐释
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: charcoal,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppTheme.getSubtleShadow(context),
                      ),
                      child: Text(
                        r.energyRelation,
                        style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. 今日行事宜忌罗盘（今日所宜 & 今日所忌）
            Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '【流日吉凶 · 行事宜忌指南】',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: gold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),

                    // 今日所宜 (Auspicious)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: jade.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '宜',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: jade),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: r.yiList.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: jade.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textPaperWhite : AppTheme.lightTextPrimary, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 今日所忌 (Taboo)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: cinnabar.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '忌',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cinnabar),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: r.jiList.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cinnabar.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textPaperWhite : AppTheme.lightTextPrimary, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 5. 五维运势能量指标条
            Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '【五维运势 · 能量指标全览】',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: gold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),
                    ...r.fortuneAspects.entries.map((entry) {
                      double progress = entry.value / 100.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 68,
                              child: Text(
                                entry.key,
                                style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: charcoal,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    entry.value >= 88
                                        ? gold
                                        : (entry.value >= 78 ? jade : cinnabar),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${entry.value}分',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: gold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 6. 今日动爻破局点（若有动爻）
            if (r.changingYao != null)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cinnabar.withValues(alpha: 0.4), width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: cinnabar),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '今日转折机微 · 【${r.changingYao!.name}】动爻',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cinnabar),
                              ),
                            ],
                          ),
                          Text(
                            '吉凶系于一动',
                            style: TextStyle(fontSize: 11, color: cinnabar.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.changingYao!.text,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.changingYao!.xiang,
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: charcoal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '【破局关键指南】\n${r.changingYao!.interpretation}',
                          style: TextStyle(fontSize: 12, color: textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. 底部 3D 洗牌切牌文案典籍大观（今日专属事功/财富/心境/原典）
            StackedWisdomDeck(
              items: [
                WisdomCardItem(
                  volume: '卷一',
                  title: '今日事功',
                  subtitle: '职场与关键决策指引',
                  content: r.careerGuidance,
                  advice: r.todayNatalHexagram.advice,
                ),
                WisdomCardItem(
                  volume: '卷二',
                  title: '求财运筹',
                  subtitle: '投资与消费心态策略',
                  content: r.wealthGuidance,
                ),
                WisdomCardItem(
                  volume: '卷三',
                  title: '心境调和',
                  subtitle: '情志与身心养护调摄',
                  content: r.mindGuidance,
                ),
                WisdomCardItem(
                  volume: '卷四',
                  title: '周易箴言',
                  subtitle: '今日原典白话精释',
                  content: '',
                  isClassic: true,
                  hexagram: r.todayNatalHexagram,
                ),
              ],
              cardHeight: 440,
            ),

            const SizedBox(height: 16),

            // 8. 底部本命排盘详批与全息盘入口
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onOpenNatalDetails,
                      icon: Icon(Icons.auto_stories, size: 16, color: gold),
                      label: Text('查看本命盘详批', style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: gold.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (widget.onNavigateToNatal != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onNavigateToNatal,
                        icon: Icon(Icons.explore, size: 16, color: isDark ? AppTheme.inkBlack : Colors.white),
                        label: Text('重排本命盘', style: TextStyle(color: isDark ? AppTheme.inkBlack : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
