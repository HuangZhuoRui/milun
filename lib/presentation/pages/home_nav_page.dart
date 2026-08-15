import 'package:flutter/material.dart';
import '../widgets/ai_floating_button.dart';
import '../widgets/floating_nav_bar.dart';
import 'archive/archive_list_page.dart';
import 'daily/daily_hexagram_page.dart';
import 'dictionary/hexagram_dict_page.dart';
import 'divination/divination_input_page.dart';

/// 页面保活包装器，防止滑动切换时页面状态被销毁
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

/// 应用全局主导航容器页面（悬浮圆角导航栏 + 手势跟手流畅平滑切换）
class HomeNavPage extends StatefulWidget {
  final int initialTabIndex;

  const HomeNavPage({super.key, this.initialTabIndex = 0});

  @override
  State<HomeNavPage> createState() => _HomeNavPageState();
}

class _HomeNavPageState extends State<HomeNavPage> {
  late final PageController _pageController;
  late int _currentIndex;
  int? _preselectedHourIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 点击导航栏标签切换页面（支持跨页连续滑翔，不逐页停顿）
  void _onTabTapped(int targetIndex) {
    if (targetIndex == _currentIndex) return;
    final int distance = (targetIndex - _currentIndex).abs();
    // 动态计算多页平滑飞行时长：1页360ms，2页460ms，3页550ms
    final int durationMs = 270 + (distance * 90);

    _pageController.animateToPage(
      targetIndex,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _onNavigateToNatal() {
    _onTabTapped(1); // 切换至本命排盘标签页
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double floatingBottomMargin = bottomPadding > 0 ? bottomPadding + 6 : 14;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. 全局手势跟手左右切换 PageView
          PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              _KeepAliveWrapper(
                child: DailyHexagramPage(
                  onNavigateToNatal: _onNavigateToNatal,
                ),
              ),
              _KeepAliveWrapper(
                child: DivinationInputPage(
                  key: ValueKey(_preselectedHourIndex),
                  initialHourIndex: _preselectedHourIndex,
                ),
              ),
              const _KeepAliveWrapper(
                child: HexagramDictPage(),
              ),
              const _KeepAliveWrapper(
                child: ArchiveListPage(),
              ),
            ],
          ),

          // 2. AI 易学参详悬浮入口按钮
          Positioned(
            right: 16,
            bottom: floatingBottomMargin + 74,
            child: const AiFloatingButton(),
          ),

          // 3. 悬浮圆角导航栏（附带流体滑动指示浮标）
          Positioned(
            left: 16,
            right: 16,
            bottom: floatingBottomMargin,
            child: FloatingNavBar(
              controller: _pageController,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: const [
                FloatingNavItem(
                  icon: Icons.today_outlined,
                  activeIcon: Icons.today,
                  label: '今日卦象',
                ),
                FloatingNavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: '本命排盘',
                ),
                FloatingNavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: '易经宝典',
                ),
                FloatingNavItem(
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt,
                  label: '亲友命簿',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
