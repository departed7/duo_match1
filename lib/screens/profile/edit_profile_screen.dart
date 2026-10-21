import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:duo_match/providers/user_provider.dart';
import 'package:duo_match/core/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _uniCtrl;
  late TextEditingController _statusCtrl;
  late TextEditingController _relCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _uniCtrl = TextEditingController(text: user?.university ?? '');
    _statusCtrl = TextEditingController(text: user?.status ?? '');
    _relCtrl = TextEditingController(text: user?.relationship ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _uniCtrl.dispose();
    _statusCtrl.dispose(); _relCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final up = Provider.of<UserProvider>(context, listen: false);
    final u = up.currentUser;
    if (u == null) return;
    up.saveProfile(
      _nameCtrl.text.trim(),
      _bioCtrl.text.trim(),
      _uniCtrl.text.trim(),
      u.gender,
      u.birthDate,
      u.photos.isNotEmpty ? u.photos.first : 'assets/images/profile_1.jpg',
      u.avatarScale,
      u.videoPath,
      _statusCtrl.text.trim(),
      _relCtrl.text.trim(),
      _emailCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль'), backgroundColor: AppColors.primaryGreen),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_nameCtrl, 'Имя'),
              _buildField(_emailCtrl, 'Email'),
              _buildField(_uniCtrl, 'Университет'),
              _buildField(_statusCtrl, 'Статус'),
              _buildField(_relCtrl, 'Отношения'),
              _buildField(_bioCtrl, 'О себе', maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label), maxLines: maxLines),
    );
  }
}