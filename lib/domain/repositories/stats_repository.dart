abstract class StatsRepository {
  Future<void> saveStats({
    required int balance,
    required int totalGames,
    required int totalMoves,
    required int correctStrategyMoves,
  });

  Future<Map<String, dynamic>> loadStats();
}
