import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ChatProvider(prefs)),
      ],
      child: const DuoMatchApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isDark;
  ThemeProvider(this._prefs) : _isDark = _prefs.getBool('is_dark_mode') ?? false;
  bool get isDark => _isDark;
  void toggleTheme() {
    _isDark = !_isDark;
    _prefs.setBool('is_dark_mode', _isDark);
    notifyListeners();
  }
}

class DuoMatchApp extends StatelessWidget {
  const DuoMatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DuoMatch',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}