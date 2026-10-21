import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:duo_match/providers/chat_provider.dart';
import 'package:duo_match/widgets/user_card.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final matches = chat.matches;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final u = matches[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: UserCard(
              user: u,
              onSwipeLeft: () {},
              onSwipeRight: () {},
            ),
          );
        },
      ),
    );
  }
}