import 'dart:typed_data';

/// Server-side no-op: a render pass has no browser to hand a download to.
void downloadBytes(Uint8List bytes, String fileName, String? mimeType) {}
