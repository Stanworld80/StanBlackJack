import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stan_blackjack/domain/repositories/stats_repository.dart';
import 'package:stan_blackjack/core/services/audio_service.dart';
import 'package:stan_blackjack/presentation/blocs/game_bloc.dart';
import 'package:stan_blackjack/presentation/blocs/game_event.dart';
import 'package:stan_blackjack/presentation/blocs/game_state.dart';
import 'package:stan_blackjack/domain/entities/card.dart';
import 'package:stan_blackjack/domain/entities/hand.dart';

class MockStatsRepository extends Mock implements StatsRepository {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late BlackjackBloc blackjackBloc;
  late MockStatsRepository mockStatsRepository;
  late MockAudioService mockAudioService;

  setUp(() {
    mockStatsRepository = MockStatsRepository();
    mockAudioService = MockAudioService();
    
    when(() => mockStatsRepository.loadStats()).thenAnswer((_) async => {
      'balance': 1000,
      'totalGames': 0,
      'totalMoves': 0,
      'correctStrategyMoves': 0,
    });
    
    when(() => mockStatsRepository.saveStats(
      balance: any(named: 'balance'),
      totalGames: any(named: 'totalGames'),
      totalMoves: any(named: 'totalMoves'),
      correctStrategyMoves: any(named: 'correctStrategyMoves'),
    )).thenAnswer((_) async => {});

    when(() => mockAudioService.playCardDeal()).thenAnswer((_) async => {});
    when(() => mockAudioService.playCardShuffle()).thenAnswer((_) async => {});
    when(() => mockAudioService.playBet()).thenAnswer((_) async => {});
    when(() => mockAudioService.playWin()).thenAnswer((_) async => {});
    when(() => mockAudioService.playLose()).thenAnswer((_) async => {});
    when(() => mockAudioService.playBust()).thenAnswer((_) async => {});

    blackjackBloc = BlackjackBloc(
      statsRepository: mockStatsRepository,
      audioService: mockAudioService,
    );
  });

  tearDown(() {
    blackjackBloc.close();
  });

  test('initial state is correct', () {
    expect(blackjackBloc.state, BlackjackState.initial());
  });

  blocTest<BlackjackBloc, BlackjackState>(
    'emits updated stats when LoadStats is added',
    build: () => blackjackBloc,
    act: (bloc) => bloc.add(LoadStats()),
    expect: () => [
      isA<BlackjackState>().having((s) => s.isLoading, 'isLoading', true),
      isA<BlackjackState>().having((s) => s.balance, 'balance', 1000).having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<BlackjackBloc, BlackjackState>(
    'emits betting status when StartGame is added',
    build: () => blackjackBloc,
    act: (bloc) => bloc.add(const StartGame(decksCount: 6)),
    expect: () => [
      isA<BlackjackState>()
        .having((s) => s.status, 'status', GameStatus.betting)
        .having((s) => s.decksCount, 'decksCount', 6),
    ],
  );

  blocTest<BlackjackBloc, BlackjackState>(
    'updates balance when PlaceBet is added',
    build: () => blackjackBloc,
    seed: () => BlackjackState.initial().copyWith(balance: 1000, status: GameStatus.betting),
    act: (bloc) => bloc.add(const PlaceBet(100)),
    expect: () => [
      isA<BlackjackState>()
        .having((s) => s.currentHandBet, 'currentHandBet', 100)
        .having((s) => s.balance, 'balance', 900),
    ],
    verify: (_) {
      verify(() => mockAudioService.playBet()).called(1);
    },
  );

  blocTest<BlackjackBloc, BlackjackState>(
    'deals cards and updates state when DealCards is added',
    build: () => blackjackBloc,
    seed: () => BlackjackState.initial().copyWith(
      balance: 900,
      handBets: [100],
      status: GameStatus.betting,
      shoe: List.generate(52, (index) => CardEntity(suit: Suit.hearts, rank: Rank.values[index % 13])),
    ),
    act: (bloc) => bloc.add(DealCards()),
    expect: () => [
      isA<BlackjackState>()
        .having((s) => s.currentPlayerHand.cards.length, 'player cards', 2)
        .having((s) => s.dealerHand.cards.length, 'dealer cards', 2)
        .having((s) => s.status, 'status', GameStatus.playing),
    ],
    verify: (_) {
      verify(() => mockAudioService.playCardShuffle()).called(1);
    },
  );

  blocTest<BlackjackBloc, BlackjackState>(
    'handles splitting a pair of 8s',
    build: () => blackjackBloc,
    seed: () => BlackjackState.initial().copyWith(
      balance: 800,
      handBets: [100],
      status: GameStatus.playing,
      playerHands: [
        HandEntity(cards: [
          CardEntity(suit: Suit.hearts, rank: Rank.eight),
          CardEntity(suit: Suit.diamonds, rank: Rank.eight),
        ]),
      ],
      dealerHand: HandEntity(cards: [CardEntity(suit: Suit.spades, rank: Rank.ten)]),
      shoe: [
        CardEntity(suit: Suit.clubs, rank: Rank.five), // card for first hand
        CardEntity(suit: Suit.hearts, rank: Rank.ten), // card for second hand
      ],
    ),
    act: (bloc) => bloc.add(SplitEvent()),
    expect: () => [
      // First state change: split occurs
      isA<BlackjackState>()
        .having((s) => s.playerHands.length, 'hands count', 2)
        .having((s) => s.balance, 'balance', 700),
      // Second state change: _onHit called for first hand
      isA<BlackjackState>()
        .having((s) => s.playerHands[0].cards.length, 'first hand cards', 2)
        .having((s) => s.activeHandIndex, 'active index', 0),
    ],
  );
}
