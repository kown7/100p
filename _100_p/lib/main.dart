import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    c = [const Color(0xFF020818), const Color(0xFF050E2A), const Color(0xFF0B1A3E)];
  } else if (progress < 0.15) {
    // pre-dawn → dawn
    final t = progress / 0.15;
    c = [
      Color.lerp(const Color(0xFF020818), const Color(0xFF1A237E), t)!,
      Color.lerp(const Color(0xFF050E2A), const Color(0xFFBF360C), t)!,
      Color.lerp(const Color(0xFF0B1A3E), const Color(0xFFFF8F00), t)!,
    ];
  } else if (progress < 0.5) {
    // dawn → midday
    final t = (progress - 0.15) / 0.35;
    c = [
      Color.lerp(const Color(0xFF1A237E), const Color(0xFF0D47A1), t)!,
      Color.lerp(const Color(0xFFBF360C), const Color(0xFF1565C0), t)!,
      Color.lerp(const Color(0xFFFF8F00), const Color(0xFF90CAF9), t)!,
    ];
  } else if (progress < 0.85) {
    // midday → late afternoon
    final t = (progress - 0.5) / 0.35;
    c = [
      Color.lerp(const Color(0xFF0D47A1), const Color(0xFF4A148C), t)!,
      Color.lerp(const Color(0xFF1565C0), const Color(0xFFE65100), t)!,
      Color.lerp(const Color(0xFF90CAF9), const Color(0xFFFF8F00), t)!,
    ];
  } else {
    // sunset → night
    final t = (progress - 0.85) / 0.15;
    c = [
      Color.lerp(const Color(0xFF4A148C), const Color(0xFF020818), t)!,
      Color.lerp(const Color(0xFFE65100), const Color(0xFF050E2A), t)!,
      Color.lerp(const Color(0xFFFF8F00), const Color(0xFF0B1A3E), t)!,
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
    if (lp.toastMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.toastMessage!),
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

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      DaylightProgressCircle(
                        progress: data.progress,
                        centerText: data.displayText,
                        isNight: data.isNight,
                      ),

                      const SizedBox(height: 52),

                      _InfoCard(data: data),

                      const Spacer(flex: 2),

                      if (lp.error != null)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: _ErrorCard(lp: lp),
                        ),

                      if (lp.isLoading && lp.error == null)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(
                  icon: Icons.wb_sunny_outlined,
                  label: 'SUNRISE',
                  value: _formatTime(data.sunrise),
                ),
                _VertDivider(),
                _InfoTile(
                  icon: Icons.nights_stay_outlined,
                  label: 'SUNSET',
                  value: _formatTime(data.sunset),
                ),
                _VertDivider(),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'LOCATION',
                  value:
                      '${data.latitude.toStringAsFixed(2)}° N\n${data.longitude.toStringAsFixed(2)}° E',
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
        Icon(icon, color: Colors.white38, size: 15),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1.5)),
        const SizedBox(height: 5),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4)),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 52,
        color: Colors.white.withValues(alpha: 0.1),
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
                    child: Text(lp.error!,
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
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: lp.requestPermissionManually,
                    icon: const Icon(Icons.my_location, size: 14),
                    label: const Text('Enable Location'),
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


