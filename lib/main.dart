/// 应用入口 —— 配置全局路由、主题（支持深色模式）、过渡动画、Drawer 导航。
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/result_page.dart';
import 'pages/detail_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';
import 'pages/tools_selection_page.dart';
import 'pages/chat_page.dart';
import 'pages/prompt_page.dart';
import 'pages/edit_profile_page.dart';
import 'services/local_storage_service.dart';

void main() {
  runApp(const TravelPlannerApp());
}

class TravelPlannerApp extends StatefulWidget {
  const TravelPlannerApp({super.key});

  @override
  State<TravelPlannerApp> createState() => _TravelPlannerAppState();
}

class _TravelPlannerAppState extends State<TravelPlannerApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await LocalStorageService().getDarkMode();
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 旅游规划助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/login':
            page = const LoginPage();
            break;
          case '/home':
            page = const HomePage();
            break;
          case '/result':
            page = const ResultPage();
            break;
          case '/detail':
            page = const DetailPage();
            break;
          case '/settings':
            page = const SettingsPage();
            break;
          case '/profile':
            page = const ProfilePage();
            break;
          case '/tools':
            page = const ToolsSelectionPage();
            break;
          case '/chat':
            page = const ChatPage();
            break;
          case '/prompt':
            page = const PromptPage();
            break;
          case '/edit_profile':
            page = const EditProfilePage();
            break;
          default:
            page = Scaffold(
              body: Center(child: Text('页面不存在：${settings.name}')),
            );
            break;
        }

        final isAuthTransition =
            settings.name == '/login' || settings.name == '/home';
        return _buildAnimatedRoute(page, settings, fadeIn: isAuthTransition);
      },
    );
  }

  static PageRouteBuilder _buildAnimatedRoute(
    Widget page,
    RouteSettings settings, {
    bool fadeIn = false,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (fadeIn) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        }
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}
