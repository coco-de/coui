import 'package:coui_web/coui_web.dart';

class FileInputDefaultExample extends StatefulComponent {
  const FileInputDefaultExample({super.key});

  @override
  State<FileInputDefaultExample> createState() => _FileInputDefaultExampleState();
}

class _FileInputDefaultExampleState extends State<FileInputDefaultExample> {
  List<String> _selectedFiles = const [];

  @override
  Component build(BuildContext context) {
    return FileInput(
      onFilesSelected: (files) {
        setState(() {
          _selectedFiles = [
            for (var i = 0; i < files.length; i++) files.item(i)!.name,
          ];
        });
      },
      multiple: true,
      hint: 'PNG, JPG, PDF · 최대 10MB',
      selectedFiles: _selectedFiles,
    );
  }
}
