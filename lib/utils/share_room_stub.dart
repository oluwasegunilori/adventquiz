import 'share_room.dart';

Future<ShareRoomOutcome> shareRoom({
  required String pin,
  required String packTitle,
}) async {
  // Non-web: caller should fall back to clipboard via the same text helper.
  throw UnsupportedError('Use clipboard on this platform');
}
