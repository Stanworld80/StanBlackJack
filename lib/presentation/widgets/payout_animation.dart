import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';

class PayoutAnimation extends StatelessWidget {
  final bool visible;
  final int amount;
  final VoidCallback onComplete;

  const PayoutAnimation({
    super.key,
    required this.visible,
    required this.amount,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || amount <= 0) return const SizedBox.shrink();

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_myejioos.json', // Confetti
            repeat: false,
            onLoaded: (composition) {
              Future.delayed(composition.duration, onComplete);
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YOU WIN!',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                      Text(
                        '+$amount Ͼ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 15)],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
