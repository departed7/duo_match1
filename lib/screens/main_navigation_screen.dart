import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'swipe/swipe_screen.dart';
import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';
import '../providers/chat_provider.dart';
import '../core/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SwipeScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chat = Provider.of<ChatProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.style_outlined, Icons.style_rounded, 'Анкеты'),
                _navItem(1, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Мэтчи', badge: chat.totalUnreadCount),
                _navItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Профиль'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData iconOutlined, IconData iconFilled, String label, {int badge = 0}) {
    final selected = _currentIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? iconFilled : iconOutlined,
                  color: selected ? AppColors.primary : Colors.grey,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}