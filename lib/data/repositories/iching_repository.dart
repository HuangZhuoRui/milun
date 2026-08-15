import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/hexagram_detail.dart';

/// 易经六十四卦数据仓库（单例模式）
class IChingRepository {
  static IChingRepository? _instance;
  static IChingRepository get instance => _instance ??= IChingRepository._();

  IChingRepository._();

  List<HexagramDetail> _hexagrams = [];
  final Map<int, HexagramDetail> _byId = {};
  final Map<String, HexagramDetail> _byCode = {};
  final Map<String, HexagramDetail> _byTrigrams = {}; // 格式："上卦-下卦" 例如 "乾-坤" -> 否卦

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// 获取只读的完整六十四卦列表
  List<HexagramDetail> get allHexagrams => List.unmodifiable(_hexagrams);

  /// 异步加载 assets 目录下的六十四卦 JSON 知识库
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      String jsonStr = await rootBundle.loadString('assets/data/iching_64.json');
      List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      _hexagrams = list.map((e) => HexagramDetail.fromJson(e as Map<String, dynamic>)).toList();

      for (var h in _hexagrams) {
        _byId[h.id] = h;
        _byCode[h.code] = h;
        _byTrigrams['${h.upperTrigram}-${h.lowerTrigram}'] = h;
      }
      _isLoaded = true;
    } catch (e) {
      // 容错处理：用于在无资源包环境（如轻量级单元测试）中进行数据兜底
      _isLoaded = false;
    }
  }

  /// 手动注入卦象数据（主要用于单元测试与调试）
  void loadFromList(List<HexagramDetail> list) {
    _hexagrams = list;
    _byId.clear();
    _byCode.clear();
    _byTrigrams.clear();
    for (var h in _hexagrams) {
      _byId[h.id] = h;
      _byCode[h.code] = h;
      _byTrigrams['${h.upperTrigram}-${h.lowerTrigram}'] = h;
    }
    _isLoaded = true;
  }

  static const HexagramDetail fallbackHexagram = HexagramDetail(
    id: 15,
    name: '地山谦',
    code: '001000',
    upperTrigram: '坤',
    lowerTrigram: '艮',
    element: '土',
    fortuneTier: '上上卦',
    fortuneDesc: '谦和 · 尊而光大',
    guaci: '谦：亨，君子有终。',
    tuan: '谦，亨。',
    xiang: '地中有山，谦。',
    overview: '谦卦象征谦逊虚怀。',
    personality: '虚怀若谷。',
    career: '事业蒸蒸日上。',
    wealth: '财运源远流长。',
    love: '相敬如宾。',
    health: '身心康泰。',
    advice: '谦尊而光。',
    yaos: [],
  );

  /// 根据卦象序号 (1..64) 获取卦象详情
  HexagramDetail getById(int id) {
    if (_hexagrams.isEmpty) return fallbackHexagram;
    return _byId[id] ?? _hexagrams.first;
  }

  /// 根据 6 位二进制卦码（初爻至上爻）查找卦象
  HexagramDetail? getByCode(String code) {
    if (_hexagrams.isEmpty) return fallbackHexagram;
    return _byCode[code] ?? fallbackHexagram;
  }

  /// 根据上下卦名称获取卦象
  HexagramDetail? getByTrigrams(String upper, String lower) {
    if (_hexagrams.isEmpty) return fallbackHexagram;
    return _byTrigrams['$upper-$lower'] ?? fallbackHexagram;
  }

  /// 模糊搜索卦象（支持卦名、上下卦、五行、卦辞、总览关键词）
  List<HexagramDetail> search(String keyword) {
    if (keyword.trim().isEmpty) return allHexagrams;
    String query = keyword.trim().toLowerCase();
    return _hexagrams.where((h) {
      return h.name.toLowerCase().contains(query) ||
          h.upperTrigram.contains(query) ||
          h.lowerTrigram.contains(query) ||
          h.element.contains(query) ||
          h.guaci.contains(query) ||
          h.overview.contains(query);
    }).toList();
  }
}
