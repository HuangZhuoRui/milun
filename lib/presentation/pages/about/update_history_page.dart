import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/updater/app_updater_service.dart';
import '../../theme/app_theme.dart';

/// 雅秋立体光影风格 · 软件更新与历史发布记录页面
class UpdateHistoryPage extends StatefulWidget {
  const UpdateHistoryPage({super.key});

  @override
  State<UpdateHistoryPage> createState() => _UpdateHistoryPageState();
}

class _UpdateHistoryPageState extends State<UpdateHistoryPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<GitHubRelease> _releases = [];

  @override
  void initState() {
    super.initState();
    _fetchReleases();
  }

  Future<void> _fetchReleases() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AppUpdaterService.instance.fetchReleases(
        owner: 'HuangZhuoRui',
        repo: 'milun',
      );

      setState(() {
        _releases = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取更新日志失败: $e';
        _isLoading = false;
      });
    }
  }

  void _onDownloadRelease(String directUrl, String tagName) {
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

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (_) {
      return isoString;
    }
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

    final latestRelease = _releases.isNotEmpty ? _releases.first : null;
    final bool hasNewer = latestRelease != null &&
        AppUpdaterService.instance.isNewerVersion(
          latestRelease.tagName,
          AppUpdaterService.currentAppVersion,
        );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.inkBlack : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '检查更新与历史',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReleases,
        color: gold,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // 1. 当前版本信息卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.getCardShadow(context),
              ),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified_rounded, color: gold, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '当前安装版本',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentVer,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _fetchReleases,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('检查更新', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. 状态提示条（发现新版 / 已是最新）
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cinnabar.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cinnabar.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: cinnabar, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: cinnabar)),
                    ),
                  ],
                ),
              )
            else if (_releases.isNotEmpty) ...[
              if (hasNewer)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gold.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.new_releases_rounded, color: gold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '发现新版本: ${latestRelease.tagName}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gold),
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
                          style: TextStyle(fontSize: 12, color: textPrimary, height: 1.45),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (latestRelease.androidDownloadUrl != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _onDownloadRelease(
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
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: jade.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: jade.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: jade, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '当前已是最新版本 ($currentVer)',
                        style: TextStyle(fontSize: 12.5, color: jade, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],

            // 3. 历史更新日志列表
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '版本发布记录与更新日志',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textSecondary,
                ),
              ),
            ),

            if (_isLoading && _releases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: gold),
                      const SizedBox(height: 12),
                      Text(
                        '正在获取版本发布记录...',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (_releases.isEmpty && _errorMessage == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.getCardShadow(context),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 36, color: gold.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      '暂无发布记录',
                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击上方「检查更新」按钮获取远端发布历史',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_releases.length, (index) {
                final release = _releases[index];
                final isLatest = index == 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.getCardShadow(context),
                  ),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                release.name.isNotEmpty ? release.name : release.tagName,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              if (isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: gold.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: gold.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    '最新',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: gold),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (release.publishedAt.isNotEmpty)
                                Text(
                                  _formatDate(release.publishedAt),
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                            ],
                          ),
                          if (release.body.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              release.body,
                              style: TextStyle(
                                fontSize: 12,
                                color: textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ],
                          if (release.androidDownloadUrl != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => _onDownloadRelease(
                                  release.androidDownloadUrl!,
                                  release.tagName,
                                ),
                                icon: Icon(Icons.download_rounded, size: 14, color: gold),
                                label: Text(
                                  '下载安装包 ${release.androidAsset != null ? "(${release.androidAsset!.formattedSize})" : ""}',
                                  style: TextStyle(fontSize: 11, color: gold, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: gold.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
