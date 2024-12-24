import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appwrite_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = true; // Loading state to wait for session check

  // Function to save session in SharedPreferences
  Future<void> saveLoginSession(String userId, String sessionId, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', sessionId);
    await prefs.setString('userId', userId);
    await prefs.setString('token', token); // Save the token
  }

  // Function to check if a session exists and navigate accordingly
  // Function to check if a session exists and navigate accordingly
  Future<void> _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('token');
    String? accessToken = prefs.getString('token');  // Adding token check

    if (userId != null && token != null) {
      // If a session exists, navigate to the home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // No session, stop loading and show the login form
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSession();  // Check for an existing session when the screen is first loaded
  }


  Future<void> _login() async {
    setState(() {
      _isLoading = true;  // Show loading spinner during login attempt
    });
    try {
      // Perform login via Appwrite service
      var session = await _appwriteService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      // Access session details directly from the returned session
      
      String sessionId = session.$id; // Session ID
      String userId = session.userId; // User ID
      String accessToken = session.jwt ?? ''; // Access token
      // Save session after successful login
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionId', sessionId);
      await prefs.setString('userId', userId);
      await prefs.setString('token', accessToken); // Save the access token

      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while checking session
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Render login form when not loading
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Session {
  get jwt => null;
}


