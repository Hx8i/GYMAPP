import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_profile.dart';
import 'services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // If null, show current user's profile
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isEditing = false;
  bool isLoading = true;
  bool isFollowing = false;
  final ProfileService _profileService = ProfileService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  UserProfile? _userProfile;
  File? _selectedImage;
  List<UserProfile> followingList = [];
  bool isLoadingFollowing = false;
  
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
    if (widget.userId == null || widget.userId == _auth.currentUser?.uid) {
      _loadFollowingList();
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await _profileService.getUserProfile(userId: widget.userId);
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
        _bioController.text = profile.bio;
      });
      if (widget.userId != null) {
        // Check if current user is following this profile
        isFollowing = await _profileService.isFollowing(widget.userId!);
      }
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

  Future<void> _toggleFollow() async {
    if (_userProfile == null) return;
    
    try {
      if (isFollowing) {
        await _profileService.unfollowUser(_userProfile!.uid);
      } else {
        await _profileService.followUser(_userProfile!.uid);
      }
      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'Basic Plan':
        return Colors.grey;
      case 'Premium User':
        return Colors.blue;
      case 'Gym Owner':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadFollowingList() async {
    if (_userProfile == null) return;
    
    setState(() => isLoadingFollowing = true);
    try {
      final list = await _profileService.getFollowingList(_userProfile!.uid);
      setState(() {
        followingList = list;
        isLoadingFollowing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading following list: $e')),
        );
      }
      setState(() => isLoadingFollowing = false);
    }
  }

  void _showFollowingList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Text(
              'Following',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${followingList.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: followingList.isEmpty
              ? const Center(
                  child: Text(
                    'Not following anyone yet',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: followingList.length,
                  itemBuilder: (context, index) {
                    final user = followingList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.profilePictureUrl != null
                              ? NetworkImage(user.profilePictureUrl!)
                              : null,
                          child: user.profilePictureUrl == null
                              ? const Icon(Icons.person, color: Colors.black54)
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlanColor(user.plan),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.plan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userId: user.uid),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

    final bool isCurrentUser = widget.userId == null || widget.userId == _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isCurrentUser)
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
                      if (isEditing && isCurrentUser)
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
                  // Name, Bio, and Follow Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _userProfile!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (isCurrentUser)
                              GestureDetector(
                                onTap: () {
                                  _loadFollowingList();
                                  _showFollowingList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, size: 16, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${followingList.length} Following',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (!isCurrentUser)
                              ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing ? Colors.white : Colors.black,
                                  foregroundColor: isFollowing ? Colors.black : Colors.white,
                                  side: BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlanColor(_userProfile!.plan),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userProfile!.plan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isEditing && isCurrentUser)
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
                  _buildStatRow("Weight", "${_userProfile!.weight.toStringAsFixed(1)} kg", isEditing && isCurrentUser),
                  _buildStatRow("Height", "${_userProfile!.height.toStringAsFixed(2)} m", isEditing && isCurrentUser),
                  _buildStatRow("Body Fat", "${_userProfile!.bodyFat.toStringAsFixed(1)}%", isEditing && isCurrentUser),
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
                    isEditing && isCurrentUser,
                  )),
                ],
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
                          plan: _userProfile!.plan,
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
                          plan: _userProfile!.plan,
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
                          plan: _userProfile!.plan,
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
                          plan: _userProfile!.plan,
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
