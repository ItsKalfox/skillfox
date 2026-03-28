// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class _C {
//   static const accent     = Color(0xFF6C56F0);
//   static const bg         = Color(0xFFF4F6FA);
//   static const cardBorder = Color(0xFFE2E6F0);
//   static const txt1       = Color(0xFF111111);
//   static const txt2       = Color(0xFF888888);
//   static const muted      = Color(0xFFA0A4B0);
//   static const green      = Color(0xFF16A34A);
//   static const greenDark  = Color(0xFF1E8449);
//   static const chip       = Color(0xFFEEF0F8);
//   static const reject     = Color(0xFFEF4444);
// }

// class PaymentOptionsScreen extends StatefulWidget {
//   final String requestId;
//   final num    totalAmount;
//   final num    inspectionFee;
//   final num    distanceFee;

//   const PaymentOptionsScreen({
//     super.key,
//     required this.requestId,
//     required this.totalAmount,
//     required this.inspectionFee,
//     required this.distanceFee,
//   });

//   @override
//   State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
// }

// class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
//   String _selected = 'cash';
//   bool _processing = false;

//   static const _methods = [
//     {'id': 'cash',   'label': 'Cash on Delivery', 'icon': Icons.payments_outlined,    'sub': 'Pay in cash when the worker arrives'},
//     {'id': 'card',   'label': 'Credit / Debit Card','icon': Icons.credit_card_rounded, 'sub': 'Visa, Mastercard accepted'},
//     {'id': 'wallet', 'label': 'Digital Wallet',    'icon': Icons.account_balance_wallet_outlined, 'sub': 'FriMi, eZ Cash, iPay'},
//   ];

//   String _fmt(num n) {
//     final s = n.toStringAsFixed(0);
//     final r = StringBuffer();
//     for (int i = 0; i < s.length; i++) {
//       if (i > 0 && (s.length - i) % 3 == 0) r.write(',');
//       r.write(s[i]);
//     }
//     return r.toString();
//   }

//   Future<void> _confirmPayment() async {
//     setState(() => _processing = true);
//     try {
//       await FirebaseFirestore.instance
//           .collection('requests')
//           .doc(widget.requestId)
//           .update({
//         'status':        'inprogress',
//         'paymentMethod': _selected,
//         'paidAt':        FieldValue.serverTimestamp(),
//       });

//       if (!mounted) return;
//       Navigator.pop(context);
//     } catch (e) {
//       if (mounted) setState(() => _processing = false);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Payment failed: $e'),
//         backgroundColor: _C.reject,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _C.bg,
//       body: Column(
//         children: [
//           Container(
//             color: Colors.white,
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).padding.top + 4,
//               bottom: 12, left: 16, right: 16,
//             ),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     width: 32, height: 32,
//                     decoration: const BoxDecoration(
//                         color: Color(0xFFF0F2F8), shape: BoxShape.circle),
//                     child: const Icon(Icons.arrow_back_ios_new_rounded,
//                         size: 14, color: Color(0xFF444444)),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text('Payment',
//                     style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: _C.txt1)),
//               ],
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [

//                   _buildBillCard(),
//                   const SizedBox(height: 16),

//                   const Text('SELECT PAYMENT METHOD',
//                       style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w600,
//                           color: _C.muted,
//                           letterSpacing: 0.6)),
//                   const SizedBox(height: 10),

//                   ..._methods.map((m) => _buildMethodTile(
//                         id:    m['id']    as String,
//                         label: m['label'] as String,
//                         icon:  m['icon']  as IconData,
//                         sub:   m['sub']   as String,
//                       )),
//                 ],
//               ),
//             ),
//           ),

//           Container(
//             color: Colors.white,
//             padding: EdgeInsets.fromLTRB(
//                 16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Total Amount',
//                         style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: _C.txt1)),
//                     Text('LKR ${_fmt(widget.totalAmount)}',
//                         style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                             color: _C.accent)),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                           colors: [Color(0xFF27AE60), _C.greenDark]),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: ElevatedButton(
//                       onPressed: _processing ? null : _confirmPayment,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         disabledBackgroundColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: _processing
//                           ? const SizedBox(
//                               width: 20, height: 20,
//                               child: CircularProgressIndicator(
//                                   color: Colors.white, strokeWidth: 2.5))
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(Icons.check_circle_outline_rounded,
//                                     color: Colors.white, size: 18),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   _selected == 'cash'
//                                       ? 'Confirm  ·  Pay on Arrival'
//                                       : 'Next  ·  Confirm Payment',
//                                   style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w700,
//                                       fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBillCard() => Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: _C.cardBorder, width: 0.5),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(children: [
//               Icon(Icons.receipt_long_outlined, size: 15, color: _C.green),
//               SizedBox(width: 6),
//               Text('BILL SUMMARY',
//                   style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: _C.muted,
//                       letterSpacing: 0.5)),
//             ]),
//
//             const SizedBox(height: 12),
//             _billRow('Inspection Fee', widget.inspectionFee),
//             const Divider(height: 12, color: _C.cardBorder),
//             _billRow('Distance Fee', widget.distanceFee),
//             const SizedBox(height: 4),
//             _billRow('Service Fee (5%)',
//                 ((widget.inspectionFee + widget.distanceFee) * 0.05).round()),
//             const Divider(height: 16, color: _C.cardBorder, thickness: 1.5),
//             Row(children: [
//               const Expanded(
//                   child: Text('Total',
//                       style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                           color: _C.txt1))),
//               Text('LKR ${_fmt(widget.totalAmount)}',
//                   style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: _C.accent)),
//             ]),
//           ],
//         ),
//       );

//   Widget _billRow(String label, num amount) => Padding(
//         padding: const EdgeInsets.symmetric(vertical: 5),
//         child: Row(children: [
//           Expanded(
//               child: Text(label,
//                   style: const TextStyle(fontSize: 12, color: _C.txt2))),
//           Text('LKR ${_fmt(amount)}',
//               style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                   color: _C.txt1)),
//         ]),
//       );

//   Widget _buildMethodTile({
//     required String id,
//     required String label,
//     required IconData icon,
//     required String sub,
//   }) {
//     final isSelected = _selected == id;
//     return GestureDetector(
//       onTap: () => setState(() => _selected = id),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? _C.accent : _C.cardBorder,
//             width: isSelected ? 1.5 : 0.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 42, height: 42,
//               decoration: BoxDecoration(
//                 color: isSelected ? _C.accent : _C.chip,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon,
//                   size: 20,
//                   color: isSelected ? Colors.white : _C.muted),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(label,
//                       style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: isSelected ? _C.accent : _C.txt1)),
//                   const SizedBox(height: 2),
//                   Text(sub,
//                       style: const TextStyle(
//                           fontSize: 11, color: _C.txt2)),
//                 ],
//               ),
//             ),
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               width: 20, height: 20,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isSelected ? _C.accent : Colors.transparent,
//                 border: Border.all(
//                     color: isSelected ? _C.accent : _C.muted, width: 1.5),
//               ),
//               child: isSelected
//                   ? const Icon(Icons.check_rounded,
//                       size: 12, color: Colors.white)
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }