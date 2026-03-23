import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../services/wallet_service.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final WalletService _walletService = WalletService();

  final TextEditingController _topUpController = TextEditingController();

  bool _savingCard = false;
  bool _deletingCard = false;
  bool _addingMoney = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _topUpController.dispose();
    super.dispose();
  }

  double _parseAmount(String raw) {
    return double.tryParse(raw.trim()) ?? 0.0;
  }

  Future<void> _saveCardAndMaybeTopUp({
    required String cardNumber,
    required String holderName,
    required String expiry,
    required String topUpRaw,
  }) async {
    setState(() {
      _savingCard = true;
    });

    try {
      await _walletService.addCard(
        userId: _uid,
        cardNumber: cardNumber,
        holderName: holderName,
        expiry: expiry,
      );

      final amount = _parseAmount(topUpRaw);
      if (amount > 0) {
        await _walletService.topUp(
          userId: _uid,
          amount: amount,
          note: 'Top-up after adding card',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount > 0
                ? 'Card saved and wallet topped up.'
                : 'Card saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _savingCard = false;
        });
      }
    }
  }

  Future<void> _showAddCardDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddCardDialog(),
    );

    if (result == null) {
      return;
    }

    await _saveCardAndMaybeTopUp(
      cardNumber: result['cardNumber'] ?? '',
      holderName: result['holderName'] ?? '',
      expiry: result['expiry'] ?? '',
      topUpRaw: result['topUpRaw'] ?? '',
    );
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This card will be removed from your wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _deletingCard = true;
    });

    try {
      await _walletService.deleteCard(userId: _uid, cardId: cardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _deletingCard = false;
        });
      }
    }
  }

  Future<void> _topUpNow() async {
    final amount = _parseAmount(_topUpController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero.')),
      );
      return;
    }

    setState(() {
      _addingMoney = true;
    });

    try {
      await _walletService.topUp(userId: _uid, amount: amount);
      if (!mounted) return;
      _topUpController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Money added to wallet.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Top-up failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _addingMoney = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        centerTitle: true,
        title: const Text('My Wallet'),
      ),
      body: StreamBuilder(
        stream: _walletService.walletStream(_uid),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final wallet = (data['wallet'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
          final card = (wallet['card'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
          final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

          final last4 = (card['last4'] as String?) ?? '----';
          final holder = (card['holderName'] as String?) ?? 'No card added';
          final expiry = (card['expiry'] as String?) ?? '--/--';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5AA4F6), Color(0xFF3A6BE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LKR ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Card: **** **** **** $last4',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$holder  •  Expires $expiry',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Saved Cards',
                trailing: IconButton(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF0E9F6E)),
                  tooltip: 'Add new card',
                ),
                child: StreamBuilder(
                  stream: _walletService.cardsStream(_uid),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return const Text(
                        'No cards yet. Tap + to add a card.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final last4 = (data['last4'] as String?) ?? '----';
                        final holder =
                            (data['holderName'] as String?) ?? 'Card Holder';
                        final expiry = (data['expiry'] as String?) ?? '--/--';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7ECF4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                color: Color(0xFF334155),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '**** **** **** $last4',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$holder • Exp $expiry',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _deletingCard
                                    ? null
                                    : () => _deleteCard(doc.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFB91C1C),
                                ),
                                tooltip: 'Delete card',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Top Up Wallet',
                child: Row(
                  children: [
                    Expanded(
                      child: _input(
                        _topUpController,
                        'Amount',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addingMoney ? null : _topUpNow,
                      child: _addingMoney
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}

class _AddCardDialog extends StatefulWidget {
  const _AddCardDialog();

  @override
  State<_AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<_AddCardDialog> {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _topUpController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _topUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(_cardController, 'Card Number'),
            const SizedBox(height: 10),
            _dialogInput(_holderController, 'Card Holder Name'),
            const SizedBox(height: 10),
            _dialogInput(_expiryController, 'Expiry (MM/YY)'),
            const SizedBox(height: 10),
            _dialogInput(
              _topUpController,
              'Top-up Amount (optional)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'cardNumber': _cardController.text,
              'holderName': _holderController.text,
              'expiry': _expiryController.text,
              'topUpRaw': _topUpController.text,
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Widget _dialogInput(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}
