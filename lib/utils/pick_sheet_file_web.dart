import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'picked_sheet_file.dart';

Future<PickedSheetFile?> pickSheetFile() {
  final completer = Completer<PickedSheetFile?>();
  final input = html.FileUploadInputElement()
    ..accept =
        '.csv,.xlsx,.xls,text/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ..style.display = 'none';

  html.document.body?.append(input);

  var fileChosen = false;

  void finish(PickedSheetFile? value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    input.remove();
  }

  input.onChange.listen((_) {
    fileChosen = true;
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onError.listen((_) => finish(null));
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        finish(
          PickedSheetFile(
            name: file.name,
            bytes: result.asUint8List(),
          ),
        );
      } else {
        finish(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  // Cancel only if the dialog closed with no file selected.
  // Never cancel after onChange — FileReader can still be loading.
  Future<void>.delayed(const Duration(milliseconds: 300), () {
    html.window.onFocus.first.then((_) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!completer.isCompleted && !fileChosen) finish(null);
      });
    });
  });

  input.click();
  return completer.future;
}
