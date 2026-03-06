import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'widgets/progress_circle.dart';

void main() {
  runApp(const OneHundredPercentApp());
}

class OneHundredPercentApp extends StatelessWidget {
  const OneHundredPercentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationProvider(),
      child: MaterialApp(
        title: 'One Hundert Percent',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

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
    // Register listener exactly once after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<LocationProvider>(context, listen: false);
      _provider!.addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.toastMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationProvider.toastMessage!),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      locationProvider.clearToast();
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
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          final locationData = locationProvider.locationData;
          
          return Stack(
            children: [
              // Main centered content (circular progress indicator and text)
              Center(
                child: DaylightProgressCircle(
                  progress: locationData.progress,
                  centerText: locationData.displayText,
                ),
              ),
              
              // Location info in top-right corner (matching Android layout)
              Positioned(
                top: 60, // Account for status bar
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Location\n'
                    'Lat  ${locationData.latitude.toStringAsFixed(2)} N\n'
                    'Long ${locationData.longitude.toStringAsFixed(2)} E',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              
              // Loading indicator
              if (locationProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              // Error message and retry functionality
              if (locationProvider.error != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationProvider.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => locationProvider.refresh(),
                              child: const Text('Retry'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => locationProvider.requestPermissionManually(),
                              icon: const Icon(Icons.location_on),
                              label: const Text('Enable Location'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // Debug FAB for manual permission testing
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
          locationProvider.requestPermissionManually();
        },
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}