import 'package:flutter/material.dart';
import 'package:gym_app_project/profile.dart';
import 'calorie.dart';
import 'comment_page.dart';
import 'explore.dart';
import 'package:google_fonts/google_fonts.dart';


class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int myIndex = 0;

  final List<Widget> pages = [
   HomePage(),
   ExplorePage(),
    CaloriesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1, // Subtle shadow for depth
        centerTitle: true,
        title: Text(
          'GYMHUB',
          style:  GoogleFonts.lora(
            textStyle: TextStyle(

            fontSize: 24,
            color: Colors.white,
          ),),
        ),
      ),

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
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Calories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
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