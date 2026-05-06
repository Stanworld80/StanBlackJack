import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

class BlackjackCardWidget extends StatelessWidget {
  final CardEntity card;

  const BlackjackCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: card.isFaceUp ? 0 : pi),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double angle, child) {
        // We want to flip horizontally
        final isBack = angle > pi / 2;
        
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack 
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi),
                child: _buildCardBack(),
              )
            : _buildCardFront(),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 75,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(2, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Top-left rank
          Positioned(
            top: 4,
            left: 4,
            child: Column(
              children: [
                Text(
                  card.rankAbbreviation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getSuitColor(card.suit),
                    height: 1,
                  ),
                ),
                Text(
                  _getSuitChar(card.suit),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSuitColor(card.suit),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          // Center suit
          Center(
            child: Text(
              _getSuitChar(card.suit),
              style: TextStyle(
                fontSize: 40,
                color: _getSuitColor(card.suit),
              ),
            ),
          ),
          // Bottom-right rank (rotated)
          Positioned(
            bottom: 4,
            right: 4,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                children: [
                  Text(
                    card.rankAbbreviation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getSuitColor(card.suit),
                      height: 1,
                    ),
                  ),
                  Text(
                    _getSuitChar(card.suit),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getSuitColor(card.suit),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 75,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(2, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Icon(Icons.casino, color: Colors.white24, size: 30),
          ),
        ),
      ),
    );
  }

  Color _getSuitColor(Suit suit) {
    switch (suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return const Color(0xFFC62828); // Deep red
      case Suit.clubs:
      case Suit.spades:
        return const Color(0xFF212121); // Almost black
    }
  }

  String _getSuitChar(Suit suit) {
    switch (suit) {
      case Suit.hearts: return '♥';
      case Suit.diamonds: return '♦';
      case Suit.clubs: return '♣';
      case Suit.spades: return '♠';
    }
  }
}
