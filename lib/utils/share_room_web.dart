import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'share_room.dart';

Future<ShareRoomOutcome> shareRoom({
  required String pin,
  required String packTitle,
}) async {
  final text = roomShareText(pin: pin, packTitle: packTitle);
  final link = roomJoinLink(pin);

  try {
    final data = web.ShareData(
      title: 'AdventQuiz',
      text: text,
      url: link,
    );
    if (web.window.navigator.canShare(data)) {
      await web.window.navigator.share(data).toDart;
      return ShareRoomOutcome.shared;
    }
  } catch (_) {
    // Canceled or unsupported.
  }

  await Clipboard.setData(ClipboardData(text: text));
  return ShareRoomOutcome.copied;
}
