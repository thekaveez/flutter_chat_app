import 'package:flutter/material.dart';
import 'package:flutter_chat_app/components/user_tile.dart';

import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();


  // show unblock dialog
  void _showUnblockBox(BuildContext context, String userId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unblock User'),
          content: const Text('Are you sure you want to unblock this user?'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  // unblock user
                  chatService.unblockUser(userId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User unblocked!')));
                },
                child: const Text('Unblock')),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {

    String userId = authService.getCurrentUser()!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Center(child: Text('Blocked Users')),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: chatService
              .getBlockedUsersStream(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final blockedUsers = snapshot.data ?? [];

            if (blockedUsers.isEmpty) {
              return const Center(child: Text('No blocked users'));
            }


            return ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return UserTile(
                    text: user['email'],
                    onTap: () => _showUnblockBox(context, user['uid'])
                );
              },
            );
          }),
          );

  }

  Widget _buildBlockedUsersList(){
    return Container();
  }
}
