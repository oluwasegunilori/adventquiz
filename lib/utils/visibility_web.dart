import 'dart:async';

import 'package:web/web.dart' as web;

Stream<bool> watchPageVisibility() {
  final controller = StreamController<bool>.broadcast();

  void emit() {
    if (!controller.isClosed) {
      controller.add(!web.document.hidden);
    }
  }

  final sub = web.document.onVisibilityChange.listen((_) => emit());
  // Initial state for late subscribers isn't required; lifecycle covers resume.
  controller.onCancel = () {
    sub.cancel();
  };
  return controller.stream;
}
