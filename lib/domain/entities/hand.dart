import 'package:equatable/equatable.dart';
import 'card.dart';

class HandEntity extends Equatable {
  final List<CardEntity> cards;
  final bool isStood;

  const HandEntity({
    required this.cards,
    this.isStood = false,
  });

  int get value {
    int total = 0;
    int aceCount = 0;

    for (var card in cards) {
      if (card.rank == Rank.ace) {
        aceCount++;
      }
      total += card.value;
    }

    while (total > 21 && aceCount > 0) {
      total -= 10;
      aceCount--;
    }

    return total;
  }

  bool get isBusted => value > 21;
  bool get isBlackjack => cards.length == 2 && value == 21 && !isStood; // Only naturally 21 is BJ
  bool get isSoft => cards.any((c) => c.rank == Rank.ace) && (value - 10) <= 11;

  HandEntity copyWith({
    List<CardEntity>? cards,
    bool? isStood,
  }) {
    return HandEntity(
      cards: cards ?? this.cards,
      isStood: isStood ?? this.isStood,
    );
  }

  @override
  List<Object?> get props => [cards, isStood];
}
