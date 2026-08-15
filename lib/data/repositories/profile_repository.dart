import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// 亲友命簿档案数据仓库（单例模式，响应式唯一数据源 Single Source of Truth）
class ProfileRepository extends ChangeNotifier {
  static const String _storageKey = 'whoami_user_profiles_v1';
  static const String _primaryProfileKey = 'whoami_primary_profile_id_v1';

  static ProfileRepository? _instance;
  static ProfileRepository get instance => _instance ??= ProfileRepository._();

  ProfileRepository._();

  List<UserProfile> _profiles = [];
  String? _primaryProfileId;
  bool _isInitialized = false;

  /// 是否已完成本地持久化数据初始化
  bool get isInitialized => _isInitialized;

  /// 内存中只读的完整亲友档案列表（主生辰固定置顶在首位，其余档案按时间排序）
  List<UserProfile> get profiles {
    if (_profiles.isEmpty) return const [];
    if (_primaryProfileId == null) return List.unmodifiable(_profiles);

    final primaryIndex = _profiles.indexWhere((p) => p.id == _primaryProfileId);
    if (primaryIndex <= 0) return List.unmodifiable(_profiles);

    final sorted = List<UserProfile>.from(_profiles);
    final primary = sorted.removeAt(primaryIndex);
    sorted.insert(0, primary);
    return List.unmodifiable(sorted);
  }

  /// 当前设定的主生日档案 ID
  String? get primaryProfileId => _primaryProfileId;

  /// 同步获取当前主生日档案（若未设定则默认返回首个档案，若无档案则返回 null）
  UserProfile? get primaryProfile {
    if (_profiles.isEmpty) return null;
    if (_primaryProfileId != null) {
      final found = _profiles.where((p) => p.id == _primaryProfileId);
      if (found.isNotEmpty) return found.first;
    }
    return _profiles.first;
  }

  /// 异步初始化加载本地 SharedPreferences 档案库
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _primaryProfileId = prefs.getString(_primaryProfileKey);

      String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
        _profiles = list
            .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _profiles = [];
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      _profiles = [];
    }
  }

  /// 异步获取所有已保存的命盘档案（如未初始化则先初始化）
  Future<List<UserProfile>> getAllProfiles() async {
    if (!_isInitialized) {
      await init();
    }
    return profiles;
  }

  /// 获取当前设定的主生日档案（如未初始化则先初始化）
  Future<UserProfile?> getPrimaryProfile() async {
    if (!_isInitialized) {
      await init();
    }
    return primaryProfile;
  }

  /// 判断指定信息是否已在亲友命簿中收藏（通过 ID 或姓名+生辰+时辰精准比对）
  bool isProfileSaved({
    String? id,
    String? name,
    DateTime? solarDate,
    int? hourIndex,
  }) {
    if (id != null) {
      return _profiles.any((p) => p.id == id);
    }
    if (name != null && solarDate != null) {
      return _profiles.any((p) =>
          p.name == name &&
          p.solarDate.year == solarDate.year &&
          p.solarDate.month == solarDate.month &&
          p.solarDate.day == solarDate.day &&
          (hourIndex == null || p.hourIndex == hourIndex));
    }
    return false;
  }

  /// 保存或更新命盘档案
  /// 内存状态立即更新并即时通知所有监听组件，磁盘异步写入
  Future<void> saveProfile(UserProfile profile) async {
    int existingIndex = _profiles.indexWhere((p) => p.id == profile.id);
    if (existingIndex >= 0) {
      _profiles[existingIndex] = profile;
    } else {
      // 检查是否已有相同姓名与生辰的记录，如有则更新其内容，否则新增
      int matchIdx = _profiles.indexWhere((p) =>
          p.name == profile.name &&
          p.solarDate.year == profile.solarDate.year &&
          p.solarDate.month == profile.solarDate.month &&
          p.solarDate.day == profile.solarDate.day &&
          p.hourIndex == profile.hourIndex);
      if (matchIdx >= 0) {
        _profiles[matchIdx] = profile;
      } else {
        _profiles.insert(0, profile);
      }
    }

    // 仅在此前从未设定过主档案时，才将首个档案设为主档案；已有主生辰不被后续新增顶替
    _primaryProfileId ??= profile.id;

    // 立即通知全应用所有依赖组件即时刷新！
    notifyListeners();

    // 异步持久化存储
    try {
      final prefs = await SharedPreferences.getInstance();
      String encoded = json.encode(_profiles.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      if (_primaryProfileId != null) {
        await prefs.setString(_primaryProfileKey, _primaryProfileId!);
      }
    } catch (_) {}
  }

  /// 根据 ID 删除指定的命盘档案
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    if (_primaryProfileId == id) {
      _primaryProfileId = _profiles.isNotEmpty ? _profiles.first.id : null;
    }

    // 立即通知全应用所有依赖组件即时刷新！
    notifyListeners();

    // 异步持久化存储
    try {
      final prefs = await SharedPreferences.getInstance();
      String encoded = json.encode(_profiles.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      if (_primaryProfileId != null) {
        await prefs.setString(_primaryProfileKey, _primaryProfileId!);
      } else {
        await prefs.remove(_primaryProfileKey);
      }
    } catch (_) {}
  }

  /// 设置指定的档案为主生日档案（手动设为主生辰，且固定在首位）
  Future<void> setPrimaryProfileId(String id) async {
    if (_primaryProfileId == id) return;
    _primaryProfileId = id;

    // 立即通知全应用所有依赖组件即时刷新！
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryProfileKey, id);
    } catch (_) {}
  }

  /// 测试用重置或注入方法
  void loadFromList(List<UserProfile> list, {String? primaryId}) {
    _profiles = List.from(list);
    _primaryProfileId = primaryId ?? (_profiles.isNotEmpty ? _profiles.first.id : null);
    _isInitialized = true;
    notifyListeners();
  }
}
