import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../twilight_calculator.dart';

class LocationProvider with ChangeNotifier {
  LocationData _locationData = LocationData.defaultLocation;
  bool _isLoading = false;
  String? _error;
  String? _toastMessage;
  StreamSubscription<Position>? _positionStream;

  LocationData get locationData => _locationData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get toastMessage => _toastMessage;

  void clearToast() {
    _toastMessage = null;
  }

  LocationProvider() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Calculate with default location first
      _calculateTwilightForLocation(_locationData.latitude, _locationData.longitude);
      
      // Try to get actual location
      await _requestLocationPermission();
    } catch (e) {
      _error = e.toString();
      developer.log('Location initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _requestLocationPermission() async {
    developer.log("Starting location permission request...");
    
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    developer.log("Location services enabled: $serviceEnabled");
    
    if (!serviceEnabled) {
      _error = "Location services are disabled. Please enable location services in Settings.";
      notifyListeners();
      return;
    }

    // Check location permission using geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    developer.log("Current permission: $permission");
    
    if (permission == LocationPermission.denied) {
      developer.log("Requesting location permission...");
      permission = await Geolocator.requestPermission();
      developer.log("Permission after request: $permission");
      
      if (permission == LocationPermission.denied) {
        _error = "Location permission denied";
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _error = "Location permissions are permanently denied. Please enable them in Settings.";
      notifyListeners();
      return;
    }

    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      developer.log("Permission granted, starting location updates...");
      await _startLocationUpdates();
    } else {
      _error = "Location permission not granted: $permission";
      notifyListeners();
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      // Get current location first
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _updateLocationData(position);

      // Start listening for location updates indefinitely (no timeLimit, no
      // distanceFilter), matching the Android app's requestLocationUpdates
      // with 5000ms interval and 1m filter.
      final LocationSettings locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              intervalDuration: const Duration(milliseconds: 5000),
              distanceFilter: 1,
            )
          : AppleSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1,
              pauseLocationUpdatesAutomatically: false,
            );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _updateLocationData,
        onError: (e) {
          developer.log('Location stream error: $e');
          // Don't crash — just log. The last known position stays on screen.
        },
      );

    } catch (e) {
      _error = e.toString();
      developer.log('Location update error: $e');
      notifyListeners();
    }
  }

  void _updateLocationData(Position position) {
    _calculateTwilightForLocation(position.latitude, position.longitude, position);
    
    // Replicate the Android toast: "A pikachu appeared nearby!"
    _toastMessage = "A pikachu appeared nearby! ${position.latitude}";
    developer.log("A pikachu appeared nearby! ${position.latitude}");
    notifyListeners();
  }

  void _calculateTwilightForLocation(double latitude, double longitude, [Position? position]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final calculator = TwilightCalculator();
    
    calculator.calculateTwilight(now, latitude, longitude);
    
    // Calculate progress and display text
    double progress = 1.0;
    String displayText = "Es ist Zeit";
    
    if (calculator.state == TwilightCalculator.night) {
      progress = 1.0;
      displayText = "Es ist Zeit";
    } else {
      // Calculate elapsed day percentage
      if (calculator.sunrise != -1 && calculator.sunset != -1) {
        double elapsedDay = (now - calculator.sunrise) / (calculator.sunset - calculator.sunrise);
        elapsedDay = elapsedDay.clamp(0.0, 1.0);
        progress = elapsedDay;
        displayText = "${(elapsedDay * 100.0).toStringAsFixed(1)}%";
        
        developer.log("Progress value: $elapsedDay");
      }
    }

    _locationData = LocationData(
      position: position,
      latitude: latitude,
      longitude: longitude,
      sunrise: calculator.sunrise,
      sunset: calculator.sunset,
      twilightState: calculator.state,
      displayText: displayText,
      progress: progress,
    );
    
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // Manual refresh method
  Future<void> refresh() async {
    await _initializeLocation();
  }

  // Manual permission request method for debugging
  Future<void> requestPermissionManually() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    await _requestLocationPermission();
    
    _isLoading = false;
    notifyListeners();
  }
}