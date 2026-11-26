/// Web implementation of `FileInput`'s file-list intake.
///
/// Selected via the conditional export in `file_input_dom.dart` for browser
/// builds — kept out of the adapter widget so it stays SSR-safe and free of
/// direct `package:web` / `dart:js_interop` dependencies.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// Collects the files a drop carries — flattening dropped directories —
/// keeps the ones [accept] admits, and returns them as a `FileList`.
///
/// The roots are captured **synchronously** — `webkitGetAsEntry()` only
/// answers while the drop event is being handled, so awaiting first would
/// hand back an empty tree. Walking the captured tree is then async.
///
/// Returns null when the drop carries no file, or when none of them
/// satisfies [accept].
Future<web.FileList?> collectAcceptedFiles(
  Object dataTransfer,
  List<String> accept,
) {
  final transfer = dataTransfer as web.DataTransfer;

  final roots = <web.FileSystemEntry>[];
  final items = transfer.items;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.kind != 'file') continue;
    final entry = item.webkitGetAsEntry();
    if (entry != null) roots.add(entry);
  }

  // No entries to walk — `dataTransfer.files` already holds the flat list
  // (and is the only payload some drag sources provide).
  if (roots.isEmpty) return Future.value(_accept(transfer.files, accept));

  return _collect(roots, accept);
}

Future<web.FileList?> _collect(
  List<web.FileSystemEntry> roots,
  List<String> accept,
) async {
  final files = <web.File>[];
  for (final root in roots) {
    files.addAll(await _walk(root));
  }

  return _accept(_toFileList(files), accept);
}

/// The accepted subset of an already-flat [files], as a `FileList` — or
/// null when none of them satisfies [accept].
///
/// The OS picker enforces `accept` at the dialog and a drop has no
/// equivalent gate, so the same rule is applied here.
web.FileList? filterFileList(web.FileList files, List<String> accept) =>
    _accept(files, accept);

/// The accepted subset of [files] — [files] itself when [accept] is empty
/// or everything matches, null when nothing does.
web.FileList? _accept(web.FileList files, List<String> accept) {
  if (files.length == 0) return null;
  if (accept.isEmpty) return files;

  final accepted = <web.File>[
    for (var i = 0; i < files.length; i++)
      if (files.item(i) case final file?)
        if (CoreFileInputAccept.matches(
          fileName: file.name,
          accept: accept,
          mimeType: file.type,
        ))
          file,
  ];
  if (accepted.isEmpty) return null;

  return _toFileList(accepted);
}

/// Flattens [entry] — a file yields itself, a directory yields everything
/// below it.
///
/// `isFile` / `isDirectory` decide the branch, not an `is` check: every
/// `package:web` type is the same `JSObject` at runtime, so an
/// extension-type test would always be true.
Future<List<web.File>> _walk(web.FileSystemEntry entry) async {
  if (entry.isFile) {
    final file = await _fileOf(entry as web.FileSystemFileEntry);

    return file == null ? const [] : [file];
  }
  if (!entry.isDirectory) return const [];

  final reader = (entry as web.FileSystemDirectoryEntry).createReader();
  final collected = <web.File>[];
  // `readEntries` hands back one batch per call (browsers cap it, Chrome at
  // 100) and signals the end with an empty batch, so it is drained until
  // empty rather than read once.
  while (true) {
    final batch = await _readEntries(reader);
    if (batch.isEmpty) return collected;
    for (final child in batch) {
      collected.addAll(await _walk(child));
    }
  }
}

Future<List<web.FileSystemEntry>> _readEntries(
  web.FileSystemDirectoryReader reader,
) {
  final completer = Completer<List<web.FileSystemEntry>>();
  reader.readEntries(
    ((JSArray<web.FileSystemEntry> entries) {
      completer.complete(entries.toDart);
    }).toJS,
  );

  return completer.future;
}

Future<web.File?> _fileOf(web.FileSystemFileEntry entry) {
  final completer = Completer<web.File?>();
  entry.file(
    ((web.File file) {
      completer.complete(file);
    }).toJS,
  );

  return completer.future;
}

/// Rebuilds a `FileList` from [files].
///
/// A `FileList` cannot be constructed directly — the only way to obtain one
/// is from a `DataTransfer`, so the list is assembled there.
web.FileList _toFileList(List<web.File> files) {
  final transfer = web.DataTransfer();
  for (final file in files) {
    final _ = transfer.items.add(file);
  }

  return transfer.files;
}

/// Whether the browser offers the File System Access directory picker.
///
/// Chrome/Edge 86+ do; Firefox and Safari do not, and the folder button is
/// rendered disabled there rather than failing on press.
bool get supportsDirectoryPicker =>
    web.window.hasProperty('showDirectoryPicker'.toJS).toDart;

/// Opens the system directory picker and returns the files it holds — the
/// accepted ones only — as a `FileList`, or null when the user cancelled
/// (or when nothing passes [accept]).
///
/// The picker call itself has to stay inside the press that triggered it —
/// browsers drop the user activation across an await — so it runs before
/// the first suspension point.
Future<web.FileList?> pickDirectoryFiles(List<String> accept) async {
  final handle = await _showDirectoryPicker();
  if (handle == null) return null;

  final files = await _walkHandle(handle, '');
  if (files.isEmpty) return null;

  return _accept(_toFileList(files), accept);
}

extension on web.Window {
  external JSPromise<web.FileSystemDirectoryHandle> showDirectoryPicker();
}

Future<web.FileSystemDirectoryHandle?> _showDirectoryPicker() async {
  try {
    return await web.window.showDirectoryPicker().toDart;
  } catch (error) {
    // AbortError is the user closing the dialog, not a failure.
    if (error.toString().contains('AbortError')) return null;
    rethrow;
  }
}

/// Flattens a directory handle, descending into subdirectories.
Future<List<web.File>> _walkHandle(
  web.FileSystemDirectoryHandle handle,
  String parentPath,
) async {
  final files = <web.File>[];
  final iterator = handle.values();
  while (true) {
    final result = await iterator.next().toDart;
    if (result.done) return files;

    final item = result.value! as web.FileSystemHandle;
    if (item.kind == 'directory') {
      files.addAll(
        await _walkHandle(item as web.FileSystemDirectoryHandle, parentPath),
      );
      continue;
    }

    files.add(await (item as web.FileSystemFileHandle).getFile().toDart);
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

/// The bytes behind a dropped or picked [file], for saving it back out.
Future<Uint8List> bytesOfFile(Object file) async {
  final buffer = await (file as web.File).arrayBuffer().toDart;

  return buffer.toDart.asUint8List();
}
