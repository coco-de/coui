/// Native Impeller probe with the same action grouping as the DOM probe.
library;

import 'package:coui_flutter/coui_flutter.dart';

void main() => runApp(const _Probe());

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _action(IconName icon) => Button(
    variant: .ghost,
    size: .sm,
    shape: .square,
    onPressed: () {},
    child: Icon(icon),
  );

  @override
  Widget build(BuildContext context) => CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    surfaceStyle: .liquidGlass,
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      floatingHeader: true,
      headers: [
        Builder(
          builder: (context) => AppBar(
            title: const Text('Dashboard'),
            centerTitle: true,
            scrollController: _scroll,
            leading: [_action(LucideIcons.menu)],
            trailing: [_action(LucideIcons.search), _action(LucideIcons.bell)],
          ),
        ),
      ],
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 144, bottom: 32),
        children: [
          for (var i = 0; i < 24; i++)
            Container(
              height: 120,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const [
                  Color(0xFF1798FF),
                  Color(0xFFFF9623),
                  Color(0xFFC63EE9),
                  Color(0xFF34C76A),
                ][i % 4],
              ),
              child: Center(child: Text('Collection ${i + 1}').onPrimary),
            ),
        ],
      ),
    ),
  );
}
