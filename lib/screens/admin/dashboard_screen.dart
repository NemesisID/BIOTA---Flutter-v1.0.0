import 'package:flutter/material.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/services/auth_service.dart';
import 'package:biota_2/screens/admin/species_management_screen.dart';
import 'package:biota_2/screens/admin/user_management_screen.dart';
import 'package:biota_2/screens/auth/welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            Text(_getTitle()),
          ],
        ),
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menu Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Kelola Spesies'),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Kelola User'),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                try {
                  await AuthService.instance.logout();
                  await AuthService.instance.clearLoginStatus(); // Tambahkan baris ini
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_selectedIndex == 0) Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Selamat Datang Admin BIOTA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Silakan pilih menu di sidebar untuk mengelola aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (_selectedIndex == 1) const Expanded(child: SpeciesManagementScreen()),
          if (_selectedIndex == 2) const Expanded(child: UserManagementScreen()),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Kelola Spesies';
      case 2:
        return 'Kelola User';
      default:
        return 'Admin Dashboard';
    }
  }
}