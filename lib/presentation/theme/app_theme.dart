import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 应用程序全局视觉主题（新中式东方矿物色系，深浅色自适应）
class AppTheme {
  // ================= 深色模式（玄墨曜金） =================
  static const Color inkBlack = Color(0xFF101216);      // 浓墨黑（主背景底色）
  static const Color surfaceCharcoal = Color(0xFF181B20); // 炭黑（卡片次级背景）
  static const Color surfaceCard = Color(0xFF22262E);     // 黛灰（主卡片背景）
  static const Color surfaceBorder = Color(0xFF2E333E);   // 幽玄边框色

  static const Color cinnabarRed = Color(0xFFD64527); // 朱砂红（动爻、警示、阳气重点）
  static const Color imperialGold = Color(0xFFE5B562); // 帝王金（主卦、本命、高亮徽章）
  static const Color jadeGreen = Color(0xFF3F8B68);   // 碧玉青（互卦、生机、木行）
  static const Color lakeBlue = Color(0xFF387CB8);    // 靛水蓝（变卦、流年、水行）
  static const Color ochreBrown = Color(0xFFB57C48);  // 赭石黄（土行、中正沉稳）

  static const Color textPaperWhite = Color(0xFFF6F4EE); // 宣纸暖白（主要标题与正文字色）
  static const Color textMistGrey = Color(0xFFA0A6B2);   // 烟水灰（次要文本与说明文字）
  static const Color textMutedDark = Color(0xFF646B79);  // 黛墨暗灰（占位符与微弱提示）

  // ================= 浅色模式（素绢水墨） =================
  static const Color lightBackground = Color(0xFFF8F6F0);      // 素绢白（浅色主背景）
  static const Color lightSurfaceCharcoal = Color(0xFFEFECE4); // 云母浅灰（浅色次级背景）
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);     // 玉白（浅色主卡片背景）
  static const Color lightSurfaceBorder = Color(0xFFE0DDD5);   // 浅绢边框色

  static const Color lightCinnabarRed = Color(0xFFC8381E); // 朱砂印泥红
  static const Color lightImperialGold = Color(0xFFBF8828); // 古法沉金
  static const Color lightJadeGreen = Color(0xFF2D7A56);   // 古玉翠青
  static const Color lightLakeBlue = Color(0xFF2B6DA3);    // 青花靛蓝
  static const Color lightOchreBrown = Color(0xFFA66E3A);  // 赭石棕黄

  static const Color lightTextPrimary = Color(0xFF1E2229);   // 松烟焦墨（浅色主标题与正文）
  static const Color lightTextSecondary = Color(0xFF5D6472); // 淡墨烟灰（浅色次要文本）
  static const Color lightTextMuted = Color(0xFF9E9B93);     // 浅墨微灰（浅色弱提示）

  /// 楷体书卷字体回退列表（适配 iOS / Android / macOS / Windows 系统自带中文字体库）
  static const List<String> kaiTiFontFamilyFallback = [
    'STKaiti',        // 华文楷体 (iOS / macOS)
    'KaiTi',          // 楷体 (Windows / Android 部分定制 ROM)
    'KaiTi_GB2312',   // 楷体_GB2312
    'Kaiti SC',       // 楷体-简 (macOS / iOS)
    'BiauKai',        // 标楷体
    'FZKai-Z03S',     // 方正楷体
    'Noto Serif CJK SC',
    'Songti SC',      // 衬线备用
    'serif',          // 通用衬线
  ];

  static const String defaultKaiTiFont = 'STKaiti';

  /// 五行标准对照色系（深色）
  static const Map<String, Color> elementColors = {
    '金': Color(0xFFE5B562),
    '木': Color(0xFF3F8B68),
    '水': Color(0xFF387CB8),
    '火': Color(0xFFD64527),
    '土': Color(0xFFB57C48),
  };

  /// 五行标准对照色系（浅色）
  static const Map<String, Color> lightElementColors = {
    '金': Color(0xFFBF8828),
    '木': Color(0xFF2D7A56),
    '水': Color(0xFF2B6DA3),
    '火': Color(0xFFC8381E),
    '土': Color(0xFFA66E3A),
  };

  /// 卦象等第吉凶标准对照色系（深色）
  static const Map<String, Color> tierColors = {
    '上上卦': Color(0xFFE5B562), // 尊贵金（大吉）
    '上吉卦': Color(0xFF3F8B68), // 生机绿（吉亨）
    '中平卦': Color(0xFF387CB8), // 沉静蓝（中平）
    '磨砺卦': Color(0xFFD47A3B), // 历练橙（遇阻成长）
    '潜修卦': Color(0xFFD64527), // 警示红（险难潜修）
  };

  /// 卦象等第吉凶标准对照色系（浅色）
  static const Map<String, Color> lightTierColors = {
    '上上卦': Color(0xFFBF8828),
    '上吉卦': Color(0xFF2D7A56),
    '中平卦': Color(0xFF2B6DA3),
    '磨砺卦': Color(0xFFC46522),
    '潜修卦': Color(0xFFC8381E),
  };

  /// 动态上下文颜色获取器
  static Color getCardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceCard : lightSurfaceCard;

  static Color getCharcoalColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceCharcoal : lightSurfaceCharcoal;

  static Color getBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceBorder : lightSurfaceBorder;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPaperWhite : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMistGrey : lightTextSecondary;

  static Color getTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMutedDark : lightTextMuted;

  static Color getBackgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? inkBlack : lightBackground;

  static Color getGoldColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? imperialGold : lightImperialGold;

  /// 全局多层柔和环境光影（营造极简立体的物理卡片悬浮质感，告别生硬线框）
  static List<BoxShadow> getCardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 6,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 14,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 5,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ];
  }

  /// 聚焦与主状态柔和光晕阴影（如主生辰、选中项）
  static List<BoxShadow> getGlowShadow(BuildContext context, Color color, {double alpha = 0.20}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
      ...getCardShadow(context),
    ];
  }

  /// 轻量微弱阴影（用于小组件、胶囊标签）
  static List<BoxShadow> getSubtleShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x2E000000) : const Color(0x0A000000),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static Color getTierColor(BuildContext context, String tier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? (tierColors[tier] ?? imperialGold)
        : (lightTierColors[tier] ?? lightImperialGold);
  }

  static Color getElementColor(BuildContext context, String element) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? (elementColors[element] ?? imperialGold)
        : (lightElementColors[element] ?? lightImperialGold);
  }

  /// 全平台统一的平滑右滑入场与向右滑出退场页面转场动画
  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );

  /// 获取暗色全局主题配置（玄墨曜金）
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: _pageTransitionsTheme,
      fontFamily: defaultKaiTiFont,
      fontFamilyFallback: kaiTiFontFamilyFallback,
      scaffoldBackgroundColor: inkBlack,
      primaryColor: imperialGold,
      colorScheme: const ColorScheme.dark(
        primary: imperialGold,
        secondary: cinnabarRed,
        surface: surfaceCharcoal,
        onPrimary: inkBlack,
        onSurface: textPaperWhite,
      ),
      cardColor: surfaceCard,
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 3,
        shadowColor: const Color(0x50000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: inkBlack,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPaperWhite,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontFamily: defaultKaiTiFont,
          fontFamilyFallback: kaiTiFontFamilyFallback,
        ),
        iconTheme: IconThemeData(color: imperialGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCharcoal,
        selectedItemColor: imperialGold,
        unselectedItemColor: textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
    );
  }

  /// 获取浅色全局主题配置（素绢水墨）
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: _pageTransitionsTheme,
      fontFamily: defaultKaiTiFont,
      fontFamilyFallback: kaiTiFontFamilyFallback,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: lightImperialGold,
      colorScheme: const ColorScheme.light(
        primary: lightImperialGold,
        secondary: lightCinnabarRed,
        surface: lightSurfaceCard,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      cardColor: lightSurfaceCard,
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        elevation: 2,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontFamily: defaultKaiTiFont,
          fontFamilyFallback: kaiTiFontFamilyFallback,
        ),
        iconTheme: IconThemeData(color: lightImperialGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceCharcoal,
        selectedItemColor: lightImperialGold,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: lightSurfaceBorder,
        thickness: 1,
      ),
    );
  }
}
