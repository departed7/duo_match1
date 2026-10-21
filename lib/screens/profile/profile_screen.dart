import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../main.dart';
import '../auth/auth_screen.dart';
import 'edit_profile_screen.dart';
import '../../services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _statusController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isExporting = false;
  bool _isMediaChanging = false;

  String _email = 'Не указан';
  String _phone = 'Не указан';
  String _relationship = 'Свободен';
  String _district = 'Центральный';

  final List<String> _quickStatuses = const [
    '📚 На парах',
    '☕ На перерыве',
    '🎧 В наушниках',
    '💻 Пишу курсач',
    '🍕 В столовой',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final up = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    String emailVal = prefs.getString('session_email') ?? prefs.getString('my_email') ?? 'Не указан';
    String phoneVal = prefs.getString('session_phone') ?? prefs.getString('my_phone') ?? 'Не указан';
    String distVal = prefs.getString('session_dist') ?? prefs.getString('my_district') ?? 'Центральный';
    String relVal = prefs.getString('my_relationship') ?? 'Свободен';

    try {
      final dynamic u = up.currentUser;
      if (u != null && u.email != null && (u.email as String).isNotEmpty) {
        emailVal = u.email;
      }
    } catch (_) {}

    setState(() {
      _email = emailVal;
      _phone = phoneVal;
      _district = distVal;
      _relationship = relVal;
    });

    if (up.currentUser != null) {
      _statusController.text = up.currentUser!.status;
      if (up.currentUser!.videoPath != null) {
        _initVideo(up.currentUser!.videoPath!);
      }
    }
  }

  Future<void> _initVideo(String path) async {
    _videoController?.dispose();
    _videoController = null;

    if (path.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
    } else if (File(path).existsSync()) {
      _videoController = VideoPlayerController.file(File(path));
    }

    if (_videoController != null) {
      await _videoController!.initialize();
      await _videoController!.setVolume(0);
      await _videoController!.setLooping(true);
      _videoController!.addListener(() {
        if (_videoController != null && _videoController!.value.isInitialized) {
          if (_videoController!.value.position >= _videoController!.value.duration) {
            _videoController!.seekTo(Duration.zero);
            _videoController!.play();
          }
        }
      });
      await _videoController!.play();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    final up = Provider.of<UserProvider>(context, listen: false);
    final u = up.currentUser;
    if (u == null) return;

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
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 18),
              const Text('Обновить фото профиля', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Выбрать фото из галереи'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(false, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: Colors.amber),
                title: Text(
                  u.isPremium ? 'Загрузить видео-аватар (до 10 сек)' : 'Видео-аватар (Требуется Premium)',
                  style: TextStyle(color: u.isPremium ? null : Colors.grey),
                ),
                trailing: u.isPremium ? null : const Icon(Icons.lock, color: Colors.amber, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  if (u.isPremium) {
                    _pickMedia(true, ImageSource.gallery);
                  } else {
                    _showPremiumDialog();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(bool isVideo, ImageSource source) async {
    final file = isVideo 
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 10))
        : await _picker.pickImage(source: source, imageQuality: 85);

    if (file != null && mounted) {
      setState(() => _isMediaChanging = true);
      final up = Provider.of<UserProvider>(context, listen: false);

      if (isVideo) {
        up.setAvatar(file.path);
        up.currentUser!.videoPath = file.path;
        await _initVideo(file.path);
      } else {
        _videoController?.dispose();
        _videoController = null;
        up.currentUser!.videoPath = null;
        up.setAvatar(file.path);
      }

      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _isMediaChanging = false);
    }
  }

  void _showBlacklistSheet(ChatProvider chat) {
    final blocked = chat.blockedUsers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            const Text('Чёрный список', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Заблокированные пользователи не видят ваш профиль и не могут писать сообщения.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: blocked.isEmpty
                  ? const Center(child: Text('В чёрном списке никого нет', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: blocked.length,
                      itemBuilder: (_, i) {
                        final b = blocked[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2234) : const Color(0xFFF1F3F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: b.photos.first.startsWith('assets')
                                  ? AssetImage(b.photos.first) as ImageProvider
                                  : NetworkImage(b.photos.first),
                            ),
                            title: Text(b.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(b.university, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: TextButton(
                              onPressed: () {
                                chat.unblockUser(b.userId);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${b.fullName} разблокирован(а)')),
                                );
                              },
                              child: const Text('Разблокировать', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    final up = Provider.of<UserProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'DuoMatch Premium',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Загрузка видео-аватаров'),
            SizedBox(height: 8),
            Text('• Отмена последнего свайпа (Rewind)'),
            SizedBox(height: 8),
            Text('• Режим приватности «Инкогнито»'),
            SizedBox(height: 8),
            Text('• Безлимитный поиск без ограничений'),
            SizedBox(height: 8),
            Text('• Золотая VIP-рамка в анкете'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              up.setPremium(true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Премиум-подписка активирована!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
            child: const Text('Активировать', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final up = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('session_email');
    await prefs.remove('session_password');
    await prefs.remove('my_email');
    await prefs.remove('my_password');
    await prefs.remove('my_user_id');
    await prefs.remove('my_full_name');

    up.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildAvatarWidget(UserProfile u) {
    if (_isMediaChanging) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    final photo = u.photos.isNotEmpty ? u.photos.first : '';

    if (photo.startsWith('assets')) {
      return Image.asset(photo, fit: BoxFit.cover);
    }

    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover),
      );
    }

    if (File(photo).existsSync()) {
      return Image.file(
        File(photo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover),
      );
    }

    return Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover);
  }

  Widget _buildAdminModerationCard(ChatProvider chat) {
    final reports = chat.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Панель модератора (Жалобы)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: reports.isEmpty ? Colors.grey.withValues(alpha: 0.2) : Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${reports.length}',
                  style: TextStyle(color: reports.isEmpty ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            const Text('Новых жалоб нет. Сообщество в порядке.', style: TextStyle(color: Colors.grey, fontSize: 12.5))
          else
            ...reports.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2234) : const Color(0xFFF1F3F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.targetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Text(r.reason, style: const TextStyle(color: Colors.orange, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.block, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        chat.blockUser(r.targetUserId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${r.targetName} заблокирован(а)')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () => chat.dismissReport(idx),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(UserProvider up) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Статистика активности',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Свайпы', '${up.totalSwipes}'),
              _statItem('Лайки', '${up.likesCount}'),
              _statItem('Мэтчи', '${up.matchesCount}'),
              _statItem('Взаимность', '${up.matchRate}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final up = Provider.of<UserProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final chat = Provider.of<ChatProvider>(context);
    final u = up.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (u == null) return const Scaffold();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              _loadUserData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: u.isPremium
                              ? const [Colors.amber, Colors.orange]
                              : const [AppColors.primary, AppColors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Theme.of(context).cardColor,
                          child: _buildAvatarWidget(u),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: u.isPremium ? Colors.amber : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: Icon(u.isPremium ? Icons.workspace_premium : Icons.camera_alt, color: Colors.white, size: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${u.fullName}, ${u.age}',
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 6),
                Icon(u.isPremium ? Icons.workspace_premium : Icons.verified, color: u.isPremium ? Colors.amber : AppColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _statusController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ваш статус...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primary, size: 20),
                    onPressed: () {
                      up.updateStatus(_statusController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Статус обновлен!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickStatuses.map((st) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(st, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      onPressed: () {
                        _statusController.text = st;
                        up.updateStatus(st);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            if (!u.isPremium)
              GestureDetector(
                onTap: _showPremiumDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Оформить DuoMatch Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('DuoMatch Premium Активен', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            if (u.userId == 'admin_1') _buildAdminModerationCard(chat),

            _buildAnalyticsCard(up),

            const SizedBox(height: 14),

            _infoBlock(u),

            const SizedBox(height: 14),

            // Пункт «Чёрный список»
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
              ),
              child: ListTile(
                leading: const Icon(Icons.block_outlined, color: AppColors.primary, size: 22),
                title: const Text('Чёрный список', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Заблокировано: ${chat.currentBlacklist.length}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                onTap: () => _showBlacklistSheet(chat),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
              ),
              child: SwitchListTile(
                secondary: const Icon(Icons.visibility_off_outlined, color: AppColors.primary, size: 22),
                title: const Text('Режим «Инкогнито»', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Скрыть статус и дистанцию в ленте', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                value: u.isIncognito,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  if (!u.isPremium) {
                    _showPremiumDialog();
                    return;
                  }
                  up.setIncognito(v);
                },
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
              ),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary, size: 22),
                title: const Text('Тёмная тема', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                value: themeProv.isDark,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => themeProv.toggleTheme(),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isExporting
                    ? null
                    : () async {
                        setState(() => _isExporting = true);
                        try {
                          await ExportService.generateAndShareApk();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
                          }
                        }
                        if (mounted) setState(() => _isExporting = false);
                      },
                icon: _isExporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_outlined, size: 18),
                label: const Text('Экспорт APK-пакета', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: const Text(
                'ВЫЙТИ ИЗ АККАУНТА',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(UserProfile u) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        children: [
          _row(Icons.email_outlined, 'Email', _email),
          const Divider(height: 16),
          _row(Icons.phone_android_outlined, 'Телефон', _phone),
          const Divider(height: 16),
          _row(Icons.school_outlined, 'ВУЗ', u.university),
          const Divider(height: 16),
          _row(Icons.favorite_outline, 'Отношения', _relationship),
          const Divider(height: 16),
          _row(Icons.location_on_outlined, 'Район', _district),
        ],
      ),
    );
  }

  Widget _row(IconData i, String l, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(i, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(l, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
}