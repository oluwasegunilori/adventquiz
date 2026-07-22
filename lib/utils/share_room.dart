import 'share_room_stub.dart'
    if (dart.library.html) 'share_room_web.dart' as impl;

enum ShareRoomOutcome { shared, copied }

/// Builds a join link for the current AdventQuiz host.
String roomJoinLink(String pin) {
  final base = Uri.base;
  final origin = base.hasScheme
      ? '${base.scheme}://${base.authority}'
      : 'https://churchgamey.web.app';
  return '$origin/join?pin=${Uri.encodeQueryComponent(pin)}';
}

String roomShareText({
  required String pin,
  required String packTitle,
}) {
  final title = packTitle.trim().isEmpty ? 'Bible trivia' : packTitle.trim();
  return 'Join my AdventQuiz ($title)!\n'
      'PIN: $pin\n'
      '${roomJoinLink(pin)}';
}

/// Native share sheet when available; otherwise copies invite text.
Future<ShareRoomOutcome> shareRoom({
  required String pin,
  required String packTitle,
}) =>
    impl.shareRoom(pin: pin, packTitle: packTitle);
