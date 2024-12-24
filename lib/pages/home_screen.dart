import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Import your custom pages
import 'home.dart';
import 'task.dart';
import 'profile.dart';
import 'location.dart';  // Add the location page import
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? locationUrl; // Store the location URL

  // Define your actual pages here, which are imported from separate .dart files
  static final List<Widget> _screens = [
    HomePage(),
    MyTaskPage(),
    Container(), // Placeholder for space between icons
    LocationScreen(), // Add the location screen to the list of screens
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Fetch user location on init
  }

  // Function to get the user's location and generate the URL
  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle permission denial
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    String url = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

    setState(() {
      locationUrl = url; // Save the location URL
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeConnect"),
        centerTitle: true,

      ),
      body: _screens[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(CupertinoIcons.home, 'Home', 0),
            buildNavBarItem(CupertinoIcons.group, 'Gadians', 1),
            const SizedBox(width: 20), // Space for floating action button
            buildNavBarItem(CupertinoIcons.location_solid, 'Location', 3),
            buildNavBarItem(CupertinoIcons.profile_circled, 'Profile', 4),
          ],
        ),
      ),
      floatingActionButton: locationUrl != null
          ? ClipOval(
        child: Material(
          color: Color(0xFF7861FF),
          elevation: 10,
          child: InkWell(
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                CupertinoIcons.location,
                size: 28,
                color: Colors.white,
              ),
            ),
            onTap: () => _openLocationLink(),
          ),
        ),
      )
          : null, // Only show floating action button if location is available
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Open the location URL in Google Maps
  void _openLocationLink() async {
    if (locationUrl != null && await canLaunch(locationUrl!)) {
      await launch(locationUrl!);
    } else {
      throw 'Could not open the location URL';
    }
  }


  // Function to build the bottom navigation bar items
  Widget buildNavBarItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? const Color(0xFF7861FF)
                : Colors.black87,
          ),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index
                  ? const Color(0xFF7861FF)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
