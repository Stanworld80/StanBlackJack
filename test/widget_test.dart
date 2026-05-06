import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stan_blackjack/domain/repositories/stats_repository.dart';
import 'package:stan_blackjack/presentation/pages/game_page.dart';
import 'package:stan_blackjack/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class MockStatsRepository extends Mock implements StatsRepository {}

void main() {
  late MockStatsRepository mockStatsRepository;

  setUp(() {
    mockStatsRepository = MockStatsRepository();
    when(() => mockStatsRepository.loadStats()).thenAnswer((_) async => {
      'balance': 1000,
      'totalGames': 0,
      'totalMoves': 0,
      'correctStrategyMoves': 0,
    });
  });

  testWidgets('Game starts with balance test', (WidgetTester tester) async {
    // Avoid font loading issues in tests
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.tableGreen,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: GamePage(statsRepository: mockStatsRepository),
    ));

    await tester.pump(); // Start animations/loading
    await tester.pump(const Duration(seconds: 1)); // Wait for LoadStats

    // Verify that our game starts and shows the balance
    expect(find.textContaining('SOLDE'), findsOneWidget);
    expect(find.textContaining('MISE'), findsOneWidget);
  });
}
