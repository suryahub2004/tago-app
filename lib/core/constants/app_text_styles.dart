import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  static const TextStyle h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
  );
}
