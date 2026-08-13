import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/irrigation_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/real_esp_api_service.dart';
import 'services/database_service.dart';
import 'services/weather_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService.instance;
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService.instance,
        ),
        Provider<ApiService>(
          create: (_) => RealEspApiService(authToken: ''),
        ),
        Provider<WeatherService>(
          create: (_) => WeatherService(),
        ),
        Provider<StorageService>(
          create: (_) => storageService,
        ),
        ChangeNotifierProvider<IrrigationProvider>(
          create: (context) => IrrigationProvider(
            apiService: Provider.of<ApiService>(context, listen: false),
            databaseService: Provider.of<DatabaseService>(context, listen: false),
            weatherService: Provider.of<WeatherService>(context, listen: false),
            storageService: Provider.of<StorageService>(context, listen: false),
          ),
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
    return MaterialApp(
      title: 'Smart Farming',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
          primary: const Color(0xFF10B981),
          secondary: Colors.teal,
          background: const Color(0xFFF8FAFC),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF334155)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF10B981);
            }
            return Colors.grey.shade400;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF10B981).withOpacity(0.3);
            }
            return Colors.grey.shade200;
          }),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A)),
          bodyMedium: TextStyle(color: Color(0xFF334155)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
