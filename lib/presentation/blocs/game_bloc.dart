import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/strategy_engine.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/hand.dart';
import '../../core/services/audio_service.dart';
import '../../domain/repositories/stats_repository.dart';
import 'game_event.dart';
import 'game_state.dart';

class BlackjackBloc extends Bloc<BlackjackEvent, BlackjackState> {
  final StatsRepository statsRepository;
  final AudioService audioService;

  BlackjackBloc({
    required this.statsRepository,
    required this.audioService,
  }) : super(BlackjackState.initial()) {
    on<LoadStats>(_onLoadStats);
    on<StartGame>(_onStartGame);
    on<PlaceBet>(_onPlaceBet);
    on<PlaceSideBet213>(_onPlaceSideBet);
    on<DealCards>(_onDealCards);
    on<HitEvent>(_onHit);
    on<StandEvent>(_onStand);
    on<DoubleDownEvent>(_onDoubleDown);
    on<InsuranceEvent>(_onInsurance);
    on<SplitEvent>(_onSplit);
    on<ResetGame>(_onResetGame);
    on<SurrenderEvent>(_onSurrender);
    on<SetShoeForTesting>((event, emit) {
      emit(state.copyWith(shoe: List<CardEntity>.from(event.cards as Iterable), status: GameStatus.betting));
    });
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<BlackjackState> emit) async {
    emit(state.copyWith(isLoading: true));
    final stats = await statsRepository.loadStats();
    emit(state.copyWith(
      balance: stats['balance'] ?? 1000,
      totalGames: stats['totalGames'] ?? 0,
      totalMoves: stats['totalMoves'] ?? 0,
      correctStrategyMoves: stats['correctStrategyMoves'] ?? 0,
      isLoading: false,
    ));
  }

  void _onStartGame(StartGame event, Emitter<BlackjackState> emit) {
    int decks = event.decksCount;
    List<CardEntity> newShoe = [];
    for (int i = 0; i < decks; i++) {
      for (var suit in Suit.values) {
        for (var rank in Rank.values) {
          newShoe.add(CardEntity(suit: suit, rank: rank));
        }
      }
    }
    newShoe.shuffle(Random());
    emit(state.copyWith(
      shoe: newShoe,
      status: GameStatus.betting,
      decksCount: decks,
      insuranceBet: false,
      isInsuranceOffered: false,
    ));
  }

  void _onPlaceBet(PlaceBet event, Emitter<BlackjackState> emit) {
    if (state.balance >= event.amount) {
      audioService.playBet();
      int currentBet = state.handBets.isNotEmpty ? state.handBets[0] : 0;
      emit(state.copyWith(
        handBets: [currentBet + event.amount],
        balance: state.balance - event.amount,
      ));
    }
  }

  void _onPlaceSideBet(PlaceSideBet213 event, Emitter<BlackjackState> emit) {
    if (state.balance >= event.amount) {
      audioService.playBet();
      emit(state.copyWith(
        sideBet213: event.amount,
        balance: state.balance - event.amount,
      ));
    }
  }

  void _onDealCards(DealCards event, Emitter<BlackjackState> emit) {
    if (state.handBets.isEmpty || state.handBets[0] == 0) {
      return;
    }

    List<CardEntity> shoe = List.from(state.shoe);
    if (shoe.length < 10) {
      add(StartGame(decksCount: state.decksCount));
      return;
    }

    CardEntity p1 = shoe.removeAt(0);
    CardEntity d1 = shoe.removeAt(0);
    CardEntity p2 = shoe.removeAt(0);
    CardEntity d2 = shoe.removeAt(0).copyWith(isFaceUp: false);

    audioService.playCardShuffle();

    HandEntity playerHand = HandEntity(cards: [p1, p2]);
    HandEntity dealerHand = HandEntity(cards: [d1, d2]);

    String sideBetMsg = '';
    int sideBetPayout = 0;
    if (state.sideBet213 > 0) {
      sideBetPayout = _calculate213Payout(p1, p2, d1);
      if (sideBetPayout > 0) {
        sideBetMsg = '21+3 GAGNÉ !';
      } else {
        sideBetMsg = '21+3 Perdu';
      }
    }

    String advice = StrategyEngine.getBestAction(playerHand, d1).name;
    // Offer insurance only if dealer has Ace AND player DOES NOT have blackjack.
    // If player has blackjack, we currently proceed to immediate resolution (Push or Win).
    bool insuranceOffered = d1.rank == Rank.ace && !playerHand.isBlackjack;

    emit(state.copyWith(
      playerHands: [playerHand],
      dealerHand: dealerHand,
      shoe: shoe,
      status: GameStatus.playing,
      activeHandIndex: 0,
      isInsuranceOffered: insuranceOffered,
      message: insuranceOffered ? 'Assurance ?' : 'Your turn',
      strategyAdvice: advice,
      sideBetResult: sideBetMsg,
      balance: state.balance + sideBetPayout,
    ));

    if (playerHand.isBlackjack) {
      _finishGame(emit);
    }
  }

  void _onInsurance(InsuranceEvent event, Emitter<BlackjackState> emit) {
    if (event.accepted) {
      int insuranceCost = state.handBets[0] ~/ 2;
      if (state.balance >= insuranceCost) {
        emit(state.copyWith(
          balance: state.balance - insuranceCost,
          insuranceBet: true,
          isInsuranceOffered: false,
          message: 'Insurance placed.',
        ));
      }
    } else {
      emit(state.copyWith(
        isInsuranceOffered: false,
      ));
    }

    // After insurance decision, check if dealer has blackjack
    if (state.dealerHand.isBlackjack) {
      _dealerTurn(emit);
    } else {
      emit(state.copyWith(message: 'Your turn'));
    }
  }

  void _onHit(HitEvent event, Emitter<BlackjackState> emit) {
    List<CardEntity> shoe = List.from(state.shoe);
    CardEntity newCard = shoe.removeAt(0);
    audioService.playCardDeal();
    
    List<HandEntity> newHands = List.from(state.playerHands);
    HandEntity currentHand = newHands[state.activeHandIndex];
    newHands[state.activeHandIndex] = currentHand.copyWith(cards: [...currentHand.cards, newCard]);
    
    bool isCorrect = _checkStrategy(BlackjackAction.hit);
    
    String advice = '';
    if (!newHands[state.activeHandIndex].isBusted) {
      advice = StrategyEngine.getBestAction(newHands[state.activeHandIndex], state.dealerHand.cards[0]).name;
    }

    emit(state.copyWith(
      playerHands: newHands,
      shoe: shoe,
      strategyAdvice: advice,
      totalMoves: state.totalMoves + 1,
      correctStrategyMoves: isCorrect ? state.correctStrategyMoves + 1 : state.correctStrategyMoves,
    ));

    if (newHands[state.activeHandIndex].isBusted) {
      _moveToNextHand(emit);
    }
  }

  void _moveToNextHand(Emitter<BlackjackState> emit) {
    if (state.activeHandIndex < state.playerHands.length - 1) {
      emit(state.copyWith(
        activeHandIndex: state.activeHandIndex + 1,
        message: 'Playing next hand...',
      ));
      // Deal second card if it was a split hand with only one card
      if (state.currentPlayerHand.cards.length == 1) {
        bool isAcesSplit = state.playerHands[0].cards[0].rank == Rank.ace && 
                         state.playerHands.length > 1 && 
                         state.playerHands[1].cards.length == 1;
        
        _onHit(HitEvent(), emit);

        if (isAcesSplit) {
          List<HandEntity> hands = List.from(state.playerHands);
          hands[state.activeHandIndex] = hands[state.activeHandIndex].copyWith(isStood: true);
          emit(state.copyWith(playerHands: hands));
          _moveToNextHand(emit); // This will then trigger dealer turn
          return;
        }
      }
    } else {
      // Check if all hands are busted
      bool allBusted = state.playerHands.every((h) => h.isBusted);
      if (allBusted) {
        _finishGame(emit);
      } else {
        _dealerTurn(emit);
      }
    }
  }

  void _onStand(StandEvent event, Emitter<BlackjackState> emit) {
    bool isCorrect = _checkStrategy(BlackjackAction.stand);
    
    List<HandEntity> newHands = List.from(state.playerHands);
    newHands[state.activeHandIndex] = newHands[state.activeHandIndex].copyWith(isStood: true);

    emit(state.copyWith(
      playerHands: newHands,
      totalMoves: state.totalMoves + 1,
      correctStrategyMoves: isCorrect ? state.correctStrategyMoves + 1 : state.correctStrategyMoves,
    ));
    
    _moveToNextHand(emit);
  }

  void _onDoubleDown(DoubleDownEvent event, Emitter<BlackjackState> emit) {
    if (state.balance < state.currentHandBet) return;

    bool isCorrect = _checkStrategy(BlackjackAction.doubleDown);
    int betAmount = state.currentHandBet;
    
    List<int> newBets = List.from(state.handBets);
    newBets[state.activeHandIndex] *= 2;

    List<CardEntity> shoe = List.from(state.shoe);
    CardEntity newCard = shoe.removeAt(0);
    audioService.playCardDeal();
    
    List<HandEntity> newHands = List.from(state.playerHands);
    newHands[state.activeHandIndex] = newHands[state.activeHandIndex].copyWith(
      cards: [...newHands[state.activeHandIndex].cards, newCard],
      isStood: true,
    );

    emit(state.copyWith(
      handBets: newBets,
      balance: state.balance - betAmount,
      playerHands: newHands,
      shoe: shoe,
      totalMoves: state.totalMoves + 1,
      correctStrategyMoves: isCorrect ? state.correctStrategyMoves + 1 : state.correctStrategyMoves,
    ));

    _moveToNextHand(emit);
  }

  void _onSurrender(SurrenderEvent event, Emitter<BlackjackState> emit) {
    if (!state.canSurrender) return;

    int bet = state.handBets[0];
    int refund = bet ~/ 2;

    emit(state.copyWith(
      status: GameStatus.gameOver,
      balance: state.balance + refund,
      handBets: [0],
      message: 'Surrendered. Half bet returned.',
      lastPayout: refund,
    ));

    statsRepository.saveStats(
      balance: state.balance + refund,
      totalGames: state.totalGames + 1,
      totalMoves: state.totalMoves + 1,
      correctStrategyMoves: state.correctStrategyMoves + (_checkStrategy(BlackjackAction.surrender) ? 1 : 0),
    );
  }

  void _onSplit(SplitEvent event, Emitter<BlackjackState> emit) {
    HandEntity currentHand = state.currentPlayerHand;
    if (currentHand.cards.length != 2 || 
        currentHand.cards[0].rank != currentHand.cards[1].rank ||
        state.balance < state.currentHandBet ||
        state.playerHands.length >= 4) {
      return;
    }

    bool isCorrect = _checkStrategy(BlackjackAction.split);
    int betAmount = state.currentHandBet;

    List<HandEntity> newHands = List.from(state.playerHands);
    List<int> newBets = List.from(state.handBets);

    HandEntity h1 = HandEntity(cards: [currentHand.cards[0]]);
    HandEntity h2 = HandEntity(cards: [currentHand.cards[1]]);

    newHands[state.activeHandIndex] = h1;
    newHands.insert(state.activeHandIndex + 1, h2);
    newBets.insert(state.activeHandIndex + 1, betAmount);

    audioService.playBet();

    bool isAces = currentHand.cards[0].rank == Rank.ace;

    emit(state.copyWith(
      playerHands: newHands,
      handBets: newBets,
      balance: state.balance - betAmount,
      totalMoves: state.totalMoves + 1,
      correctStrategyMoves: isCorrect ? state.correctStrategyMoves + 1 : state.correctStrategyMoves,
      message: isAces ? 'Aces split! One card each.' : 'Hands split!',
    ));

    // Deal second card to first hand
    _onHit(HitEvent(), emit);

    if (isAces) {
      // Stand on the first hand and move to next
      List<HandEntity> hands = List.from(state.playerHands);
      hands[state.activeHandIndex] = hands[state.activeHandIndex].copyWith(isStood: true);
      emit(state.copyWith(playerHands: hands));
      _moveToNextHand(emit);
    }
  }

  void _dealerTurn(Emitter<BlackjackState> emit) {
    List<CardEntity> shoe = List.from(state.shoe);
    List<CardEntity> dealerCards = List.from(state.dealerHand.cards);
    
    dealerCards[1] = dealerCards[1].copyWith(isFaceUp: true);
    HandEntity dealerHand = HandEntity(cards: dealerCards);

    while (dealerHand.value < 17) {
      if (shoe.isEmpty) break;
      dealerHand = HandEntity(cards: [...dealerHand.cards, shoe.removeAt(0)]);
    }

    emit(state.copyWith(
      dealerHand: dealerHand,
      shoe: shoe,
      status: GameStatus.dealerTurn,
    ));

    _finishGame(emit);
  }

  void _finishGame(Emitter<BlackjackState> emit) {
    int totalPayout = 0;
    List<String> messages = [];
    int dealerVal = state.dealerHand.value;

    // Handle insurance payout
    if (state.insuranceBet && state.dealerHand.isBlackjack) {
      totalPayout += (state.handBets[0] ~/ 2) * 3;
    }

    for (int i = 0; i < state.playerHands.length; i++) {
      HandEntity hand = state.playerHands[i];
      int bet = state.handBets[i];
      int handPayout = 0;
      String handMsg = '';

      if (hand.isBusted) {
        handMsg = 'Busted';
        audioService.playBust();
      } else if (state.dealerHand.isBusted) {
        handMsg = 'Win!';
        handPayout = bet * 2;
        audioService.playWin();
      } else if (hand.isBlackjack && !state.dealerHand.isBlackjack) {
        handMsg = 'Blackjack!';
        handPayout = (bet * 2.5).toInt();
        audioService.playWin();
      } else if (hand.value > dealerVal) {
        handMsg = 'Win!';
        handPayout = bet * 2;
        audioService.playWin();
      } else if (hand.value < dealerVal) {
        handMsg = 'Lose';
        audioService.playLose();
      } else {
        handMsg = 'Push';
        handPayout = bet;
      }
      
      totalPayout += handPayout;
      messages.add(state.playerHands.length > 1 ? 'Hand ${i+1}: $handMsg' : handMsg);
    }

    // Reveal dealer cards
    final revealedDealerHand = state.dealerHand.copyWith(
      cards: state.dealerHand.cards.map((c) => c.copyWith(isFaceUp: true)).toList(),
    );

    final newState = state.copyWith(
      status: GameStatus.gameOver,
      message: messages.join(' | '),
      balance: state.balance + totalPayout,
      handBets: state.handBets.map((_) => 0).toList(),
      activeHandIndex: 0,
      sideBet213: 0,
      insuranceBet: false,
      isInsuranceOffered: false,
      dealerHand: revealedDealerHand,
      totalGames: state.totalGames + 1,
      lastPayout: totalPayout,
    );
    
    emit(newState);
    
    statsRepository.saveStats(
      balance: newState.balance,
      totalGames: newState.totalGames,
      totalMoves: newState.totalMoves,
      correctStrategyMoves: newState.correctStrategyMoves,
    );
  }

  void _onResetGame(ResetGame event, Emitter<BlackjackState> emit) {
    emit(BlackjackState.initial().copyWith(
      balance: state.balance,
      totalGames: state.totalGames,
      totalMoves: state.totalMoves,
      correctStrategyMoves: state.correctStrategyMoves,
      shoe: state.shoe,
      decksCount: state.decksCount,
    ));
  }

  int _calculate213Payout(CardEntity p1, CardEntity p2, CardEntity d1) {
    List<CardEntity> cards = [p1, p2, d1];
    bool isSuited = cards.every((c) => c.suit == p1.suit);
    List<int> ranks = cards.map((c) => c.rank.index).toList()..sort();
    bool isStraight = (ranks[1] == ranks[0] + 1 && ranks[2] == ranks[1] + 1) ||
        (ranks[0] == 0 && ranks[1] == 1 && ranks[2] == 12); // A-2-3 (0, 1, 12)
    bool isThreeOfAKind = p1.rank == p2.rank && p2.rank == d1.rank;

    if (isSuited && isThreeOfAKind) return state.sideBet213 * 101; 
    if (isSuited && isStraight) return state.sideBet213 * 41; 
    if (isThreeOfAKind) return state.sideBet213 * 31; 
    if (isStraight) return state.sideBet213 * 11; 
    if (isSuited) return state.sideBet213 * 6; 

    return 0;
  }

  bool _checkStrategy(BlackjackAction action) {
    BlackjackAction best = StrategyEngine.getBestAction(state.currentPlayerHand, state.dealerHand.cards[0]);
    return action == best;
  }
}
