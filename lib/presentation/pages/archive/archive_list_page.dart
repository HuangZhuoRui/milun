import 'package:flutter/material.dart';
import '../../../core/calendar/bazi_engine.dart';
import '../../../core/iching/iching_calculator.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../divination/divination_input_page.dart';
import '../divination/divination_result_page.dart';

/// 亲友八字命簿列表页面（响应式直连 ProfileRepository 唯一数据源）
class ArchiveListPage extends StatelessWidget {
  const ArchiveListPage({super.key});

  void _onCalculateProfile(BuildContext context, UserProfile p) {
    final bazi = BaZiEngine.calculate(
      solarDate: p.solarDate,
      hourIndex: p.hourIndex,
      isHourKnown: p.isHourKnown,
      longitude: p.longitude,
    );

    final result = IChingCalculator.calculateHexagrams(
      name: p.name,
      gender: p.gender,
      solarDate: p.solarDate,
      hourIndex: p.hourIndex,
      isHourKnown: p.isHourKnown,
      repository: IChingRepository.instance,
      bazi: bazi,
      birthCity: p.birthCity,
      longitude: p.longitude,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DivinationResultPage(result: result),
      ),
    );
  }

  void _onSetPrimary(BuildContext context, UserProfile p) {
    // 设为主生辰不需要确认，即刻生效
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return ListenableBuilder(
      listenable: ProfileRepository.instance,
      builder: (context, _) {
        final profiles = ProfileRepository.instance.profiles;
        final primaryId = ProfileRepository.instance.primaryProfileId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('亲友八字命簿'),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: gold),
                tooltip: '新建排盘',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DivinationInputPage()),
                  );
                },
              ),
            ],
          ),
          body: profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppTheme.getTextMuted(context)),
                      const SizedBox(height: 16),
                      Text(
                        '命簿暂无记录',
                        style: TextStyle(fontSize: 16, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '排盘后点击右上角星形按钮即可存入亲友档案',
                        style: TextStyle(fontSize: 12, color: AppTheme.getTextMuted(context)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DivinationInputPage()),
                          );
                        },
                        icon: Icon(Icons.add, color: isDark ? AppTheme.inkBlack : Colors.white),
                        label: Text(
                          '添加新档案',
                          style: TextStyle(
                            color: isDark ? AppTheme.inkBlack : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final p = profiles[index];
                    final bool isPrimary = (primaryId == p.id) || (primaryId == null && index == 0);

                    return SlidableArchiveCard(
                      key: ValueKey(p.id),
                      profile: p,
                      isPrimary: isPrimary,
                      onTap: () => _onCalculateProfile(context, p),
                      onSetPrimary: () => _onSetPrimary(context, p),
                      onDelete: () => _onDeleteProfile(context, p),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// 支持向左滑动、雅致素净纯色调的亲友命簿卡片组件
class SlidableArchiveCard extends StatefulWidget {
  final UserProfile profile;
  final bool isPrimary;
  final VoidCallback onTap;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  const SlidableArchiveCard({
    super.key,
    required this.profile,
    required this.isPrimary,
    required this.onTap,
    required this.onSetPrimary,
    required this.onDelete,
  });

  @override
  State<SlidableArchiveCard> createState() => _SlidableArchiveCardState();
}

class _SlidableArchiveCardState extends State<SlidableArchiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;

  double get _maxExtent => widget.isPrimary ? 80.0 : 164.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(SlidableArchiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPrimary != widget.isPrimary || oldWidget.profile.id != widget.profile.id) {
      _controller.value = 0;
      _dragExtent = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragExtent -= delta;
      if (_dragExtent < 0) {
        _dragExtent = 0;
      } else if (_dragExtent > _maxExtent) {
        final over = _dragExtent - _maxExtent;
        _dragExtent = _maxExtent + over * 0.2;
      }
      _controller.value = (_dragExtent / _maxExtent).clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -260 || _dragExtent > _maxExtent * 0.38) {
      _open();
    } else {
      _close();
    }
  }

  void _open() {
    _controller.animateTo(1.0, duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
    _dragExtent = _maxExtent;
  }

  void _close() {
    _controller.animateTo(0.0, duration: const Duration(milliseconds: 180), curve: Curves.easeInCubic);
    _dragExtent = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final cardBg = AppTheme.getCardColor(context);
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    final p = widget.profile;
    final isPrimary = widget.isPrimary;
    final progress = _animation.value;
    final slideOffset = -progress * _maxExtent;

    String shichenText = p.isHourKnown && p.hourIndex >= 0
        ? '${BaZiEngine.earthlyBranches[p.hourIndex]}时'
        : '时辰不详';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: charcoal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.getSubtleShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // 1. 底层：雅秋素简·立体质感操作按钮
          Positioned(
            right: 10,
            top: 10,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPrimary) ...[
                  // 「设为主生辰」沉香雅金立体按钮
                  Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Material(
                      color: isDark ? const Color(0xFF262016) : const Color(0xFFF4ECE0),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _close();
                          widget.onSetPrimary();
                        },
                        child: Container(
                          width: 76,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withValues(alpha: isDark ? 0.15 : 0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: gold,
                                size: 20,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '设为主生辰',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // 「删除」深隐朱砂立体按钮
                Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: Material(
                    color: isDark ? const Color(0xFF281818) : const Color(0xFFF8EAEA),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _close();
                        widget.onDelete();
                      },
                      child: Container(
                        width: 66,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: cinnabar.withValues(alpha: isDark ? 0.15 : 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: cinnabar,
                              size: 20,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '删除',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: cinnabar,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 表层：雅致立体悬浮命盘卡片（告别生硬线框，温润光影）
          Transform.translate(
            offset: Offset(slideOffset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isPrimary
                      ? AppTheme.getGlowShadow(context, gold, alpha: 0.14)
                      : AppTheme.getCardShadow(context),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (_controller.value > 0.05) {
                        _close();
                      } else {
                        widget.onTap();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: isPrimary ? 0.18 : 0.08),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.name.isNotEmpty ? p.name.substring(0, 1) : '命',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        p.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isPrimary ? gold : textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: charcoal,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.gender,
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                    ),
                                    if (isPrimary) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: gold.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star, size: 10, color: gold),
                                            const SizedBox(width: 2),
                                            Text(
                                              '主生辰',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: gold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.solarDate.year}年${p.solarDate.month}月${p.solarDate.day}日 · $shichenText${p.birthCity != null ? " · ${p.birthCity}" : ""}',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                if (p.notes.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '备注：${p.notes}',
                                    style: TextStyle(fontSize: 11, color: AppTheme.getTextMuted(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // 提示滑动的素雅小箭头
                          Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.getTextMuted(context).withValues(alpha: 0.35),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
