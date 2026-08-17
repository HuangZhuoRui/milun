import 'package:flutter/material.dart';
import '../../../core/calendar/bazi_engine.dart';
import '../../../core/iching/iching_calculator.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/iching_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/slidable_archive_card.dart';
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
