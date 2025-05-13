import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_profile.dart';
import 'services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isEditing = false;
  bool isLoading = true;
  final ProfileService _profileService = ProfileService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  UserProfile? _userProfile;
  File? _selectedImage;
  
  // Stats
  double weight = 85.5;
  double bodyFat = 15.2;
  Map<String, double> prs = {
    "Bench Press": 120.0,
    "Squat": 180.0,
    "Deadlift": 200.0,
  };

  double _calculateBMI(double weight, double height) {
    // Height is in meters, weight in kg
    if (height == 0) return 0;
    return weight / (height * height);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBMIMeter() {
    if (_userProfile == null || _userProfile!.weight == 0 || _userProfile!.height == 0) {
      return const SizedBox.shrink();
    }

    final double bmi = _calculateBMI(_userProfile!.weight, _userProfile!.height);
    final String category = _getBMICategory(bmi);
    final Color bmiColor = _getBMIColor(bmi);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: Colors.black),
              const SizedBox(width: 8),
              const Text(
                "BMI Status",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        color: bmiColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: bmi / 40, // Assuming max BMI of 40
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: bmiColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '18.5',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '25',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '30',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await _profileService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
        _bioController.text = profile.bio;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _profileService.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        profilePicture: _selectedImage,
        weight: _userProfile?.weight,
        height: _userProfile?.height,
        bodyFat: _userProfile?.bodyFat,
        prs: _userProfile?.prs,
      );
      await _loadUserProfile();
      setState(() => isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.black,
            ),
            onPressed: () {
              if (isEditing) {
                _saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_userProfile?.profilePictureUrl != null
                                  ? NetworkImage(_userProfile!.profilePictureUrl!)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null && _userProfile?.profilePictureUrl == null
                              ? const Icon(Icons.person, size: 40, color: Colors.black54)
                              : null,
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Name and Bio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEditing)
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        else
                          Text(
                            _userProfile!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (isEditing)
                          TextField(
                            controller: _bioController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        else
                          Text(
                            _userProfile!.bio,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BMI Meter
            _buildBMIMeter(),

            const SizedBox(height: 20),

            // Stats Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        "Fitness Stats",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow("Weight", "${_userProfile!.weight.toStringAsFixed(1)} kg", isEditing),
                  _buildStatRow("Height", "${_userProfile!.height.toStringAsFixed(2)} m", isEditing),
                  _buildStatRow("Body Fat", "${_userProfile!.bodyFat.toStringAsFixed(1)}%", isEditing),
                  const Divider(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        "Personal Records",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._userProfile!.prs.entries.map((entry) => _buildStatRow(
                    entry.key,
                    "${entry.value.toStringAsFixed(1)} kg",
                    isEditing,
                  )),
                ],
              ),
            ),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showLogoutConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isEditing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isEditing)
            SizedBox(
              width: 100,
              child: TextField(
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: value,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                onChanged: (newValue) {
                  final doubleValue = double.tryParse(newValue);
                  if (doubleValue != null) {
                    setState(() {
                      if (label == "Weight") {
                        _userProfile = UserProfile(
                          uid: _userProfile!.uid,
                          name: _userProfile!.name,
                          bio: _userProfile!.bio,
                          profilePictureUrl: _userProfile!.profilePictureUrl,
                          weight: doubleValue,
                          height: _userProfile!.height,
                          bodyFat: _userProfile!.bodyFat,
                          prs: _userProfile!.prs,
                        );
                      } else if (label == "Height") {
                        _userProfile = UserProfile(
                          uid: _userProfile!.uid,
                          name: _userProfile!.name,
                          bio: _userProfile!.bio,
                          profilePictureUrl: _userProfile!.profilePictureUrl,
                          weight: _userProfile!.weight,
                          height: doubleValue,
                          bodyFat: _userProfile!.bodyFat,
                          prs: _userProfile!.prs,
                        );
                      } else if (label == "Body Fat") {
                        _userProfile = UserProfile(
                          uid: _userProfile!.uid,
                          name: _userProfile!.name,
                          bio: _userProfile!.bio,
                          profilePictureUrl: _userProfile!.profilePictureUrl,
                          weight: _userProfile!.weight,
                          height: _userProfile!.height,
                          bodyFat: doubleValue,
                          prs: _userProfile!.prs,
                        );
                      } else {
                        final updatedPrs = Map<String, double>.from(_userProfile!.prs);
                        updatedPrs[label] = doubleValue;
                        _userProfile = UserProfile(
                          uid: _userProfile!.uid,
                          name: _userProfile!.name,
                          bio: _userProfile!.bio,
                          profilePictureUrl: _userProfile!.profilePictureUrl,
                          weight: _userProfile!.weight,
                          height: _userProfile!.height,
                          bodyFat: _userProfile!.bodyFat,
                          prs: updatedPrs,
                        );
                      }
                    });
                  }
                },
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
