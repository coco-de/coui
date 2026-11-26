import 'dart:typed_data';

/// A file the user chose in the browser's file picker.
///
/// Only the file's description is known up front. Its bytes are read by
/// [readBytes] when the editor asks, so a file that is too big or the wrong
/// type is refused from [size] and [mimeType] alone, without ever being
/// loaded into memory.
abstract interface class RichEditorPickedFile {
  /// The file's name (`photo.png`).
  String get name;

  /// The type the browser reported, lower-case; empty when it reported none.
  String get mimeType;

  /// The file's size in bytes.
  int get size;

  /// Reads the file's content.
  Future<Uint8List> readBytes();
}
