import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/stats_repository.dart';

class FirestoreStatsRepository implements StatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreStatsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<void> saveStats({
    required int balance,
    required int totalGames,
    required int totalMoves,
    required int correctStrategyMoves,
  }) async {
    if (_uid == null) return;

    await _firestore.collection('users').doc(_uid).set({
      'balance': balance,
      'totalGames': totalGames,
      'totalMoves': totalMoves,
      'correctStrategyMoves': correctStrategyMoves,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>> loadStats() async {
    try {
      if (_uid == null) {
        // Try to sign in anonymously if not signed in
        await _auth.signInAnonymously();
      }

      if (_uid == null) return {};

      final doc = await _firestore.collection('users').doc(_uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      // Return empty stats on error to allow app to function
      return {};
    }
    return {};
  }
}
