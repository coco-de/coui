import 'package:coui_web/coui_web.dart';

class CommandEmptyExample extends StatefulComponent {
  const CommandEmptyExample({super.key});

  @override
  State<CommandEmptyExample> createState() => _CommandEmptyExampleState();
}

class _CommandEmptyExampleState extends State<CommandEmptyExample> {
  String _query = 'zzz';

  @override
  Component build(BuildContext context) {
    return Command(
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelect: (_) {},
      groups: const [
        CoreCommandGroup(
          heading: '추천',
          items: [
            CoreCommandItem(value: 'calendar', label: '캘린더'),
            CoreCommandItem(value: 'search', label: '이모지 검색'),
            CoreCommandItem(value: 'calculator', label: '계산기'),
          ],
        ),
      ],
    );
  }
}
