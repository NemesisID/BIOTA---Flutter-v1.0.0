import 'package:biota_2/models/data.dart';
import 'package:flutter/material.dart';
import 'package:biota_2/widgets/bottom_nav_bar.dart';
import 'package:biota_2/screens/user/homepage_screen.dart';
import 'package:biota_2/screens/user/profile_screen.dart';
import 'package:biota_2/screens/user/explore_screen.dart';
import 'package:biota_2/screens/user/event_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  final Data? focusSpecies;
  
  const HomeScreen({
    super.key,
    this.initialTab = 0,
    this.focusSpecies,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  Data? _focusSpecies;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _focusSpecies = widget.focusSpecies;
  }

  void _onTabChange(int index, Data? species) {
    setState(() {
      _currentIndex = index;
      _focusSpecies = species;
    });
  }

  List<Widget> get _screens => [
    HomePageScreen(onTabChange: _onTabChange),
    ExploreScreen(focusSpecies: _focusSpecies),
    const EventScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Reset focus species saat navigasi manual (kecuali ke explore)
            if (index != 1) _focusSpecies = null;
          });
        },
      ),
    );
  }
}