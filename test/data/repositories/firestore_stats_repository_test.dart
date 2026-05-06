import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stan_blackjack/data/repositories/firestore_stats_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FirestoreStatsRepository repository;
  final mockUser = MockUser(uid: 'test_uid', email: 'test@example.com');

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    repository = FirestoreStatsRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('FirestoreStatsRepository', () {
    test('saveStats saves data to correct firestore path', () async {
      await repository.saveStats(
        balance: 1500,
        totalGames: 10,
        totalMoves: 50,
        correctStrategyMoves: 40,
      );

      final doc = await fakeFirestore.collection('users').doc('test_uid').get();
      
      expect(doc.exists, true);
      expect(doc.data()?['balance'], 1500);
      expect(doc.data()?['totalGames'], 10);
      expect(doc.data()?['totalMoves'], 50);
      expect(doc.data()?['correctStrategyMoves'], 40);
      expect(doc.data()?['updatedAt'], isNotNull);
    });

    test('loadStats returns data from firestore', () async {
      await fakeFirestore.collection('users').doc('test_uid').set({
        'balance': 2000,
        'totalGames': 5,
        'totalMoves': 20,
        'correctStrategyMoves': 18,
      });

      final stats = await repository.loadStats();

      expect(stats['balance'], 2000);
      expect(stats['totalGames'], 5);
      expect(stats['totalMoves'], 20);
      expect(stats['correctStrategyMoves'], 18);
    });

    test('loadStats signs in anonymously if not signed in', () async {
      final mockAuthLoggedOut = MockFirebaseAuth(signedIn: false);
      final repositoryLoggedOut = FirestoreStatsRepository(
        firestore: fakeFirestore,
        auth: mockAuthLoggedOut,
      );

      // Initially uid is null
      expect(mockAuthLoggedOut.currentUser, isNull);

      await repositoryLoggedOut.loadStats();

      // Should be signed in anonymously
      expect(mockAuthLoggedOut.currentUser, isNotNull);
      expect(mockAuthLoggedOut.currentUser!.isAnonymous, true);
    });
  });
}
