import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/ai/deepseek_service.dart';
import '../../../data/models/ai_chat_message.dart';
import '../../../data/models/hexagram_detail.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/ai_chat_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deepseek_whale_icon.dart';
import 'ai_settings_dialog.dart';

/// 雅秋立体光影风格 · AI 易学参详独立页面（支持多会话切换与历史管理）
class AiAnalysisPage extends StatefulWidget {
  final DivinationResult? initialResult;
  final UserProfile? initialProfile;

  const AiAnalysisPage({
    super.key,
    this.initialResult,
    this.initialProfile,
  });

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Set<String> _selectedProfileIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<AiStreamChunk>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    // 1. 默认自动勾选主生辰档案
    final primary = ProfileRepository.instance.primaryProfile;
    if (primary != null) {
      _selectedProfileIds.add(primary.id);
    } else if (widget.initialProfile != null) {
      _selectedProfileIds.add(widget.initialProfile!.id);
    }

    // 2. 动态刷新官方模型列表
    if (DeepSeekService.instance.hasValidKey) {
      DeepSeekService.instance.fetchModels().then((_) {
        if (mounted) setState(() {});
      });
    }

    // 3. 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(immediate: true));
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<AiChatMessage> get _messages => AiChatRepository.instance.messages;

  void _scrollToBottom({bool immediate = false}) {
    if (_scrollController.hasClients) {
      if (immediate) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// 发送新消息并流式生成回复
  Future<void> _sendMessage() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (!DeepSeekService.instance.hasValidKey) {
      final configured = await AiSettingsDialog.show(context);
      if (configured != true || !DeepSeekService.instance.hasValidKey) return;
    }

    // 获取主生辰与其他对比档案
    final allProfiles = ProfileRepository.instance.profiles;
    UserProfile? primaryProf = widget.initialProfile ?? ProfileRepository.instance.primaryProfile;
    if (primaryProf == null && allProfiles.isNotEmpty) {
      primaryProf = allProfiles.first;
    }

    if (primaryProf == null) {
      setState(() {
        _errorMessage = '请先在档案命簿中保存或创建一个生辰档案';
      });
      return;
    }

    final primaryRes = widget.initialResult ?? DeepSeekService.calculateResultForProfile(primaryProf);

    // 筛选对比亲友档案
    final List<UserProfile> comparedProfs = [];
    final List<DivinationResult> comparedRes = [];
    final List<String> profileNames = [primaryProf.name];

    for (final id in _selectedProfileIds) {
      if (id != primaryProf.id) {
        final match = allProfiles.where((p) => p.id == id).firstOrNull;
        if (match != null) {
          comparedProfs.add(match);
          comparedRes.add(DeepSeekService.calculateResultForProfile(match));
          profileNames.add(match.name);
        }
      }
    }

    // 1. 立即上屏用户提问气泡并清空输入框
    final userMsg = AiChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      profileNames: profileNames,
    );

    // 2. 预备空的助理回复气泡用于接收实时流式增量
    final assistantMsg = AiChatMessage(
      id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: '',
      reasoningContent: '',
      timestamp: DateTime.now(),
    );

    setState(() {
      _promptController.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    await AiChatRepository.instance.addMessage(userMsg);
    await AiChatRepository.instance.addMessage(assistantMsg);
    _scrollToBottom();

    // 3. 构造学术 System Prompt 与精炼数据 Payload
    final systemPrompt = DeepSeekService.instance.buildSystemPrompt();
    final userPayload = DeepSeekService.instance.buildUserDataPayload(
      primaryProfile: primaryProf,
      primaryResult: primaryRes,
      comparedProfiles: comparedProfs,
      comparedResults: comparedRes,
      userQuestion: text,
    );

    String streamedContent = '';
    String streamedReasoning = '';

    _streamSubscription?.cancel();
    _streamSubscription = DeepSeekService.instance
        .streamChat(
      systemPrompt: systemPrompt,
      userPayload: userPayload,
      history: _messages.sublist(0, _messages.length - 2),
    )
        .listen(
      (chunk) {
        if (chunk.error != null) {
          setState(() {
            _isLoading = false;
            _errorMessage = chunk.error;
          });
        } else {
          setState(() {
            if (chunk.reasoningContent != null) {
              streamedReasoning += chunk.reasoningContent!;
            }
            if (chunk.content != null) {
              streamedContent += chunk.content!;
            }

            final updatedAssistant = assistantMsg.copyWith(
              content: streamedContent,
              reasoningContent: streamedReasoning.isNotEmpty ? streamedReasoning : null,
            );

            AiChatRepository.instance.updateLastMessage(updatedAssistant);

            if (chunk.isDone) {
              _isLoading = false;
            }
          });
          _scrollToBottom();
        }
      },
      onError: (err) {
        setState(() {
          _isLoading = false;
          _errorMessage = '连接中断: $err';
        });
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  /// 开启全新独立会话草稿（未发送文字前不落库保存）
  Future<void> _startNewSession() async {
    _streamSubscription?.cancel();
    await AiChatRepository.instance.startNewSessionDraft();
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
    _scrollToBottom(immediate: true);
  }

  /// 弹出模型选择与深度思考开关切换底板
  Future<void> _showModelSelectorSheet() async {
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final models = DeepSeekService.instance.availableModels;
            final current = DeepSeekService.instance.model;
            final isThinking = DeepSeekService.instance.enableThinking;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 16
                    : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. 深度思考模式全局开关
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.getSubtleShadow(context),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        value: isThinking,
                        activeThumbColor: gold,
                        activeTrackColor: gold.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: Row(
                          children: [
                            Icon(Icons.psychology, color: gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '深度思考模式 (Thinking Mode)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            isThinking
                                ? '已开启：推导演算并输出完整思维链 (reasoning)'
                                : '已关闭：极速直接生成回答，降低耗时',
                            style: TextStyle(fontSize: 11.5, color: textSecondary),
                          ),
                        ),
                        onChanged: (val) async {
                          await DeepSeekService.instance.setThinkingEnabled(val);
                          setSheetState(() {});
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. 官方模型列表标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择 DeepSeek 模型',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.refresh, size: 15, color: gold),
                        label: Text('刷新官方列表', style: TextStyle(fontSize: 12, color: gold)),
                        onPressed: () async {
                          await DeepSeekService.instance.fetchModels();
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. 模型列表项
                  ...models.map((m) {
                    final bool isSelected = m == current;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          await DeepSeekService.instance.setModel(m);
                          if (mounted) setState(() {});
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? gold.withValues(alpha: 0.14) : cardBg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: gold.withValues(alpha: 0.14),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : AppTheme.getSubtleShadow(context),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? gold : textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? gold : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.contains('flash')
                                          ? '官方推荐极速模型，推理兼具速度与智慧'
                                          : m.contains('pro')
                                              ? '专业旗舰模型，适合高难复杂推演'
                                              : 'DeepSeek 官方模型',
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
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
    final charcoal = AppTheme.getCharcoalColor(context);
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    final allProfiles = ProfileRepository.instance.profiles;
    final primaryId = ProfileRepository.instance.primaryProfileId;
    final currentModel = DeepSeekService.instance.model;
    final bool isThinking = DeepSeekService.instance.enableThinking;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 左侧展开历史对话侧边栏
      drawer: _buildHistoryDrawer(context),
      appBar: AppBar(
        centerTitle: true,
        // 将左上角返回图标替换为展开历史对话的入口
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            icon: const Icon(Icons.history_rounded, size: 23),
            tooltip: '展开历史对话',
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'AI 易学参详明镜',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            // 居中显示的当前模型与思考模式选择器
            GestureDetector(
              onTap: _showModelSelectorSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isThinking ? Icons.psychology : Icons.bolt,
                      color: gold,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentModel · ${isThinking ? "深度思考" : "极速模式"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: gold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, color: gold, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'API 设置',
            onPressed: () async {
              await AiSettingsDialog.show(context);
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 顶部命盘对比选择器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: charcoal.withValues(alpha: 0.6),
              boxShadow: AppTheme.getSubtleShadow(context),
            ),
            child: Row(
              children: [
                Text(
                  '比对命盘:',
                  style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: allProfiles.map((p) {
                        final bool isPrimary = (primaryId == p.id) || (primaryId == null && allProfiles.indexOf(p) == 0);
                        final bool isSelected = _selectedProfileIds.contains(p.id) || isPrimary;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            onSelected: isPrimary
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedProfileIds.add(p.id);
                                      } else {
                                        _selectedProfileIds.remove(p.id);
                                      }
                                    });
                                  },
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPrimary)
                                  Container(
                                    margin: const EdgeInsets.only(right: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: gold,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '我',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppTheme.inkBlack : Colors.white,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${p.name}${p.notes.isNotEmpty && !isPrimary ? " (${p.notes})" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? gold : textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: cardBg,
                            selectedColor: gold.withValues(alpha: 0.18),
                            checkmarkColor: gold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 主体消息流与悬浮输入框 Stack（实现文字穿透滚动在输入框下方）
          Expanded(
            child: Stack(
              children: [
                // (1) 对话气泡消息流列表：全高度滚动，底部留出足够安全间距让最后一条消息滚动到悬浮框之上
                Positioned.fill(
                  child: _messages.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            MediaQuery.of(context).padding.bottom > 0
                                ? MediaQuery.of(context).padding.bottom + 90
                                : 96,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildMessageItem(context, msg, index == _messages.length - 1 && _isLoading);
                          },
                        ),
                ),

                // (2) 错误信息横条 (如有)
                if (_errorMessage != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: cinnabar.withValues(alpha: 0.14),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: cinnabar, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(fontSize: 12, color: cinnabar),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // (3) 真正悬浮在页面上方的毛玻璃圆角输入栏（自适应文字高度自动伸缩）
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 12
                      : 18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: cardBg.withValues(alpha: isDark ? 0.88 : 0.92),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: gold.withValues(alpha: isDark ? 0.28 : 0.20),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.09),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: gold.withValues(alpha: isDark ? 0.14 : 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: TextField(
                                  key: const ValueKey('ai_chat_input_field'),
                                  controller: _promptController,
                                  enabled: !_isLoading,
                                  style: TextStyle(fontSize: 14.5, color: textPrimary, height: 1.45),
                                  minLines: 1,
                                  maxLines: 6,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration(
                                    hintText: '向 AI 请教具体问题或合盘参详...',
                                    hintStyle: TextStyle(fontSize: 13.5, color: AppTheme.getTextMuted(context)),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: GestureDetector(
                                key: const ValueKey('ai_send_button'),
                                onTap: _isLoading
                                    ? () {
                                        _streamSubscription?.cancel();
                                        setState(() => _isLoading = false);
                                      }
                                    : _sendMessage,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: gold,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: gold.withValues(alpha: 0.38),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_upward_rounded,
                                          color: isDark ? AppTheme.inkBlack : Colors.white,
                                          size: 21,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建左侧历史对话抽屉
  Widget _buildHistoryDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);

    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;
    final sessions = AiChatRepository.instance.sessions;
    final currentSessionId = AiChatRepository.instance.currentSessionId;

    return Drawer(
      backgroundColor: charcoal,
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: gold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '历史参详对话',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${sessions.length} 个会话',
                          style: TextStyle(fontSize: 11, color: gold, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 开启新对话按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startNewSession();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('开启新参详会话', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: isDark ? AppTheme.inkBlack : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 会话列表
            if (sessions.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, color: textSecondary.withValues(alpha: 0.4), size: 36),
                        const SizedBox(height: 10),
                        Text(
                          '暂无历史对话记录',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '提问发出后将自动为您记录保存',
                          style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final bool isCurrent = s.id == currentSessionId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isCurrent ? gold.withValues(alpha: 0.14) : cardBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            Navigator.pop(context);
                            if (!isCurrent) {
                              _streamSubscription?.cancel();
                              await AiChatRepository.instance.switchSession(s.id);
                              setState(() {
                                _isLoading = false;
                                _errorMessage = null;
                              });
                              _scrollToBottom(immediate: true);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isCurrent ? Icons.chat_bubble : Icons.chat_bubble_outline,
                                  size: 16,
                                  color: isCurrent ? gold : textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrent ? gold : textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s.messages.length} 条消息 · ${s.updatedAt.month}月${s.updatedAt.day}日',
                                        style: TextStyle(fontSize: 10.5, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 16, color: textSecondary),
                                  tooltip: '删除会话',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        backgroundColor: charcoal,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text(
                                          '删除参详记录',
                                          style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        content: Text(
                                          '确定要删除「${s.title}」这条历史对话记录吗？删除后将无法恢复。',
                                          style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogCtx, false),
                                            child: Text('取消', style: TextStyle(color: textSecondary)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: cinnabar,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => Navigator.pop(dialogCtx, true),
                                            child: const Text('确认删除', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await AiChatRepository.instance.deleteSession(s.id);
                                      setState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final gold = AppTheme.getGoldColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DeepSeekWhaleIcon(size: 56, color: gold),
            const SizedBox(height: 16),
            Text(
              'AI 易学明镜已就绪',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '已为您载入当前本命全息数据。\n在下方输入您想请教的问题，或勾选多位亲友生辰进行深度合盘参详。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, AiChatMessage msg, bool isStreamingNow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;

    final bool isUser = msg.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 48),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: isDark ? 0.22 : 0.16),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: AppTheme.getSubtleShadow(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msg.profileNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '【附带: ${msg.profileNames.join("、")}】',
                          style: TextStyle(fontSize: 10, color: gold, fontWeight: FontWeight.bold),
                        ),
                      ),
                    SelectableText(
                      msg.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final bool hasReasoning = msg.reasoningContent != null && msg.reasoningContent!.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: DeepSeekWhaleIcon(size: 24, color: gold),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: AppTheme.getCardShadow(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 思考过程折叠卡片
                    if (hasReasoning)
                      _ThinkingAccordion(
                        reasoningText: msg.reasoningContent!,
                        isStreaming: isStreamingNow && msg.content.isEmpty,
                        jadeColor: jade,
                        textColor: textSecondary,
                      ),

                    // 2. Markdown 格式化正文渲染
                    if (msg.content.isNotEmpty)
                      MarkdownBody(
                        data: msg.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 13.5,
                            color: textPrimary,
                            height: 1.65,
                            letterSpacing: 0.2,
                          ),
                          h1: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: gold,
                            height: 1.5,
                          ),
                          h2: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: gold,
                            height: 1.45,
                          ),
                          h3: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: gold,
                            height: 1.4,
                          ),
                          h4: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                          em: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: textPrimary,
                          ),
                          blockquote: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                            height: 1.5,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: charcoal.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border(left: BorderSide(color: gold, width: 3)),
                          ),
                          blockquotePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          code: TextStyle(
                            fontSize: 12,
                            color: gold,
                            backgroundColor: charcoal.withValues(alpha: 0.6),
                          ),
                          listBullet: TextStyle(
                            fontSize: 13.5,
                            color: gold,
                          ),
                          tableBody: TextStyle(
                            fontSize: 12.5,
                            color: textPrimary,
                          ),
                          tableHead: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      )
                    else if (isStreamingNow && !hasReasoning)
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                          ),
                          const SizedBox(width: 8),
                          Text('正在推衍易理...', style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),

                    // 3. 底部复制全文操作按钮
                    if (msg.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: msg.content));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已复制 AI 参详内容')),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 13, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '复制',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// 思考过程折叠组件
class _ThinkingAccordion extends StatefulWidget {
  final String reasoningText;
  final bool isStreaming;
  final Color jadeColor;
  final Color textColor;

  const _ThinkingAccordion({
    required this.reasoningText,
    required this.isStreaming,
    required this.jadeColor,
    required this.textColor,
  });

  @override
  State<_ThinkingAccordion> createState() => _ThinkingAccordionState();
}

class _ThinkingAccordionState extends State<_ThinkingAccordion> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isStreaming;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.getCharcoalColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 15, color: widget.jadeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.isStreaming
                          ? '正在推演思维链 (${widget.reasoningText.length} 字)...'
                          : '易理思维链推演 (${widget.reasoningText.length} 字)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: widget.jadeColor,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: widget.textColor,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                widget.reasoningText,
                style: TextStyle(
                  fontSize: 11.5,
                  color: widget.textColor,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
