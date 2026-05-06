import 'dart:ui';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/game_bloc.dart';
import '../blocs/game_event.dart';
import '../blocs/game_state.dart';
import '../widgets/blackjack_card.dart';
import '../widgets/payout_animation.dart';
import '../widgets/strategy_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/audio_service.dart';
import '../../data/repositories/firestore_stats_repository.dart';
import '../../domain/repositories/stats_repository.dart';

class GamePage extends StatefulWidget {
  final StatsRepository? statsRepository;
  const GamePage({super.key, this.statsRepository});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final AudioService _audioService = AudioService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _audioService,
      child: BlocProvider(
        create: (context) => BlackjackBloc(
          statsRepository: widget.statsRepository ?? FirestoreStatsRepository(),
          audioService: _audioService,
        )..add(LoadStats())..add(const StartGame()),
        child: const GameView(),
      ),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BlackjackBloc, BlackjackState>(
        listener: (context, state) {
          if (state.isInsuranceOffered) {
            _showInsuranceDialog(context);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          return Stack(
            children: [
              // Background Table
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.tableGradient,
                ),
              ),

              // Table Markings
              const Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.1,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('BLACKJACK PAYS 3 TO 2', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('DEALER MUST STAND ON 17 AND MUST DRAW TO 16', style: TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(height: 20),
                          Text('INSURANCE PAYS 2 TO 1', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: ClipRect(
                  child: Column(
                    children: [
                      // Top Bar (Decks Selection)
                      _buildTopBar(context, state),
      
                      // Dealer Area
                      Expanded(
                        flex: 3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _buildDealerArea(state),
                        ),
                      ),
      
                      // Center Message & Advice
                      _buildMessageArea(state),
      
                      // Player Area
                      Expanded(
                        flex: 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _buildPlayerArea(state),
                        ),
                      ),
      
                      // Stats Bar
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: _buildStatsBar(state),
                        ),
                      ),
      
                      // Control Panel
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: _buildControlPanel(context, state),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Payout Animation
              if (state.status == GameStatus.gameOver && state.lastPayout > 0)
                IgnorePointer(
                  child: PayoutAnimation(
                    visible: true,
                    amount: state.lastPayout,
                    onComplete: () {},
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, BlackjackState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: Colors.white24, size: 16),
              const SizedBox(width: 4),
              Text('${state.decksCount} JEUX', style: const TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
          if (state.status == GameStatus.betting)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white54),
              onPressed: () => _showDeckSelection(context),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.gold),
            onPressed: () => _showStrategyGuide(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerArea(BlackjackState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('DEALER', style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12)),
        const SizedBox(height: 20),
        Wrap(
          spacing: -40, // Overlapping cards
          children: state.dealerHand.cards.map((c) => BlackjackCardWidget(card: c)).toList(),
        ),
        if (state.status == GameStatus.dealerTurn || state.status == GameStatus.gameOver)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${state.dealerHand.value}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageArea(BlackjackState state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey('${state.status}_${state.message}_${state.sideBetResult}'),
        children: [
          Text(
            state.message.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          if (state.sideBetResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                state.sideBetResult.toUpperCase(),
                style: TextStyle(
                  color: state.sideBetResult.contains('GAGNÉ') ? AppColors.gold : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          if (state.strategyAdvice.isNotEmpty && state.status == GameStatus.playing)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.gold.withValues(alpha: 0.3), Colors.transparent]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                'CONSEIL: ${state.strategyAdvice.toUpperCase()}',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea(BlackjackState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.playerHands.length, (index) {
              final hand = state.playerHands[index];
              final isActive = index == state.activeHandIndex && state.status == GameStatus.playing;
              
              return _ActiveHandDecorator(
                isActive: isActive,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                    border: isActive ? Border.all(color: AppColors.gold, width: 3) : Border.all(color: Colors.transparent, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: _FloatingArrow(),
                        )
                      else
                        const SizedBox(height: 36),
                      Wrap(
                        spacing: -40,
                        children: hand.cards.map((c) => BlackjackCardWidget(card: c)).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.gold : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isActive ? [
                            const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ] : null,
                        ),
                        child: Text(
                          '${hand.value}',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.handBets[index]} Ͼ',
                        style: TextStyle(
                          color: isActive ? AppColors.gold : Colors.white54,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(BlackjackState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black38,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SOLDE', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('${state.balance} Ͼ', style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          if (state.totalGames > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PRÉCISION STRATÉGIE', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('${((state.correctStrategyMoves / (state.totalMoves == 0 ? 1 : state.totalMoves)) * 100).toStringAsFixed(1)}%', 
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('MISE ACTUELLE', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('${state.handBets.reduce((a, b) => a + b) + state.sideBet213} Ͼ', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, BlackjackState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.black54,
      ),
      child: _buildControls(context, state),
    );
  }

  Widget _buildControls(BuildContext context, BlackjackState state) {
    if (state.status == GameStatus.betting) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildChip(context, 10, AppColors.chipRed, key: const Key('chip_10')),
            const SizedBox(width: 12),
            _buildChip(context, 50, AppColors.chipBlue, key: const Key('chip_50')),
            const SizedBox(width: 12),
            _buildChip(context, 100, AppColors.chipBlack, key: const Key('chip_100')),
            const SizedBox(width: 12),
            _buildChip(context, 10, Colors.purple, isSide: true, key: const Key('chip_side')),
            const SizedBox(width: 24),
            _buildActionButton(
              key: const Key('btn_deal'),
              label: 'DISTRIBUER',
              onPressed: state.handBets[0] > 0 ? () => context.read<BlackjackBloc>().add(DealCards()) : null,
              color: AppColors.gold,
              textColor: Colors.black,
            ),
          ],
        ),
      );
    }

    if (state.status == GameStatus.playing) {
      final canSplit = state.currentPlayerHand.cards.length == 2 && 
                      state.currentPlayerHand.cards[0].rank == state.currentPlayerHand.cards[1].rank &&
                      state.balance >= state.currentHandBet;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              key: const Key('btn_hit'),
              label: 'HIT',
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<BlackjackBloc>().add(HitEvent());
              },
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              key: const Key('btn_stand'),
              label: 'STAND',
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<BlackjackBloc>().add(StandEvent());
              },
              color: Colors.red.shade700,
            ),
            if (state.currentPlayerHand.cards.length == 2 && state.balance >= state.currentHandBet) ...[
              const SizedBox(width: 12),
              _buildActionButton(
                key: const Key('btn_double'),
                label: 'DOUBLE',
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  context.read<BlackjackBloc>().add(DoubleDownEvent());
                },
                color: Colors.orange.shade800,
              ),
            ],
            if (canSplit) ...[
              const SizedBox(width: 12),
              _buildActionButton(
                key: const Key('btn_split'),
                label: 'SÉPARER',
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  context.read<BlackjackBloc>().add(SplitEvent());
                },
                color: Colors.purple.shade700,
              ),
            ],
            if (state.canSurrender) ...[
              const SizedBox(width: 12),
              _buildActionButton(
                key: const Key('btn_surrender'),
                label: 'ABANDONNER',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<BlackjackBloc>().add(SurrenderEvent());
                },
                color: Colors.orange.shade900,
              ),
            ],
          ],
        ),
      );
    }

    if (state.status == GameStatus.gameOver) {
      return _buildActionButton(
        key: const Key('btn_new_game'),
        label: 'NOUVELLE MAIN',
        onPressed: () {
          HapticFeedback.vibrate();
          context.read<BlackjackBloc>().add(ResetGame());
        },
        color: AppColors.gold,
        textColor: Colors.black,
        isFullWidth: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChip(BuildContext context, int amount, Color color, {bool isSide = false, Key? key}) {
    return _AnimatedChip(
      key: key,
      amount: amount,
      color: color,
      isSide: isSide,
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<BlackjackBloc>().add(isSide ? PlaceSideBet213(amount) : PlaceBet(amount));
      },
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color, Color textColor = Colors.white, bool isFullWidth = false, Key? key}) {
    final btn = ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        disabledBackgroundColor: color.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );

    if (isFullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }

  void _showStrategyGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'STRATÉGIE DE BASE',
                  style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              const Expanded(child: StrategyChart()),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsuranceDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('ASSURANCE ?', style: TextStyle(color: AppColors.gold)),
          content: const Text('Le croupier a un As. Voulez-vous prendre une assurance pour la moitié de votre mise ?'),
          actions: [
            TextButton(
              onPressed: () {
                context.read<BlackjackBloc>().add(const InsuranceEvent(accepted: false));
                Navigator.pop(dialogContext);
              },
              child: const Text('NON', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<BlackjackBloc>().add(const InsuranceEvent(accepted: true));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('OUI (ASSURER)'),
            ),
          ],
        ),
      );
    });
  }

  void _showDeckSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('CONFIGURATION SABOT', style: TextStyle(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 4, 6, 8].map((n) => ListTile(
            title: Text('$n JEUX DE CARTES', style: const TextStyle(color: Colors.white)),
            onTap: () {
              context.read<BlackjackBloc>().add(StartGame(decksCount: n));
              Navigator.pop(dialogContext);
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _AnimatedChip extends StatefulWidget {
  final int amount;
  final Color color;
  final bool isSide;
  final VoidCallback onTap;

  const _AnimatedChip({
    super.key,
    required this.amount,
    required this.color,
    required this.onTap,
    this.isSide = false,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
                gradient: RadialGradient(
                  colors: [widget.color.withValues(alpha: 0.8), widget.color],
                  stops: const [0.7, 1.0],
                ),
              ),
              child: Center(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.amount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isSide ? '21+3' : 'JETON',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingArrow extends StatefulWidget {
  const _FloatingArrow();

  @override
  State<_FloatingArrow> createState() => _FloatingArrowState();
}

class _FloatingArrowState extends State<_FloatingArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (!StanBlackJackApp.disableAnimations) {
      _controller.repeat(reverse: true);
    }
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFFFD700), size: 32),
          ),
        );
      },
    );
  }
}

class _ActiveHandDecorator extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const _ActiveHandDecorator({required this.child, required this.isActive});

  @override
  State<_ActiveHandDecorator> createState() => _ActiveHandDecoratorState();
}

class _ActiveHandDecoratorState extends State<_ActiveHandDecorator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (widget.isActive && !StanBlackJackApp.disableAnimations) {
      _controller.repeat(reverse: true);
    }
    _glowAnimation = Tween<double>(begin: 5.0, end: 25.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_ActiveHandDecorator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && !StanBlackJackApp.disableAnimations) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.2),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
