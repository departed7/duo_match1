import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../main.dart';
import '../auth/auth_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final up = Provider.of<UserProvider>(context);
    final u = up.currentUser;
    if (u == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('ПРОФИЛЬ')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          Transform.scale(scale: u.avatarScale, child: CircleAvatar(radius: 65, backgroundImage: u.photos.first.startsWith('assets') ? AssetImage(u.photos.first) as ImageProvider : FileImage(File(u.photos.first)))),
          if (u.isPremium) const CircleAvatar(radius: 18, backgroundColor: Colors.amber, child: Icon(Icons.star, color: Colors.white, size: 18)),
        ]),
        const SizedBox(height: 20),
        Text('${u.fullName}, ${u.age}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(u.university, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())), child: const Text('Редактировать')),
        const SizedBox(height: 20),
        _tile(Icons.workspace_premium, 'DuoMatch Premium', u.isPremium, (v) => up.setPremium(v), Colors.amber),
        _tile(Icons.dark_mode, 'Темная тема', tp.isDark, (v) => tp.toggleTheme(), AppColors.electricBlue),
        _tile(Icons.visibility_off, 'Невидимка', u.isIncognito, (v) => u.isPremium ? up.setIncognito(v) : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Только для Premium'))), Colors.purple),
        const SizedBox(height: 40),
        TextButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false), child: const Text('Выйти', style: TextStyle(color: Colors.red))),
      ])),
    );
  }

  Widget _tile(IconData i, String t, bool v, Function(bool) o, Color c) => ListTile(leading: Icon(i, color: c), title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Switch(value: v, onChanged: o, activeThumbColor: c));
}