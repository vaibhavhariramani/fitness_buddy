import 'package:flutter/material.dart';

import 'chat/chats_tab.dart';
import 'friends/friends_tab.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends', icon: Icon(Icons.people_outline)),
              Tab(text: 'Chats', icon: Icon(Icons.chat_bubble_outline)),
            ],
          ),
        ),
        body: const TabBarView(children: [FriendsTab(), ChatsTab()]),
      ),
    );
  }
}
