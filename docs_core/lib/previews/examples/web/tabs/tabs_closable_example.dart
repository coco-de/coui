import 'package:coui_web/coui_web.dart';

class TabsClosableExample extends StatefulComponent {
  const TabsClosableExample({super.key});

  @override
  State<TabsClosableExample> createState() => _TabsClosableExampleState();
}

class _TabsClosableExampleState extends State<TabsClosableExample> {
  static const _files = ['main.dart', 'app.dart', 'theme.dart'];

  final _open = [..._files];
  int _index = 0;

  void _close(int index) {
    setState(() {
      _open.removeAt(index);
      if (index < _index || _index == _open.length) {
        _index = (_index - 1).clamp(0, _open.length);
      }
    });
  }

  void _reopen() {
    setState(() {
      _open
        ..clear()
        ..addAll(_files);
      _index = 0;
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        if (_open.isEmpty)
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: _reopen,
            child: const Text('파일 다시 열기'),
          )
        else
          Tabs(
            tabs: [
              for (final (i, file) in _open.indexed) CoreTabItem(label: file, onClose: () => _close(i)),
            ],
            selectedIndex: _index,
            onChanged: (index) => setState(() => _index = index),
          ),
        Gap.space16(),
        Text(
          _open.isEmpty ? '모든 파일을 닫았어요.' : '편집 중: ${_open[_index]}',
        ).bodyMedium.onSurface,
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
