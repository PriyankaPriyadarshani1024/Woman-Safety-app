import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/home_screen.dart';
import 'package:untitled/pages/login_screen.dart';
import 'package:untitled/pages/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Initial screen that checks session status
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// New SplashScreen that handles session checking
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check login session and navigate accordingly
  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await checkLoginSession();
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(), // Show loading indicator while checking
          SizedBox(height: 20),
          Text('Checking session...'), // Optionally show a text
        ],
      ),
      ),
    );
  }
}

// Function to check if a session exists in SharedPreferences
Future<bool> checkLoginSession() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? sessionId = prefs.getString('sessionId');
  String? userId = prefs.getString('userId');

  // If both sessionId and userId exist, consider the user logged in
  return sessionId != null && userId != null;
}
