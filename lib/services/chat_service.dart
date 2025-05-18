import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all chats for the current user
  Stream<List<Chat>> getUserChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get messages for a specific chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Create a new chat
  Future<String> createChat({
    required String courseId,
    required String courseTitle,
    required String studentId,
    required String studentName,
    required String instructorId,
    required String instructorName,
  }) async {
    final chatRef = await _firestore.collection('chats').add({
      'courseId': courseId,
      'courseTitle': courseTitle,
      'studentId': studentId,
      'studentName': studentName,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'participants': [studentId, instructorId],
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessage': 'Chat started',
      'isRead': false,
    });

    return chatRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) throw Exception('User data not found');

    // Add message to chat
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': userId,
      'senderName': userData['name'],
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update chat metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessage': content,
      'isRead': false,
    });
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isRead': true,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
} 