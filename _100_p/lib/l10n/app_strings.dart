import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/location_error.dart';

/// Minimal hand-written localization — supports 'en' and 'de'.
/// Resolved from the device locale; falls back to English.
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  bool get _de => locale.languageCode == 'de';

  // ── Center ring text ────────────────────────────────────────────────────
  /// Shown when it is night (the app's identity tagline stays German in both
  /// languages as a deliberate design choice, but can be overridden).
  String get nightText => 'Es ist Zeit';

  /// Sub-label below the percentage during the day.
  String get elapsedLabel => _de ? 'DES TAGES VERGANGEN' : 'OF DAY ELAPSED';

  // ── Info card labels ─────────────────────────────────────────────────────
  String get sunrise    => _de ? 'SONNENAUFGANG' : 'SUNRISE';
  String get sunset     => _de ? 'SONNENUNTERGANG' : 'SUNSET';
  String get location   => _de ? 'STANDORT' : 'LOCATION';

  // ── Buttons ──────────────────────────────────────────────────────────────
  String get retry          => _de ? 'Wiederholen' : 'Retry';
  String get enableLocation => _de ? 'Standort aktivieren' : 'Enable Location';

  // ── Toast ─────────────────────────────────────────────────────────────────
  String pikachuToast(double lat) => _de
      ? 'Ein Pikachu ist in der Nähe aufgetaucht! $lat'
      : 'A pikachu appeared nearby! $lat';

  // ── Error messages ────────────────────────────────────────────────────────
  String errorMessage(LocationErrorType type) {
    switch (type) {
      case LocationErrorType.servicesDisabled:
        return _de
            ? 'Ortungsdienste sind deaktiviert. Bitte in den Einstellungen aktivieren.'
            : 'Location services are disabled. Please enable them in Settings.';
      case LocationErrorType.permissionDenied:
        return _de
            ? 'Standortzugriff verweigert.'
            : 'Location permission denied.';
      case LocationErrorType.permanentlyDenied:
        return _de
            ? 'Standortzugriff dauerhaft verweigert. Bitte in den Einstellungen aktivieren.'
            : 'Location permissions are permanently denied. Please enable them in Settings.';
      case LocationErrorType.unknown:
        return _de
            ? 'Ein unbekannter Fehler ist aufgetreten.'
            : 'An unknown error occurred.';
    }
  }

  // ── Delegate ─────────────────────────────────────────────────────────────
  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
