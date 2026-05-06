import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/game_page.dart';
import 'core/theme/app_colors.dart';
import 'domain/repositories/stats_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StanBlackJackApp());
}

class StanBlackJackApp extends StatelessWidget {
  final StatsRepository? statsRepository;
  static bool disableAnimations = false;
  const StanBlackJackApp({super.key, this.statsRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StanBlackJack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.tableGreen,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.tableGreen,
          brightness: Brightness.dark,
        ),
      ),
      home: GamePage(statsRepository: statsRepository),
    );
  }
}
