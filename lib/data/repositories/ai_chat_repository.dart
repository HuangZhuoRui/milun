import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_chat_session.dart';

/// AI 会话历史持久化仓库（单例模式，空会话延迟保存与多会话 SSOT 管理）
class AiChatRepository extends ChangeNotifier {
  static final AiChatRepository instance = AiChatRepository._();
  AiChatRepository._();

  static const String _sessionsStorageKey = 'whoami_ai_chat_sessions_v1';
  static const String _currentSessionStorageKey = 'whoami_ai_current_session_id_v1';
  static const String _legacyHistoryStorageKey = 'ai_chat_history_v1';

  final List<AiChatSession> _sessions = [];
  String? _currentSessionId;
  AiChatSession? _draftSession;

  /// 只读的有效历史会话列表（自动过滤掉未发消息的空会话）
  List<AiChatSession> get sessions =>
      List.unmodifiable(_sessions.where((s) => s.messages.isNotEmpty));

  String? get currentSessionId => _currentSessionId;

  /// 当前激活的会话对象（若在草稿模式下返回内存草稿）
  AiChatSession get currentSession {
    if (_currentSessionId != null) {
      final found = _sessions.where((s) => s.id == _currentSessionId);
      if (found.isNotEmpty) return found.first;
    }
    return _draftSession ??= AiChatSession.create(title: '新易学参详');
  }

  List<AiChatMessage> get messages => currentSession.messages;

  /// 初始化本地多会话数据
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsStorageKey);

    _sessions.clear();

    if (sessionsJson != null && sessionsJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(sessionsJson);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final s = AiChatSession.fromJson(item);
            if (s.messages.isNotEmpty) {
              _sessions.add(s);
            }
          }
        }
      } catch (_) {
        _sessions.clear();
      }
    }

    // 兼容旧版历史数据平滑迁移
    if (_sessions.isEmpty) {
      final legacyJson = prefs.getString(_legacyHistoryStorageKey);
      if (legacyJson != null && legacyJson.isNotEmpty) {
        try {
          final List<dynamic> legacyList = jsonDecode(legacyJson);
          final List<AiChatMessage> legacyMsgs = [];
          for (final item in legacyList) {
            if (item is Map<String, dynamic>) {
              legacyMsgs.add(AiChatMessage.fromJson(item));
            }
          }
          if (legacyMsgs.isNotEmpty) {
            final title = legacyMsgs.first.content.length > 14
                ? '${legacyMsgs.first.content.substring(0, 14)}...'
                : legacyMsgs.first.content;
            final migrated = AiChatSession(
              id: 'session_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              createdAt: legacyMsgs.first.timestamp,
              updatedAt: legacyMsgs.last.timestamp,
              messages: legacyMsgs,
            );
            _sessions.add(migrated);
          }
        } catch (_) {}
      }
    }

    _currentSessionId = prefs.getString(_currentSessionStorageKey);
    if (_currentSessionId == null || !_sessions.any((s) => s.id == _currentSessionId)) {
      if (_sessions.isNotEmpty) {
        _currentSessionId = _sessions.first.id;
        _draftSession = null;
      } else {
        _currentSessionId = null;
        _draftSession = AiChatSession.create(title: '新易学参详');
      }
    }

    notifyListeners();
  }

  /// 开启新会话草稿（仅在内存中预备，未发文字前绝不存入本地存储）
  Future<void> startNewSessionDraft() async {
    _currentSessionId = null;
    _draftSession = AiChatSession.create(title: '新易学参详');
    notifyListeners();
  }

  /// 切换到指定历史会话
  Future<void> switchSession(String sessionId) async {
    if (_sessions.any((s) => s.id == sessionId)) {
      _currentSessionId = sessionId;
      _draftSession = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionStorageKey, sessionId);
      notifyListeners();
    }
  }

  /// 删除指定会话
  Future<void> deleteSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions.removeAt(index);
      if (_currentSessionId == sessionId) {
        if (_sessions.isNotEmpty) {
          _currentSessionId = _sessions.first.id;
          _draftSession = null;
        } else {
          _currentSessionId = null;
          _draftSession = AiChatSession.create(title: '新易学参详');
        }
      }
      await _save();
      notifyListeners();
    }
  }

  /// 向当前会话追加消息（若是草稿，在此刻正式入库并持久化）
  Future<void> addMessage(AiChatMessage message) async {
    AiChatSession session;

    if (_currentSessionId == null || _draftSession != null) {
      // 从草稿正式升级为正式会话
      session = _draftSession ?? AiChatSession.create(title: '新易学参详');
      _draftSession = null;
      _currentSessionId = session.id;
      _sessions.insert(0, session);
    } else {
      session = currentSession;
    }

    session.messages.add(message);
    session.updatedAt = DateTime.now();

    // 自动根据首条提问生成标题
    if (session.messages.length == 1 && message.role == 'user') {
      final text = message.content.trim();
      session.title = text.length > 14 ? '${text.substring(0, 14)}...' : text;
    }

    await _save();
    notifyListeners();
  }

  /// 更新当前会话最后一条消息
  Future<void> updateLastMessage(AiChatMessage updated) async {
    final session = currentSession;
    if (session.messages.isNotEmpty) {
      session.messages[session.messages.length - 1] = updated;
      session.updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  /// 清空当前会话消息
  Future<void> clearHistory() async {
    if (_currentSessionId != null) {
      await deleteSession(_currentSessionId!);
    } else {
      _draftSession = AiChatSession.create(title: '新易学参详');
      notifyListeners();
    }
  }

  /// 持久化保存所有非空会话
  Future<void> _save() async {
    final validSessions = _sessions.where((s) => s.messages.isNotEmpty).toList();
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(validSessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsStorageKey, jsonStr);
    if (_currentSessionId != null) {
      await prefs.setString(_currentSessionStorageKey, _currentSessionId!);
    }
  }
}
