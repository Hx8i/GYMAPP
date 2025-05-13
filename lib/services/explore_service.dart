import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ExploreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users except the current user
  Stream<List<UserProfile>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    });
  }

  // Search users by name or username
  Stream<List<UserProfile>> searchUsers(String query, String currentUserId) {
    if (query.isEmpty) {
      return getAllUsers(currentUserId);
    }

    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.bio.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
} 