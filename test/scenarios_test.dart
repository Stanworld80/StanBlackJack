import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stan_blackjack/main.dart' as app;
import 'package:stan_blackjack/presentation/pages/game_page.dart';
import 'package:stan_blackjack/domain/repositories/stats_repository.dart';
import 'package:stan_blackjack/presentation/blocs/game_bloc.dart';
import 'package:stan_blackjack/presentation/blocs/game_event.dart';
import 'package:stan_blackjack/domain/entities/card.dart';

class MockStatsRepository implements StatsRepository {
  int lastSavedBalance = 0;
  int lastSavedTotalGames = 0;
  int lastSavedTotalMoves = 0;
  int lastSavedCorrectStrategyMoves = 0;

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
    lastSavedBalance = balance;
    lastSavedTotalGames = totalGames;
    lastSavedTotalMoves = totalMoves;
    lastSavedCorrectStrategyMoves = correctStrategyMoves;
  }
}

void main() {
  group('Blackjack Scenario Tests', () {
    testWidgets('Split Aces Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      // Find the bloc to inject our custom shoe
      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe for splitting Aces
      // Order of deal: P1, D1, P2, D2(hidden), then P1-hit, P2-hit...
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.ace), // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),  // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.ace), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),  // D2 (hidden)
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),  // Next for P1
        const CardEntity(suit: Suit.diamonds, rank: Rank.jack), // Next for P2
        const CardEntity(suit: Suit.clubs, rank: Rank.five),   // Next for Dealer...
        const CardEntity(suit: Suit.clubs, rank: Rank.six),
        const CardEntity(suit: Suit.clubs, rank: Rank.seven),
        const CardEntity(suit: Suit.clubs, rank: Rank.eight),
        const CardEntity(suit: Suit.clubs, rank: Rank.nine),
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we have two Aces
      expect(find.text('SÉPARER'), findsOneWidget);

      // Tap Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // In the case of Aces split, it should deal one card each and automatically stand
      // Verify we have two hands now
      expect(find.textContaining('21'), findsWidgets); 
      
      // Should go straight to game over since Aces split only get one card
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });

    testWidgets('Insurance Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe where dealer has an Ace
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.two),   // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ace),   // D1 (Ace!)
        const CardEntity(suit: Suit.diamonds, rank: Rank.three), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),  // D2 (hidden, will be Blackjack)
        const CardEntity(suit: Suit.clubs, rank: Rank.two),
        const CardEntity(suit: Suit.clubs, rank: Rank.three),
        const CardEntity(suit: Suit.clubs, rank: Rank.four),
        const CardEntity(suit: Suit.clubs, rank: Rank.five),
        const CardEntity(suit: Suit.clubs, rank: Rank.six),
        const CardEntity(suit: Suit.clubs, rank: Rank.seven),
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Insurance dialog should be shown
      expect(find.text('ASSURANCE ?'), findsNWidgets(2));
      expect(find.byType(AlertDialog), findsOneWidget);

      // Accept insurance
      await tester.tap(find.text('OUI (ASSURER)'));
      await tester.pumpAndSettle();

      // Wait for game over processing
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Verify balance (1000 - 100 bet - 50 insurance + 150 insurance payout = 1000)
      // Since it's a dealer blackjack, insurance pays 2:1 on 50 = 100 profit + 50 stake = 150 back.
      expect(find.textContaining('1000'), findsOneWidget);
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });
    
    testWidgets('21+3 Side Bet Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe for 21+3 Suited Straight (Hearts 2, 3, 4)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.two),   // P1
        const CardEntity(suit: Suit.hearts, rank: Rank.four),   // D1
        const CardEntity(suit: Suit.hearts, rank: Rank.three), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),   // D2
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),    // Filler...
        const CardEntity(suit: Suit.clubs, rank: Rank.nine),
        const CardEntity(suit: Suit.clubs, rank: Rank.eight),
        const CardEntity(suit: Suit.clubs, rank: Rank.seven),
        const CardEntity(suit: Suit.clubs, rank: Rank.six),
        const CardEntity(suit: Suit.clubs, rank: Rank.five),
        const CardEntity(suit: Suit.clubs, rank: Rank.four),
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Place bets
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chip_side'))); // 10 on side bet
      await tester.pumpAndSettle();
      
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify side bet win message
      expect(find.text('21+3 GAGNÉ !'), findsOneWidget);
      
      // Balance check: 1000 - 100 - 10 + 410 (side bet payout) = 1300
      // Note: Regular game continues.
      expect(find.textContaining('1300'), findsOneWidget);
    });

    testWidgets('Split 8s Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe for splitting 8s
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.eight),  // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.six),    // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.eight), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.seven),  // D2
        const CardEntity(suit: Suit.hearts, rank: Rank.two),   // Next for hand 1
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),   // Next for hand 1 (will stand)
        const CardEntity(suit: Suit.diamonds, rank: Rank.three), // Next for hand 2
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),  // Next for hand 2 (will stand)
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),    // Dealer next...
        const CardEntity(suit: Suit.clubs, rank: Rank.nine),
        const CardEntity(suit: Suit.clubs, rank: Rank.eight),
        const CardEntity(suit: Suit.clubs, rank: Rank.seven),
        const CardEntity(suit: Suit.clubs, rank: Rank.six),
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Hand 1 (8, 2 = 10)
      expect(find.textContaining('10'), findsWidgets);
      
      // Hit on hand 1
      await tester.tap(find.byKey(const Key('btn_hit')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Hand 1 should now be 20 (8, 2, 10)
      expect(find.textContaining('20'), findsWidgets);

      // Stand on hand 1
      await tester.tap(find.byKey(const Key('btn_stand')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Hand 2 (8, 3 = 11)
      expect(find.textContaining('11'), findsWidgets);

      // Hit on hand 2
      await tester.tap(find.byKey(const Key('btn_hit')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Hand 2 should now be 21 (8, 3, 10)
      expect(find.textContaining('21'), findsWidgets);

      // Stand on hand 2
      await tester.tap(find.byKey(const Key('btn_stand')));
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Dealer turn

      // Verify game over
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });

    testWidgets('Surrender Scenario and Strategy Advice', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe for Surrender (16 vs 10)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.six),  // P2
        const CardEntity(suit: Suit.spades, rank: Rank.seven),  // D2
        const CardEntity(suit: Suit.hearts, rank: Rank.two),
        const CardEntity(suit: Suit.hearts, rank: Rank.three),
        const CardEntity(suit: Suit.hearts, rank: Rank.four),
        const CardEntity(suit: Suit.hearts, rank: Rank.five),
        const CardEntity(suit: Suit.hearts, rank: Rank.seven),
        const CardEntity(suit: Suit.hearts, rank: Rank.eight),
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify Strategy Advice suggests Surrender (Abandonner)
      // We'll search for the text 'SURRENDER' regardless of prefix
      expect(find.textContaining('SURRENDER'), findsOneWidget);

      // Verify Surrender button is visible
      expect(find.byKey(const Key('btn_surrender')), findsOneWidget);
      expect(find.text('ABANDONNER'), findsOneWidget);

      // Tap Surrender
      await tester.tap(find.byKey(const Key('btn_surrender')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Balance check: 1000 - 100 + 50 (refund) = 950
      expect(find.textContaining('950'), findsOneWidget);
      expect(find.textContaining('SURRENDERED'), findsOneWidget);
      
      // Verify game over
      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });

    testWidgets('Multiple Splits (Limit 4) Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Prepare a shoe for multiple splits (Limit 4)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.eight),   // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.six),      // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.eight), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),     // D2
        const CardEntity(suit: Suit.clubs, rank: Rank.eight),    // Card for first split
        const CardEntity(suit: Suit.spades, rank: Rank.eight),   // Card for second split
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),     // Card for third split
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),   // Card for P2
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),      // Card for P3
        const CardEntity(suit: Suit.spades, rank: Rank.ten),     // Card for P4
        const CardEntity(suit: Suit.hearts, rank: Rank.nine),    // Dealer next...
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 1st Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 2nd Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 3rd Split
      await tester.tap(find.byKey(const Key('btn_split')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we have 4 hands and Split is no longer available
      expect(find.text('SÉPARER'), findsNothing);
      
      // Complete the game
      await tester.tap(find.byKey(const Key('btn_stand'))); // Hand 1
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('btn_stand'))); // Hand 2
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('btn_stand'))); // Hand 3
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('btn_stand'))); // Hand 4
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byKey(const Key('btn_new_game')), findsOneWidget);
    });

    testWidgets('Strategy Precision Tracking Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Shoe: P(11), D(6) -> Double Down is correct.
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.six),    // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.six),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.five), // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),    // D2
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // Hit 1 -> 21
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),     // Dealer next...
        const CardEntity(suit: Suit.hearts, rank: Rank.two),    // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.three),  // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.four),   // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.five),   // Filler
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Correct action is Double Down, but we Hit.
      await tester.tap(find.byKey(const Key('btn_hit')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Now we have 21. Correct action is Stand.
      await tester.tap(find.byKey(const Key('btn_stand')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify stats
      expect(mockRepo.lastSavedTotalMoves, 2);
      expect(mockRepo.lastSavedCorrectStrategyMoves, 1);
    });

    testWidgets('Dealer Bust Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Shoe: P(20), D(12) -> Dealer hits and busts.
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.six),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),  // P2
        const CardEntity(suit: Suit.spades, rank: Rank.six),    // D2
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // Dealer hit -> 22
        const CardEntity(suit: Suit.hearts, rank: Rank.two),    // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.three),  // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.four),   // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.five),   // Filler
        const CardEntity(suit: Suit.hearts, rank: Rank.six),    // Filler
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      // Bet and Deal
      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Player Stands
      await tester.tap(find.byKey(const Key('btn_stand')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Win and balance
      expect(find.text('WIN!'), findsOneWidget);
      expect(find.textContaining('1100'), findsOneWidget);
    });

    testWidgets('Push Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Shoe: P(20), D(20)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),  // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),    // D2
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('btn_stand')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Push and balance (1000 - 100 bet + 100 refund = 1000)
      expect(find.text('PUSH'), findsOneWidget);
      expect(find.textContaining('1000'), findsOneWidget);
    });

    testWidgets('Player Bust Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Shoe: P(12), D(20), P hits 10 -> 22 (Bust)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.two),     // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ten),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),  // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),    // D2
        const CardEntity(suit: Suit.hearts, rank: Rank.ten),    // Player Hit -> 22
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('btn_hit')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify Busted and balance (1000 - 100 = 900)
      expect(find.text('BUSTED'), findsOneWidget);
      expect(find.textContaining('900'), findsOneWidget);
    });

    testWidgets('Blackjack Push Scenario', (tester) async {
      app.StanBlackJackApp.disableAnimations = true;
      final mockRepo = MockStatsRepository();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app.StanBlackJackApp(statsRepository: mockRepo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(GameView));
      final bloc = context.read<BlackjackBloc>();

      // Shoe: P(BJ), D(BJ)
      final testCards = [
        const CardEntity(suit: Suit.hearts, rank: Rank.ace),    // P1
        const CardEntity(suit: Suit.clubs, rank: Rank.ace),     // D1
        const CardEntity(suit: Suit.diamonds, rank: Rank.ten),  // P2
        const CardEntity(suit: Suit.spades, rank: Rank.ten),    // D2
      ];

      bloc.add(SetShoeForTesting(testCards));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_deal')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should automatically end because of Blackjack
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Push and balance (1000 - 100 + 100 = 1000)
      expect(find.text('PUSH'), findsOneWidget);
      expect(find.textContaining('1000'), findsOneWidget);
    });
  });
}
