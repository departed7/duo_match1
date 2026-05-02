import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/user_card.dart';
import '../../main.dart';
import '../../core/app_theme.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<ChatProvider>(context);
    final up = Provider.of<UserProvider>(context);
    bool isPre = up.currentUser?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('МЭТЧИ', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(25),
        children: [
          const Text('КТО ВАС ЛАЙКНУЛ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cp.likers.length, itemBuilder: (c, i) => GestureDetector(
            onTap: () {
              if (isPre) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(), body: Center(child: UserCard(user: cp.likers[i])))));
              } else {
                _showPaywall(context);
              }
            },
            child: Container(
              width: 95, margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                image: DecorationImage(image: NetworkImage(cp.likers[i].photos.first), fit: BoxFit.cover),
              ),
              child: !isPre ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black45, child: const Icon(Icons.lock_outline, color: Colors.white70, size: 30))),
              ) : null,
            ),
          ))),
          const SizedBox(height: 40),
          const Text('ВАШИ ДИАЛОГИ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          if (cp.matches.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('Пока мэтчей нет.')))
          else ...cp.matches.map((u) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
              borderRadius: BorderRadius.circular(22), 
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(), body: Center(child: UserCard(user: u))))),
                child: CircleAvatar(radius: 30, backgroundImage: u.photos.first.startsWith('assets') ? AssetImage(u.photos.first) as ImageProvider : NetworkImage(u.photos.first)),
              ),
              title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(cp.getLastMessage(u.userId), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(user: u))),
            ),
          )),
        ],
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      title: const Icon(Icons.workspace_premium, color: Colors.amber, size: 50),
      content: const Text('DuoMatch Premium позволит вам видеть всех, кто поставил вам лайк!', textAlign: TextAlign.center),
      actions: [Center(child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('ПОНЯТНО', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.electricBlue))))],
    ));
  }
}