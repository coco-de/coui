import 'package:coui_web/coui_web.dart' hide Document, runApp;
import 'package:jaspr/server.dart' show Document, runApp;

void main() {
  final config = ThemeConfig.defaults();
  runApp(
    Document(
      title: 'CoUI Web example',
      head: [
        const Component.element(
          tag: 'script',
          attributes: {'src': 'https://cdn.tailwindcss.com/3.4.17'},
        ),
        Component.element(
          tag: 'script',
          children: [RawText(config.tailwindConfig)],
        ),
        Component.element(
          tag: 'style',
          children: [RawText(config.cssVariables)],
        ),
      ],
      body: CoUIWeb(
        theme: ThemeData.coui,
        child: Button(
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ),
    ),
  );
}
