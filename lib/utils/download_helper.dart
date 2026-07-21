import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as impl;

void downloadTextFile(String filename, String text) =>
    impl.downloadTextFile(filename, text);
