import 'package:coui_flutter/coui_flutter.dart';

class FileInputDefaultExample extends StatefulWidget {
  const FileInputDefaultExample({super.key});

  @override
  State<FileInputDefaultExample> createState() => _FileInputDefaultExampleState();
}

class _FileInputDefaultExampleState extends State<FileInputDefaultExample> {
  List<String> _selectedFiles = const [];

  void handleFilesSelected(List<XFile> files) {
    setState(() {
      _selectedFiles = files.map((f) => f.name).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FileInput(
      onFilesSelected: handleFilesSelected,
      multiple: true,
      hint: 'PNG, JPG, PDF · 최대 10MB',
      selectedFiles: _selectedFiles,
    );
  }
}
