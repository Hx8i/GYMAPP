import 'package:flutter/material.dart';

class CommentPage extends StatelessWidget {
  const CommentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Static example comment
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://th.bing.com/th/id/OIP.JOtiSWFSJCdh8HWXJ6oaAQHaHa?rs=1&pid=ImgDetMain'),
            ),
            title: Text('user123'),
            subtitle: Text('This is awesome!'),
          ),
          // Add more comments here
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Handle posting logic
              },
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
