import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Starts a browser download of the image and returns a message to show
Future<String> saveBarcodeImage(Uint8List bytes, String fileName) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.appendChild(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
  return 'downloaded: $fileName';
}
