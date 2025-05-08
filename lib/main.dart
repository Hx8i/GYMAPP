import 'package:flutter/material.dart';
import 'package:gym_app_project/home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
 title: 'GymApp',
      debugShowCheckedModeBanner: false,
      home: const Homepage(),

    );
  }
}


