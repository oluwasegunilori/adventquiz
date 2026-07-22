import 'visibility_stub.dart'
    if (dart.library.html) 'visibility_web.dart' as impl;

/// Fires `true` when the page/tab is visible, `false` when hidden.
Stream<bool> watchPageVisibility() => impl.watchPageVisibility();
