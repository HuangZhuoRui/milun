import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// GitHub Release 实体模型
class GitHubRelease {
  final int id;
  final String tagName;
  final String name;
  final String body;
  final String publishedAt;
  final List<GitHubAsset> assets;

  const GitHubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'] as List<dynamic>? ?? [];
    return GitHubRelease(
      id: json['id'] as int? ?? 0,
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      assets: rawAssets
          .map((a) => GitHubAsset.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 获取 Android APK 下载链接（优先返回 .apk 文件）
  String? get androidDownloadUrl {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) {
        return asset.browserDownloadUrl;
      }
    }
    return null;
  }

  /// 获取 APK 文件名与大小
  GitHubAsset? get androidAsset {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) {
        return asset;
      }
    }
    return null;
  }
}

/// GitHub Release 附件模型
class GitHubAsset {
  final int id;
  final String name;
  final int size;
  final String browserDownloadUrl;

  const GitHubAsset({
    required this.id,
    required this.name,
    required this.size,
    required this.browserDownloadUrl,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
    );
  }

  /// 文件大小格式化为 MB
  String get formattedSize {
    if (size <= 0) return '';
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// 下载进度实时状态模型
class DownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final double progress; // 0.0 ~ 1.0
  final double speedBytesPerSec;
  final String status; // 'downloading', 'completed', 'failed', 'canceled'

  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this.speedBytesPerSec,
    required this.status,
  });

  String get formattedReceived => _formatBytes(receivedBytes);
  String get formattedTotal => _formatBytes(totalBytes);
  String get formattedSpeed => '${_formatBytes(speedBytesPerSec.toInt())}/s';
  int get percentage => (progress * 100).clamp(0, 100).toInt();

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 应用版本更新与自建服务器加速服务
class AppUpdaterService {
  AppUpdaterService._();
  static final AppUpdaterService instance = AppUpdaterService._();

  /// 当前应用版本号
  static const String currentAppVersion = '1.0.0';
  static const String currentBuildNumber = '1';

  /// 自建加速代理基础域名
  static const String _accelerateBaseUrl = 'https://update.vincenthzr.org:8443';

  HttpClient? _currentDownloadClient;
  bool _isDownloading = false;
  bool _isCancelled = false;
  bool get isDownloading => _isDownloading;
  bool get isCancelled => _isCancelled;

  /// 取消当前下载
  void cancelDownload() {
    _isCancelled = true;
    _isDownloading = false;
    try {
      _currentDownloadClient?.close(force: true);
    } catch (_) {}
    _currentDownloadClient = null;
  }

  /// 在应用内直接流式下载 Release APK 并实时上报进度
  Future<File?> downloadReleaseApk({
    required String downloadUrl,
    required String fileName,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    _isDownloading = true;
    _isCancelled = false;
    final client = HttpClient();
    _currentDownloadClient = client;
    client.badCertificateCallback = (cert, host, port) => true;

    File? targetFile;

    try {
      final dir = await getTemporaryDirectory();
      final safeFileName = fileName.endsWith('.apk') ? fileName : '$fileName.apk';
      targetFile = File('${dir.path}/$safeFileName');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set('User-Agent', 'MiLun-App/1.0');
      request.headers.set('Accept', 'application/octet-stream');

      final response = await request.close();
      if (response.statusCode != 200 && response.statusCode != 302 && response.statusCode != 301) {
        throw Exception('下载失败，HTTP状态码: ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      final sink = targetFile.openWrite();
      int receivedBytes = 0;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in response) {
        if (_isCancelled || !_isDownloading) {
          await sink.close();
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          return null;
        }

        receivedBytes += chunk.length;
        sink.add(chunk);

        final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
        final speed = elapsedSec > 0 ? (receivedBytes / elapsedSec) : 0.0;
        final progressRatio = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;

        onProgress(DownloadProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          progress: progressRatio,
          speedBytesPerSec: speed,
          status: 'downloading',
        ));
      }

      await sink.flush();
      await sink.close();

      if (_isCancelled || !_isDownloading) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        return null;
      }

      onProgress(DownloadProgress(
        receivedBytes: receivedBytes,
        totalBytes: receivedBytes,
        progress: 1.0,
        speedBytesPerSec: 0,
        status: 'completed',
      ));

      _isDownloading = false;
      return targetFile;
    } catch (e) {
      if (_isCancelled) {
        try {
          if (targetFile != null && await targetFile.exists()) {
            await targetFile.delete();
          }
        } catch (_) {}
        return null;
      }

      _isDownloading = false;
      onProgress(const DownloadProgress(
        receivedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        speedBytesPerSec: 0,
        status: 'failed',
      ));
      rethrow;
    } finally {
      client.close();
      if (_currentDownloadClient == client) {
        _currentDownloadClient = null;
      }
    }
  }

  /// 调起系统安装器安装 APK
  Future<void> installApk(File apkFile) async {
    try {
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('调起安装程序结果: ${result.type} - ${result.message}');
    } catch (e) {
      debugPrint('调起安装程序失败: $e');
    }
  }

  /// 获取仓库的所有 Releases（优先使用自建加速接口，失败则自动直连 GitHub）
  Future<List<GitHubRelease>> fetchReleases({
    String owner = 'HuangZhuoRui',
    String repo = 'milun',
  }) async {
    // 1. 尝试自建加速节点
    try {
      final proxyUrl = Uri.parse('$_accelerateBaseUrl/api/$repo/releases');
      final releases = await _requestReleases(proxyUrl);
      if (releases != null && releases.isNotEmpty) {
        return releases;
      }
    } catch (e) {
      debugPrint('自建加速节点请求失败，尝试直连 GitHub: $e');
    }

    // 2. 优雅降级直连 GitHub 官方接口
    try {
      final githubUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');
      final releases = await _requestReleases(githubUrl);
      if (releases != null) {
        return releases;
      }
    } catch (e) {
      debugPrint('直连 GitHub API 请求失败: $e');
    }

    return [];
  }

  Future<List<GitHubRelease>?> _requestReleases(Uri uri) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MiLun-App/1.0');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> jsonList = jsonDecode(responseBody) as List<dynamic>;
        return jsonList
            .map((item) => GitHubRelease.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// 构建自建服务器加速下载链接
  String getAcceleratedDownloadUrl(String directUrl) {
    if (directUrl.isEmpty) return directUrl;

    const githubPrefix = 'https://github.com/';
    if (directUrl.startsWith(githubPrefix)) {
      final relativePath = directUrl.substring(githubPrefix.length);
      return '$_accelerateBaseUrl/download/$relativePath';
    }

    return directUrl;
  }

  /// 判断最新版本是否高于当前版本
  bool isNewerVersion(String latestTagName, String currentVer) {
    try {
      final cleanLatest = _cleanVersion(latestTagName);
      final cleanCurrent = _cleanVersion(currentVer);

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final length = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      for (int i = 0; i < length; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _cleanVersion(String v) {
    String res = v.trim().toLowerCase();
    if (res.startsWith('v')) {
      res = res.substring(1);
    }
    final plusIndex = res.indexOf('+');
    if (plusIndex != -1) {
      res = res.substring(0, plusIndex);
    }
    final hyphenIndex = res.indexOf('-');
    if (hyphenIndex != -1) {
      res = res.substring(0, hyphenIndex);
    }
    return res;
  }
}
