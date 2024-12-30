import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_bindings.dart';
import 'features/presentation/screens/splash/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'core/routes/app_routes.dart';

void main() async {
  await GetStorage.init();
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');

    // Load environment variables
    await dotenv.load();
    print('Environment variables loaded');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    // Don't print the actual key, just check if it exists
    print(
      'SUPABASE_ANON_KEY exists: ${dotenv.env['SUPABASE_ANON_KEY'] != null}',
    );

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print('Supabase initialized');

    runApp(const MyApp());
    print('App started');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Shop Now',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBindings(),
      home: const SplashScreen(),
      getPages: AppRoutes.routes,
      initialRoute: AppRoutes.splash,
    );
  }
}
