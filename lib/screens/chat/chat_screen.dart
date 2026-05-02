import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../core/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile user;
  const ChatScreen({super.key, required this.user});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<ChatProvider>(context);
    final msgs = cp.getMessages(widget.user.userId).reversed.toList();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Expanded(child: ListView.builder(reverse: true, padding: const EdgeInsets.all(25), itemCount: msgs.length, itemBuilder: (c, i) {
          final m = msgs[i];
          return Align(alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: m.isMe ? AppColors.electricBlue : (isDark ? const Color(0xFF252A41) : Colors.grey[200]), borderRadius: BorderRadius.circular(22)),
            child: Text(m.text, style: TextStyle(color: m.isMe || isDark ? Colors.white : Colors.black87, fontSize: 15)),
          ));
        })),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: const InputDecoration(hintText: 'Написать сообщение...', filled: true))),
            const SizedBox(width: 15),
            CircleAvatar(radius: 28, backgroundColor: AppColors.electricBlue, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: () {
              if (_ctrl.text.isEmpty) return;
              cp.sendMessage(widget.user.userId, _ctrl.text);
              cp.botReply(widget.user.userId, widget.user.gender, widget.user.university);
              _ctrl.clear();
            })),
          ]),
        )
      ]),
    );
  }
}