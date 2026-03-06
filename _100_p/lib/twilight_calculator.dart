import 'dart:math';

class TwilightCalculator {
  /// Value of [state] if it is currently day
  static const int day = 0;

  /// Value of [state] if it is currently night  
  static const int night = 1;

  static const double _degreesToRadians = pi / 180.0;

  // element for calculating solar transit.
  static const double _j0 = 0.0009;

  // correction for civil twilight
  static const double _altitudeCorrection = -0.104719755;

  // coefficients for calculating Equation of Center.
  static const double _c1 = 0.0334196;
  static const double _c2 = 0.000349066;
  static const double _c3 = 0.000005236;

  static const double _obliquity = 0.40927971;

  // Java time on Jan 1, 2000 12:00 UTC.
  static const int _utc2000 = 946728000000;

  /// Time of sunset (civil twilight) in milliseconds or -1 in the case the day
  /// or night never ends.
  late int sunset;

  /// Time of sunrise (civil twilight) in milliseconds or -1 in the case the  
  /// day or night never ends.
  late int sunrise;

  /// Current state
  late int state;

  /// Calculates the civil twilight based on time and geo-coordinates.
  ///
  /// [time] time in milliseconds.
  /// [latitude] latitude in degrees.
  /// [longitude] longitude in degrees.
  void calculateTwilight(int time, double latitude, double longitude) {
    final double daysSince2000 = (time - _utc2000) / (24 * 60 * 60 * 1000);

    // mean anomaly
    final double meanAnomaly = 6.240059968 + daysSince2000 * 0.01720197;

    // true anomaly
    final double trueAnomaly = meanAnomaly +
        _c1 * sin(meanAnomaly) +
        _c2 * sin(2 * meanAnomaly) +
        _c3 * sin(3 * meanAnomaly);

    // ecliptic longitude
    final double solarLng = trueAnomaly + 1.796593063 + pi;

    // solar transit in days since 2000
    final double arcLongitude = -longitude / 360;
    double n = (daysSince2000 - _j0 - arcLongitude).round().toDouble();
    double solarTransitJ2000 = n +
        _j0 +
        arcLongitude +
        0.0053 * sin(meanAnomaly) +
        -0.0069 * sin(2 * solarLng);

    // declination of sun
    double solarDec = asin(sin(solarLng) * sin(_obliquity));

    final double latRad = latitude * _degreesToRadians;
    double cosHourAngle = (sin(_altitudeCorrection) -
            sin(latRad) * sin(solarDec)) /
        (cos(latRad) * cos(solarDec));

    // The day or night never ends for the given date and location, if this value is out of
    // range.
    if (cosHourAngle >= 1) {
      state = night;
      sunset = -1;
      sunrise = -1;
      return;
    } else if (cosHourAngle <= -1) {
      state = day;
      sunset = -1;
      sunrise = -1;
      return;
    }

    double hourAngle = acos(cosHourAngle) / (2 * pi);
    sunset = ((solarTransitJ2000 + hourAngle) * 24 * 60 * 60 * 1000).round() + _utc2000;
    sunrise = ((solarTransitJ2000 - hourAngle) * 24 * 60 * 60 * 1000).round() + _utc2000;

    if (sunrise < time && sunset > time) {
      state = day;
    } else {
      state = night;
    }
  }
}