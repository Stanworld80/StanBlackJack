import 'package:equatable/equatable.dart';

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  two, three, four, five, six, seven, eight, nine, ten,
  jack, queen, king, ace
}

class CardEntity extends Equatable {
  final Suit suit;
  final Rank rank;
  final bool isFaceUp;

  const CardEntity({
    required this.suit,
    required this.rank,
    this.isFaceUp = true,
  });

  int get value {
    switch (rank) {
      case Rank.two: return 2;
      case Rank.three: return 3;
      case Rank.four: return 4;
      case Rank.five: return 5;
      case Rank.six: return 6;
      case Rank.seven: return 7;
      case Rank.eight: return 8;
      case Rank.nine: return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king: return 10;
      case Rank.ace: return 11; // Default to 11, handled in Hand logic
    }
  }

  String get rankAbbreviation {
    switch (rank) {
      case Rank.two: return '2';
      case Rank.three: return '3';
      case Rank.four: return '4';
      case Rank.five: return '5';
      case Rank.six: return '6';
      case Rank.seven: return '7';
      case Rank.eight: return '8';
      case Rank.nine: return '9';
      case Rank.ten: return '10';
      case Rank.jack: return 'J';
      case Rank.queen: return 'Q';
      case Rank.king: return 'K';
      case Rank.ace: return 'A';
    }
  }

  @override
  List<Object?> get props => [suit, rank, isFaceUp];

  CardEntity copyWith({bool? isFaceUp}) {
    return CardEntity(
      suit: suit,
      rank: rank,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }
}
