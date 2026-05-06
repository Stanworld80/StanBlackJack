import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stan_blackjack/main.dart' as app;
import 'package:stan_blackjack/domain/repositories/stats_repository.dart';
import 'package:stan_blackjack/domain/entities/card.dart';
import 'package:stan_blackjack/presentation/blocs/game_bloc.dart';
import 'package:stan_blackjack/presentation/blocs/game_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

Future<void> setTestShoe(WidgetTester tester, List<CardEntity> cards) async {
  final shoe = [...cards];
  while (shoe.length < 10) {
    shoe.add(CardEntity(suit: Suit.spades, rank: Rank.two));
  }
  
  // Find the BuildContext from the app
  final BuildContext context = tester.element(find.byType(app.StanBlackJackApp));
  context.read<BlackjackBloc>().add(SetShoeForTesting(shoe));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Blackjack Game Integration Test', () {
    testWidgets('Full game loop: Bet, Deal, Hit, Stand, New Game', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      // Set surface size for the test
      tester.view.physicalSize = const Size(1280, 800);
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
      // Wait for dealing animation - using a long settle to ensure animations finish
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Now we should be in playing state (unless we got a blackjack)
      // Check for HIT or STAND buttons
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

    testWidgets('Double down scenario', (tester) async {
       app.StanBlackJackApp.disableAnimations = true;
       final mockRepo = MockStatsRepository();
      // Set surface size for the test
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Place bet
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();

      // Deal
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if double is available (only 2 cards)
      final doubleButton = find.byKey(const Key('btn_double'));
      if (doubleButton.evaluate().isNotEmpty) {
        await tester.tap(doubleButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // After double, it should automatically stand and go to dealer turn/game over
        expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
      }
    });
    testWidgets('Split Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Set shoe: 8, 8 for player, 6 for dealer
      await setTestShoe(tester, [
        CardEntity(suit: Suit.spades, rank: Rank.eight), // P1
        CardEntity(suit: Suit.hearts, rank: Rank.six),   // D1
        CardEntity(suit: Suit.clubs, rank: Rank.eight),  // P2
        CardEntity(suit: Suit.diamonds, rank: Rank.ten), // D2 (face down)
      ]);

      // Place bet
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();

      // Deal
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify "SÉPARER" button is visible
      expect(find.byKey(const Key('btn_split')), findsOneWidget);

      // Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we have 2 hands now
      expect(find.textContaining('100 Ͼ'), findsNWidgets(2));
    });

    testWidgets('Side Bet 21+3 Flush Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Set shoe: Flush (all Hearts)
      await setTestShoe(tester, [
        CardEntity(suit: Suit.hearts, rank: Rank.two),   // P1
        CardEntity(suit: Suit.hearts, rank: Rank.four),  // D1
        CardEntity(suit: Suit.hearts, rank: Rank.six),   // P2
        CardEntity(suit: Suit.spades, rank: Rank.ten),   // D2
      ]);

      // Place bets
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chip_side')));
      await tester.pumpAndSettle();

      // Deal
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify side bet win message
      expect(find.textContaining('21+3 GAGNÉ'), findsOneWidget);
    });

    testWidgets('Insurance Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Set shoe: Dealer has Ace, and will have Blackjack
      await setTestShoe(tester, [
        CardEntity(suit: Suit.spades, rank: Rank.ten),   // P1
        CardEntity(suit: Suit.hearts, rank: Rank.ace),   // D1
        CardEntity(suit: Suit.clubs, rank: Rank.five),   // P2
        CardEntity(suit: Suit.diamonds, rank: Rank.king), // D2 (face down, creates Blackjack)
      ]);

      // Place bet
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();

      // Deal
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify Insurance Dialog
      expect(find.text('ASSURANCE ?'), findsOneWidget);

      // Accept Insurance
      await tester.tap(find.text('OUI (ASSURER)'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dealer has Blackjack, so game should end
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });
  });
}
