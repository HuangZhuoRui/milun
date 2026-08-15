import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/updater/app_updater_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deepseek_whale_icon.dart';
import '../ai/ai_settings_dialog.dart';

/// 雅秋立体光影风格 · 弥纶关于与设置页面
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isCheckingUpdate = false;
  String? _updateError;
  List<GitHubRelease>? _releases;
  bool _hasChecked = false;

  Future<void> _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateError = null;
    });

    try {
      final list = await AppUpdaterService.instance.fetchReleases(
        owner: 'HuangZhuoRui',
        repo: 'milun',
      );

      setState(() {
        _releases = list;
        _hasChecked = true;
        _isCheckingUpdate = false;
      });
    } catch (e) {
      setState(() {
        _updateError = '检查更新失败: $e';
        _hasChecked = true;
        _isCheckingUpdate = false;
      });
    }
  }

  void _openAiSettings() {
    showDialog(
      context: context,
      builder: (ctx) => const AiSettingsDialog(),
    );
  }

  void _onDownloadNewVersion(String directUrl, String tagName) {
    final acceleratedUrl = AppUpdaterService.instance.getAcceleratedDownloadUrl(directUrl);

    Clipboard.setData(ClipboardData(text: acceleratedUrl));

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final gold = AppTheme.getGoldColor(ctx);
        final cardBg = AppTheme.getCardColor(ctx);
        final textPrimary = AppTheme.getTextPrimary(ctx);
        final textSecondary = AppTheme.getTextSecondary(ctx);

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: gold, size: 22),
              const SizedBox(width: 8),
              Text(
                '版本 $tagName 加速下载',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已为您生成自建高速节点镜像链接，并自动复制到剪贴板。您可在浏览器或下载工具中直接粘贴下载：',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF3EDE2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  acceleratedUrl,
                  style: TextStyle(fontSize: 11, color: gold, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('我知道了', style: TextStyle(color: gold)),
            ),
          ],
        );
      },
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
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    final currentVer = 'v${AppUpdaterService.currentAppVersion}+${AppUpdaterService.currentBuildNumber}';

    final latestRelease = (_releases != null && _releases!.isNotEmpty) ? _releases!.first : null;
    final bool hasNewer = latestRelease != null &&
        AppUpdaterService.instance.isNewerVersion(
          latestRelease.tagName,
          AppUpdaterService.currentAppVersion,
        );

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
            // 1. 品牌与徽标 Header
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: isDark ? 0.25 : 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: gold.withValues(alpha: isDark ? 0.35 : 0.25),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '弥',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: gold,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '弥纶 · MiLun',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '《周易·系辞》“易与天地准，故能弥纶天地之道”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Text(
                      '当前版本: $currentVer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: gold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. 核心功能配置 Card
            _buildSectionTitle(context, '系统配置'),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      onTap: _openAiSettings,
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE8E0D2)),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

            const SizedBox(height: 20),

            // 3. 检查更新 Card (带自建节点加速)
            _buildSectionTitle(context, '版本更新与发布'),
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
                  Row(
                    children: [
                      Icon(Icons.system_update_alt_rounded, color: gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '版本检查与加速分发',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isCheckingUpdate ? null : _checkUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isCheckingUpdate
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('检查更新', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_updateError != null) ...[
                    const SizedBox(height: 10),
                    Text(_updateError!, style: TextStyle(fontSize: 11.5, color: cinnabar)),
                  ],
                  if (_hasChecked && latestRelease != null) ...[
                    const SizedBox(height: 14),
                    if (hasNewer) ...[
                      // 发现新版本
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gold.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.new_releases_rounded, color: gold, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '发现新版本: ${latestRelease.tagName}',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: gold),
                                ),
                                if (latestRelease.androidAsset != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      '(${latestRelease.androidAsset!.formattedSize})',
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ),
                              ],
                            ),
                            if (latestRelease.body.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                latestRelease.body,
                                style: TextStyle(fontSize: 12, color: textPrimary, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 10),
                            if (latestRelease.androidDownloadUrl != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _onDownloadNewVersion(
                                    latestRelease.androidDownloadUrl!,
                                    latestRelease.tagName,
                                  ),
                                  icon: const Icon(Icons.speed_rounded, size: 16),
                                  label: const Text(
                                    '极速下载新版 (自建加速镜像)',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 已是最新版本
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: jade, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '当前已是最新版本，无需更新',
                            style: TextStyle(fontSize: 12.5, color: jade, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ] else if (!_hasChecked) ...[
                    const SizedBox(height: 6),
                    Text(
                      '支持直连 GitHub 与自建高速代理镜像节点，畅享秒级更新。',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. 关于与文化说明 Card
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

            const SizedBox(height: 20),

            // 5. 开源致谢与版权
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
