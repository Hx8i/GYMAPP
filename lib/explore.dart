import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final List<Map<String, String>> allUsers = [
    {"name": "JackFitness", "username": "@jackfit", "image": "https://th.bing.com/th/id/OIP.tYgiA0k2yFCN_0U0__FO0wHaHa?rs=1&pid=ImgDetMain"},
    {"name": "Chris busted", "username": "@chris_c", "image": "https://th.bing.com/th/id/OIP.Cg-ZlObMTaVjDg4T80O_bQAAAA?rs=1&pid=ImgDetMain"},
    {"name": "Ronnie Bellman", "username": "@ronnielifts", "image": "https://th.bing.com/th/id/OIP.nyu7gtv41Q8Zmlq7oVQ10gHaHb?w=173&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7"},
    {"name": "Hashem Nasralah", "username": "@hashemmena", "image": "https://scontent.fbey4-2.fna.fbcdn.net/v/t39.30808-6/460296246_3742251679395709_2440378386848011706_n.jpg?_nc_cat=109&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=A56L5Vq9LLoQ7kNvwE8WjkJ&_nc_oc=Adk7G6ujm6gHDrQzqltJ-APoLSkJMBd7a2t-fu07ohBJU5DazlhqxP-54J61ew-8GNw&_nc_zt=23&_nc_ht=scontent.fbey4-2.fna&_nc_gid=CvNrk25V25ixI0UvOvCeQQ&oh=00_AfE3Fa-GU9CiX6u_vg95xxPsJ0Zi_6n2iw-JDx7WtfHOCQ&oe=6801A8EC"},
  ];

  String query = '';

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredUsers = allUsers
        .where((user) => user["name"]!.toLowerCase().contains(query.toLowerCase()) ||
        user["username"]!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user["image"]!),
                  ),
                  title: Text(user["name"]!),
                  subtitle: Text(user["username"]!),
                  onTap: () {
                    // Navigate to user profile (optional)
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
