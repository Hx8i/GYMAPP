import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/course.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all published courses
  Stream<List<Course>> getPublishedCourses() {
    return _firestore
        .collection('courses')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get courses created by a specific user
  Stream<List<Course>> getUserCourses(String userId) {
    return _firestore
        .collection('courses')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get courses subscribed by a user
  Stream<List<Course>> getSubscribedCourses() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('courses')
        .where('subscribers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Create a new course
  Future<String> createCourse({
    required String title,
    required String description,
    required double price,
    required List<WorkoutPlan> workoutPlans,
    List<File>? videos,
    List<File>? photos,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) throw Exception('User data not found');

    // Check if user is premium
    if (userData['plan'] != 'Premium User' && userData['plan'] != 'Gym Owner') {
      throw Exception('Only premium users can create courses');
    }

    // Upload videos and photos if provided
    List<String> videoUrls = [];
    List<String> photoUrls = [];

    if (videos != null) {
      for (var video in videos) {
        final ref = _storage.ref().child('courses/$userId/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        await ref.putFile(video);
        videoUrls.add(await ref.getDownloadURL());
      }
    }

    if (photos != null) {
      for (var photo in photos) {
        final ref = _storage.ref().child('courses/$userId/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(photo);
        photoUrls.add(await ref.getDownloadURL());
      }
    }

    // Create course document
    final courseRef = await _firestore.collection('courses').add({
      'title': title,
      'description': description,
      'creatorId': userId,
      'creatorName': userData['name'],
      'price': price,
      'subscribers': [],
      'workoutPlans': workoutPlans.map((plan) => plan.toMap()).toList(),
      'videoUrls': videoUrls,
      'photoUrls': photoUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'isPublished': true,
    });

    return courseRef.id;
  }

  // Subscribe to a course
  Future<void> subscribeToCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('courses').doc(courseId).update({
      'subscribers': FieldValue.arrayUnion([userId]),
    });
  }

  // Unsubscribe from a course
  Future<void> unsubscribeFromCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('courses').doc(courseId).update({
      'subscribers': FieldValue.arrayRemove([userId]),
    });
  }

  // Publish a course
  Future<void> publishCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    if (!courseDoc.exists) throw Exception('Course not found');

    final courseData = courseDoc.data();
    if (courseData == null) throw Exception('Course data not found');

    if (courseData['creatorId'] != userId) {
      throw Exception('Only the course creator can publish the course');
    }

    await _firestore.collection('courses').doc(courseId).update({
      'isPublished': true,
    });
  }

  // Unpublish a course
  Future<void> unpublishCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    if (!courseDoc.exists) throw Exception('Course not found');

    final courseData = courseDoc.data();
    if (courseData == null) throw Exception('Course data not found');

    if (courseData['creatorId'] != userId) {
      throw Exception('Only the course creator can unpublish the course');
    }

    await _firestore.collection('courses').doc(courseId).update({
      'isPublished': false,
    });
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    if (!courseDoc.exists) throw Exception('Course not found');

    final courseData = courseDoc.data();
    if (courseData == null) throw Exception('Course data not found');

    if (courseData['creatorId'] != userId) {
      throw Exception('Only the course creator can delete the course');
    }

    // Delete course document
    await _firestore.collection('courses').doc(courseId).delete();

    // Delete associated media files
    if (courseData['videoUrls'] != null) {
      for (String videoUrl in courseData['videoUrls']) {
        try {
          final ref = _storage.refFromURL(videoUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting video: $e');
        }
      }
    }

    if (courseData['photoUrls'] != null) {
      for (String photoUrl in courseData['photoUrls']) {
        try {
          final ref = _storage.refFromURL(photoUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }
    }
  }
} 