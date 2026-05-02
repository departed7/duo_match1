import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _n, _b, _u;
  late String _g;
  late DateTime _d;
  String? _p, _v;
  double _s = 1.0;

  @override
  void initState() {
    super.initState();
    final u = Provider.of<UserProvider>(context, listen: false).currentUser!;
    _n = TextEditingController(text: u.fullName);
    _b = TextEditingController(text: u.bio);
    _u = TextEditingController(text: u.university);
    _g = u.gender; 
    _d = u.birthDate; 
    _p = u.photos.first; 
    _s = u.avatarScale; 
    _v = u.videoPath;
  }

  @override
  Widget build(BuildContext context) {
    final up = Provider.of<UserProvider>(context);
    final user = up.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('РЕДАКТИРОВАНИЕ'), actions: [IconButton(icon: const Icon(Icons.done_all_rounded, color: AppColors.electricBlue), onPressed: () {
        up.saveProfile(_n.text, _b.text, _u.text, _g, _d, _p!, _s, _v);
        Navigator.pop(context);
      })]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
        const Text('Настройте размер аватарки'),
        Slider(value: _s, min: 0.5, max: 1.5, activeColor: AppColors.electricBlue, onChanged: (v) => setState(() => _s = v)),
        GestureDetector(
          onTap: () async {
            final img = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (img != null) {
              setState(() => _p = img.path);
            }
          },
          child: Container(
            height: 150 * _s, width: 150 * _s,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: AppColors.electricBlue, width: 3),
              image: DecorationImage(image: _p!.startsWith('assets') ? AssetImage(_p!) as ImageProvider : FileImage(File(_p!)), fit: BoxFit.cover)
            ),
          ),
        ),
        const SizedBox(height: 30),
        if (user.isPremium) ...[
          ElevatedButton.icon(onPressed: () => setState(() => _v = "video_path"), icon: const Icon(Icons.videocam), label: Text(_v == null ? 'Загрузить видео' : 'Видео загружено')),
          const SizedBox(height: 20),
        ],
        _f(_n, 'ФИО'),
        _f(_u, 'Университет'),
        _f(_b, 'О себе', m: 5),
      ])),
    );
  }

  Widget _f(TextEditingController c, String l, {int m = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(controller: c, maxLines: m, decoration: InputDecoration(labelText: l, filled: true)),
    );
  }
}