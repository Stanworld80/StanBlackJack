import 'package:equatable/equatable.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/hand.dart';

enum GameStatus { betting, playing, dealerTurn, gameOver }

class BlackjackState extends Equatable {
  final GameStatus status;
  final List<HandEntity> playerHands;
  final HandEntity dealerHand;
  final List<CardEntity> shoe;
  final int decksCount;
  final int balance;
  final List<int> handBets;
  final int activeHandIndex;
  final int sideBet213;
  final String message;
  final String strategyAdvice;
  final String sideBetResult;
  final int totalGames;
  final int correctStrategyMoves;
  final int totalMoves;
  final bool isInsuranceOffered;
  final bool insuranceBet;
  final bool isLoading;
  final int lastPayout;

  const BlackjackState({
    required this.status,
    required this.playerHands,
    required this.dealerHand,
    required this.shoe,
    this.decksCount = 6,
    required this.balance,
    required this.handBets,
    this.activeHandIndex = 0,
    this.sideBet213 = 0,
    required this.message,
    required this.strategyAdvice,
    this.sideBetResult = '',
    this.totalGames = 0,
    this.correctStrategyMoves = 0,
    this.totalMoves = 0,
    this.isInsuranceOffered = false,
    this.insuranceBet = false,
    this.isLoading = false,
    this.lastPayout = 0,
  });

  HandEntity get currentPlayerHand => playerHands[activeHandIndex];
  int get currentHandBet => handBets[activeHandIndex];
  bool get canSurrender => 
      status == GameStatus.playing && 
      playerHands.length == 1 && 
      playerHands[0].cards.length == 2;

  factory BlackjackState.initial() {
    return const BlackjackState(
      status: GameStatus.betting,
      playerHands: [HandEntity(cards: [])],
      dealerHand: HandEntity(cards: []),
      shoe: [],
      balance: 1000,
      handBets: [0],
      activeHandIndex: 0,
      message: 'Place your bet!',
      strategyAdvice: '',
      lastPayout: 0,
    );
  }

  BlackjackState copyWith({
    GameStatus? status,
    List<HandEntity>? playerHands,
    HandEntity? dealerHand,
    List<CardEntity>? shoe,
    int? decksCount,
    int? balance,
    List<int>? handBets,
    int? activeHandIndex,
    int? sideBet213,
    String? message,
    String? strategyAdvice,
    String? sideBetResult,
    int? totalGames,
    int? correctStrategyMoves,
    int? totalMoves,
    bool? isInsuranceOffered,
    bool? insuranceBet,
    bool? isLoading,
    int? lastPayout,
  }) {
    return BlackjackState(
      status: status ?? this.status,
      playerHands: playerHands ?? this.playerHands,
      dealerHand: dealerHand ?? this.dealerHand,
      shoe: shoe ?? this.shoe,
      decksCount: decksCount ?? this.decksCount,
      balance: balance ?? this.balance,
      handBets: handBets ?? this.handBets,
      activeHandIndex: activeHandIndex ?? this.activeHandIndex,
      sideBet213: sideBet213 ?? this.sideBet213,
      message: message ?? this.message,
      strategyAdvice: strategyAdvice ?? this.strategyAdvice,
      sideBetResult: sideBetResult ?? this.sideBetResult,
      totalGames: totalGames ?? this.totalGames,
      correctStrategyMoves: correctStrategyMoves ?? this.correctStrategyMoves,
      totalMoves: totalMoves ?? this.totalMoves,
      isInsuranceOffered: isInsuranceOffered ?? this.isInsuranceOffered,
      insuranceBet: insuranceBet ?? this.insuranceBet,
      isLoading: isLoading ?? this.isLoading,
      lastPayout: lastPayout ?? this.lastPayout,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerHands,
        dealerHand,
        shoe,
        decksCount,
        balance,
        handBets,
        activeHandIndex,
        sideBet213,
        message,
        strategyAdvice,
        sideBetResult,
        totalGames,
        correctStrategyMoves,
        totalMoves,
        isInsuranceOffered,
        insuranceBet,
        isLoading,
        lastPayout,
      ];
}
