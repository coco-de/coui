import 'package:coui_web/coui_web.dart';

class TabPaneEditorStripExample extends StatefulComponent {
  const TabPaneEditorStripExample({super.key});

  @override
  State<TabPaneEditorStripExample> createState() => _TabPaneEditorStripExampleState();
}

class _TabPaneEditorStripExampleState extends State<TabPaneEditorStripExample> {
  final List<String> _files = ['main.dart', 'pubspec.yaml', 'README.md'];
  int _index = 0;

  void _handleClose(int index) {
    if (_files.length == 1) return;
    setState(() {
      _files.removeAt(index);
      if (_index >= _files.length) _index = _files.length - 1;
    });
  }

  @override
  Component build(BuildContext context) {
    return TabPane(
      variant: .editorStrip,
      tabs: [
        for (var i = 0; i < _files.length; i++)
          CoreTabItem(
            label: _files[i],
            leading: Icon(LucideIcons.fileCode),
            onClose: () => _handleClose(i),
          ),
      ],
      selectedIndex: _index,
      onChanged: (index) => setState(() => _index = index),
    );
  }
}
