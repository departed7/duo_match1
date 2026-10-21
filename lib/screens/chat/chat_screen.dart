import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:duo_match/providers/chat_provider.dart';
import 'package:duo_match/models/user_model.dart';
import 'package:duo_match/core/app_theme.dart';
import 'package:duo_match/providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final curUser = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (curUser != null) {
        Provider.of<ChatProvider>(context, listen: false).updateUserId(curUser.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final allMatches = chat.matches;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Сообщения', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: false,
        elevation: 0,
      ),
      body: allMatches.isEmpty
          ? const Center(child: Text('Нет активных совпадений. Свайпайте анкеты!', style: TextStyle(color: Colors.grey)))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: Text(
                    'Новые пары',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: allMatches.length,
                    itemBuilder: (context, i) {
                      final m = allMatches[i];
                      return GestureDetector(
                        onTap: () {
                          chat.markAsRead(m.userId);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailView(user: m)));
                        },
                        child: Container(
                          width: 74,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: m.isPremium
                                        ? const [Colors.amber, Colors.orange]
                                        : const [AppColors.primary, AppColors.blue],
                                  ),
                                ),
                                child: SafeAvatar(user: m, size: 52),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                m.fullName.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Text(
                    'Диалоги',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                ...allMatches.map((u) {
                  final unread = chat.getUnreadCount(u.userId);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: SafeAvatar(user: u, size: 48),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.fullName,
                              style: TextStyle(
                                fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                          if (u.isPremium)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          u.lastMessage ?? 'Начните диалог',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? (isDark ? Colors.white : Colors.black87) : Colors.grey[600],
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: unread > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      onTap: () {
                        chat.markAsRead(u.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatDetailView(user: u)),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class SafeAvatar extends StatefulWidget {
  final UserProfile user;
  final double size;

  const SafeAvatar({super.key, required this.user, this.size = 50});

  @override
  State<SafeAvatar> createState() => _SafeAvatarState();
}

class _SafeAvatarState extends State<SafeAvatar> {
  VideoPlayerController? _vCtrl;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant SafeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.videoPath != widget.user.videoPath) {
      _initVideo();
    }
  }

  void _initVideo() async {
    _vCtrl?.dispose();
    _vCtrl = null;

    final v = widget.user.videoPath;
    if (v != null && v.isNotEmpty) {
      if (v.startsWith('http')) {
        _vCtrl = VideoPlayerController.networkUrl(Uri.parse(v));
      } else if (File(v).existsSync()) {
        _vCtrl = VideoPlayerController.file(File(v));
      }

      if (_vCtrl != null) {
        await _vCtrl!.initialize();
        await _vCtrl!.setVolume(0);
        await _vCtrl!.setLooping(true);
        _vCtrl!.addListener(() {
          if (_vCtrl != null && _vCtrl!.value.isInitialized) {
            if (_vCtrl!.value.position >= _vCtrl!.value.duration) {
              _vCtrl!.seekTo(Duration.zero);
              _vCtrl!.play();
            }
          }
        });
        await _vCtrl!.play();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _vCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _vCtrl != null && _vCtrl!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _vCtrl!.value.size.width,
                  height: _vCtrl!.value.size.height,
                  child: VideoPlayer(_vCtrl!),
                ),
              )
            : _renderImage(),
      ),
    );
  }

  Widget _renderImage() {
    final photo = widget.user.photos.isNotEmpty ? widget.user.photos.first : '';

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
}

class ChatDetailView extends StatefulWidget {
  final UserProfile user;
  const ChatDetailView({super.key, required this.user});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _send() {
    if (_msgCtrl.text.trim().isEmpty) return;
    Provider.of<ChatProvider>(context, listen: false).sendMessage(widget.user.userId, _msgCtrl.text.trim());
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReportDialog() {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Модерация анкеты', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Действие в отношении ${widget.user.fullName}:', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Пожаловаться за спам/оскорбления'),
              onTap: () {
                chat.reportUser(widget.user.userId, widget.user.fullName, 'Спам / неприемлемое поведение');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Жалоба отправлена администратору на модерацию')),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Заблокировать навсегда', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                chat.blockUser(widget.user.userId);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.user.fullName} заблокирован(а) и удален(а) из чатов')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final msgs = chat.getMessages(widget.user.userId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0.5,
        title: Row(
          children: [
            SafeAvatar(user: widget.user, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.fullName, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                  Text(widget.user.university.split('•').first.trim(), style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.grey, size: 22),
            tooltip: 'Модерация',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: msgs.length,
              itemBuilder: (ctx, i) {
                final msg = msgs[i];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color: msg.isMe ? AppColors.primary : theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                      ),
                      border: msg.isMe ? null : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.cardColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Написать сообщение...',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}