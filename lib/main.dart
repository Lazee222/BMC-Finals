
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/product_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const UrbanBrewApp());
}

class UrbanBrewApp extends StatelessWidget {
  const UrbanBrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    const coffeeBackground = Color(0xFF151311);
    const coffeeCaramel = Color(0xFFB87945);
    const coffeeCream = Color(0xFFF5E6D3);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Brew',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: coffeeBackground,
        colorScheme: const ColorScheme.dark(
          primary: coffeeCaramel,
          secondary: Color(0xFF6F452B),
          surface: Color(0xFF211C18),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: coffeeCream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: coffeeBackground,
          foregroundColor: coffeeCream,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF211C18),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeCaramel,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const ProductListScreen(),
    );
  }
}
