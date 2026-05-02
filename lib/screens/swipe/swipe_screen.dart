import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../models/user_model.dart';
import '../../widgets/user_card.dart';
import '../../widgets/action_button.dart';
import '../../core/app_theme.dart';
import '../../services/geo_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final List<UserProfile> _users = [];
  int _currentIndex = 0;
  Position? _pos;
  String _genderFilter = 'Женщин';
  RangeValues _ageRange = const RangeValues(18, 25);
  double _radius = 15.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _pos = await GeoService.requestGeoLocation();
    _loadUsers();
    if (mounted) {
      Provider.of<ChatProvider>(context, listen: false).initLikers();
    }
  }

  void _loadUsers() {
    _users.clear();
    _users.addAll([
      UserProfile(userId: 'u1', fullName: 'Дарья Белова', birthDate: DateTime(2006,4,4), gender: 'Женский', university: 'РЭУ им. Плеханова • 3 курс', bio: 'Обожаю эстетику города, кофе и виниловые пластинки. Ищу компанию для походов на концерты на Kai Angel и 9mice.', photos: ['assets/images/profile_1.jpg'], interests: ['Блогерство'], latitude: 55.75, longitude: 37.61),
      UserProfile(userId: 'u2', fullName: 'Лусине Осипян', birthDate: DateTime(2004,11,17), gender: 'Женский', university: 'РЭУ им. Плеханова • 3 курс', bio: 'Учусь понимать людей. Люблю долгие прогулки, зеленый чай липтон и душевные разговоры.', photos: ['assets/images/profile_2.jpg'], interests: ['Игры'], latitude: 55.76, longitude: 37.62),
    ]);
    for (int i = 0; i < 30; i++) {
      _users.add(_gen(i));
    }
    if (mounted) {
      setState(() {});
    }
  }

  UserProfile _gen(int i) {
    bool isF = _genderFilter == 'Женщин' || (_genderFilter == 'Всех' && Random().nextBool());
    return UserProfile(
      userId: 'st_$i', fullName: isF ? 'София' : 'Марк', 
      birthDate: DateTime(2000 + Random().nextInt(7)), gender: isF ? 'Женский' : 'Мужской', 
      university: 'НИУ ВШЭ', bio: 'Привет! Я студент московского вуза. Давай знакомиться!', 
      photos: [isF ? "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=600" : "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600"], 
      interests: [], latitude: 55.75 + i*0.001, longitude: 37.61 + i*0.001
    );
  }

  void _onSwipe(String type, ChatProvider cp, UserProvider up) {
    HapticFeedback.lightImpact();
    if (type == 'rewind') {
      if (!up.currentUser!.isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Доступно в Premium')));
        return;
      }
      final user = cp.undoLastSwipe();
      if (user != null) {
        setState(() { _currentIndex--; _users.insert(_currentIndex, user); });
      }
      return;
    }
    final user = _users[_currentIndex];
    cp.addToHistory(user);
    if (type == 'like') {
      cp.createMatch(user);
      HapticFeedback.vibrate();
    }
    setState(() => _currentIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<ChatProvider>(context);
    final up = Provider.of<UserProvider>(context);
    if (_users.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('DUOMATCH'), actions: [IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _showFilters)]),
      body: _currentIndex < _users.length 
        ? Column(children: [
            Expanded(child: Stack(children: [
              Center(child: UserCard(user: _users[_currentIndex])),
              Positioned(top: 25, right: 40, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(15)), 
                child: Text(up.currentUser?.isIncognito ?? false ? 'Скрыто' : '${GeoService.calculateDistance(_pos?.latitude ?? 0, _pos?.longitude ?? 0, _users[_currentIndex].latitude, _users[_currentIndex].longitude).toStringAsFixed(1)} км', 
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
            ])),
            Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ActionButton(icon: Icons.refresh, color: Colors.amber, onTap: () => _onSwipe('rewind', cp, up), isSmall: true),
              ActionButton(icon: Icons.close_rounded, color: Colors.red, onTap: () => _onSwipe('dislike', cp, up)),
              ActionButton(icon: Icons.favorite_rounded, color: Colors.green, onTap: () => _onSwipe('like', cp, up)),
            ])),
          ])
        : const Center(child: Text('Люди вокруг закончились')),
    );
  }

  void _showFilters() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))), builder: (c) => StatefulBuilder(builder: (c, setS) => Padding(
      padding: const EdgeInsets.all(35),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('ПАРАМЕТРЫ ПОИСКА', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          initialValue: _genderFilter,
          items: ['Мужчин', 'Женщин', 'Всех'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) { 
            setS(() { 
              _genderFilter = v!; 
              _loadUsers(); 
            }); 
          },
        ),
        const SizedBox(height: 25),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Радиус поиска'), Text('${_radius.round()} км')]),
        Slider(value: _radius, min: 1, max: 100, activeColor: AppColors.electricBlue, onChanged: (v) {
          setS(() => setState(() => _radius = v));
        }),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Возраст'), Text('${_ageRange.start.round()}-${_ageRange.end.round()}')]),
        RangeSlider(values: _ageRange, min: 18, max: 30, activeColor: AppColors.electricBlue, onChanged: (v) {
          setS(() => setState(() => _ageRange = v));
        }),
        const SizedBox(height: 40),
        ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)), onPressed: () => Navigator.pop(c), child: const Text('ПРИМЕНИТЬ')),
      ]),
    )));
  }
}