/// Web implementation of `coui_web`'s file download.
///
/// Selected via the conditional export in `co_file_saver_dom.dart` for
/// browser builds — kept out of `co_file_saver.dart` so it stays SSR-safe
/// and free of direct `package:web` / `dart:js_interop` dependencies.
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands [bytes] to the browser as a download named [fileName].
///
/// The blob URL is revoked right after the click — the browser has already
/// taken the reference, and leaving it alive pins the whole file in memory
/// for the lifetime of the document.
void downloadBytes(Uint8List bytes, String fileName, String? mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor
    ..click()
    ..remove();
  web.URL.revokeObjectURL(url);
}
