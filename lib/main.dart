import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/game_page.dart';
import 'core/theme/app_colors.dart';
import 'domain/repositories/stats_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Disable runtime fetching if it's causing issues in some environments
    // GoogleFonts.config.allowRuntimeFetching = true; 

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const StanBlackJackApp());
  } catch (e, stack) {
    debugPrint('Fatal error during initialization: $e');
    debugPrint(stack.toString());
    // Run app anyway with basic settings if possible
    runApp(const StanBlackJackApp());
  }
}

class StanBlackJackApp extends StatelessWidget {
  final StatsRepository? statsRepository;
  static bool disableAnimations = false;
  const StanBlackJackApp({super.key, this.statsRepository});

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark();
    
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.outfitTextTheme(darkTheme.textTheme);
    } catch (e) {
      debugPrint('GoogleFonts failed, using default text theme: $e');
      textTheme = darkTheme.textTheme;
    }

    return MaterialApp(
      title: 'StanBlackJack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.tableGreen,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.tableGreen,
          brightness: Brightness.dark,
        ),
      ),
      home: GamePage(statsRepository: statsRepository),
    );
  }
}
