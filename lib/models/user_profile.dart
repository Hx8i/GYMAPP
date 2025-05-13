import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String bio;
  final String? profilePictureUrl;
  final double weight;
  final double height;
  final double bodyFat;
  final Map<String, double> prs;

  UserProfile({
    required this.uid,
    required this.name,
    required this.bio,
    this.profilePictureUrl,
    required this.weight,
    required this.height,
    required this.bodyFat,
    required this.prs,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      bodyFat: (data['bodyFat'] ?? 0.0).toDouble(),
      prs: Map<String, double>.from(data['prs'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'weight': weight,
      'height': height,
      'bodyFat': bodyFat,
      'prs': prs,
    };
  }
} 