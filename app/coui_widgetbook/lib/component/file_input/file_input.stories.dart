import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'file_input.stories.g.dart';

/// Maps a file extension to its Bootstrap file-type icon.
IconName _fileIcon(String extension) => switch (extension) {
  'avi' || 'mkv' || 'mp4' => BootstrapIcons.filePlay,
  'doc' || 'docx' => BootstrapIcons.fileWord,
  'gif' || 'jpeg' || 'jpg' || 'png' => BootstrapIcons.fileImage,
  'mp3' || 'wav' => BootstrapIcons.fileMusic,
  'pdf' => BootstrapIcons.filetypePdf,
  'ppt' || 'pptx' => BootstrapIcons.filePpt,
  'rar' || 'zip' => BootstrapIcons.fileZip,
  'xls' || 'xlsx' => BootstrapIcons.fileExcel,
  _ => BootstrapIcons.file,
};

/// Demo host mapping a file extension to a file-type icon.
class FileIconDemo extends StatelessWidget {
  /// Creates a [FileIconDemo].
  const FileIconDemo({super.key, this.extension = 'pdf'});

  /// File extension whose icon is shown (for example `pdf` or `zip`).
  final String extension;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space8,
      children: [
        Icon(_fileIcon(extension)),
        Text('.$extension'),
      ],
    );
  }
}

/// Navigation metadata for the file icons demo.
const kComponentMeta = ComponentMeta(name: 'FileIcons', path: 'demo');

/// Story metadata for [FileIconDemo].
const kMeta = Meta(FileIconDemo.new);

/// PDF file icon with an editable extension knob.
final $Default = _Story();

/// Word document icon.
final $Document = _Story(args: _Args(extension: StringArg('doc')));

/// Spreadsheet icon.
final $Spreadsheet = _Story(args: _Args(extension: StringArg('xls')));

/// Presentation icon.
final $Presentation = _Story(args: _Args(extension: StringArg('ppt')));

/// Archive icon.
final $Archive = _Story(args: _Args(extension: StringArg('zip')));

/// Image icon.
final $Image = _Story(args: _Args(extension: StringArg('jpg')));

/// Audio icon.
final $Audio = _Story(args: _Args(extension: StringArg('mp3')));

/// Video icon.
final $Video = _Story(args: _Args(extension: StringArg('mp4')));

/// Fallback icon for unknown extensions.
final $Unknown = _Story(args: _Args(extension: StringArg('txt')));
