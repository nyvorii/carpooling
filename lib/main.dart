import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'menu_screen.dart';
import 'home_screen.dart';
import 'models/route_model.dart';
import 'models/latlng_adapter.dart';
import 'models/booking_model.dart';
import 'models/geocoding_cache_model.dart';
import 'services/booking_service.dart';
import 'providers/user_mode_provider.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  await Hive.initFlutter();

  Hive.registerAdapter(LatLngAdapter());
  Hive.registerAdapter(RouteModelAdapter());
  Hive.registerAdapter(BookingModelAdapter());
  Hive.registerAdapter(GeocodingCacheAdapter());

  try {
    await Hive.openBox<RouteModel>('routes');
    await Hive.openBox<BookingModel>('bookings');
    await Hive.openBox<GeocodingCache>('geocoding_cache');

    final cacheBox = Hive.box<GeocodingCache>('geocoding_cache');
    print('[MAIN] Geocoding cache box otwarta, rozmiar: ${cacheBox.length}');
  } catch (e) {
    print('[MAIN] Błąd otwierania Hive boxes: $e');
    await Hive.deleteBoxFromDisk('routes');
    await Hive.deleteBoxFromDisk('bookings');
    await Hive.deleteBoxFromDisk('geocoding_cache');
    await Hive.openBox<RouteModel>('routes');
    await Hive.openBox<BookingModel>('bookings');
    await Hive.openBox<GeocodingCache>('geocoding_cache');
  }

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        Provider<BookingService>(
          create: (_) => BookingService(),
        ),
        ChangeNotifierProvider<UserModeProvider>(
          create: (_) => UserModeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingService = Provider.of<BookingService>(context, listen: false);
    bookingService.initializeFCM();

    return MaterialApp(
      title: 'Carpooling App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return HomeScreen();
    } else {
      return const MenuScreen();
    }
  }
}