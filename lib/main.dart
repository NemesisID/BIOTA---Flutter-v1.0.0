import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biota_2/screens/auth/splash_screen.dart';
import 'package:biota_2/screens/auth/login_screen.dart';
import 'package:biota_2/screens/auth/register_screen.dart';
import 'package:biota_2/screens/user/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi locale untuk date formatting
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  
  // Disable debug banner untuk mengurangi gesture conflicts
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const MyApp());
} 
  
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BIOTA App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HomeScreen(
            initialTab: args?['initialTab'] ?? 0,
            focusSpecies: args?['focusSpecies'],
          );
        },
      },
    );
  }
}