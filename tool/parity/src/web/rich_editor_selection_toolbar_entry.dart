/// Client fixture for the rich editor selection toolbar probe: editors a real
/// Chrome can select text in, so the probe can read where the toolbar that
/// floats over the selection lands and when it goes.
///
/// The toolbar exists only after text is selected in a hydrated editor — the
/// selection, the focus and the boxes are the browser's, which no VM test has
/// — hence a client entry, compiled and loaded by
/// `rich_editor_selection_toolbar_probe_test.dart`.
///
///   · `top` — at the top of the page, with no toolbar in its box: its first
///     line has no room above it;
///   · `main` — in the middle of the page, several paragraphs;
///   · `edge` — narrow, against the left edge of the page;
///   · `off` — `showSelectionToolbar: false`;
///   · `readonly` — read-only;
///   · `tall` — thirty lines, more than its box shows: its text scrolls;
///   · `elsewhere` — a button outside every editor, to take the focus.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

Component _placed(String id, Component editor, {Map<String, String>? css}) =>
    div(
      [editor],
      id: id,
      styles: Styles(raw: {'width': '600px', ...?css}),
    );

void main() => client.runApp(
  CoUIWeb(
    theme: .coui,
    child: div(
      [
        _placed(
          'top',
          const RichEditor(initialValue: 'first line', showToolbar: false),
        ),
        _placed(
          'main',
          const RichEditor(
            initialValue: 'one\n\ntwo\n\nthree\n\nhello world',
          ),
          css: {'margin': '160px 0 0 300px'},
        ),
        _placed(
          'edge',
          const RichEditor(initialValue: 'one\n\ntwo\n\nhi'),
          css: {'width': '200px', 'margin-top': '24px'},
        ),
        _placed(
          'off',
          const RichEditor(
            initialValue: 'one\n\ntwo\n\nno toolbar',
            showSelectionToolbar: false,
          ),
          css: {'margin': '24px 0 0 300px'},
        ),
        _placed(
          'readonly',
          const RichEditor(
            initialValue: 'one\n\ntwo\n\nread only',
            readOnly: true,
          ),
          css: {'margin': '24px 0 0 300px'},
        ),
        _placed(
          'tall',
          RichEditor(
            initialValue: [
              for (var i = 0; i < 30; i++) 'line $i',
            ].join('\n\n'),
          ),
          css: {'margin': '24px 0 0 300px'},
        ),
        const button([Text('Elsewhere')], id: 'elsewhere'),
      ],
      styles: const Styles(raw: {'padding-bottom': '400px'}),
    ),
  ),
);
