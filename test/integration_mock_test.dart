import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stan_blackjack/main.dart' as app;
import 'package:stan_blackjack/domain/repositories/stats_repository.dart';

class MockStatsRepository implements StatsRepository {
  @override
  Future<Map<String, dynamic>> loadStats() async {
    return {
      'balance': 1000,
      'totalGames': 0,
      'totalMoves': 0,
      'correctStrategyMoves': 0,
    };
  }

  @override
  Future<void> saveStats({
    required int balance,
    required int totalGames,
    required int totalMoves,
    required int correctStrategyMoves,
  }) async {
    // Do nothing for mock
  }
}

void main() {
  group('Blackjack Game Widget-level Integration Test', () {
    testWidgets('Full game loop: Bet, Deal, Hit, Stand, New Game', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      // Set surface size for the test
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Start the app
      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Verify we are in betting state
      expect(find.text('DISTRIBUER'), findsOneWidget);
      expect(find.byKey(const Key('chip_10')), findsOneWidget);

      // Place a bet
      await tester.tap(find.byKey(const Key('chip_10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chip_50')));
      await tester.pumpAndSettle();

      // Verify total bet is 60
      expect(find.textContaining('60'), findsWidgets);
      expect(find.textContaining('940'), findsOneWidget);

      // Deal cards
      await tester.tap(find.byKey(const Key('btn_deal')));
      // Wait for dealing animation
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Now we should be in playing state (unless we got a blackjack)
      final hitButton = find.byKey(const Key('btn_hit'));
      final standButton = find.byKey(const Key('btn_stand'));

      if (hitButton.evaluate().isNotEmpty) {
        // We are playing
        await tester.tap(hitButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Stand
        if (standButton.evaluate().isNotEmpty) {
          await tester.tap(standButton);
          await tester.pumpAndSettle(const Duration(seconds: 3)); // Dealer turn
        }
      }

      // Should eventually reach Game Over
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);

      // Start a new game
      await tester.tap(find.byKey(const Key('btn_new_game')));
      await tester.pumpAndSettle();

      // Back to betting
      expect(find.text('DISTRIBUER'), findsOneWidget);
    });
  });
}
