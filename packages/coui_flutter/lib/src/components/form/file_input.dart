import 'package:coui_flutter/coui_flutter.dart';

Widget _buildFileIcon(String extension) {
  switch (extension) {
    case 'pdf':
      return const Icon(BootstrapIcons.filetypePdf);

    case 'doc':
    case 'docx':
      return const Icon(BootstrapIcons.fileWord);

    case 'xls':
    case 'xlsx':
      return const Icon(BootstrapIcons.fileExcel);

    case 'ppt':
    case 'pptx':
      return const Icon(BootstrapIcons.filePpt);

    case 'zip':
    case 'rar':
      return const Icon(BootstrapIcons.fileZip);

    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return const Icon(BootstrapIcons.fileImage);

    case 'mp3':
    case 'wav':
      return const Icon(BootstrapIcons.fileMusic);

    case 'mp4':
    case 'avi':
    case 'mkv':
      return const Icon(BootstrapIcons.filePlay);

    default:
      return const Icon(BootstrapIcons.file);
  }
}

typedef FileIconBuilder = Widget Function(String extension);

class FileIconProviderData {
  const FileIconProviderData._({this.builder, this.icons});

  final FileIconBuilder? builder;

  final Map<String, Widget>? icons;

  Widget buildIcon(String extension) {
    if (builder != null) return builder!(extension);
    final icon = icons?[extension];
    if (icon != null) return icon;

    return _buildFileIcon(extension);
  }
}

//
// class SingleFileInput extends StatelessWidget {
//   final XFile? file;
//   final ValueChanged<XFile?>? onChanged;
//   final bool acceptDrop;
//   final bool enabled;
//
//   const SingleFileInput({
//     super.key,
//     this.file,
//     this.onChanged,
//     this.acceptDrop = false,
//     this.enabled = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     throw UnimplementedError();
//   }
// }
