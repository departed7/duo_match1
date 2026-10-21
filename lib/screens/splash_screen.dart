import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import 'auth/auth_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _animCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      final up = Provider.of<UserProvider>(context, listen: false);
      if (up.currentUser != null) {
        Provider.of<ChatProvider>(context, listen: false).updateUserId(up.currentUser!.userId);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainNavigationScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151A28),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFF222938),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 44,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'DUOMATCH',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 7,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151A28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF222938),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'STUDENT EDITION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'РЭУ им. Г.В. Плеханова • 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}