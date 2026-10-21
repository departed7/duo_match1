import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../providers/user_provider.dart';
import '../../core/app_theme.dart';
import '../main_navigation_screen.dart';
import '../../services/auth_service.dart';
import '../../providers/chat_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _uniCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _districtSearchCtrl = TextEditingController();
  final TextEditingController _uniSearchCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime _birthDate = DateTime(2003, 1, 1);
  String _gender = 'Мужской';
  String _lookingFor = 'Отношения';
  String _lookingForGender = 'Женский';
  String _relationship = 'Свободен';
  String _district = 'Центральный';
  String _avatarPath = 'assets/images/profile_1.jpg';
  String? _videoPath;
  bool _isLoading = false;
  bool _isPremium = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  VideoPlayerController? _videoController;
  String? _authError;
  bool _isMediaLoading = false;

  final List<String> _allDistricts = const [
    'Центральный', 'Северный', 'Южный', 'Восточный', 'Западный',
    'Арбат', 'Хамовники', 'Пресненский', 'Тверской', 'Басманный',
    'Химки', 'Мытищи', 'Королёв', 'Люберцы', 'Красногорск',
    'Одинцово', 'Балашиха', 'Реутов', 'Долгопрудный', 'Видное',
  ];

  final List<String> _allUnis = const [
    'РЭУ им. Плеханова', 'МГУ', 'МГТУ им. Баумана', 'ВШЭ', 'РУДН',
    'РАНХиГС', 'МГИМО', 'МИФИ', 'Финансовый университет',
    'МГМСУ', 'МАРХИ', 'РГГУ', 'МПГУ', 'МИСиС', 'РХТУ',
  ];

  final List<String> _lookingForOptions = const [
    'Отношения', 'Дружба', 'Общение', 'Компания для учёбы', 'Совместные прогулки',
  ];

  List<String> get _filteredDistricts {
    if (_districtSearchCtrl.text.isEmpty) return _allDistricts;
    return _allDistricts.where((d) => d.toLowerCase().contains(_districtSearchCtrl.text.toLowerCase())).toList();
  }

  List<String> get _filteredUnis {
    if (_uniSearchCtrl.text.isEmpty) return _allUnis;
    return _allUnis.where((u) => u.toLowerCase().contains(_uniSearchCtrl.text.toLowerCase())).toList();
  }

  List<String> get _relationships {
    if (_gender == 'Мужской') {
      return const ['Свободен', 'В отношениях', 'Влюблён', 'Всё сложно', 'В активном поиске'];
    } else {
      return const ['Свободна', 'В отношениях', 'Влюблена', 'Всё сложно', 'В активном поиске'];
    }
  }

  @override
  void initState() {
    super.initState();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _districtSearchCtrl.addListener(() => setState(() {}));
    _uniSearchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _uniCtrl.dispose();
    _bioCtrl.dispose();
    _districtSearchCtrl.dispose();
    _uniSearchCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _authError = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _phoneCtrl.clear();
      _nameCtrl.clear();
      _uniCtrl.clear();
      _bioCtrl.clear();
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 30);
    final last = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: last,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickMedia(bool isVideo) async {
    final file = isVideo 
        ? await _picker.pickVideo(source: ImageSource.gallery) 
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (file != null) {
      setState(() => _isMediaLoading = true);
      if (isVideo) {
        if (_videoController != null) await _videoController!.dispose();
        _videoController = VideoPlayerController.file(File(file.path));
        await _videoController!.initialize();
        await _videoController!.setVolume(0);
        await _videoController!.setLooping(true);
        await _videoController!.play();
        setState(() {
          _videoPath = file.path;
          _avatarPath = file.path;
          _isMediaLoading = false;
        });
      } else {
        if (_videoController != null) await _videoController!.dispose();
        setState(() {
          _avatarPath = file.path;
          _videoPath = null;
          _videoController = null;
          _isMediaLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _authError = 'Заполните все поля');
      return;
    }

    final up = Provider.of<UserProvider>(context, listen: false);
    final cp = Provider.of<ChatProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _authError = null;
    });

    final testUser = AuthService.getTestUser(email, pass);
    if (testUser != null) {
      up.setUser(testUser);
      cp.updateUserId(testUser.userId);

      final p = await SharedPreferences.getInstance();
      await p.setString('session_email', testUser.email);
      await p.setString('my_looking_for_gender', testUser.gender == 'Мужской' ? 'Женский' : 'Мужской');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
      return;
    }

    if (_isLoginMode) {
      final p = await SharedPreferences.getInstance();
      final savedEmail = p.getString('session_email');
      final savedPass = p.getString('session_password');

      if (savedEmail == email && savedPass == pass) {
        if (up.currentUser != null) {
          cp.updateUserId(up.currentUser!.userId);
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _authError = 'Неверный логин или пароль';
        });
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    up.saveProfile(
      _nameCtrl.text.trim(),
      _bioCtrl.text.trim().isEmpty ? 'Студент DuoMatch' : _bioCtrl.text.trim(),
      _uniCtrl.text.trim().isEmpty ? 'РЭУ им. Плеханова' : _uniCtrl.text.trim(),
      _gender,
      _birthDate,
      _avatarPath,
      1.0,
      _videoPath,
      'В сети',
      _relationship,
      email,
    );

    final p = await SharedPreferences.getInstance();
    await p.setString('session_email', email);
    await p.setString('session_password', pass);
    await p.setString('my_looking_for_gender', _lookingForGender);
    await p.setBool('my_premium', _isPremium);

    if (up.currentUser != null) {
      cp.updateUserId(up.currentUser!.userId);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Widget _buildAvatarFrame() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: ClipOval(
            child: _isMediaLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: 110,
                    height: 110,
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        : Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover),
                  ),
          ),
        ),
        TextButton.icon(
          onPressed: _showMediaOptions,
          icon: const Icon(Icons.add_a_photo, color: AppColors.primary, size: 20),
          label: const Text('Загрузить фото/видео', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: const Text('Выбрать фото из галереи'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.amber),
                title: const Text('Загрузить видео-аватар (до 10 сек)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUniPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final list = _filteredUnis;
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _uniSearchCtrl,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Поиск университета...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setSheetState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(list[i], style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      onTap: () {
                        setState(() {
                          _uniCtrl.text = list[i];
                          _uniSearchCtrl.clear();
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final list = _filteredDistricts;
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _districtSearchCtrl,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Поиск района Москвы...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setSheetState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(list[i], style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      onTap: () {
                        setState(() {
                          _district = list[i];
                          _districtSearchCtrl.clear();
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: suffix,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPicker(String label, String value, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          child: Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'DuoMatch',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginMode ? 'Авторизация в системе' : 'Регистрация студента',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),
                  if (!_isLoginMode) _buildAvatarFrame(),
                  if (_authError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(_authError!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  _buildField(_emailCtrl, 'Email', Icons.mail_outline),
                  _buildField(
                    _passwordCtrl,
                    'Пароль',
                    Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  if (!_isLoginMode) ...[
                    _buildField(_nameCtrl, 'Имя и фамилия', Icons.person_outline),
                    _buildField(_phoneCtrl, 'Телефон (+7...)', Icons.phone_android_outlined),
                    _buildField(_bioCtrl, 'О себе', Icons.info_outline),
                    _buildPicker('Университет', _uniCtrl.text.isEmpty ? 'Выберите ВУЗ из списка' : _uniCtrl.text, Icons.school_outlined, _showUniPicker),
                    _buildPicker('Дата рождения', '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}', Icons.cake_outlined, _pickBirthDate),
                    _buildPicker('Район проживания', _district, Icons.location_on_outlined, _showDistrictPicker),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: InputDecoration(
                          labelText: 'Мой пол',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),
                          DropdownMenuItem(value: 'Женский', child: Text('Женский')),
                        ],
                        onChanged: (v) => setState(() {
                          _gender = v!;
                          _relationship = (v == 'Мужской' ? 'Свободен' : 'Свободна');
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _lookingForGender,
                        decoration: InputDecoration(
                          labelText: 'Кого ищу',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Мужской', child: Text('Парней')),
                          DropdownMenuItem(value: 'Женский', child: Text('Девушек')),
                        ],
                        onChanged: (v) => setState(() => _lookingForGender = v!),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _lookingFor,
                        decoration: InputDecoration(
                          labelText: 'Цель поиска',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: _lookingForOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) => setState(() => _lookingFor = v!),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('DuoMatch Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Видео-аватары и режим невидимки'),
                      value: _isPremium,
                      activeThumbColor: Colors.amber,
                      onChanged: (v) => setState(() => _isPremium = v),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLoginMode ? 'Войти' : 'Создать аккаунт', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _switchMode,
                    child: Text(
                      _isLoginMode ? 'Создать новый аккаунт' : 'Уже есть аккаунт? Войти',
                      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}