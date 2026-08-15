import 'package:flutter/material.dart';
import '../../../core/ai/deepseek_service.dart';
import '../../theme/app_theme.dart';

/// DeepSeek API 基础配置弹窗
class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AiSettingsDialog(),
    );
  }

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late double _temperature;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final service = DeepSeekService.instance;
    _apiKeyController = TextEditingController(text: service.apiKey);
    _baseUrlController = TextEditingController(text: service.baseUrl);
    _temperature = service.temperature;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _onTestConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final res = await DeepSeekService.instance.testConnection(
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = res['success'] as bool? ?? false;
        _testMessage = res['message'] as String? ?? '';
      });
    }
  }

  Future<void> _onSave() async {
    await DeepSeekService.instance.saveSettings(
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      temperature: _temperature,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DeepSeek API 配置已保存'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final charcoal = AppTheme.getCharcoalColor(context);
    final jade = isDark ? AppTheme.jadeGreen : AppTheme.lightJadeGreen;
    final cinnabar = isDark ? AppTheme.cinnabarRed : AppTheme.lightCinnabarRed;

    return Dialog(
      backgroundColor: charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.vpn_key_outlined, color: gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DeepSeek API 配置',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '配置 API Key 与服务代理',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. API Key 输入框
            Text(
              'DeepSeek API Key',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                style: TextStyle(fontSize: 13.5, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'sk-...',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.getTextMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. API 基础地址 (Base URL)
            Text(
              'API Base URL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.getSubtleShadow(context),
              ),
              child: TextField(
                controller: _baseUrlController,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'https://api.deepseek.com',
                  hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.getTextMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. 测试连接反馈信息
            if (_testMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? jade : cinnabar).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle : Icons.error_outline,
                      color: _testSuccess == true ? jade : cinnabar,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess == true ? jade : cinnabar,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 底部操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _onTestConnection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: gold.withValues(alpha: 0.5)),
                    ),
                    child: _isTesting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                          )
                        : Text('测试连接', style: TextStyle(color: gold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '保存配置',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.inkBlack : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
