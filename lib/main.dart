import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_bindings.dart';
import 'features/presentation/screens/splash/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'core/routes/app_routes.dart';
import 'features/presentation/controllers/product_controller.dart';
import 'features/presentation/controllers/category_controller.dart';
import 'features/data/services/product_search_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Configure system UI to prevent default splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize GetStorage first (fastest)
    await GetStorage.init();
    print('GetStorage initialized');

    // Load environment variables
    await dotenv.load();
    print('Environment variables loaded');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    print(
      'SUPABASE_ANON_KEY exists: ${dotenv.env['SUPABASE_ANON_KEY'] != null}',
    );

    // Initialize Supabase before starting the app
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print('Supabase initialized');

    // Initialize controllers in background after app starts
    _initializeControllersInBackground();

    runApp(const MyApp());
    print('App started');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> _initializeControllersInBackground() async {
  try {
    // Initialize services and controllers
    Get.put(ProductSearchService());
    Get.put(ProductController());
    Get.put(CategoryController());

    print('All controllers initialized');
  } catch (e, stackTrace) {
    print('Error during controller initialization: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Be Smart Mall',
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
