import 'package:coui_web/coui_web.dart';

class CommandScrollableExample extends StatefulComponent {
  const CommandScrollableExample({super.key});

  @override
  State<CommandScrollableExample> createState() => _CommandScrollableExampleState();
}

class _CommandScrollableExampleState extends State<CommandScrollableExample> {
  String _query = '';

  static final List<CoreCommandGroup<Component>> _groups = [
    CoreCommandGroup(
      heading: '페이지',
      items: [
        for (var i = 1; i <= 24; i++) CoreCommandItem(value: 'page-$i', label: '페이지 $i'),
      ],
    ),
  ];

  @override
  Component build(BuildContext context) {
    return Command(
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelect: (_) {},
      groups: _groups,
    );
  }
}
