import 'package:flutter/material.dart';
import 'core/ai/deepseek_service.dart';
import 'core/updater/app_updater_service.dart';
import 'data/repositories/ai_chat_repository.dart';
import 'data/repositories/iching_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'presentation/pages/home_nav_page.dart';
import 'presentation/theme/app_theme.dart';

/// 应用程序主入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化易经六十四卦知识库、档案数据源、AI 对话历史、DeepSeek 引擎与版本管理
  await IChingRepository.instance.init();
  await ProfileRepository.instance.init();
  await AiChatRepository.instance.init();
  await DeepSeekService.instance.init();
  await AppUpdaterService.instance.init();
  runApp(const WhoAmIApp());
}

/// 弥纶 (MiLun) 易经本命八字推算应用主组件
class WhoAmIApp extends StatelessWidget {
  const WhoAmIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '弥纶',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 自动根据系统设置自适应深浅色模式
      home: const HomeNavPage(),
    );
  }
}
