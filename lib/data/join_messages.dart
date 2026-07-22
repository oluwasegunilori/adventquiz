import '../models/room.dart';

/// User-facing copy when a room is no longer accepting new players.
String joinClosedMessage(RoomStatus status) {
  if (status == RoomStatus.finished) {
    return 'This game has already finished. Ask the host to create a new room.';
  }
  return 'This game has already started — you can only join while players are still in the lobby.';
}
