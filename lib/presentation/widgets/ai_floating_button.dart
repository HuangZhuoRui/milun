import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/hexagram_detail.dart';
import '../../data/models/user_profile.dart';
import '../pages/ai/ai_analysis_page.dart';
import '../theme/app_theme.dart';

import 'deepseek_whale_icon.dart';

/// 雅秋立体光影风格 · AI 易学参详悬浮按钮
class AiFloatingButton extends StatelessWidget {
  final DivinationResult? currentResult;
  final UserProfile? currentProfile;

  const AiFloatingButton({
    super.key,
    this.currentResult,
    this.currentProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppTheme.getGoldColor(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AiAnalysisPage(
              initialResult: currentResult,
              initialProfile: currentProfile,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: isDark ? 0.35 : 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DeepSeekWhaleIcon(
              size: 20,
              color: isDark ? AppTheme.inkBlack : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'AI 参详',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.inkBlack : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
