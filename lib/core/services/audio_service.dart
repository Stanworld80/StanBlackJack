import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCardDeal() async {
    await _playAsset('sounds/card_deal.mp3');
  }

  Future<void> playCardShuffle() async {
    await _playAsset('sounds/card_shuffle.mp3');
  }

  Future<void> playBet() async {
    await _playAsset('sounds/chip_bet.mp3');
  }

  Future<void> playWin() async {
    await _playAsset('sounds/win.mp3');
  }

  Future<void> playLose() async {
    await _playAsset('sounds/lose.mp3');
  }

  Future<void> playBust() async {
    await _playAsset('sounds/bust.mp3');
  }

  Future<void> _playAsset(String path) async {
    try {
      await _player.play(AssetSource(path));
    } catch (e) {
      // Ignore audio errors to prevent game crash
      debugPrint('Audio play error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
