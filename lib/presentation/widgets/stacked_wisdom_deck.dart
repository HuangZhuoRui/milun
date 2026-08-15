import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/hexagram_detail.dart';
import '../theme/app_theme.dart';

/// 易学典籍卡片数据模型
class WisdomCardItem {
  final String volume; // 卷号，如 '卷一'
  final String title; // 主标题，如 '东方人格'
  final String subtitle; // 维度副标，如 '性格底色与潜能'
  final String content; // 详批文案
  final String? advice; // 处世锦囊
  final bool isClassic; // 是否为周易原典
  final HexagramDetail? hexagram;

  const WisdomCardItem({
    required this.volume,
    required this.title,
    required this.subtitle,
    required this.content,
    this.advice,
    this.isClassic = false,
    this.hexagram,
  });
}

/// 空间层级变换状态
class _CardTransform {
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double darkScrim;

  const _CardTransform({
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.darkScrim,
  });

  /// 根据阶梯层级计算变换参数（step 0 为顶层活跃卡片，step 1 为次级扇形，step 2 为深层扇形，step 3 为背景预备层）
  static _CardTransform forStep(double step) {
    final s = step.clamp(0.0, 3.5);
    return _CardTransform(
      x: s * 14.0,
      y: -s * 12.0,
      scale: 1.0 - (s * 0.05).clamp(0.0, 0.18),
      rotation: s * (3.0 * math.pi / 180.0),
      darkScrim: (s * 0.14).clamp(0.0, 0.45),
    );
  }
}

/// 东方易学典籍 · 极简连续物理洗牌切牌卡片堆组件（深浅色自适应）
class StackedWisdomDeck extends StatefulWidget {
  final List<WisdomCardItem> items;
  final double cardHeight;

  const StackedWisdomDeck({
    super.key,
    required this.items,
    this.cardHeight = 440,
  });

  @override
  State<StackedWisdomDeck> createState() => _StackedWisdomDeckState();
}

class _StackedWisdomDeckState extends State<StackedWisdomDeck>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  bool _isAnimating = false;

  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 切换到目标卷宗
  void _shuffleTo(int targetIndex) {
    if (_isAnimating || targetIndex == _currentIndex) return;
    final total = widget.items.length;
    if (total == 0) return;

    final isNext = (targetIndex > _currentIndex && !(targetIndex == total - 1 && _currentIndex == 0)) ||
        (_currentIndex == total - 1 && targetIndex == 0);

    // 下一张朝左滑出 (-360)，上一张从左覆入 (+360)
    final targetOffset = isNext ? -360.0 : 360.0;

    _isAnimating = true;
    _slideAnimation = Tween<double>(begin: _dragOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _slideAnimation.value;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = targetIndex % total;
        _dragOffset = 0.0;
        _isAnimating = false;
      });
    });
  }

  /// 手势拖拽水平位移更新
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.primaryDelta!;
    });
  }

  /// 手势结束判定（左滑切下一张，右滑覆回上一张）
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;
    const threshold = 55.0;
    final total = widget.items.length;

    if (_dragOffset < -threshold || velocity < -400) {
      // 向左滑出 -> 切换到下一卷
      final nextIndex = (_currentIndex + 1) % total;
      _animateComplete(targetOffset: -380.0, onComplete: () {
        setState(() {
          _currentIndex = nextIndex;
          _dragOffset = 0.0;
        });
      });
    } else if (_dragOffset > threshold || velocity > 400) {
      // 向右覆入 -> 切换到上一卷（上一张盖上来，下层退一张）
      final prevIndex = (_currentIndex - 1 + total) % total;
      _animateComplete(targetOffset: 380.0, onComplete: () {
        setState(() {
          _currentIndex = prevIndex;
          _dragOffset = 0.0;
        });
      });
    } else {
      // 距离未达阈值 -> 平滑弹性归位
      _animateSpringBack();
    }
  }

  /// 执行切牌完成动画
  void _animateComplete({required double targetOffset, required VoidCallback onComplete}) {
    _isAnimating = true;

    _slideAnimation = Tween<double>(begin: _dragOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _slideAnimation.value;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      HapticFeedback.lightImpact();
      onComplete();
      setState(() {
        _isAnimating = false;
      });
    });
  }

  /// 归位弹性动画
  void _animateSpringBack() {
    _isAnimating = true;
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {
          _dragOffset = _slideAnimation.value;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    if (total == 0) return const SizedBox.shrink();

    // 预留顶部与右侧扇形展开空间
    const double topFanOutSpace = 24.0;
    const double rightFanOutSpace = 28.0;
    final double containerHeight = widget.cardHeight + topFanOutSpace;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20 + rightFanOutSpace),
      child: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: SizedBox(
          height: containerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomLeft,
            children: _buildContinuousStack(total),
          ),
        ),
      ),
    );
  }

  /// 构建数学严格连续的卡片堆叠
  List<Widget> _buildContinuousStack(int total) {
    final double progress = -_dragOffset / 320.0;
    final bool isNext = progress >= 0;
    final double p = progress.abs().clamp(0.0, 1.2);

    final widgets = <Widget>[];

    if (isNext) {
      // 场景 A：向左滑动（下一张）
      if (total >= 4) {
        final double step = (3.0 - p).clamp(2.0, 3.0);
        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex + 3) % total],
            index: (_currentIndex + 3) % total,
            total: total,
            transform: _CardTransform.forStep(step),
            opacity: p.clamp(0.0, 1.0),
            isInteractive: false,
          ),
        );
      }

      if (total >= 3) {
        final double step = (2.0 - p).clamp(1.0, 2.0);
        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex + 2) % total],
            index: (_currentIndex + 2) % total,
            total: total,
            transform: _CardTransform.forStep(step),
            opacity: 1.0,
            isInteractive: false,
          ),
        );
      }

      if (total >= 2) {
        final double step = (1.0 - p).clamp(0.0, 1.0);
        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex + 1) % total],
            index: (_currentIndex + 1) % total,
            total: total,
            transform: _CardTransform.forStep(step),
            opacity: 1.0,
            isInteractive: false,
          ),
        );
      }

      final double clampedP = p.clamp(0.0, 1.0);
      final double swingProgress = math.sin(clampedP * math.pi);
      final double swingX = -clampedP * 380.0;
      final double swingY = swingProgress * 30.0;
      final double swingRot = -clampedP * 0.14 - (swingProgress * 0.08);
      final double fadeOut = (1.0 - (p - 0.5) / 0.5).clamp(0.0, 1.0);

      widgets.add(
        _buildCardContainer(
          item: widget.items[_currentIndex],
          index: _currentIndex,
          total: total,
          transform: _CardTransform(
            x: swingX,
            y: swingY,
            scale: 1.0,
            rotation: swingRot,
            darkScrim: 0.0,
          ),
          opacity: p > 0.5 ? fadeOut : 1.0,
          isInteractive: p < 0.2,
        ),
      );
    } else {
      // 场景 B：向右滑动（上一张）
      if (total >= 3) {
        final double step = (2.0 + p).clamp(2.0, 3.0);
        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex + 2) % total],
            index: (_currentIndex + 2) % total,
            total: total,
            transform: _CardTransform.forStep(step),
            opacity: (1.0 - p).clamp(0.0, 1.0),
            isInteractive: false,
          ),
        );
      }

      if (total >= 2) {
        final double step = (1.0 + p).clamp(1.0, 2.0);
        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex + 1) % total],
            index: (_currentIndex + 1) % total,
            total: total,
            transform: _CardTransform.forStep(step),
            opacity: 1.0,
            isInteractive: false,
          ),
        );
      }

      final double step = p.clamp(0.0, 1.0);
      widgets.add(
        _buildCardContainer(
          item: widget.items[_currentIndex],
          index: _currentIndex,
          total: total,
          transform: _CardTransform.forStep(step),
          opacity: 1.0,
          isInteractive: false,
        ),
      );

      if (total >= 2) {
        final double clampedP = p.clamp(0.0, 1.0);
        final double inX = -(1.0 - clampedP) * 380.0;
        final double inY = (1.0 - clampedP) * 16.0;
        final double inRot = -(1.0 - clampedP) * 0.12;

        widgets.add(
          _buildCardContainer(
            item: widget.items[(_currentIndex - 1 + total) % total],
            index: (_currentIndex - 1 + total) % total,
            total: total,
            transform: _CardTransform(
              x: inX,
              y: inY,
              scale: 1.0,
              rotation: inRot,
              darkScrim: 0.0,
            ),
            opacity: 1.0,
            isInteractive: true,
          ),
        );
      }
    }

    return widgets;
  }

  /// 核心卡片容器：实色卡底 + 表面暗光蒙层（深浅色自适应）
  Widget _buildCardContainer({
    required WisdomCardItem item,
    required int index,
    required int total,
    required _CardTransform transform,
    required double opacity,
    required bool isInteractive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getCardColor(context);

    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      height: widget.cardHeight,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(transform.x, transform.y),
          child: Transform.rotate(
            angle: transform.rotation,
            alignment: Alignment.bottomLeft,
            child: Transform.scale(
              scale: transform.scale,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: isInteractive ? null : () => _shuffleTo(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                        blurRadius: isDark ? 16 : 12,
                        offset: const Offset(0, 6),
                      ),
                      if (transform.darkScrim < 0.05)
                        BoxShadow(
                          color: AppTheme.getGoldColor(context).withValues(alpha: isDark ? 0.06 : 0.08),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // 卡片完整正文主体
                        _buildCardBody(item, index, total, isInteractive: isInteractive),

                        // 表面蒙层（制造景深感）
                        if (transform.darkScrim > 0.01)
                          Positioned.fill(
                            child: Container(
                              color: isDark
                                  ? Colors.black.withValues(alpha: transform.darkScrim)
                                  : Colors.white.withValues(alpha: transform.darkScrim * 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 卡片完整视觉主体（内嵌标题区与正文排版）
  Widget _buildCardBody(
    WisdomCardItem item,
    int index,
    int total, {
    required bool isInteractive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 卡片内嵌精美标题栏
          _buildInnerHeader(item, index, total),

          const SizedBox(height: 10),

          // 细分隔线
          Container(
            height: 0.6,
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.4),
          ),

          const SizedBox(height: 12),

          // 2. 卡片内正文精修区域
          Expanded(
            child: item.isClassic && item.hexagram != null
                ? _buildClassicContent(item.hexagram!, isInteractive: isInteractive)
                : _buildTextContent(item, isInteractive: isInteractive),
          ),
        ],
      ),
    );
  }

  /// 卡片内嵌标题栏（典籍书卷风范）
  Widget _buildInnerHeader(WisdomCardItem item, int index, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 卷号与主标题
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.volume} · ${item.title}',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getGoldColor(context),
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 右上角极简卷宗索引微标
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppTheme.getCharcoalColor(context),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${index + 1} / $total',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }

  /// 绘制现代洞察正文（严谨古雅排版）
  Widget _buildTextContent(WisdomCardItem item, {required bool isInteractive}) {
    return SingleChildScrollView(
      physics: isInteractive ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 正文段落
          Text(
            item.content,
            style: TextStyle(
              fontSize: 14.5,
              color: AppTheme.getTextPrimary(context),
              height: 1.76,
              letterSpacing: 0.35,
            ),
          ),

          // 处世锦囊引用框
          if (item.advice != null && item.advice!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getCharcoalColor(context),
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(color: AppTheme.getGoldColor(context), width: 3.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '【处世锦囊】',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getGoldColor(context),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.advice!,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.getTextPrimary(context),
                      height: 1.58,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// 绘制周易原典卦辞、彖象与六爻精释（专业古籍排版）
  Widget _buildClassicContent(HexagramDetail hex, {required bool isInteractive}) {
    return SingleChildScrollView(
      physics: isInteractive ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassicBlock('【卦辞】', hex.guaci, isMain: true),
          const SizedBox(height: 14),
          _buildClassicBlock('【彖传】', hex.tuan),
          const SizedBox(height: 14),
          _buildClassicBlock('【大象传】', hex.xiang),
          const SizedBox(height: 18),

          // 六爻爻辞全览
          Text(
            '【六爻爻辞全览】',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getGoldColor(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...hex.yaos.reversed.map((y) {
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.getCharcoalColor(context),
                borderRadius: BorderRadius.circular(6),
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
                          color: y.isYang ? AppTheme.getGoldColor(context) : AppTheme.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        y.isYang ? '阳爻 (—)' : '阴爻 (--)',
                        style: TextStyle(fontSize: 10.5, color: AppTheme.getTextMuted(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    y.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.getTextPrimary(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    y.xiang,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.getTextSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildClassicBlock(String title, String content, {bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMain ? 13.5 : 12.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.getGoldColor(context),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: TextStyle(
            fontSize: isMain ? 14.5 : 13.5,
            color: isMain ? AppTheme.getTextPrimary(context) : AppTheme.getTextSecondary(context),
            height: isMain ? 1.62 : 1.55,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
