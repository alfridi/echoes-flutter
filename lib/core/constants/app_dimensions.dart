import 'package:flutter/material.dart';

/// Corner radius tokens for Echoes tactile widgets.
abstract class AppRadii {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius full = BorderRadius.all(Radius.circular(9999));
}

/// Elevation and paper box shadow tokens for Echoes.
abstract class AppShadows {
  static const List<BoxShadow> paperCard = [
    BoxShadow(
      color: Color.fromRGBO(28, 29, 26, 0.05),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color.fromRGBO(28, 29, 26, 0.03),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> floatingSheet = [
    BoxShadow(
      color: Color.fromRGBO(27, 28, 25, 0.08),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
