import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        // Create default profile for new user
        final defaultProfile = UserProfile(
          uid: user.uid,
          name: user.displayName ?? 'New User',
          bio: 'Welcome to Gym App! Update your profile to get started.',
          profilePictureUrl: null,
          weight: 0.0,
          height: 0.0,
          bodyFat: 0.0,
          prs: {
            'Bench Press': 0.0,
            'Squat': 0.0,
            'Deadlift': 0.0,
          },
        );

        // Save default profile to Firestore
        await _firestore.collection('users').doc(user.uid).set(defaultProfile.toMap());
        return defaultProfile;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    File? profilePicture,
    double? weight,
    double? height,
    double? bodyFat,
    Map<String, double>? prs,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? profilePictureUrl;
      if (profilePicture != null) {
        final ref = _storage.ref().child('profile_pictures/${user.uid}');
        await ref.putFile(profilePicture);
        profilePictureUrl = await ref.getDownloadURL();
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;
      if (weight != null) updates['weight'] = weight;
      if (height != null) updates['height'] = height;
      if (bodyFat != null) updates['bodyFat'] = bodyFat;
      if (prs != null) updates['prs'] = prs;

      await userRef.update(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
} 