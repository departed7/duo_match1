import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isLogin = true;
  String? _pickedPath;

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email == 'admin' && pass == 'Password123!') {
      final admin = UserProfile(
        userId: 'admin_id',
        fullName: 'Александр (Admin)',
        university: 'РЭУ им. Плеханова',
        bio: 'Разработчик DuoMatch Premium',
        birthDate: DateTime(2003, 1, 1),
        gender: 'Мужской',
        photos: ['assets/images/profile_1.jpg'],
        interests: ['Код', 'Дизайн'],
        latitude: 0,
        longitude: 0,
        isPremium: true,
      );
      Provider.of<UserProvider>(context, listen: false).setUser(admin);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
      return;
    }

    if (email.isEmpty || !email.contains('@') && email.length < 10) {
      _showError('Введите корректный Email или телефон');
      return;
    }
    if (pass.length < 6) {
      _showError('Пароль должен быть от 6 символов');
      return;
    }

    if (!_isLogin && (_nameCtrl.text.isEmpty || _uniCtrl.text.isEmpty)) {
      _showError('Заполните данные профиля');
      return;
    }

    final user = UserProfile(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _isLogin ? 'Пользователь' : _nameCtrl.text,
      university: _isLogin ? 'Студент' : _uniCtrl.text,
      bio: _bioCtrl.text.isEmpty ? 'Привет! Я в DuoMatch' : _bioCtrl.text,
      birthDate: DateTime(2004, 1, 1),
      gender: 'Мужской',
      photos: [_pickedPath ?? 'assets/images/profile_1.jpg'],
      interests: [],
      latitude: 0,
      longitude: 0,
    );

    Provider.of<UserProvider>(context, listen: false).setUser(user);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.softCoral, size: 80),
              const SizedBox(height: 20),
              Text(_isLogin ? 'С ВОЗВРАЩЕНИЕМ' : 'СОЗДАТЬ АККАУНТ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 40),
              if (!_isLogin) ...[
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (img != null) setState(() => _pickedPath = img.path);
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _pickedPath != null ? FileImage(File(_pickedPath!)) : null,
                    child: _pickedPath == null ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(height: 30),
                _input(_nameCtrl, 'Ваше имя', Icons.person_outline),
                _input(_uniCtrl, 'Университет и курс', Icons.school_outlined),
                _input(_bioCtrl, 'О себе', Icons.edit_note_outlined),
              ],
              _input(_emailCtrl, 'Логин (Email или Телефон)', Icons.alternate_email),
              _input(_passCtrl, 'Пароль', Icons.lock_outline, obscure: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 65), backgroundColor: AppColors.electricBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                child: Text(_isLogin ? 'ВОЙТИ' : 'ЗАРЕГИСТРИРОВАТЬСЯ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти', style: const TextStyle(color: AppColors.graphite)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}