import 'package:flutter/material.dart';
import 'package:gym_app_project/profile.dart';
import 'calorie.dart';
import 'comment_page.dart';
import 'explore.dart';
import 'Maps.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int myIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> pages = [
   HomePage(),
   ExplorePage(),
   const MapsPage(),
   CaloriesPage(),
   ProfilePage(),
  ];

  final String appId = 'e43bfa08';
  final String appKey = '1d81898bcefe7695ed3b765026cdb4ef';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1, // Subtle shadow for depth
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'GYMHUB',
          style:  GoogleFonts.lora(
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
      drawer: DrawerContent(),
      body: pages[myIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Calories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class DrawerContent extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DrawerContent({Key? key}) : super(key: key);

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(
                  _auth.currentUser?.email ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Post'),
            onTap: () {
              // TODO: Navigate to Add Post page
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Courses'),
            onTap: () {
              // TODO: Navigate to Courses page
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }
}

class Post {
  final String username;
  final String userImage;
  final String postImage;
  final String caption;

  Post({
    required this.username,
    required this.userImage,
    required this.postImage,
    required this.caption,
  });
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final List<Post> posts = [
    Post(
      username: "LiverKing",
      userImage: "https://via.placeholder.com/150",
      postImage: "https://th.bing.com/th/id/OIP.pAQ1nV_X1mdH9z3gGw9zdAHaE8?rs=1&pid=ImgDetMain",
      caption: "PEAK NATURAL PHYSIC!!",
    ),
    Post(
      username: "JackFitness",
      userImage: "https://via.placeholder.com/150",
      postImage: "https://i.ytimg.com/vi/NButY3BaVW4/maxresdefault.jpg",
      caption: "Progress after 2 years. don't be jealous guys \u{1F604}.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(post.userImage),
                ),
                title: Text(post.username),
                subtitle: const Text("2h ago"),
                trailing: Icon(Icons.more_vert),
              ),
              Image.network(post.postImage),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(post.caption),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 8,),
                  const LikeButton(),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommentPage()),
                      );
                    },
                  )
                  ,
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
class LikeButton extends StatefulWidget {
  const LikeButton({Key? key}) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border_rounded,
        color: isLiked ? Colors.red : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          isLiked = !isLiked;
        });
      },
    );
  }
}