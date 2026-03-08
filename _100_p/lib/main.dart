import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'models/location_data.dart';
import 'providers/location_provider.dart';
import 'widgets/progress_circle.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const OneHundredPercentApp());
}

class OneHundredPercentApp extends StatelessWidget {
  const OneHundredPercentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider(),
      child: MaterialApp(
        title: 'One Hundert Percent',
        debugShowCheckedModeBanner: false,
        locale: const Locale('de'), // default; overridden by device locale
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF020818),
        ),
        home: const HomePage(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sky gradient — smoothly shifts from dawn → noon → dusk → night
// ---------------------------------------------------------------------------
LinearGradient _skyGradient(double progress, bool isNight) {
  const stops = [0.0, 0.5, 1.0];
  late List<Color> c;

  if (isNight) {
    // Deep midnight navy
    c = [const Color(0xFF020818), const Color(0xFF050E2A), const Color(0xFF0B1A3E)];
  } else if (progress < 0.08) {
    // Pre-dawn: navy to first pink glow on horizon
    final t = progress / 0.08;
    c = [
      Color.lerp(const Color(0xFF020818), const Color(0xFF37265A), t)!,
      Color.lerp(const Color(0xFF050E2A), const Color(0xFFBF360C), t)!,
      Color.lerp(const Color(0xFF0B1A3E), const Color(0xFFFF8F00), t)!,
    ];
  } else if (progress < 0.18) {
    // Sunrise: warm orange horizon, sky turning purple → blue starts appearing
    final t = (progress - 0.08) / 0.10;
    c = [
      Color.lerp(const Color(0xFF37265A), const Color(0xFF1565C0), t)!,
      Color.lerp(const Color(0xFFBF360C), const Color(0xFF42A5F5), t)!,
      Color.lerp(const Color(0xFFFF8F00), const Color(0xFFFFE0B2), t)!,
    ];
  } else if (progress < 0.30) {
    // Mid-morning (≈9–11am): clear bright blue sky dominates fully
    final t = (progress - 0.18) / 0.12;
    c = [
      Color.lerp(const Color(0xFF1565C0), const Color(0xFF1976D2), t)!,
      Color.lerp(const Color(0xFF42A5F5), const Color(0xFF64B5F6), t)!,
      Color.lerp(const Color(0xFFFFE0B2), const Color(0xFFE3F2FD), t)!,
    ];
  } else if (progress < 0.70) {
    // Midday: vivid azure top, hazy white-blue horizon
    final t = (progress - 0.30) / 0.40;
    c = [
      Color.lerp(const Color(0xFF1976D2), const Color(0xFF1565C0), t)!,
      Color.lerp(const Color(0xFF64B5F6), const Color(0xFF90CAF9), t)!,
      Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFFFF9C4), t)!,
    ];
  } else if (progress < 0.85) {
    // Late afternoon → golden hour
    final t = (progress - 0.70) / 0.15;
    c = [
      Color.lerp(const Color(0xFF1565C0), const Color(0xFF6A1B9A), t)!,
      Color.lerp(const Color(0xFF90CAF9), const Color(0xFFEF6C00), t)!,
      Color.lerp(const Color(0xFFFFF9C4), const Color(0xFFFFCC02), t)!,
    ];
  } else {
    // Sunset → night
    final t = (progress - 0.85) / 0.15;
    c = [
      Color.lerp(const Color(0xFF6A1B9A), const Color(0xFF020818), t)!,
      Color.lerp(const Color(0xFFEF6C00), const Color(0xFF050E2A), t)!,
      Color.lerp(const Color(0xFFFFCC02), const Color(0xFF0B1A3E), t)!,
    ];
  }

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: c,
    stops: stops,
  );
}

String _formatTime(int ms) {
  if (ms <= 0) return '--:--';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<LocationProvider>(context, listen: false);
      _provider!.addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    final lp = Provider.of<LocationProvider>(context, listen: false);
    if (lp.pendingToastLat != null) {
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.pikachuToast(lp.pendingToastLat!)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      lp.clearToast();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<LocationProvider>(
        builder: (context, lp, _) {
          final data = lp.locationData;
          final gradient = _skyGradient(data.progress, data.isNight);

          return AnimatedContainer(
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(gradient: gradient),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Stars — only visible at night
                AnimatedOpacity(
                  opacity: data.isNight ? 1.0 : 0.0,
                  duration: const Duration(seconds: 2),
                  child: const _StarField(),
                ),

                // Sun glow — only visible during the day
                if (!data.isNight)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: data.isNight ? 0.0 : 1.0,
                      duration: const Duration(seconds: 2),
                      child: _SunGlow(progress: data.progress),
                    ),
                  ),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      DaylightProgressCircle(
                        progress: data.progress,
                        centerText: data.isNight
                            ? AppStrings.of(context).nightText
                            : data.displayText,
                        isNight: data.isNight,
                      ),

                      const SizedBox(height: 52),

                      _InfoCard(data: data),

                      const Spacer(flex: 2),

                      if (lp.errorType != null)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: _ErrorCard(lp: lp),
                        ),

                      if (lp.isLoading && lp.errorType == null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: CircularProgressIndicator(
                            color: Colors.white38,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sun glow (day background radial burst)
// ---------------------------------------------------------------------------
class _SunGlow extends StatelessWidget {
  final double progress;
  const _SunGlow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final x = progress.clamp(0.0, 1.0);
    final alignment = Alignment(x * 2 - 1, -0.65);

    // How warm (orange) vs cool (white) the sun is:
    // 0–10%: full orange dawn, 10–25%: rapidly cools to pale gold, 25–75%: white-gold midday
    final warmth = progress < 0.10
        ? 1.0
        : progress < 0.25
            ? 1.0 - ((progress - 0.10) / 0.15)
            : 0.0;

    // Core colour: lerp from deep amber (dawn) to pale white-gold (day)
    final coreR = (255).round();
    final coreG = (165 + (255 - 165) * (1 - warmth)).round().clamp(0, 255);
    final coreB = (0 + 220 * (1 - warmth)).round().clamp(0, 255);

    // Intensity: strong at dawn/dusk edges, slightly dimmer at peak midday
    final intensity = progress < 0.15
        ? (progress / 0.15) * 0.55          // fade in at dawn
        : progress > 0.85
            ? ((1.0 - progress) / 0.15) * 0.55 // fade out at dusk
            : 0.30 + (1.0 - (progress - 0.5).abs() * 1.5).clamp(0.0, 1.0) * 0.15;

    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: 1.0,
          colors: [
            Color.fromRGBO(coreR, coreG, coreB, intensity.clamp(0.0, 1.0)),
            Color.fromRGBO(coreR, coreG, coreB, (intensity * 0.35).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Star field (night background)
// ---------------------------------------------------------------------------
class _StarField extends StatelessWidget {
  const _StarField();

  static final _stars = List.generate(110, (i) {
    final rng = math.Random(i * 2654435761);
    return (
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      r: 0.4 + rng.nextDouble() * 1.4,
      a: 0.25 + rng.nextDouble() * 0.75,
    );
  });

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StarsPainter(_stars));
}

class _StarsPainter
    extends CustomPainter {
  final List<({double x, double y, double r, double a})> stars;
  const _StarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: s.a),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

// ---------------------------------------------------------------------------
// Frosted-glass info card (sunrise / sunset / coordinates)
// ---------------------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final LocationData data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: isIOS ? CupertinoIcons.sunrise : Icons.wb_sunny_outlined,
                    label: s.sunrise,
                    value: _formatTime(data.sunrise),
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: _InfoTile(
                    icon: isIOS ? CupertinoIcons.sunset : Icons.nights_stay_outlined,
                    label: s.sunset,
                    value: _formatTime(data.sunset),
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: _InfoTile(
                    icon: isIOS ? CupertinoIcons.location : Icons.location_on_outlined,
                    label: s.location,
                    value:
                        '${data.latitude.toStringAsFixed(2)}°\n${data.longitude.toStringAsFixed(2)}°',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 15),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white54, fontSize: 8.5, letterSpacing: 1.2),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  // ignore: unused_element
  const _VertDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withValues(alpha: 0.15),
      );
}

// ---------------------------------------------------------------------------
// Error / permission card
// ---------------------------------------------------------------------------
class _ErrorCard extends StatelessWidget {
  final LocationProvider lp;
  const _ErrorCard({required this.lp});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lp.errorType != null
                          ? s.errorMessage(lp.errorType!)
                          : '',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: lp.refresh,
                    child: Text(s.retry,
                        style: const TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: lp.requestPermissionManually,
                    icon: const Icon(Icons.my_location, size: 14),
                    label: Text(s.enableLocation),
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


