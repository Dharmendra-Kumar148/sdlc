import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sdlc/core/logging/logger_service.dart';
import 'package:sdlc/core/constants/app_constants.dart';
import 'package:sdlc/viewmodel/media_viewmodel.dart';
import 'package:sdlc/viewmodel/filter_viewmodel.dart';
import 'package:sdlc/viewmodel/beauty_viewmodel.dart';
import 'package:sdlc/viewmodel/compression_viewmodel.dart';
import 'package:sdlc/viewmodel/post_viewmodel.dart';
import 'package:sdlc/view/screens/splash_screen.dart';
import 'package:sdlc/view/screens/login_screen.dart';
import 'package:sdlc/view/screens/dashboard_screen.dart';
import 'package:sdlc/view/screens/editor_screen.dart';
import 'package:sdlc/view/screens/preview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("DEBUG: main() started");
  LoggerService.info(LoggerService.auth, "System Bootstrapping...");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaViewModel()),
        ChangeNotifierProvider(create: (_) => FilterViewModel()),
        ChangeNotifierProvider(create: (context) => BeautyViewModel(Provider.of<FilterViewModel>(context, listen: false).engine)),
        ChangeNotifierProvider(create: (_) => CompressionViewModel()),
        ChangeNotifierProvider(create: (_) => PostViewModel()),
      ],
      child: const GaonGramApp(),
    ),
  );
  
  debugPrint("DEBUG: runApp() called");
}

class GaonGramApp extends StatelessWidget {
  const GaonGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryBlue,
        scaffoldBackgroundColor: AppConstants.darkBackground,
        fontFamily: 'Inter',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/editor': (context) => const EditorScreen(),
        '/preview': (context) => const PreviewScreen(),
      },
    );
  }
}
