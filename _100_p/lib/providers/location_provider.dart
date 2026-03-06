import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../models/location_error.dart';
import '../twilight_calculator.dart';

class LocationProvider with ChangeNotifier {
  LocationData _locationData = LocationData.defaultLocation;
  bool _isLoading = false;
  LocationErrorType? _errorType;
  // Latitude of the latest position update — null means no pending toast.
  double? _pendingToastLat;
  StreamSubscription<Position>? _positionStream;

  LocationData get locationData => _locationData;
  bool get isLoading => _isLoading;
  LocationErrorType? get errorType => _errorType;
  double? get pendingToastLat => _pendingToastLat;

  void clearToast() {
    _pendingToastLat = null;
    // No notifyListeners — clearing the toast must not trigger a rebuild.
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
      _errorType = LocationErrorType.unknown;
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
      _errorType = LocationErrorType.servicesDisabled;
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
        _errorType = LocationErrorType.permissionDenied;
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _errorType = LocationErrorType.permanentlyDenied;
      notifyListeners();
      return;
    }

    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      developer.log("Permission granted, starting location updates...");
      await _startLocationUpdates();
    } else {
      _errorType = LocationErrorType.unknown;
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
      _errorType = LocationErrorType.unknown;
      developer.log('Location update error: $e');
      notifyListeners();
    }
  }

  void _updateLocationData(Position position) {
    _calculateTwilightForLocation(position.latitude, position.longitude, position);
    _pendingToastLat = position.latitude; // UI will read + translate this
    developer.log('Location updated: ${position.latitude}, ${position.longitude}');
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
    
    _errorType = null;
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

  // Manual permission request method
  Future<void> requestPermissionManually() async {
    _isLoading = true;
    _errorType = null;
    notifyListeners();
    
    await _requestLocationPermission();
    
    _isLoading = false;
    notifyListeners();
  }
}