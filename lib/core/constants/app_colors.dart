import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF3629B7);
  static const Color primary2 = Color(0xFF5655B9);
  static const Color primary4 = Color(0xFFF2F1F9);

  static const Color gradientStart = Color(0xFF469FEF);
  static const Color gradientMid = Color(0xFF5C75F0);
  static const Color gradientEnd = Color(0xFF6C56F0);

  static const Color neutral1 = Color(0xFF343434);
  static const Color neutral2 = Color(0xFF898989);
  static const Color neutral4 = Color(0xFFCACACA);
  static const Color neutral6 = Color(0xFFFFFFFF);

  static const Color textDefault = Color(0xFF979797);
  static const Color borderColor = Color(0xFFCBCBCB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFFFFDFF);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.258, 0.652],
    colors: [gradientStart, gradientMid, gradientEnd],
  );
}