import '../../domain/entities/card.dart';
import '../../domain/entities/hand.dart';

enum BlackjackAction { hit, stand, doubleDown, split, insurance, surrender }

class StrategyEngine {
  static BlackjackAction getBestAction(HandEntity playerHand, CardEntity dealerUpCard) {
    int playerValue = playerHand.value;
    int dealerValue = dealerUpCard.value;
    bool isSoft = playerHand.cards.any((c) => c.rank == Rank.ace) && playerHand.cards.length == 2;
    // Recalculate isSoft for multi-card hands if value is low enough
    if (playerHand.cards.any((c) => c.rank == Rank.ace)) {
       // A hand is soft if an Ace can be counted as 11 without busting
       int sumWithoutOneAce = 0;
       bool foundAce = false;
       for (var c in playerHand.cards) {
         if (!foundAce && c.rank == Rank.ace) {
           foundAce = true;
         } else {
           sumWithoutOneAce += c.value;
         }
       }
       isSoft = foundAce && (sumWithoutOneAce + 11 <= 21);
    }

    // 1. Surrender (Late Surrender rules)
    if (playerHand.cards.length == 2) {
      if (playerValue == 16 && (dealerValue >= 9 && dealerValue <= 11)) return BlackjackAction.surrender;
      if (playerValue == 15 && dealerValue == 10) return BlackjackAction.surrender;
    }

    // 2. Split logic
    if (playerHand.cards.length == 2 && playerHand.cards[0].rank == playerHand.cards[1].rank) {
      Rank rank = playerHand.cards[0].rank;
      if (rank == Rank.ace || rank == Rank.eight) return BlackjackAction.split;
      if (rank == Rank.two || rank == Rank.three || rank == Rank.seven) {
        if (dealerValue <= 7) return BlackjackAction.split;
      }
      if (rank == Rank.six && dealerValue <= 6) return BlackjackAction.split;
      if (rank == Rank.four && (dealerValue == 5 || dealerValue == 6)) return BlackjackAction.split;
      if (rank == Rank.nine && (dealerValue <= 9 && dealerValue != 7)) return BlackjackAction.split;
    }

    // 3. Soft Totals
    if (isSoft) {
      if (playerValue >= 19) return BlackjackAction.stand;
      if (playerValue == 18) {
        if (dealerValue <= 8) return BlackjackAction.stand;
        if (dealerValue >= 9) return BlackjackAction.hit;
      }
      if (playerValue == 17 && (dealerValue >= 3 && dealerValue <= 6)) return BlackjackAction.doubleDown;
      if (playerValue == 16 && (dealerValue >= 4 && dealerValue <= 6)) return BlackjackAction.doubleDown;
      if (playerValue == 15 && (dealerValue >= 4 && dealerValue <= 6)) return BlackjackAction.doubleDown;
      if (playerValue == 14 && (dealerValue >= 5 && dealerValue <= 6)) return BlackjackAction.doubleDown;
      if (playerValue == 13 && (dealerValue >= 5 && dealerValue <= 6)) return BlackjackAction.doubleDown;
      
      return BlackjackAction.hit;
    }

    // 4. Hard Totals
    if (playerValue >= 17) return BlackjackAction.stand;
    if (playerValue >= 13 && playerValue <= 16) {
      if (dealerValue <= 6) return BlackjackAction.stand;
      return BlackjackAction.hit;
    }
    if (playerValue == 12) {
      if (dealerValue >= 4 && dealerValue <= 6) return BlackjackAction.stand;
      return BlackjackAction.hit;
    }
    if (playerValue == 11) return BlackjackAction.doubleDown;
    if (playerValue == 10) {
      if (dealerValue <= 9) return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    if (playerValue == 9) {
      if (dealerValue >= 3 && dealerValue <= 6) return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }

    return BlackjackAction.hit;
  }
}
