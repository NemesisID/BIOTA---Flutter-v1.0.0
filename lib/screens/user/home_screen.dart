import 'package:biota_2/models/event.dart';
import 'package:flutter/material.dart';
import 'package:biota_2/widgets/bottom_nav_bar.dart';
import 'package:biota_2/screens/user/homepage_screen.dart';
import 'package:biota_2/screens/user/profile_screen.dart';
import 'package:biota_2/screens/user/explore_screen.dart'; // Import explore_screen.dart
import 'package:biota_2/screens/user/event_screen.dart'; // Import event_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePageScreen(),
    const ExploreScreen(),
    const EventScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}