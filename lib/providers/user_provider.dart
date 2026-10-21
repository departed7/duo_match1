import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  UserProfile? _currentUser;

  int _totalSwipes = 0;
  int _likesCount = 0;
  int _matchesCount = 0;

  UserProvider(this._prefs) {
    _initUser();
  }

  UserProfile? get currentUser => _currentUser;
  int get totalSwipes => _totalSwipes;
  int get likesCount => _likesCount;
  int get matchesCount => _matchesCount;
  int get matchRate => _totalSwipes == 0 ? 0 : ((_matchesCount / _totalSwipes) * 100).round();

  void _loadUserStats(String uid) {
    if (uid == 'u_volkov') {
      _totalSwipes = _prefs.getInt('swipes_$uid') ?? 42;
      _likesCount = _prefs.getInt('likes_$uid') ?? 26;
      _matchesCount = _prefs.getInt('matches_$uid') ?? 8;
    } else if (uid == 'u_belova') {
      _totalSwipes = _prefs.getInt('swipes_$uid') ?? 35;
      _likesCount = _prefs.getInt('likes_$uid') ?? 14;
      _matchesCount = _prefs.getInt('matches_$uid') ?? 11;
    } else if (uid == 'u_osipyan') {
      _totalSwipes = _prefs.getInt('swipes_$uid') ?? 28;
      _likesCount = _prefs.getInt('likes_$uid') ?? 10;
      _matchesCount = _prefs.getInt('matches_$uid') ?? 7;
    } else {
      _totalSwipes = _prefs.getInt('swipes_$uid') ?? 18;
      _likesCount = _prefs.getInt('likes_$uid') ?? 9;
      _matchesCount = _prefs.getInt('matches_$uid') ?? 4;
    }
  }

  void _initUser() {
    final String? name = _prefs.getString('my_full_name');
    final String uid = _prefs.getString('my_user_id') ?? 'u_volkov';
    _loadUserStats(uid);

    if (name != null && name.isNotEmpty) {
      String photoPath = _prefs.getString('my_photo') ?? 'assets/images/profile_1.jpg';

      if (!photoPath.startsWith('assets') && !photoPath.startsWith('http') && !File(photoPath).existsSync()) {
        photoPath = 'assets/images/profile_1.jpg';
      }

      _currentUser = UserProfile(
        userId: uid,
        fullName: name,
        university: _prefs.getString('my_uni') ?? 'РЭУ им. Плеханова',
        bio: _prefs.getString('my_bio') ?? 'Студент DuoMatch',
        status: _prefs.getString('my_status') ?? 'Учусь в ВУЗе',
        birthDate: DateTime.tryParse(_prefs.getString('my_birth') ?? '') ?? DateTime(2004, 1, 1),
        gender: _prefs.getString('my_gender') ?? 'Мужской',
        photos: [photoPath],
        interests: const ['Музыка', 'Кофе', 'Спорт', 'Учеба'],
        isPremium: _prefs.getBool('my_premium') ?? false,
        isIncognito: _prefs.getBool('incognito_$uid') ?? false,
        avatarScale: _prefs.getDouble('my_scale') ?? 1.0,
        videoPath: _prefs.getString('my_video'),
        relationship: _prefs.getString('my_relationship') ?? 'Свободен',
      );
    }
  }

  void setIncognito(bool v) {
    if (_currentUser != null) {
      _currentUser!.isIncognito = v;
      _prefs.setBool('incognito_${_currentUser!.userId}', v);
      notifyListeners();
    }
  }

  void recordDislike() {
    if (_currentUser == null) return;
    _totalSwipes++;
    _prefs.setInt('swipes_${_currentUser!.userId}', _totalSwipes);
    notifyListeners();
  }

  void recordLike({bool isMatch = false}) {
    if (_currentUser == null) return;
    _totalSwipes++;
    _likesCount++;
    if (isMatch) _matchesCount++;
    _prefs.setInt('swipes_${_currentUser!.userId}', _totalSwipes);
    _prefs.setInt('likes_${_currentUser!.userId}', _likesCount);
    _prefs.setInt('matches_${_currentUser!.userId}', _matchesCount);
    notifyListeners();
  }

  void setUser(UserProfile user) {
    _currentUser = user;
    _loadUserStats(user.userId);
    _prefs.setString('my_user_id', user.userId);
    _prefs.setString('my_full_name', user.fullName);
    if (user.photos.isNotEmpty) {
      _prefs.setString('my_photo', user.photos.first);
    }
    _prefs.setBool('my_premium', user.isPremium);
    notifyListeners();
  }

  void saveProfile(
    String n,
    String b,
    String u,
    String g,
    DateTime d,
    String p,
    double s,
    String? v,
    String st, [
    String rel = 'Свободен',
    String? email,
  ]) {
    final uid = _currentUser?.userId ?? 'u_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = UserProfile(
      userId: uid,
      fullName: n,
      university: u,
      bio: b,
      birthDate: d,
      gender: g,
      photos: [p],
      interests: const ['Музыка', 'Кофе', 'Спорт'],
      relationship: rel,
      email: email ?? '',
      isPremium: _currentUser?.isPremium ?? false,
      isIncognito: _currentUser?.isIncognito ?? false,
    );

    _prefs.setString('my_user_id', uid);
    _prefs.setString('my_full_name', n);
    _prefs.setString('my_bio', b);
    _prefs.setString('my_uni', u);
    _prefs.setString('my_gender', g);
    _prefs.setString('my_birth', d.toIso8601String());
    _prefs.setString('my_photo', p);
    _prefs.setDouble('my_scale', s);
    _prefs.setString('my_status', st);
    _prefs.setString('my_relationship', rel);
    if (v != null) _prefs.setString('my_video', v);
    if (email != null) _prefs.setString('session_email', email);

    notifyListeners();
  }

  void updateStatus(String s) {
    if (_currentUser != null) {
      _currentUser!.status = s;
      _prefs.setString('my_status', s);
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

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}