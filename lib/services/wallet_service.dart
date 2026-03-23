import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  WalletService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  CollectionReference<Map<String, dynamic>> _historyRef(String userId) {
    return _userRef(userId).collection('wallet_history');
  }

  CollectionReference<Map<String, dynamic>> _cardsRef(String userId) {
    return _userRef(userId).collection('wallet_cards');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> walletStream(String userId) {
    return _userRef(userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> historyStream(String userId) {
    return _historyRef(userId).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> cardsStream(String userId) {
    return _cardsRef(userId).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> ensureWallet(String userId) async {
    final userDoc = _userRef(userId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userDoc);
      final data = snap.data() ?? <String, dynamic>{};
      final wallet = (data['wallet'] as Map<String, dynamic>?);
      final hasBalance = wallet != null && wallet['balance'] != null;

      if (hasBalance) {
        return;
      }

      tx.set(
        userDoc,
        {
          'wallet': {
            'balance': 0.0,
            'currency': 'LKR',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> addCard({
    required String userId,
    required String cardNumber,
    required String holderName,
    required String expiry,
  }) async {
    final cleaned = cardNumber.trim();
    final last4 = cleaned.length >= 4
        ? cleaned.substring(cleaned.length - 4)
        : cleaned;

    final cardDoc = _cardsRef(userId).doc();

    await cardDoc.set({
      'number': cleaned,
      'last4': last4,
      'holderName': holderName.trim(),
      'expiry': expiry.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _userRef(userId).set({
      'wallet': {
        'card': {
          'cardId': cardDoc.id,
          'number': cleaned,
          'last4': last4,
          'holderName': holderName.trim(),
          'expiry': expiry.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    await _historyRef(userId).add({
      'type': 'card_add',
      'amount': 0,
      'note': 'Card ****$last4 added',
      'cardId': cardDoc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    final userDoc = _userRef(userId);
    final cardDoc = _cardsRef(userId).doc(cardId);

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userDoc);
      final cardSnap = await tx.get(cardDoc);

      if (!cardSnap.exists) {
        return;
      }

      final cardData = cardSnap.data() ?? <String, dynamic>{};
      final deletedLast4 = (cardData['last4'] as String?) ?? '----';

      final userData = userSnap.data() ?? <String, dynamic>{};
      final wallet =
          (userData['wallet'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final selectedCard =
          (wallet['card'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final selectedCardId = selectedCard['cardId'] as String?;

      tx.delete(cardDoc);

      if (selectedCardId == cardId) {
        tx.set(
          userDoc,
          {
            'wallet': {
              'card': null,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );
      }

      tx.set(
        _historyRef(userId).doc(),
        {
          'type': 'card_delete',
          'amount': 0,
          'note': 'Card ****$deletedLast4 deleted',
          'cardId': cardId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<void> topUp({
    required String userId,
    required double amount,
    String source = 'card',
    String note = 'Wallet top-up',
  }) async {
    final userDoc = _userRef(userId);
    final historyDoc = _historyRef(userId).doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userDoc);
      final data = snap.data() ?? <String, dynamic>{};
      final wallet = (data['wallet'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final current = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
      final next = current + amount;

      tx.set(
        userDoc,
        {
          'wallet': {
            'balance': next,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      tx.set(historyDoc, {
        'type': 'topup',
        'amount': amount,
        'balanceAfter': next,
        'source': source,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> payWorker({
    required String userId,
    required String requestId,
    required String workerName,
    required double amount,
  }) async {
    final userDoc = _userRef(userId);
    final historyDoc = _historyRef(userId).doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userDoc);
      final data = snap.data() ?? <String, dynamic>{};
      final wallet = (data['wallet'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final current = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

      if (current < amount) {
        throw StateError('Insufficient wallet balance');
      }

      final next = current - amount;

      tx.set(
        userDoc,
        {
          'wallet': {
            'balance': next,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      tx.set(historyDoc, {
        'type': 'worker_pay',
        'amount': amount,
        'balanceAfter': next,
        'requestId': requestId,
        'workerName': workerName,
        'note': 'Payment to worker',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
