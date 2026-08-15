import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/updater/app_updater_service.dart';
import '../../theme/app_theme.dart';

/// 雅秋立体光影风格 · 应用内安装包下载与安装弹窗
class DownloadProgressDialog extends StatefulWidget {
  final String directUrl;
  final String tagName;
  final bool useProxy;

  const DownloadProgressDialog({
    super.key,
    required this.directUrl,
    required this.tagName,
    required this.useProxy,
  });

  static Future<void> show(
    BuildContext context, {
    required String directUrl,
    required String tagName,
    required bool useProxy,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DownloadProgressDialog(
        directUrl: directUrl,
        tagName: tagName,
        useProxy: useProxy,
      ),
    );
  }

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  DownloadProgress _progress = const DownloadProgress(
    receivedBytes: 0,
    totalBytes: 0,
    progress: 0.0,
    speedBytesPerSec: 0,
    status: 'downloading',
  );

  File? _downloadedFile;
  String? _errorMessage;
  bool _isUserCancelled = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isUserCancelled = false;
      _errorMessage = null;
      _downloadedFile = null;
      _progress = const DownloadProgress(
        receivedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        speedBytesPerSec: 0,
        status: 'downloading',
      );
    });

    final targetUrl = widget.useProxy
        ? AppUpdaterService.instance.getAcceleratedDownloadUrl(widget.directUrl)
        : widget.directUrl;

    final fileName = 'milun_${widget.tagName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.apk';

    try {
      final file = await AppUpdaterService.instance.downloadReleaseApk(
        downloadUrl: targetUrl,
        fileName: fileName,
        onProgress: (p) {
          if (mounted && !_isUserCancelled) {
            setState(() {
              _progress = p;
            });
          }
        },
      );

      if (mounted && file != null && !_isUserCancelled) {
        setState(() {
          _downloadedFile = file;
        });
      }
    } catch (e) {
      if (mounted && !_isUserCancelled) {
        setState(() {
          _errorMessage = '下载失败: $e';
        });
      }
    }
  }

  void _onCancel() {
    _isUserCancelled = true;
    AppUpdaterService.instance.cancelDownload();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onInstall() {
    if (_downloadedFile != null) {
      AppUpdaterService.instance.installApk(_downloadedFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final cardBg = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    final isCompleted = _progress.status == 'completed' && _downloadedFile != null;
    final isFailed = _progress.status == 'failed' || _errorMessage != null;

    return PopScope(
      canPop: isCompleted || isFailed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isCompleted && !isFailed) {
          _onCancel();
        }
      },
      child: Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏与通道 Badge
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : (isFailed ? Icons.error_rounded : Icons.downloading_rounded),
                    color: isCompleted ? jade : (isFailed ? cinnabar : gold),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isCompleted
                          ? '安装包下载完成'
                          : (isFailed ? '下载失败' : '正在下载新版本'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (widget.useProxy ? gold : textSecondary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.useProxy ? '🚀 代理加速' : '🌐 官方直连',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.useProxy ? gold : textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 进度条与数据
              if (!isCompleted && !isFailed) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress.totalBytes > 0 ? _progress.progress : null,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFE8E0D2),
                    valueColor: AlwaysStoppedAnimation<Color>(gold),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _progress.totalBytes > 0
                          ? '${_progress.formattedReceived} / ${_progress.formattedTotal} (${_progress.percentage}%)'
                          : '已接收 ${_progress.formattedReceived}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    if (_progress.speedBytesPerSec > 0)
                      Text(
                        '⚡ ${_progress.formattedSpeed}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: gold,
                        ),
                      ),
                  ],
                ),
              ],

              // 下载完成提示
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: jade.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: jade.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded, color: jade, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'APK 安装包已就绪 (${_progress.formattedTotal})，点击下方按钮立即安装升级。',
                          style: TextStyle(fontSize: 12, color: textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 失败提示
              if (isFailed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cinnabar.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cinnabar.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: cinnabar, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? '下载中断，请检查网络连接后重试。',
                          style: TextStyle(fontSize: 12, color: cinnabar, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 底部操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isCompleted && !isFailed) ...[
                    TextButton(
                      onPressed: _onCancel,
                      child: Text('取消下载', style: TextStyle(color: textSecondary)),
                    ),
                  ] else if (isFailed) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('关闭', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _startDownload,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('重试下载'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ] else if (isCompleted) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('稍后安装', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _onInstall,
                      icon: const Icon(Icons.system_security_update_rounded, size: 16),
                      label: const Text('立即安装', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
