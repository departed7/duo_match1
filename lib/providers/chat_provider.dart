import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';

class UserReport {
  final String fromUserId;
  final String targetUserId;
  final String targetName;
  final String reason;
  final DateTime timestamp;

  UserReport({
    required this.fromUserId,
    required this.targetUserId,
    required this.targetName,
    required this.reason,
    required this.timestamp,
  });
}

class ChatProvider with ChangeNotifier {
  final SharedPreferences? prefs;
  String _currentUserId = 'u_volkov';
  final List<UserProfile> _matches = [];
  final Map<String, List<ChatMessage>> _history = {};
  final List<UserProfile> _likers = [];
  final List<UserProfile> _swipeHistory = [];
  final Random _rnd = Random();

  static final Map<String, Set<String>> _userMatches = {
    'u_volkov': {'u_belova'},
    'u_belova': {'u_volkov'},
    'u_osipyan': <String>{},
    'admin_1': {'u_volkov', 'u_belova', 'u_osipyan'},
  };

  static final Map<String, List<Map<String, dynamic>>> _dialogDatabase = {};
  static final List<UserReport> _globalReports = [];
  static final Map<String, Set<String>> _personalBlacklists = {};

  final List<String> _femaleNames = const [
    'Анастасия', 'Мария', 'Елена', 'Ирина', 'Виктория',
    'Екатерина', 'Ольга', 'Анна', 'Алина', 'Софья',
    'Полина', 'Юлия', 'Татьяна', 'Ксения', 'Валерия',
  ];

  final List<String> _maleNames = const [
    'Алексей', 'Дмитрий', 'Иван', 'Максим', 'Артём',
    'Егор', 'Никита', 'Кирилл', 'Андрей', 'Сергей',
    'Михаил', 'Владимир', 'Роман', 'Павел', 'Даниил',
  ];

  final List<String> _femaleBio = const [
    'Студентка РЭУ. Ищу компанию для совместной учебы и прогулок.',
    'Увлекаюсь дизайном, фотографией и иностранными языками.',
    'Люблю хороший кофе, выставки и душевные разговоры.',
    'Пишу дипломную работу, в перерывах слушаю винил.',
  ];

  final List<String> _maleBio = const [
    'Студент МГТУ. Увлекаюсь техникой, спортом и музыкой.',
    'Играю на гитаре, люблю походы и активный отдых.',
    'Инженерное мышление, позитивный взгляд на жизнь.',
    'Ищу единомышленников для общения и совместных проектов.',
  ];

  final List<String> _shortMessageReplies = const [
    "Привет! Как твои дела?",
    "Привет! Что нового?",
    "Привет! Чем занимаешься?",
  ];

  final List<String> _femaleReplies = const [
    "Привет! Рада знакомству :) На каком курсе учишься?",
    "Привет! Тоже в этом корпусе учишься?",
    "Привет-привет! Как прошла сегодняшняя пара?",
  ];

  final List<String> _maleReplies = const [
    "Привет! Рад знакомству. Чем увлекаешься?",
    "Привет! Классная анкета, давно здесь?",
    "Привет! Как настроение сегодня?",
  ];

  ChatProvider([this.prefs]) {
    _initDefaultContext();
  }

  Set<String> get currentBlacklist => _personalBlacklists[_currentUserId] ?? {};

  List<UserProfile> get matches =>
      _matches.where((u) => !currentBlacklist.contains(u.userId)).toList();

  List<UserProfile> get blockedUsers {
    final ids = currentBlacklist;
    List<UserProfile> list = [];
    for (var id in ids) {
      for (var u in AuthService.testUsers) {
        if (u.userId == id) list.add(u);
      }
    }
    return list;
  }

  List<UserProfile> get likers => _likers;
  List<UserProfile> get swipeHistory => _swipeHistory;
  List<UserReport> get reports => _globalReports;

  int get totalUnreadCount {
    int count = 0;
    _history.forEach((_, list) {
      count += list.where((m) => !m.isMe && !m.isRead).length;
    });
    return count;
  }

  int getUnreadCount(String partnerId) {
    return (_history[partnerId] ?? []).where((m) => !m.isMe && !m.isRead).length;
  }

  void markAsRead(String partnerId) {
    final list = _history[partnerId];
    if (list != null && list.any((m) => !m.isMe && !m.isRead)) {
      for (var m in list) {
        if (!m.isMe) m.isRead = true;
      }
      notifyListeners();
    }
  }

  void updateUserId(String uid) {
    _currentUserId = uid;
    _initDefaultContext();
  }

  String _getChatKey(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}::${list[1]}';
  }

  void _initDefaultContext() {
    _matches.clear();
    _history.clear();

    _userMatches.putIfAbsent(_currentUserId, () => <String>{});
    final myMatchIds = _userMatches[_currentUserId]!;

    for (var id in myMatchIds) {
      if (id == _currentUserId || currentBlacklist.contains(id)) continue;

      UserProfile? user;
      for (var u in AuthService.testUsers) {
        if (u.userId == id) user = u;
      }

      user ??= UserProfile(
        userId: id,
        fullName: 'Студент',
        birthDate: DateTime(2003, 1, 1),
        gender: 'Студент',
        university: 'РЭУ им. Плеханова',
        photos: const ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'],
      );

      _matches.add(user);

      final chatKey = _getChatKey(_currentUserId, id);
      final rawList = _dialogDatabase[chatKey] ?? [];

      _history[id] = rawList.map((item) {
        final sId = item['senderId'] as String;
        return ChatMessage(
          senderId: sId,
          receiverId: item['receiverId'] as String,
          text: item['text'] as String,
          timestamp: DateTime.parse(item['timestamp'] as String),
          isMe: sId == _currentUserId,
          isRead: item['isRead'] ?? (sId == _currentUserId),
        );
      }).toList();

      if (_history[id]!.isNotEmpty) {
        user.lastMessage = _history[id]!.last.text;
      } else {
        user.lastMessage = 'Начните диалог';
      }
    }

    initLikers();
    notifyListeners();
  }

  void reportUser(String targetId, String targetName, String reason) {
    _globalReports.add(UserReport(
      fromUserId: _currentUserId,
      targetUserId: targetId,
      targetName: targetName,
      reason: reason,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void blockUser(String targetId) {
    _personalBlacklists[_currentUserId] ??= {};
    _personalBlacklists[_currentUserId]!.add(targetId);
    _matches.removeWhere((m) => m.userId == targetId);
    notifyListeners();
  }

  void unblockUser(String targetId) {
    if (_personalBlacklists[_currentUserId] != null) {
      _personalBlacklists[_currentUserId]!.remove(targetId);
      for (var u in AuthService.testUsers) {
        if (u.userId == targetId) {
          _matches.add(u);
        }
      }
      notifyListeners();
    }
  }

  void dismissReport(int index) {
    if (index >= 0 && index < _globalReports.length) {
      _globalReports.removeAt(index);
      notifyListeners();
    }
  }

  void initLikers() {
    if (_likers.isNotEmpty) return;
    for (int i = 0; i < 6; i++) {
      bool isF = i % 2 == 0;
      String name = isF ? _femaleNames[i] : _maleNames[i];
      String bio = isF ? _femaleBio[i % _femaleBio.length] : _maleBio[i % _maleBio.length];

      _likers.add(UserProfile(
        userId: 'liker_$i',
        fullName: name,
        birthDate: DateTime(2003, 5, 10 + i),
        gender: isF ? 'Женский' : 'Мужской',
        university: 'РЭУ им. Плеханова • Студент',
        bio: bio,
        status: 'В сети',
        photos: [
          isF
              ? 'https://randomuser.me/api/portraits/women/${20 + i}.jpg'
              : 'https://randomuser.me/api/portraits/men/${20 + i}.jpg'
        ],
        interests: const ['Музыка', 'Кофе', 'Спорт'],
      ));
    }
  }

  String getSuggestedGreeting(String text, String gender) {
    if (text.length < 3) {
      return _shortMessageReplies[_rnd.nextInt(_shortMessageReplies.length)];
    }
    if (gender == 'Женский') {
      return _femaleReplies[_rnd.nextInt(_femaleReplies.length)];
    }
    return _maleReplies[_rnd.nextInt(_maleReplies.length)];
  }

  void createMatch(UserProfile target) {
    if (target.userId == _currentUserId || currentBlacklist.contains(target.userId)) return;

    _userMatches.putIfAbsent(_currentUserId, () => <String>{});
    _userMatches[_currentUserId]!.add(target.userId);

    _userMatches.putIfAbsent(target.userId, () => <String>{});
    _userMatches[target.userId]!.add(_currentUserId);

    target.lastMessage = 'Начните диалог';
    _matches.removeWhere((m) => m.userId == target.userId);
    _matches.insert(0, target);
    _history[target.userId] ??= [];

    notifyListeners();
  }

  void addToHistory(UserProfile user) {
    _swipeHistory.add(user);
    notifyListeners();
  }

  UserProfile? undoLastSwipe() {
    if (_swipeHistory.isNotEmpty) {
      final user = _swipeHistory.removeLast();
      notifyListeners();
      return user;
    }
    return null;
  }

  String getLastMessage(String userId) {
    if (_history[userId] == null || _history[userId]!.isEmpty) {
      return "";
    }
    return _history[userId]!.last.text;
  }

  List<ChatMessage> getMessages(String id) {
    return _history[id] ?? [];
  }

  void sendMessage(String id, String text) {
    if (id == _currentUserId || currentBlacklist.contains(id)) return;

    _userMatches.putIfAbsent(_currentUserId, () => <String>{});
    _userMatches[_currentUserId]!.add(id);

    _userMatches.putIfAbsent(id, () => <String>{});
    _userMatches[id]!.add(_currentUserId);

    _history[id] ??= [];
    final now = DateTime.now();

    final msg = ChatMessage(
      senderId: _currentUserId,
      receiverId: id,
      text: text,
      timestamp: now,
      isMe: true,
      isRead: false,
    );
    _history[id]!.add(msg);

    for (var m in _matches) {
      if (m.userId == id) {
        m.lastMessage = text;
      }
    }

    final chatKey = _getChatKey(_currentUserId, id);
    _dialogDatabase[chatKey] ??= [];
    _dialogDatabase[chatKey]!.add({
      'senderId': _currentUserId,
      'receiverId': id,
      'text': text,
      'timestamp': now.toIso8601String(),
      'isRead': false,
    });

    notifyListeners();
  }
}