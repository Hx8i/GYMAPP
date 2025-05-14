import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import '../models/user_profile.dart';
import 'dart:math';

class ExploreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Get random users except the current user with optional plan filter
  Stream<List<UserProfile>> getRandomUsers(String currentUserId, {String? planFilter, int limit = 10}) {
    Query query = _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId);
    
    if (planFilter != null && planFilter.isNotEmpty) {
      query = query.where('plan', isEqualTo: planFilter);
    }

    return query.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
      
      // Shuffle the users list
      users.shuffle(_random);
      
      // Return limited number of users
      return users.take(limit).toList();
    });
  }

  // Search users by name or username with optional plan filter
  Stream<List<UserProfile>> searchUsers(String query, String currentUserId, {String? planFilter}) {
    if (query.isEmpty) {
      return getRandomUsers(currentUserId, planFilter: planFilter);
    }

    Query firestoreQuery = _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId);
    
    if (planFilter != null && planFilter.isNotEmpty) {
      firestoreQuery = firestoreQuery.where('plan', isEqualTo: planFilter);
    }

    return firestoreQuery.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.bio.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
} 