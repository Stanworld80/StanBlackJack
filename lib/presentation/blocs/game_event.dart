import 'package:equatable/equatable.dart';

abstract class BlackjackEvent extends Equatable {
  const BlackjackEvent();

  @override
  List<Object?> get props => [];
}

class StartGame extends BlackjackEvent {
  final int decksCount;
  const StartGame({this.decksCount = 6});

  @override
  List<Object?> get props => [decksCount];
}

class PlaceBet extends BlackjackEvent {
  final int amount;
  const PlaceBet(this.amount);

  @override
  List<Object?> get props => [amount];
}

class PlaceSideBet213 extends BlackjackEvent {
  final int amount;
  const PlaceSideBet213(this.amount);

  @override
  List<Object?> get props => [amount];
}

class DealCards extends BlackjackEvent {}

class HitEvent extends BlackjackEvent {}

class StandEvent extends BlackjackEvent {}

class DoubleDownEvent extends BlackjackEvent {}

class SplitEvent extends BlackjackEvent {}

class ResetGame extends BlackjackEvent {}
class SurrenderEvent extends BlackjackEvent {}

class LoadStats extends BlackjackEvent {}

class InsuranceEvent extends BlackjackEvent {
  final bool accepted;
  const InsuranceEvent({required this.accepted});

  @override
  List<Object?> get props => [accepted];
}

class SetShoeForTesting extends BlackjackEvent {
  final List<dynamic> cards; // dynamic to avoid importing CardEntity if not needed, but better use it
  const SetShoeForTesting(this.cards);

  @override
  List<Object?> get props => [cards];
}
