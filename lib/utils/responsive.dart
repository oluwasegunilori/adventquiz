import 'package:flutter/material.dart';

/// Shared breakpoints for AdventQuiz layouts.
extension AdventResponsive on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Phones / narrow browser windows.
  bool get isCompact => screenSize.width < 600;

  /// Very small phones.
  bool get isTiny => screenSize.width < 380;

  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: isTiny ? 14 : (isCompact ? 16 : 24),
        vertical: isCompact ? 12 : 24,
      );

  double get pageMaxWidth => isCompact ? screenSize.width : 720;
}
