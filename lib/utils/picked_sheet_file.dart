import 'dart:typed_data';

class PickedSheetFile {
  const PickedSheetFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
