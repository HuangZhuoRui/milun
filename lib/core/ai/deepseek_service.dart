import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/calendar/bazi_engine.dart';
import '../../core/iching/iching_calculator.dart';
import '../../data/models/ai_chat_message.dart';
import '../../data/models/hexagram_detail.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/iching_repository.dart';

/// DeepSeek AI 流式事件分块
class AiStreamChunk {
  final String? content;
  final String? reasoningContent;
  final bool isDone;
  final String? error;

  const AiStreamChunk({
    this.content,
    this.reasoningContent,
    this.isDone = false,
    this.error,
  });
}

/// DeepSeek AI 易学参详服务引擎
class DeepSeekService {
  static final DeepSeekService instance = DeepSeekService._();
  DeepSeekService._();

  static const String _keyApiKey = 'deepseek_api_key';
  static const String _keyModel = 'deepseek_model';
  static const String _keyBaseUrl = 'deepseek_base_url';
  static const String _keyTemperature = 'deepseek_temperature';
  static const String _keyCachedModels = 'deepseek_cached_models';
  static const String _keyEnableThinking = 'deepseek_enable_thinking';

  static const String modelChat = 'deepseek-chat';
  static const String modelReasoner = 'deepseek-reasoner';
  static const String defaultModel = 'deepseek-v4-flash';

  String _apiKey = '';
  String _model = defaultModel;
  String _baseUrl = 'https://api.deepseek.com';
  double _temperature = 0.7;
  bool _enableThinking = true;

  List<String> _availableModels = [
    'deepseek-v4-flash',
    'deepseek-v4-pro',
    'deepseek-reasoner',
    'deepseek-chat',
  ];

  String get apiKey => _apiKey;
  String get model => _model;
  String get baseUrl => _baseUrl;
  double get temperature => _temperature;
  bool get enableThinking => _enableThinking;
  List<String> get availableModels => List.unmodifiable(_availableModels);
  bool get hasValidKey => _apiKey.trim().isNotEmpty;

  /// 初始化并从本地加载配置与官方模型列表缓存
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_keyApiKey) ?? '';
    _model = prefs.getString(_keyModel) ?? defaultModel;
    _baseUrl = prefs.getString(_keyBaseUrl) ?? 'https://api.deepseek.com';
    _temperature = prefs.getDouble(_keyTemperature) ?? 0.7;
    _enableThinking = prefs.getBool(_keyEnableThinking) ?? true;

    final cached = prefs.getStringList(_keyCachedModels);
    if (cached != null && cached.isNotEmpty) {
      _availableModels = cached;
    }
  }

  /// 保存基础设置
  Future<void> saveSettings({
    required String apiKey,
    required String baseUrl,
    required double temperature,
  }) async {
    _apiKey = apiKey.trim();
    _baseUrl = baseUrl.trim().isEmpty ? 'https://api.deepseek.com' : baseUrl.trim();
    _temperature = temperature;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, _apiKey);
    await prefs.setString(_keyBaseUrl, _baseUrl);
    await prefs.setDouble(_keyTemperature, _temperature);
  }

  /// 切换模型
  Future<void> setModel(String newModel) async {
    _model = newModel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModel, _model);
  }

  /// 开启或关闭深度思考模式（Thinking Mode）
  Future<void> setThinkingEnabled(bool enabled) async {
    _enableThinking = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableThinking, _enableThinking);
  }

  /// 从 DeepSeek 官方接口获取可用模型列表 (GET /models)
  Future<List<String>> fetchModels({
    String? apiKey,
    String? baseUrl,
  }) async {
    final keyToUse = apiKey?.trim() ?? _apiKey;
    final urlToUse = (baseUrl?.trim().isNotEmpty == true) ? baseUrl!.trim() : _baseUrl;

    if (keyToUse.isEmpty) {
      return _availableModels;
    }

    HttpClient? client;
    try {
      final endpoint = Uri.parse('$urlToUse/models');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(endpoint);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $keyToUse');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final respBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(respBody);
        final data = json['data'] as List?;
        if (data != null && data.isNotEmpty) {
          final List<String> fetched = [];
          for (final item in data) {
            if (item is Map && item['id'] != null) {
              fetched.add(item['id'].toString());
            }
          }

          if (fetched.isNotEmpty) {
            _availableModels = fetched;
            if (!_availableModels.contains(_model) && _availableModels.isNotEmpty) {
              _model = _availableModels.first;
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(_keyCachedModels, _availableModels);
            await prefs.setString(_keyModel, _model);
          }
        }
      }
    } catch (_) {
      // 保持当前模型列表
    } finally {
      client?.close();
    }
    return _availableModels;
  }

  /// 测试 API Key 连通性
  Future<Map<String, dynamic>> testConnection({
    String? apiKey,
    String? baseUrl,
  }) async {
    final keyToTest = apiKey?.trim() ?? _apiKey;
    final urlToTest = (baseUrl?.trim().isNotEmpty == true) ? baseUrl!.trim() : _baseUrl;

    if (keyToTest.isEmpty) {
      return {'success': false, 'message': 'API Key 不能为空'};
    }

    HttpClient? client;
    try {
      final endpoint = Uri.parse('$urlToTest/chat/completions');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final request = await client.postUrl(endpoint);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $keyToTest');

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': '1'}
        ],
        'thinking': {'type': 'disabled'},
        'stream': false,
        'max_tokens': 5,
      });

      request.write(body);
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        fetchModels(apiKey: keyToTest, baseUrl: urlToTest);
        return {'success': true, 'message': '连接成功！DeepSeek API 验证通过'};
      } else {
        String errDetail = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(respBody);
          if (errJson['error'] != null && errJson['error']['message'] != null) {
            errDetail = errJson['error']['message'];
          }
        } catch (_) {
          errDetail = respBody;
        }
        return {'success': false, 'message': '验证失败: $errDetail'};
      }
    } catch (e) {
      return {'success': false, 'message': '网络连接异常: $e'};
    } finally {
      client?.close();
    }
  }

  /// 精炼、关键的系统提示词（避免过度冗长导致思考链冗余）
  String buildSystemPrompt() {
    return '''你是一位精通《周易》与传统四柱干支五行学的国学易理大师。

【研判准则】
1. 依据文王六十四卦与孔子《十翼》义理，结合大衍筮法天地之数演算逻辑。
2. 卦象全息维度：
   - 【本卦】：命主先天基调与本质性格。
   - 【互卦】：内在机变与发展阶段。
   - 【变卦】：事态趋向与转化结果。
   - 【错卦/综卦】：反观镜鉴与逆向解法。
3. 体用生克：无动爻为体，有动爻为用，结合日元五行生克权衡。若有多人合盘，分析双方日元与本命卦的生克合化。

【输出要求】
- 语言雅致精练，文白相融，重点突出，兼顾易理深度与现代实际行动指南。
- 使用规范 Markdown 排版（适当使用加粗、各级标题、引用块和列表，增强阅读层次）。''';
  }

  /// 紧凑精炼的数据载荷（仅提供核心必要数据，避免思考链爆炸）
  String buildUserDataPayload({
    required UserProfile primaryProfile,
    required DivinationResult primaryResult,
    List<UserProfile> comparedProfiles = const [],
    List<DivinationResult> comparedResults = const [],
    required String userQuestion,
  }) {
    final buffer = StringBuffer();

    // 1. 核心命主关键信息
    buffer.writeln('【核心命主 / 本人 (主生辰)】:');
    buffer.writeln('- 姓名: ${primaryProfile.name} | 性别: ${primaryProfile.gender}');
    buffer.writeln('- 四柱: ${primaryResult.bazi.yearGanZhi}(${primaryResult.bazi.yearNaYin}) ${primaryResult.bazi.monthGanZhi}(${primaryResult.bazi.monthNaYin}) ${primaryResult.bazi.dayGanZhi}(${primaryResult.bazi.dayNaYin}) ${primaryResult.bazi.hourGanZhi}(${primaryResult.bazi.hourNaYin})');
    buffer.writeln('- 日元: ${primaryResult.bazi.dayMaster} (${primaryResult.bazi.dayMasterElement}) | 五行分布: ${primaryResult.bazi.fiveElementsCount}');
    buffer.writeln('- 本命卦: 第${primaryResult.mainHexagram.id}卦·${primaryResult.mainHexagram.name} (${primaryResult.mainHexagram.upperTrigram}上${primaryResult.mainHexagram.lowerTrigram}下 · 五行${primaryResult.mainHexagram.element})');
    if (primaryResult.changingYaoIndex != null && primaryResult.changingYao != null) {
      buffer.writeln('- 动爻: 第${primaryResult.changingYaoIndex! + 1}爻 (${primaryResult.changingYao!.name})');
    }
    buffer.write('- 关联卦象: 互卦【${primaryResult.mutualHexagram.name}】');
    if (primaryResult.transformedHexagram != null) {
      buffer.write(' · 变卦【${primaryResult.transformedHexagram!.name}】');
    }
    buffer.write(' · 错卦【${primaryResult.oppositeHexagram.name}】 · 综卦【${primaryResult.inverseHexagram.name}】\n');

    // 2. 对比对象关键信息（如有）
    if (comparedProfiles.isNotEmpty && comparedResults.isNotEmpty) {
      buffer.writeln('\n【对比合盘对象】:');
      for (int i = 0; i < comparedProfiles.length; i++) {
        final cp = comparedProfiles[i];
        final cr = comparedResults.length > i ? comparedResults[i] : null;
        if (cr == null) continue;

        buffer.writeln('- 对象${i + 1}: ${cp.name} (${cp.notes.isEmpty ? "亲友" : cp.notes}, ${cp.gender}) | 八字: ${cr.bazi.yearGanZhi} ${cr.bazi.monthGanZhi} ${cr.bazi.dayGanZhi} ${cr.bazi.hourGanZhi} | 日元: ${cr.bazi.dayMaster}(${cr.bazi.dayMasterElement}) | 本命卦: ${cr.mainHexagram.name}${cr.transformedHexagram != null ? " · 变卦: ${cr.transformedHexagram!.name}" : ""}');
      }
    }

    // 3. 用户咨询主题
    buffer.writeln('\n【求测问题】:');
    buffer.writeln(userQuestion.trim().isEmpty ? '请为我做全面的命盘深度详批与近期运势决策指引。' : userQuestion.trim());

    return buffer.toString();
  }

  /// 发起 Server-Sent Events (SSE) 实时流式对话请求
  Stream<AiStreamChunk> streamChat({
    required String systemPrompt,
    required String userPayload,
    List<AiChatMessage> history = const [],
  }) async* {
    if (_apiKey.trim().isEmpty) {
      yield const AiStreamChunk(error: '请先配置您的 DeepSeek API Key');
      return;
    }

    HttpClient? client;
    try {
      final endpoint = Uri.parse('$_baseUrl/chat/completions');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(endpoint);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');

      // 组装历史多轮上下文
      final List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': systemPrompt},
      ];

      final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final msg in recentHistory) {
        if (msg.role == 'user' || msg.role == 'assistant') {
          final Map<String, dynamic> msgMap = {
            'role': msg.role,
            'content': msg.content,
          };
          // 如果开启思考模式且此前有 reasoning_content，携带它以保证思维链连贯
          if (_enableThinking && msg.reasoningContent != null && msg.reasoningContent!.isNotEmpty) {
            msgMap['reasoning_content'] = msg.reasoningContent;
          }
          messages.add(msgMap);
        }
      }

      messages.add({'role': 'user', 'content': userPayload});

      // 遵循官方文档：使用 thinking: {type: 'enabled'/'disabled'}
      final Map<String, dynamic> requestData = {
        'model': _model,
        'messages': messages,
        'stream': true,
        'thinking': {
          'type': _enableThinking ? 'enabled' : 'disabled',
        },
      };

      if (!_enableThinking) {
        requestData['temperature'] = _temperature;
      }

      request.write(jsonEncode(requestData));
      final response = await request.close();

      if (response.statusCode != 200) {
        final errText = await response.transform(utf8.decoder).join();
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(errText);
          if (errJson['error'] != null && errJson['error']['message'] != null) {
            errorMsg = errJson['error']['message'];
          }
        } catch (_) {
          errorMsg = errText;
        }
        yield AiStreamChunk(error: 'DeepSeek 请求失败 ($errorMsg)');
        return;
      }

      final streamLines = response.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in streamLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          if (jsonStr == '[DONE]') {
            yield const AiStreamChunk(isDone: true);
            break;
          }

          try {
            final data = jsonDecode(jsonStr);
            final choices = data['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                final content = delta['content'] as String?;
                final reasoning = delta['reasoning_content'] as String?;

                if (content != null || reasoning != null) {
                  yield AiStreamChunk(
                    content: content,
                    reasoningContent: reasoning,
                  );
                }
              }
            }
          } catch (_) {
            // 忽略异常
          }
        }
      }
    } catch (e) {
      yield AiStreamChunk(error: '网络连接异常: $e');
    } finally {
      client?.close();
    }
  }

  /// 辅助计算 Profile 的 DivinationResult
  static DivinationResult calculateResultForProfile(UserProfile p) {
    final bazi = BaZiEngine.calculate(
      solarDate: p.solarDate,
      hourIndex: p.hourIndex,
      isHourKnown: p.isHourKnown,
      longitude: p.longitude,
    );

    return IChingCalculator.calculateHexagrams(
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
  }
}
