import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../screens/main_navigation_screen.dart';

class AuthService {
  static const String _sessionKey = 'is_logged_in';
  static const String _adminLogin = 'admin';
  static const String _adminPass = 'Password123!';

  static String? validateIdentity(String value) {
    if (value.isEmpty) {
      return 'Введите Email или Телефон';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^\+?[78]?[0-9]{10,11}$');
    if (value == _adminLogin) {
      return null;
    }
    if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value)) {
      return 'Неверный формат почты или номера';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Введите пароль';
    }
    if (value == _adminPass) {
      return null;
    }
    if (value.length < 8) {
      return 'Минимум 8 символов';
    }
    return null;
  }

  static Future<void> performLogin({
    required BuildContext context,
    required String login,
    required String password,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    if (login == _adminLogin && password == _adminPass) {
      final admin = UserProfile(
        userId: 'admin_root',
        fullName: 'Александр (Admin)',
        university: 'РЭУ им. Плеханова',
        bio: 'Главный разработчик DuoMatch Premium.',
        birthDate: DateTime(2003, 1, 1),
        gender: 'Мужской',
        photos: ['assets/images/profile_1.jpg'],
        interests: ['Dart', 'Flutter'],
        latitude: 55.75,
        longitude: 37.61,
        isPremium: true,
      );

      if (!context.mounted) {
        return;
      }

      Provider.of<UserProvider>(context, listen: false).setUser(admin);
      await prefs.setBool(_sessionKey, true);
      
      if (!context.mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      throw Exception('Пользователь не найден. Зарегистрируйтесь.');
    }
  }

  static Future<void> performRegistration({
    required BuildContext context,
    required String name,
    required String uni,
    required String bio,
    required String gender,
    required DateTime birth,
    required String photo,
    required double scale,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final newUser = UserProfile(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: name,
      university: uni,
      bio: bio,
      birthDate: birth,
      gender: gender,
      photos: [photo],
      interests: [],
      latitude: 55.75,
      longitude: 37.61,
      avatarScale: scale,
    );

    if (!context.mounted) {
      return;
    }

    Provider.of<UserProvider>(context, listen: false).setUser(newUser);
    await prefs.setBool(_sessionKey, true);

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }
}