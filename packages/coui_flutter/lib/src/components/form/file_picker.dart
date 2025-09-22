import 'package:coui_flutter/coui_flutter.dart';

// const fileByteUnits = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
// const fileBitUnits = ['Bi', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
// String formatFileSize(int bytes, List<String> units) {
//   if (bytes <= 0) return '0 ${units[0]}';
//   final
// }

/// A file picker widget for selecting and managing file uploads.
///
/// **Work in Progress** - This component is under active development and
/// may have incomplete functionality or undergo API changes.
///
/// Provides a comprehensive interface for file selection with drag-and-drop
/// support, file management capabilities, and customizable presentation.
/// Displays selected files as a list of manageable items with options
/// for adding, removing, and organizing uploaded files.
///
/// Supports hot drop functionality for drag-and-drop file uploads and
/// provides visual feedback during file operations. The picker can be
/// customized with titles, subtitles, and custom file item presentations.
///
/// Example:
/// ```dart
/// FilePicker(
///   title: Text('Upload Documents'),
///   subtitle: Text('Drag files here or click to browse'),
///   hotDropEnabled: true,
///   onAdd: () => _selectFiles(),
///   children: selectedFiles.map((file) =>
///     FileItem(file: file, onRemove: () => _removeFile(file))
///   ).toList(),
/// )
/// ```
class FilePicker extends StatelessWidget {
  const FilePicker({
    required this.children,
    this.hotDropEnabled = false,
    this.hotDropping = false,
    super.key,
    this.onAdd,
    this.subtitle,
    this.title,
  });

  final Widget? title;
  final Widget? subtitle;
  final bool hotDropEnabled;
  final bool hotDropping;
  final List<Widget> children;

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class FileItem extends StatelessWidget {
  const FileItem({
    required this.fileName,
    this.fileSize,
    this.fileType,
    super.key,
    this.onDownload,
    this.onPreview,
    this.onRemove,
    this.onRetry,
    this.thumbnail,
    this.uploadProgress,
  });

  final double? uploadProgress;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final VoidCallback? onDownload;
  final Widget? thumbnail;
  final VoidCallback? onPreview;
  final Widget fileName;
  final Widget? fileSize;

  final Widget? fileType;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
