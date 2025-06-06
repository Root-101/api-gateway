import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

@JS('URL.createObjectURL')
external String createObjectUrlFromBlob(Blob blob);

@JS('URL.revokeObjectURL')
external void revokeObjectUrl(String url);

class ExportDocument {
  static void downloadDocument(
    String content, {
    String? filename,
    String type = 'application/json',
  }) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final parts = <JSAny>[bytes.toJS].toJS;

    final blob = Blob(parts, BlobPropertyBag(type: type));
    final url = createObjectUrlFromBlob(blob);

    String safeFilename =
        filename ?? 'backup-${DateTime.now().toString()}.json';

    final anchor =
        HTMLAnchorElement()
          ..href = url
          ..download = safeFilename;

    anchor.click();
    revokeObjectUrl(url);
  }
}
