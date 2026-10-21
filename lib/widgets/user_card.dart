import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/user_model.dart';
import '../core/app_theme.dart';

class UserCard extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const UserCard({
    super.key,
    required this.user,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  VideoPlayerController? _vCtrl;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.userId != widget.user.userId || oldWidget.user.videoPath != widget.user.videoPath) {
      _initVideo();
    }
  }

  void _initVideo() async {
    _vCtrl?.dispose();
    _vCtrl = null;

    final vPath = widget.user.videoPath;
    if (vPath != null && vPath.isNotEmpty) {
      if (vPath.startsWith('http')) {
        _vCtrl = VideoPlayerController.networkUrl(Uri.parse(vPath));
      } else if (File(vPath).existsSync()) {
        _vCtrl = VideoPlayerController.file(File(vPath));
      }

      if (_vCtrl != null) {
        await _vCtrl!.initialize();
        _vCtrl!.setVolume(0);
        _vCtrl!.setLooping(true);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = widget.user;

    return GestureDetector(
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -250) {
          widget.onSwipeLeft();
        } else if (details.velocity.pixelsPerSecond.dx > 250) {
          widget.onSwipeRight();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.cardColor,
          border: Border.all(
            color: user.isPremium ? Colors.amber : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: user.isPremium ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildMedia(user),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.4, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Плашка расстояния (скрывается при Инкогнито)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isIncognito ? Icons.visibility_off : Icons.near_me,
                        size: 13,
                        color: user.isIncognito ? Colors.amber : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isIncognito ? 'Скрыто' : '1.4 км',
                        style: TextStyle(
                          color: user.isIncognito ? Colors.amber : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${user.fullName}, ${user.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isPremium) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 22),
                              ],
                            ],
                          ),
                        ),
                        if (_vCtrl != null && _vCtrl!.value.isInitialized)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.play_arrow, size: 14, color: Colors.black87),
                                Text('ВИДЕО', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 15, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.university,
                            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Статус пользователя
                    if (user.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          user.status,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),

                    const SizedBox(height: 8),
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (user.interests.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.interests.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(UserProfile user) {
    if (_vCtrl != null && _vCtrl!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _vCtrl!.value.size.width,
          height: _vCtrl!.value.size.height,
          child: VideoPlayer(_vCtrl!),
        ),
      );
    }

    final String photoPath = user.photos.isNotEmpty ? user.photos.first : '';

    if (photoPath.startsWith('assets')) {
      return Image.asset(photoPath, fit: BoxFit.cover);
    }

    if (photoPath.startsWith('http')) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover),
      );
    }

    if (File(photoPath).existsSync()) {
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover),
      );
    }

    return Image.asset('assets/images/profile_1.jpg', fit: BoxFit.cover);
  }
}