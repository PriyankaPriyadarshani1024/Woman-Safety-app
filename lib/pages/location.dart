import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? mapController;
  LatLng _initialPosition = LatLng(37.78825, -122.4324); // Default location (San Francisco)
  LatLng _currentPosition = LatLng(37.78825, -122.4324);
  bool _isLocationFetched = false; // To track if location is fetched

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Automatically fetch the location on initialization
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Handle permission denial
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      // Get the user's current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _initialPosition = _currentPosition;
        _isLocationFetched = true; // Mark that the location is fetched
      });

      // Move the camera to the user's current location
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 14),
          ),
        );
      }
    } catch (e) {
      // Handle errors if location fetching fails
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location Map")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              if (_isLocationFetched) {
                // If location is already fetched, move the camera to the user's current position
                mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentPosition, zoom: 14),
                  ),
                );
              }
            },
            markers: {
              Marker(
                markerId: MarkerId('user_location'),
                position: _currentPosition,
                infoWindow: InfoWindow(title: 'You are here'),
              ),
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _getUserLocation,
              child: Text("Refresh Location"),
            ),
          ),
        ],
      ),
    );
  }
}
