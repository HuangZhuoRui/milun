import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../core/updater/app_updater_service.dart';
import '../../theme/app_theme.dart';
import 'download_progress_dialog.dart';

/// 更新日志结构化解析模型
class ParsedChangelog {
  final List<String> features;
  final List<String> fixes;
  final List<String> others;

  const ParsedChangelog({
    required this.features,
    required this.fixes,
    required this.others,
  });

  bool get hasCategorized => features.isNotEmpty || fixes.isNotEmpty;

  static ParsedChangelog parse(String rawBody) {
    final List<String> features = [];
    final List<String> fixes = [];
    final List<String> others = [];

    final lines = rawBody.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      String content = line;
      if (content.startsWith('- ') || content.startsWith('* ')) {
        content = content.substring(2).trim();
      }

      final lower = content.toLowerCase();
      if (lower.startsWith('tmp:') || lower.startsWith('tmp：') || lower.startsWith('tmp ') ||
          lower.startsWith('temp:') || lower.startsWith('temp：') || lower.startsWith('temp ')) {
        continue;
      }

      if (lower.startsWith('feat:') || lower.startsWith('feat：')) {
        features.add(content.substring(5).trim());
      } else if (lower.startsWith('feat ')) {
        features.add(content.substring(5).trim());
      } else if (lower.startsWith('feature:') || lower.startsWith('feature ')) {
        features.add(content.substring(lower.indexOf('feature') + 7).trim());
      } else if (lower.startsWith('fix:') || lower.startsWith('fix：')) {
        fixes.add(content.substring(4).trim());
      } else if (lower.startsWith('fix ')) {
        fixes.add(content.substring(4).trim());
      } else if (lower.startsWith('bugfix:') || lower.startsWith('bugfix ')) {
        fixes.add(content.substring(lower.indexOf('bugfix') + 6).trim());
      } else if (content.isNotEmpty) {
        others.add(content);
      }
    }

    return ParsedChangelog(
      features: features,
      fixes: fixes,
      others: others,
    );
  }
}

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

  void _onDownload({
    required String directUrl,
    required String tagName,
    required bool useProxy,
  }) {
    DownloadProgressDialog.show(
      context,
      directUrl: directUrl,
      tagName: tagName,
      useProxy: useProxy,
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

  String _formatReleaseName(String tagName) {
    String cleanTag = tagName.trim();
    if (cleanTag.startsWith('android-')) {
      cleanTag = cleanTag.substring(8);
    }
    if (!cleanTag.startsWith('v') && !cleanTag.startsWith('V')) {
      cleanTag = 'v$cleanTag';
    }
    return '弥纶 $cleanTag';
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

    final currentVer = 'v${AppUpdaterService.currentAppVersion}';

    final latestRelease = _releases.isNotEmpty ? _releases.first : null;
    final bool hasNewer = latestRelease != null &&
        AppUpdaterService.instance.isNewerVersion(
          latestRelease.tagName,
          AppUpdaterService.currentAppVersion,
        );

    final historyReleases = hasNewer ? _releases.sublist(1) : _releases;

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
          '软件更新',
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
            // 1. 当前版本卡片
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
                              '当前版本',
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

            // 错误提示
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
              ),

            // 2. 新版本卡片（当发现新版时置顶呈现）
            if (hasNewer) ...[
              _buildSectionHeader(context, '新版本'),
              const SizedBox(height: 8),
              _buildReleaseCard(
                context,
                release: latestRelease,
                isNewVersionHighlight: true,
              ),
              const SizedBox(height: 16),
            ] else if (_releases.isNotEmpty && _errorMessage == null) ...[
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
                      '当前已是最新版本',
                      style: TextStyle(fontSize: 12.5, color: jade, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            // 3. 历史更新列表
            _buildSectionHeader(context, '历史更新'),
            const SizedBox(height: 8),

            if (_isLoading && _releases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: gold),
                      const SizedBox(height: 12),
                      Text(
                        '正在获取更新日志...',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (historyReleases.isEmpty && _errorMessage == null)
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
                      '暂无历史更新记录',
                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击上方「检查更新」按钮获取发布日志',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(historyReleases.length, (index) {
                final release = historyReleases[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReleaseCard(
                    context,
                    release: release,
                    isNewVersionHighlight: false,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textSecondary = AppTheme.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _buildReleaseCard(
    BuildContext context, {
    required GitHubRelease release,
    required bool isNewVersionHighlight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    final parsedNotes = ParsedChangelog.parse(release.body);
    final title = _formatReleaseName(release.tagName);

    return Container(
      decoration: BoxDecoration(
        color: isNewVersionHighlight ? gold.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(18),
        border: isNewVersionHighlight
            ? Border.all(color: gold.withValues(alpha: 0.35), width: 1.2)
            : null,
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
              // 标题与发布日期
              Row(
                children: [
                  Icon(
                    isNewVersionHighlight ? Icons.new_releases_rounded : Icons.history_edu_rounded,
                    color: gold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  if (isNewVersionHighlight) ...[
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

              const SizedBox(height: 12),

              // 分类解析与 Markdown 渲染
              if (parsedNotes.hasCategorized) ...[
                // 1. 功能更新
                if (parsedNotes.features.isNotEmpty) ...[
                  _buildCategoryBadge(
                    icon: Icons.auto_awesome_rounded,
                    label: '功能更新',
                    color: jade,
                  ),
                  const SizedBox(height: 6),
                  _buildMarkdownContent(
                    context,
                    parsedNotes.features.map((f) => '- $f').join('\n'),
                  ),
                  const SizedBox(height: 10),
                ],

                // 2. 问题修复
                if (parsedNotes.fixes.isNotEmpty) ...[
                  _buildCategoryBadge(
                    icon: Icons.build_circle_rounded,
                    label: '问题修复',
                    color: cinnabar,
                  ),
                  const SizedBox(height: 6),
                  _buildMarkdownContent(
                    context,
                    parsedNotes.fixes.map((f) => '- $f').join('\n'),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. 其他优化
                if (parsedNotes.others.isNotEmpty) ...[
                  _buildCategoryBadge(
                    icon: Icons.tune_rounded,
                    label: '其他优化',
                    color: textSecondary,
                  ),
                  const SizedBox(height: 6),
                  _buildMarkdownContent(
                    context,
                    parsedNotes.others.map((f) => '- $f').join('\n'),
                  ),
                  const SizedBox(height: 8),
                ],
              ] else if (release.body.isNotEmpty) ...[
                // 未识别到前缀时直接完整 Markdown 渲染
                _buildMarkdownContent(context, release.body),
                const SizedBox(height: 8),
              ],

              // 双选项下载按钮：代理加速下载 + 正常直连下载
              if (release.androidDownloadUrl != null) ...[
                const SizedBox(height: 6),
                if (isNewVersionHighlight)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onDownload(
                            directUrl: release.androidDownloadUrl!,
                            tagName: release.tagName,
                            useProxy: true,
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                          label: Text(
                            '代理加速下载 ${release.androidAsset != null ? "(${release.androidAsset!.formattedSize})" : ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onDownload(
                            directUrl: release.androidDownloadUrl!,
                            tagName: release.tagName,
                            useProxy: false,
                          ),
                          icon: Icon(Icons.public_rounded, size: 15, color: gold),
                          label: const Text(
                            '正常直连下载',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: gold,
                            side: BorderSide(color: gold.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _onDownload(
                          directUrl: release.androidDownloadUrl!,
                          tagName: release.tagName,
                          useProxy: false,
                        ),
                        icon: Icon(Icons.public_rounded, size: 13, color: textSecondary),
                        label: Text('正常下载', style: TextStyle(fontSize: 11, color: textSecondary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _onDownload(
                          directUrl: release.androidDownloadUrl!,
                          tagName: release.tagName,
                          useProxy: true,
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 13),
                        label: Text(
                          '加速下载 ${release.androidAsset != null ? "(${release.androidAsset!.formattedSize})" : ""}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, String markdownData) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final gold = AppTheme.getGoldColor(context);

    return MarkdownBody(
      data: markdownData,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 12.5,
          color: textPrimary,
          height: 1.45,
        ),
        listBullet: TextStyle(
          fontSize: 12.5,
          color: gold,
          fontWeight: FontWeight.bold,
        ),
        strong: TextStyle(
          fontSize: 12.5,
          color: gold,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          fontSize: 11.5,
          color: gold,
          backgroundColor: textSecondary.withValues(alpha: 0.08),
          fontFamily: 'monospace',
        ),
        blockquote: TextStyle(
          fontSize: 12,
          color: textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
