import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Bakes EXIF orientation so pixel data matches what Flutter displays.
Uint8List normalizeHandPhotoBytes(Uint8List bytes, {int quality = 92}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  final oriented = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodeJpg(oriented, quality: quality));
}
