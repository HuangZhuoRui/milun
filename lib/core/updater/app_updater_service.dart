import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

/// 应用版本更新与自建服务器加速服务
class AppUpdaterService {
  AppUpdaterService._();
  static final AppUpdaterService instance = AppUpdaterService._();

  /// 当前应用版本号
  static const String currentAppVersion = '1.0.0';
  static const String currentBuildNumber = '1';

  /// 自建加速代理基础域名
  static const String _accelerateBaseUrl = 'https://update.vincenthzr.org:8443';

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
    // 允许自建服务的证书通过
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
  /// 将 https://github.com/HuangZhuoRui/milun/releases/download/...
  /// 转换为 https://update.vincenthzr.org:8443/download/HuangZhuoRui/milun/releases/download/...
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
