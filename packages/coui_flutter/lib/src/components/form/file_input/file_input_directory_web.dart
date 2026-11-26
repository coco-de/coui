/// Web reading of a picked directory — selected via the conditional export
/// in `file_input_directory.dart`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dir_picker/dir_picker.dart';
import 'package:file_drop/file_drop.dart' show XFile;
import 'package:web/web.dart' as web;

/// Whether the browser offers the File System Access directory picker.
///
/// Chrome/Edge 86+ do; Firefox and Safari do not, and the folder button is
/// rendered disabled there rather than failing on press.
bool get supportsDirectoryPicker =>
    web.window.hasProperty('showDirectoryPicker'.toJS).toDart;

/// The files inside a picked directory, as byte-backed [XFile]s.
///
/// Browsers never expose a filesystem path, so the directory handle is
/// walked and each file read into memory — the browser-side equivalent of
/// the path-backed `XFile`s the native branch hands over.
Future<List<XFile>> filesOfPickedDirectory(PickedLocation location) async {
  if (location is! WebPickedLocation) return const [];

  return _walk(location.handle, '');
}

Future<List<XFile>> _walk(
  web.FileSystemDirectoryHandle handle,
  String parentPath,
) async {
  final files = <XFile>[];
  final iterator = handle.values();
  while (true) {
    final result = await iterator.next().toDart;
    if (result.done) return files;

    final item = result.value! as web.FileSystemHandle;
    final path = parentPath.isEmpty ? item.name : '$parentPath/${item.name}';
    if (item.kind == 'directory') {
      files.addAll(
        await _walk(item as web.FileSystemDirectoryHandle, path),
      );
      continue;
    }

    final file = await (item as web.FileSystemFileHandle).getFile().toDart;
    final buffer = await file.arrayBuffer().toDart;
    files.add(
      XFile.fromData(
        buffer.toDart.asUint8List(),
        name: path,
        lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
      ),
    );
  }
}

extension on web.FileSystemDirectoryHandle {
  external _AsyncIterator values();
}

extension type const _AsyncIterator._(JSObject _) implements JSObject {
  external JSPromise<_IteratorResult> next();
}

extension type const _IteratorResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSAny? get value;
}
