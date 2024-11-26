

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/message.dart';

class ChatService extends ChangeNotifier{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['email'] != _auth.currentUser!.email)
          .map((doc) => doc.data()).toList();
    });
  }

  // Get users except the blocked users
  Stream<List<Map<String, dynamic>>> getUsersExceptBlockedUsersStream() {
    final currentUser = _auth.currentUser;
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
          // get blocked user ids
      final blockedUsersIds = snapshot.docs.map((doc) => doc.id).toList();
      // get all users
      final userSnapshot = await _firestore.collection('users').get();
      // return list excluding current user and blocked users
      return userSnapshot.docs
          .where((doc) => doc.data()['email'] != currentUser.email && !blockedUsersIds.contains(doc.id))
          .map((doc) => doc.data()).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverID, message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Create message
    Message newMessage = Message(
      senderID: currentUserId,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );
    
    List<String> ids = [currentUserId, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');
    
    // Save message to the database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());
  }

    // Get message
  Stream<QuerySnapshot> getMessages(String userID, otherUserID){
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Report user
  Future<void> reportUser(String messageID,String userID) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedNy': currentUser!.uid,
      'messageId': messageID,
      'messageOwnerId': userID,
      'timestamp': FieldValue.serverTimestamp()
    };
    await _firestore.collection('reports').add(report);
  }

  // Block user
  Future<void> blockUser(String userID) async{
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userID).set({});
    notifyListeners();
  }

  // Unblock user
  Future<void> unblockUser(String userID) async{
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userID).delete();
    notifyListeners();
  }

  // Get blocked users
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userID) {
    return _firestore
        .collection('users')
        .doc(userID)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUsersIds = snapshot.docs.map((doc) => doc.id).toList();
      
      final userDocs = await Future.wait(
        blockedUsersIds
            .map((id) => _firestore.collection('users').doc(id).get())
      );

      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    });
  }

  }