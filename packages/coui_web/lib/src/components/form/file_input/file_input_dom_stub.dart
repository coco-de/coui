import 'dart:typed_data';

import 'package:universal_web/web.dart' as web;

/// Server-side no-op: nothing is dropped during a render pass, and the VM
/// has no `DataTransfer` to read.
Future<web.FileList?> collectAcceptedFiles(
  Object dataTransfer,
  List<String> accept,
) => .value();

/// Server-side no-op: the VM has no `FileList` to rebuild.
web.FileList? filterFileList(web.FileList files, List<String> accept) => null;

/// Server-side no-op: the VM has no browser to ask, and the folder button
/// is rendered for a browser that can actually open the picker.
bool get supportsDirectoryPicker => false;

/// Server-side no-op: nothing is picked during a render pass.
Future<web.FileList?> pickDirectoryFiles(List<String> accept) => .value();

/// Server-side no-op: the VM has no `File` to read.
Future<Uint8List> bytesOfFile(Object file) => .value(Uint8List(0));
