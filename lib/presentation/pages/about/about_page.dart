import 'package:flutter/material.dart';
import '../../../core/updater/app_updater_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deepseek_whale_icon.dart';
import '../ai/ai_settings_dialog.dart';
import 'update_history_page.dart';

/// 雅秋立体光影风格 · 弥纶关于与设置页面
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _openAiSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AiSettingsDialog(),
    );
  }

  void _openUpdateHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;

    final currentVer = 'v${AppUpdaterService.currentAppVersion}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 90
                : 100,
          ),
          children: [
            // 1. 顶部纯文字品牌 Header（已移除顶部图标）
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '弥纶 · MiLun',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '《周易·系辞》“易与天地准，故能弥纶天地之道”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gold.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: Text(
                      '当前版本: $currentVer',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: gold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. 系统设置与更新入口 Card
            _buildSectionTitle(context, '系统与功能配置'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.getCardShadow(context),
              ),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      leading: const Padding(
                        padding: EdgeInsets.all(4),
                        child: DeepSeekWhaleIcon(size: 24),
                      ),
                      title: Text(
                        'DeepSeek 认知智能配置',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      subtitle: Text(
                        '配置 API Key、自适应模型与深度思考 (Thinking Mode)',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold),
                      onTap: () => _openAiSettings(context),
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE8E0D2)),
                    ListTile(
                      leading: Icon(Icons.system_update_alt_rounded, color: gold, size: 22),
                      title: Text(
                        '软件更新',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      subtitle: Text(
                        '检查新版本与浏览历史更新',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold),
                      onTap: () => _openUpdateHistory(context),
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE8E0D2)),
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                      ),
                      leading: Icon(Icons.security_rounded, color: jade, size: 22),
                      title: Text(
                        '本地数理与隐私保障',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      subtitle: Text(
                        '干支、八字与易经六十四卦全离线推演，私钥手机端加密存储',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 3. 关于与文化说明 Card
            _buildSectionTitle(context, '易理哲学与设计'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.getCardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '五维时空卦象体系',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '本命卦立足当下根基，互卦洞察内在动机，变卦预测未来走向，错卦反观对立盲区，综卦换位破除困局。五维一体，全息映射人生轨迹。',
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '雅秋 (Autumn Grace) 美学',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '融合东方宣纸与墨黑古金，以温润的弥散阴影与立体悬浮造型，替代扁平机械的生硬边框，构筑宁静沉浸的易道参详意境。',
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. 开源致谢与版权
            Center(
              child: Column(
                children: [
                  Text(
                    '开源仓库: github.com/HuangZhuoRui/milun',
                    style: TextStyle(fontSize: 11, color: AppTheme.getTextMuted(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 弥纶 · 基于 MIT License 开源发布',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.getTextMuted(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final textSecondary = AppTheme.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textSecondary,
        ),
      ),
    );
  }
}
