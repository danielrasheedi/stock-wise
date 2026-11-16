import 'dart:io';
import 'dart:typed_data';

/// Writes the image to the phone's Downloads folder and returns a message to show
Future<String> saveBarcodeImage(Uint8List bytes, String fileName) async {
  final file = File('/storage/emulated/0/Download/$fileName');
  await file.writeAsBytes(bytes);
  return 'saved to Downloads: $fileName';
}
