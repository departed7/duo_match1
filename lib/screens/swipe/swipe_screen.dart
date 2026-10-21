import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duo_match/models/user_model.dart';
import 'package:duo_match/widgets/user_card.dart';
import 'package:duo_match/core/app_theme.dart';
import 'package:duo_match/providers/chat_provider.dart';
import 'package:duo_match/providers/user_provider.dart';
import 'package:duo_match/services/auth_service.dart';
import 'package:duo_match/screens/chat/chat_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> with TickerProviderStateMixin {
  final List<UserProfile> _stack = [];
  int _idx = 0;
  final Random _rnd = Random();

  String _filterGender = 'Все';
  String _filterLookingFor = 'Все';
  String _filterDistrict = 'Все';
  bool _onlyMyUni = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _moveAnim;
  late Animation<double> _rotateAnim;
  Offset _dragOffset = Offset.zero;

  final List<String> _districts = const [
    'Все', 'Центральный', 'Хамовники', 'Арбат', 'Пресненский',
    'Тверской', 'Басманный', 'Замоскворечье', 'Южный', 'Северный',
  ];

  List<String> _getAvailableGoals(String myGender, String targetGender) {
    if (myGender == 'Мужской' && targetGender == 'Мужской') {
      return const ['Все', 'Дружба', 'Общение', 'Компания для учёбы'];
    }
    if (myGender == 'Женский' && targetGender == 'Женский') {
      return const ['Все', 'Дружба', 'Общение', 'Компания для учёбы'];
    }
    return const ['Все', 'Отношения', 'Дружба', 'Общение', 'Компания для учёбы'];
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _moveAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_animCtrl);
    _rotateAnim = Tween<double>(begin: 0, end: 0).animate(_animCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeck());
  }

  Future<void> _loadDeck() async {
    final up = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final myId = up.currentUser?.userId ?? '';
    final myUni = up.currentUser?.university.split('•').first.trim() ?? 'РЭУ им. Плеханова';
    final prefGender = prefs.getString('my_looking_for_gender') ?? 'Все';

    List<UserProfile> list = [];

    for (var u in AuthService.testUsers) {
      if (u.userId != myId && u.userId != 'admin_1') {
        list.add(u);
      }
    }

    list.add(UserProfile(
      userId: 'video_user_1',
      fullName: 'Виктория Смирнова',
      birthDate: DateTime(2004, 6, 12),
      gender: 'Женский',
      university: 'РЭУ им. Плеханова • 2 курс',
      bio: 'Смотрите мое видео в анкете! Увлекаюсь спортом, музыкой и путешествиями.',
      status: 'Смотри видео',
      photos: const ['https://randomuser.me/api/portraits/women/55.jpg'],
      videoPath: 'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-1232-small.mp4',
      interests: const ['Спорт', 'Кино', 'Путешествия'],
      isPremium: true,
    ));

    final femaleNames = ['Полина', 'Екатерина', 'Софья', 'Анна', 'Виктория', 'Мария', 'Алина'];
    final maleNames = ['Кирилл', 'Михаил', 'Андрей', 'Иван', 'Максим', 'Роман', 'Сергей'];
    final unis = ['РЭУ им. Плеханова', 'МГУ', 'МГТУ им. Баумана', 'ВШЭ', 'МИРЭА'];
    final interestsPool = ['Музыка', 'Кофе', 'Спорт', 'Кино', 'Дизайн', 'Книги', 'Игры'];

    for (int i = 0; i < 12; i++) {
      String g;
      if (_filterGender == 'Все') {
        g = (prefGender == 'Все') ? (_rnd.nextBool() ? 'Женский' : 'Мужской') : prefGender;
      } else {
        g = _filterGender;
      }

      bool isF = g == 'Женский';
      String name = isF ? femaleNames[_rnd.nextInt(femaleNames.length)] : maleNames[_rnd.nextInt(maleNames.length)];
      String uni = _onlyMyUni ? myUni : unis[_rnd.nextInt(unis.length)];
      String dist = _districts[1 + _rnd.nextInt(_districts.length - 1)];
      int picNum = 10 + _rnd.nextInt(55);

      list.add(UserProfile(
        userId: 'candidate_${g}_$i',
        fullName: name,
        birthDate: DateTime(2003, 1 + _rnd.nextInt(11), 1 + _rnd.nextInt(25)),
        gender: g,
        university: '$uni • ${1 + _rnd.nextInt(4)} курс',
        bio: 'Студент $uni. Район $dist. Люблю проводить время активно и с пользой.',
        status: 'В сети',
        photos: [isF ? 'https://randomuser.me/api/portraits/women/$picNum.jpg' : 'https://randomuser.me/api/portraits/men/$picNum.jpg'],
        interests: (List<String>.from(interestsPool)..shuffle(_rnd)).take(3).toList(),
      ));
    }

    list.removeWhere((u) => u.userId == myId);

    if (_filterGender != 'Все') {
      list = list.where((u) => u.gender == _filterGender).toList();
    }
    if (_onlyMyUni) {
      list = list.where((u) => u.university.contains(myUni)).toList();
    }
    if (_filterDistrict != 'Все') {
      list = list.where((u) => u.bio.contains(_filterDistrict)).toList();
    }

    if (!mounted) return;
    setState(() {
      _stack.clear();
      _stack.addAll(list);
      _idx = 0;
      _dragOffset = Offset.zero;
    });
  }

  void _runAnimation(bool isRight) {
    if (_idx >= _stack.length) return;

    final up = Provider.of<UserProvider>(context, listen: false);

    if (!up.currentUser!.isPremium && _idx >= 6) {
      _showLimitDialog();
      return;
    }

    HapticFeedback.lightImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    _moveAnim = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(isRight ? screenWidth * 1.5 : -screenWidth * 1.5, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _rotateAnim = Tween<double>(
      begin: _dragOffset.dx / 25 * (pi / 180),
      end: isRight ? 0.35 : -0.35,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward().then((_) {
      final target = _stack[_idx];
      final cp = Provider.of<ChatProvider>(context, listen: false);

      if (isRight) {
        up.recordLike(isMatch: true);
        cp.createMatch(target);
        _showMatchDialog(target);
      } else {
        up.recordDislike();
        _handleNext();
      }
    });
  }

  void _handleNext() {
    setState(() {
      _idx++;
      _dragOffset = Offset.zero;
    });
    _animCtrl.reset();
  }

  void _handleUndo() {
    final up = Provider.of<UserProvider>(context, listen: false);
    if (!up.currentUser!.isPremium) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber),
              SizedBox(width: 8),
              Flexible(child: Text('DuoMatch Premium', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: const Text('Отмена последнего свайпа (Rewind) доступна только в Premium-версии.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
        ),
      );
      return;
    }

    if (_idx > 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _idx--;
        _dragOffset = Offset.zero;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Анкета возвращена! (Rewind)'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Flexible(child: Text('Лимит исчерпан', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: const Text('Вы просмотрели 6 анкет. В бесплатной версии установлен лимит. Оформите Premium в профиле для безлимитного поиска!'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
      ),
    );
  }

  void _showMatchDialog(UserProfile u) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 54),
              const SizedBox(height: 16),
              Text(
                'Взаимная симпатия!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Вы и ${u.fullName} понравились друг другу.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleNext();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Позже'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleNext();
                        final cp = Provider.of<ChatProvider>(context, listen: false);
                        cp.markAsRead(u.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatDetailView(user: u)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Написать', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilters() {
    final up = Provider.of<UserProvider>(context, listen: false);
    final myGender = up.currentUser?.gender ?? 'Мужской';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) {
          final goals = _getAvailableGoals(myGender, _filterGender);
          if (!goals.contains(_filterLookingFor)) {
            _filterLookingFor = 'Все';
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Фильтры поиска', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Кого показывать:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _filterGender,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Все', child: Text('Все')),
                    DropdownMenuItem(value: 'Мужской', child: Text('Парней')),
                    DropdownMenuItem(value: 'Женский', child: Text('Девушек')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setSheet(() {
                        _filterGender = v;
                        _filterLookingFor = 'Все';
                      });
                      setState(() {
                        _filterGender = v;
                        _filterLookingFor = 'Все';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Район Москвы:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _filterDistrict,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheet(() => _filterDistrict = v);
                      setState(() => _filterDistrict = v);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Цель поиска:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _filterLookingFor,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: goals.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheet(() => _filterLookingFor = v);
                      setState(() => _filterLookingFor = v);
                    }
                  },
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Только студенты моего ВУЗа', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  value: _onlyMyUni,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    setSheet(() => _onlyMyUni = v);
                    setState(() => _onlyMyUni = v);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadDeck();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Применить фильтр', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final up = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Знакомства', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: SafeArea(
        child: _idx >= _stack.length
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 70, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Вы просмотрели все анкеты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDeck,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Загрузить ещё', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          if (!_animCtrl.isAnimating) {
                            setState(() => _dragOffset += d.delta);
                          }
                        },
                        onPanEnd: (d) {
                          if (_dragOffset.dx > 120) {
                            _runAnimation(true);
                          } else if (_dragOffset.dx < -120) {
                            _runAnimation(false);
                          } else {
                            setState(() => _dragOffset = Offset.zero);
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (ctx, child) {
                            final pos = _animCtrl.isAnimating ? _moveAnim.value : _dragOffset;
                            final rot = _animCtrl.isAnimating ? _rotateAnim.value : _dragOffset.dx / 25 * (pi / 180);
                            return Transform.translate(
                              offset: pos,
                              child: Transform.rotate(
                                angle: rot,
                                child: Stack(
                                  children: [
                                    UserCard(
                                      user: _stack[_idx],
                                      onSwipeLeft: () => _runAnimation(false),
                                      onSwipeRight: () => _runAnimation(true),
                                    ),
                                    Positioned(
                                      top: 24,
                                      left: 28,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${_stack[_idx].calculateCompatibility(up.currentUser?.interests ?? [])}% совпадение',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionButton(Icons.replay_rounded, Colors.orange, _handleUndo, 50, theme),
                        _actionButton(Icons.close_rounded, Colors.redAccent, () => _runAnimation(false), 65, theme),
                        _actionButton(Icons.favorite_rounded, AppColors.primary, () => _runAnimation(true), 65, theme),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, double size, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }
}