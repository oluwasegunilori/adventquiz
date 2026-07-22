import 'picked_sheet_file.dart';
import 'pick_sheet_file_stub.dart'
    if (dart.library.html) 'pick_sheet_file_web.dart' as impl;

export 'picked_sheet_file.dart';

/// Opens a file chooser for CSV / Excel question sheets.
Future<PickedSheetFile?> pickSheetFile() => impl.pickSheetFile();
