import 'package:flutter/material.dart';
import 'package:flutter_chat_app/components/my_drawer.dart';
import 'package:flutter_chat_app/services/auth/auth_service.dart';
import 'package:flutter_chat_app/services/chat/chat_service.dart';

import '../components/user_tile.dart';
import 'chat_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Center(child: Text('Home')),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
        stream: _chatService.getUsersExceptBlockedUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.map<Widget>((userData) =>
                _buildUserListItem(userData, context)).toList(),
          );
        });
  }

  Widget _buildUserListItem(Map<String, dynamic> userData,
      BuildContext context) {
    if (userData['email'] != _authService.getCurrentUser()!.email){
      return UserTile(
          text: userData['email'],
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) =>
                    ChatPage(
                        receiverEmail: userData['email'],
                        receiverID: userData['uid'])));
          }
      );
    } else {
      return Container();
    }
  }
}
