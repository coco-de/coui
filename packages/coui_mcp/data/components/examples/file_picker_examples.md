# File Picker Examples

This document contains example code for the file_picker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FilePickerExample1 extends StatefulWidget {
  const FilePickerExample1({super.key});

  @override
  State<FilePickerExample1> createState() => _FilePickerExample1State();
}

class _FilePickerExample1State extends State<FilePickerExample1> {
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
      hint: 'PNG, JPG, PDF up to 10MB',
      selectedFiles: _selectedFiles,
    );
  }
}

```

