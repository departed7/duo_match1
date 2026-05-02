import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'models/user_model.dart';
import 'models/message_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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

class UserProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  UserProfile? _currentUser;

  UserProvider(this._prefs) {
    _initUser();
  }

  UserProfile? get currentUser => _currentUser;

  void _initUser() {
    final String? name = _prefs.getString('my_full_name');
    if (name != null) {
      _currentUser = UserProfile(
        userId: 'me',
        fullName: name,
        university: _prefs.getString('my_uni') ?? 'Студент',
        bio: _prefs.getString('my_bio') ?? '',
        birthDate: DateTime.tryParse(_prefs.getString('my_birth') ?? '') ?? DateTime(2004),
        gender: _prefs.getString('my_gender') ?? 'Мужской',
        photos: [_prefs.getString('my_photo') ?? 'assets/images/profile_1.jpg'],
        interests: [],
        latitude: 0.0,
        longitude: 0.0,
        isPremium: _prefs.getBool('my_premium') ?? false,
        avatarScale: _prefs.getDouble('my_scale') ?? 1.0,
      );
    }
  }

  void setUser(UserProfile user) {
    _currentUser = user;
    _prefs.setString('my_full_name', user.fullName);
    _prefs.setString('my_photo', user.photos.first);
    _prefs.setBool('my_premium', user.isPremium);
    notifyListeners();
  }

  void saveProfile(String n, String b, String u, String g, DateTime d, String p, double s, String? v) {
    if (_currentUser != null) {
      _currentUser!.fullName = n;
      _currentUser!.bio = b;
      _currentUser!.university = u;
      _currentUser!.gender = g;
      _currentUser!.birthDate = d;
      _currentUser!.photos = [p];
      _currentUser!.avatarScale = s;
      _currentUser!.videoPath = v;

      _prefs.setString('my_full_name', n);
      _prefs.setString('my_bio', b);
      _prefs.setString('my_uni', u);
      _prefs.setString('my_gender', g);
      _prefs.setString('my_birth', d.toIso8601String());
      _prefs.setString('my_photo', p);
      _prefs.setDouble('my_scale', s);
      notifyListeners();
    }
  }

  void setAvatar(String path) {
    if (_currentUser != null) {
      _currentUser!.photos = [path];
      _prefs.setString('my_photo', path);
      notifyListeners();
    }
  }

  void setPremium(bool v) {
    if (_currentUser != null) {
      _currentUser!.isPremium = v;
      _prefs.setBool('my_premium', v);
      notifyListeners();
    }
  }

  void setIncognito(bool v) {
    if (_currentUser != null) {
      _currentUser!.isIncognito = v;
      notifyListeners();
    }
  }
}

class ChatProvider with ChangeNotifier {
  final List<UserProfile> _matches = [];
  final Map<String, List<ChatMessage>> _history = {};
  final List<UserProfile> _likers = [];
  final List<UserProfile> _swipeHistory = [];

  List<UserProfile> get matches => _matches;
  List<UserProfile> get likers => _likers;

  void initLikers() {
    if (_likers.isEmpty) {
      _likers.addAll([
        UserProfile(userId: 'l1', fullName: 'Анна', birthDate: DateTime(2005), gender: 'Женский', university: 'ВШЭ', bio: 'Привет!', photos: ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'], interests: [], latitude: 0, longitude: 0),
        UserProfile(userId: 'l2', fullName: 'Мария', birthDate: DateTime(2004), gender: 'Женский', university: 'МГУ', bio: 'Привет!', photos: ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400'], interests: [], latitude: 0, longitude: 0),
      ]);
      notifyListeners();
    }
  }

  void createMatch(UserProfile u) {
    if (!_matches.any((m) => m.userId == u.userId)) {
      _matches.add(u);
      String greeting = u.gender == 'Женский' 
        ? "Приветик! Ты мне очень понравился 😊 Давай познакомимся?" 
        : "Привет! Видел твою анкету. Я ${u.fullName}, чем занимаешься?";
      u.lastMessage = greeting;
      _history[u.userId] = [ChatMessage(senderId: 'bot', text: greeting, timestamp: DateTime.now(), isMe: false)];
      notifyListeners();
    }
  }

  void addToHistory(UserProfile user) {
    _swipeHistory.add(user);
    notifyListeners();
  }

  UserProfile? undoLastSwipe() {
    if (_swipeHistory.isNotEmpty) {
      return _swipeHistory.removeLast();
    }
    return null;
  }

  String getLastMessage(String userId) {
    if (_history[userId] == null || _history[userId]!.isEmpty) {
      return "";
    }
    return _history[userId]!.last.text;
  }

  List<ChatMessage> getMessages(String id) => _history[id] ?? [];

  void sendMessage(String id, String text) {
    if (_history[id] == null) {
      _history[id] = [];
    }
    _history[id]!.add(ChatMessage(senderId: 'me', text: text, timestamp: DateTime.now(), isMe: true));
    if (_matches.any((m) => m.userId == id)) {
      _matches.firstWhere((m) => m.userId == id).lastMessage = text;
    }
    notifyListeners();
  }

  void botReply(String id, String gender, String uni) {
    Future.delayed(const Duration(seconds: 2), () {
      if (_history[id] == null) return;
      int count = _history[id]!.where((m) => m.isMe).length;
      String lastMeMessage = _history[id]!.lastWhere((m) => m.isMe).text.trim();
      String r = "";
      if (lastMeMessage == "." || lastMeMessage.length < 2) {
        r = "Что за точка?) Расскажи лучше о себе!";
      } else {
        if (gender == 'Женский') {
          if (count == 1) { r = "Ого, это звучит круто! А я как раз учусь в $uni. Часто там бываешь?"; }
          else if (count == 2) { r = "Слушай, ты кажешься очень интересным человеком. Дай свой ТГ?"; }
          else { r = "Давай встретимся в субботу? Я знаю одно отличное место ☕"; }
        } else {
          if (count == 1) { r = "Понятно. Я вот сейчас на парах сижу, скучно. А ты?"; }
          else if (count == 2) { r = "Кстати, а ты любишь ночные прогулки или больше по заведениям?"; }
          else { r = "Давай спишемся в Телеграме и договоримся о встрече?"; }
        }
      }
      _history[id]!.add(ChatMessage(senderId: 'bot', text: r, timestamp: DateTime.now(), isMe: false));
      if (_matches.any((m) => m.userId == id)) {
        _matches.firstWhere((m) => m.userId == id).lastMessage = r;
      }
      notifyListeners();
    });
  }
}

class DuoMatchApp extends StatelessWidget {
  const DuoMatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}