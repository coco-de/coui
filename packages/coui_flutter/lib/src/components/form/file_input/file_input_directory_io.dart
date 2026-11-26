import 'package:cross_file/cross_file.dart';
import 'package:dir_picker/dir_picker.dart';

/// Every native platform `dir_picker` supports has a system directory
/// dialog, so the folder button is always offered there.
bool get supportsDirectoryPicker => true;

/// The files inside a picked directory, as path-backed [XFile]s.
///
/// Entries are read recursively — a folder pick means "this folder's
/// contents", and stopping at the first level would silently drop the
/// nested ones a drop of the same folder brings in.
Future<List<XFile>> filesOfPickedDirectory(PickedLocation location) async {
  final entries = await DirPicker.listEntries(location, recursive: true);

  return [
    for (final entry in entries)
      if (!entry.isDirectory) _xfileOf(entry),
  ];
}

/// Builds an [XFile] for a picked [entry].
///
/// A `file://` URI maps straight to a path, which `XFile` reads lazily.
/// Android's SAF hands over `content://` URIs instead — those are kept as
/// the file's identity rather than guessed at, since resolving one to bytes
/// needs the app's own content-resolver layer and `dir_picker` exposes
/// metadata only.
XFile _xfileOf(FileSystemEntry entry) {
  final path = switch (entry.uri) {
    null => entry.name,
    final uri when uri.scheme == 'file' => uri.toFilePath(),
    final uri => uri.toString(),
  };

  return XFile(
    path,
    name: entry.name,
    length: entry.size,
    lastModified: entry.lastModified,
  );
}
