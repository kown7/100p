import 'package:geolocator/geolocator.dart';

class LocationData {
  final Position? position;
  final double latitude;
  final double longitude;
  final int sunrise;
  final int sunset;
  final int twilightState;
  final String displayText;
  final double progress;

  LocationData({
    this.position,
    required this.latitude,
    required this.longitude,
    required this.sunrise,
    required this.sunset,
    required this.twilightState,
    required this.displayText,
    required this.progress,
  });

  // Default location (Zurich) matching the Android app
  static LocationData get defaultLocation => LocationData(
        latitude: 47.3769, // Zurich latitude
        longitude: 8.5417, // Zurich longitude
        sunrise: -1,
        sunset: -1,
        twilightState: 0,
        displayText: "Es ist Zeit",
        progress: 1.0,
      );

  LocationData copyWith({
    Position? position,
    double? latitude,
    double? longitude,
    int? sunrise,
    int? sunset,
    int? twilightState,
    String? displayText,
    double? progress,
  }) {
    return LocationData(
      position: position ?? this.position,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      twilightState: twilightState ?? this.twilightState,
      displayText: displayText ?? this.displayText,
      progress: progress ?? this.progress,
    );
  }
}