// `Divider(semantic: true)` is what turns a purely decorative rule into a
// meaningful ARIA `role="separator"` + `aria-label` — this file is the
// over-announce guard: the *default* (unchanged from before #3497) must
// render with neither attribute. The default-divider test below
// constructs `Divider` bare — no `semantic:` argument at any layer — so
// it actually exercises the constructor's own default rather than a
// test helper's.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

/// The vector table shared with the Core reference test, the Flutter widget
/// test and the Chrome probe (cwd is `packages/coui_web` under `dart test`).
const _kLabelVectorsPath =
    '../coui_core/test/fixtures/divider_label_vectors.json';

// Whole-value strings, deliberately not substrings. `contains('1fr')` is
// satisfied by a share on either side of the label, which is exactly the axis
// under test — the assertion would pass no matter which segment collapsed
// (`web/pseudo-state-emit.md` warns about this same trap for ring classes).
//
// A segment with a weight is a flexible track that gives way to nothing when
// the label takes the whole axis; a segment without one is a track as long as
// its content, which is its inset. The label's track is always its content.
const _kShare = 'minmax(0, 1fr)';
const _kContent = 'auto';
const _kLineClass = 'bg-outline-variant';

/// The tracks of a labelled divider's wrapper for [leading] / [trailing]
/// segment tracks, label between.
String _tracks(String leading, String trailing) =>
    '$leading $_kContent $trailing';

/// Renders [divider] through the server pipeline and returns the labelled
/// wrapper: its `class` attribute and inline declarations, and the two line
/// segments' `class` attributes in DOM order (leading, trailing).
///
/// The centred child sits between them, so indices 0 and 2 are the
/// segments — asserting on that shape also pins that the segments stay the
/// wrapper's own children, one per track.
Future<
  ({
    String? classes,
    Map<String, String> inline,
    String? leading,
    String? trailing,
  })
>
_wrapper(ServerTester tester, Divider divider) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: divider));
  final response = await tester.request('/');
  final root = response.document!.querySelector('#d')!;
  final children = root.children;

  expect(children, hasLength(3));
  return (
    classes: root.attributes['class'],
    inline: _declarations(root.attributes['style']),
    leading: children.first.attributes['class'],
    trailing: children.last.attributes['class'],
  );
}

const _kIndent = 24.0;
const _kEndIndent = 8.0;
const _kIndentedStyle = CoreDividerStyle(
  indent: _kIndent,
  endIndent: _kEndIndent,
);

/// The declarations of an inline `style` attribute as a property → value map.
Map<String, String> _declarations(String? raw) => {
  for (final declaration in (raw ?? '').split(';'))
    if (declaration.contains(':'))
      declaration.substring(0, declaration.indexOf(':')).trim(): declaration
          .substring(declaration.indexOf(':') + 1)
          .trim(),
};

/// Renders [divider] and returns the inline declarations of its root (`#d`)
/// and of each child, in DOM order.
Future<({Map<String, String> root, List<Map<String, String>> children})>
_inline(
  ServerTester tester,
  Divider divider,
) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: divider));
  final response = await tester.request('/');
  final root = response.document!.querySelector('#d')!;

  return (
    root: _declarations(root.attributes['style']),
    children: [
      for (final child in root.children)
        _declarations(child.attributes['style']),
    ],
  );
}

/// Renders [divider] and returns its root's `class` attribute and inline
/// declarations — the two places the line's length can be stated.
Future<({String? classes, Map<String, String> inline})> _rootLine(
  ServerTester tester,
  Divider divider,
) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: divider));
  final response = await tester.request('/');
  final root = response.document!.querySelector('#d')!;

  return (
    classes: root.attributes['class'],
    inline: _declarations(root.attributes['style']),
  );
}

void main() {
  group('Divider childAlignment (#4200)', () {
    testServer('unspecified shares the room around the label equally', (
      tester,
    ) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(id: 'd', child: Text('OR')),
      );

      // Where the pixels end up — the label at the centre of the box — is
      // pinned by the Chrome probe and the parity captures; this pins the
      // weights the template is built from.
      expect(
        wrapper.inline['grid-template-columns'],
        _tracks(_kShare, _kShare),
      );
      expect(wrapper.leading, _kLineClass);
      expect(wrapper.trailing, _kLineClass);
    });

    testServer('explicit center matches the unspecified render', (
      tester,
    ) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: CoreDividerStyle(childAlignment: .center),
          child: Text('OR'),
        ),
      );

      expect(
        wrapper.inline['grid-template-columns'],
        _tracks(_kShare, _kShare),
      );
      expect(wrapper.leading, _kLineClass);
      expect(wrapper.trailing, _kLineClass);
    });

    testServer('start collapses the leading segment only', (tester) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: CoreDividerStyle(childAlignment: .start),
          child: Text('OR'),
        ),
      );

      expect(
        wrapper.inline['grid-template-columns'],
        _tracks(_kContent, _kShare),
      );
      expect(wrapper.leading, _kLineClass);
      expect(wrapper.trailing, _kLineClass);
    });

    testServer('end collapses the trailing segment only', (tester) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: CoreDividerStyle(childAlignment: .end),
          child: Text('OR'),
        ),
      );

      expect(
        wrapper.inline['grid-template-columns'],
        _tracks(_kShare, _kContent),
      );
      expect(wrapper.leading, _kLineClass);
      expect(wrapper.trailing, _kLineClass);
    });

    testServer('a vertical divider emits the same weights along its rows', (
      tester,
    ) async {
      // Orientation moves the template to the rows and the thickness to the
      // width; it must not reach the weights, or `start` would mean two
      // different things depending on which way the rule runs.
      final wrapper = await _wrapper(
        tester,
        const Divider(
          id: 'd',
          orientation: .vertical,
          dividerStyle: CoreDividerStyle(childAlignment: .start),
          child: Text('OR'),
        ),
      );

      expect(
        wrapper.inline['grid-template-rows'],
        _tracks(_kContent, _kShare),
      );
      expect(wrapper.inline, isNot(contains('grid-template-columns')));
      expect(wrapper.leading, _kLineClass);
      expect(wrapper.trailing, _kLineClass);
    });

    testServer('a raw colour override leaves the segments classless', (
      tester,
    ) async {
      // A non-token colour goes inline, leaving the colour class empty —
      // the segments carry no sizing class of their own, so there is no
      // `class` attribute at all and nothing to dangle.
      final wrapper = await _wrapper(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: CoreDividerStyle(
            color: CoreColor(0xFFFF0000),
            childAlignment: .start,
          ),
          child: Text('OR'),
        ),
      );

      expect(
        wrapper.inline['grid-template-columns'],
        _tracks(_kContent, _kShare),
      );
      expect(wrapper.leading, isNull);
      expect(wrapper.trailing, isNull);
    });

    testServer('a childless divider is untouched by the axis', (tester) async {
      // No child means no segments to weight; the single line still
      // fills its axis rather than becoming a grid.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Divider(
            id: 'd',
            dividerStyle: CoreDividerStyle(childAlignment: .start),
          ),
        ),
      );
      final response = await tester.request('/');
      final node = response.document?.querySelector('#d');

      expect(node!.attributes['class'], 'shrink-0 w-full bg-outline-variant');
      expect(node.children, isEmpty);
    });
  });

  group('Divider indent / endIndent are logical', () {
    // The margins are the reading-direction sides of the line, so they ride
    // the CSS logical properties and follow `dir` — `margin-left` would pin
    // them to the physical left whatever the document's direction. The
    // browser does the mirroring; what a test can check is that the
    // declaration names the logical side and no physical one.
    testServer('a horizontal line margins its inline start and end', (
      tester,
    ) async {
      final inline = (await _inline(
        tester,
        const Divider(id: 'd', dividerStyle: _kIndentedStyle),
      )).root;

      expect(inline['margin-inline-start'], spaceCss(_kIndent));
      expect(inline['margin-inline-end'], spaceCss(_kEndIndent));
      expect(inline, isNot(contains('margin-left')));
      expect(inline, isNot(contains('margin-right')));
    });

    testServer('a labelled divider indents the leading segment at its start '
        'and the trailing one at its end', (tester) async {
      final rendered = await _inline(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: _kIndentedStyle,
          child: Text('OR'),
        ),
      );
      // [leading line, label wrapper, trailing line] — the flex row mirrors
      // under `dir="rtl"`, so the first segment is the start-side one.
      final leading = rendered.children.first;
      final trailing = rendered.children.last;

      expect(leading['margin-inline-start'], spaceCss(_kIndent));
      expect(leading, isNot(contains('margin-inline-end')));
      expect(trailing['margin-inline-end'], spaceCss(_kEndIndent));
      expect(trailing, isNot(contains('margin-inline-start')));
      for (final side in [leading, trailing]) {
        expect(side, isNot(contains('margin-left')));
        expect(side, isNot(contains('margin-right')));
      }
    });

    testServer('a vertical line keeps top and bottom — they are not reading '
        'sides', (tester) async {
      final inline = (await _inline(
        tester,
        const Divider(
          id: 'd',
          orientation: .vertical,
          dividerStyle: _kIndentedStyle,
        ),
      )).root;

      expect(inline['margin-top'], spaceCss(_kIndent));
      expect(inline['margin-bottom'], spaceCss(_kEndIndent));
      expect(inline, isNot(contains('margin-inline-start')));
      expect(inline, isNot(contains('margin-inline-end')));
    });

    testServer('an unindented line states the logical pair too — the side it '
        'names does not depend on the value', (tester) async {
      final inline = (await _inline(tester, const Divider(id: 'd'))).root;

      // A zero indent still emits its declaration, so a regression back to a
      // physical property fails here even when nobody passed an indent.
      expect(inline.keys.where((k) => k.startsWith('margin')), [
        'margin-inline-start',
        'margin-inline-end',
      ]);
    });
  });

  group('An inset line is shortened by its insets', () {
    // `width: 100%` plus the margins is the container plus the insets: the
    // line would start inside the box and run out past its far edge, where
    // Flutter's line is `width - indent - endIndent` long. An inset line
    // states its length itself and gives up the fill class — one declaration
    // of the length, never both.
    testServer('a horizontal line is the container less both insets', (
      tester,
    ) async {
      final line = await _rootLine(
        tester,
        const Divider(id: 'd', dividerStyle: _kIndentedStyle),
      );

      expect(
        line.inline['width'],
        'calc(100% - ${spaceCss(_kIndent)} - ${spaceCss(_kEndIndent)})',
      );
      expect(line.classes, 'shrink-0 bg-outline-variant');
    });

    testServer('a vertical line is the container less both insets along its '
        'height', (tester) async {
      final line = await _rootLine(
        tester,
        const Divider(
          id: 'd',
          orientation: .vertical,
          dividerStyle: _kIndentedStyle,
        ),
      );

      expect(
        line.inline['height'],
        'calc(100% - ${spaceCss(_kIndent)} - ${spaceCss(_kEndIndent)})',
      );
      // The cross axis is the stroke, as it always was.
      expect(
        line.inline['width'],
        strokeWidthCss(CoreDividerStyle.defaultThickness),
      );
      expect(line.classes, 'shrink-0 bg-outline-variant');
    });

    testServer('an inset at one end alone shortens it by that inset', (
      tester,
    ) async {
      final line = await _rootLine(
        tester,
        const Divider(id: 'd', dividerStyle: CoreDividerStyle(indent: 24)),
      );

      expect(
        line.inline['width'],
        'calc(100% - ${spaceCss(24)} - ${spaceCss(0)})',
      );
      expect(line.classes, 'shrink-0 bg-outline-variant');
    });

    testServer('a line with no inset keeps the fill class and states no '
        'length', (tester) async {
      final horizontal = await _rootLine(tester, const Divider(id: 'd'));
      final vertical = await _rootLine(
        tester,
        const Divider(id: 'd', orientation: .vertical),
      );

      expect(horizontal.classes, 'shrink-0 w-full bg-outline-variant');
      expect(horizontal.inline, isNot(contains('width')));
      expect(vertical.classes, 'shrink-0 h-full bg-outline-variant');
      expect(vertical.inline, isNot(contains('height')));
    });

    testServer('the segments of a labelled divider are grid items and state '
        'no length', (tester) async {
      // A grid item stretches across its track less its margins, so the
      // segments need no subtraction and fill what their track gives them.
      final rendered = await _inline(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: _kIndentedStyle,
          child: Text('OR'),
        ),
      );

      for (final segment in [rendered.children.first, rendered.children.last]) {
        expect(segment, isNot(contains('width')));
      }
    });
  });

  group('A labelled divider holds each inset inside its segment', () {
    // The inset is the line's margin and the line is a grid item, so the
    // margin lies inside the item's track: the tracks beside the label split
    // what it leaves by their weights whatever the insets are, and an inset
    // only shortens its line. A margin on a flex item would instead come out
    // of the space the segments share, which moves the label off the centre
    // of the box by half the difference between the two insets.
    //
    // Where the label and the lines land is measured in Chrome against the
    // shared vector table (`divider_label_position_probe_test.dart`); this
    // group reads the same table and pins the markup each row is built from.
    final doc =
        jsonDecode(File(_kLabelVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    // The tracks each alignment is built from, spelled out here so that a
    // change to the mapping fails a test instead of following the code.
    final trackTemplates = {
      'center': _tracks(_kShare, _kShare),
      'start': _tracks(_kContent, _kShare),
      'end': _tracks(_kShare, _kContent),
    };

    test('every alignment of the table has a template here', () {
      expect(
        {for (final c in cases) c['alignment']! as String},
        trackTemplates.keys.toSet(),
      );
      expect(
        CoreDividerChildAlignment.values.map((alignment) => alignment.name),
        containsAll(trackTemplates.keys),
      );
    });

    for (final c in cases) {
      final horizontal = c['orientation'] == 'horizontal';
      final indent = (c['indent']! as num).toDouble();
      final endIndent = (c['endIndent']! as num).toDouble();
      final childPadding = (c['childPadding']! as num).toDouble();

      testServer('${c['name']}: the insets ride the segments as margins and '
          'the label carries its padding', (tester) async {
        final rendered = await _inline(
          tester,
          Divider(
            id: 'd',
            orientation: horizontal ? .horizontal : .vertical,
            dividerStyle: CoreDividerStyle(
              indent: indent,
              endIndent: endIndent,
              childAlignment: CoreDividerChildAlignment.values.byName(
                c['alignment']! as String,
              ),
              childPadding: CoreEdgeInsets.symmetric(
                horizontal: childPadding,
              ),
            ),
            child: const Text('OR'),
          ),
        );
        final leading = rendered.children.first;
        final label = rendered.children[1];
        final trailing = rendered.children.last;

        expect(
          rendered.root[horizontal
              ? 'grid-template-columns'
              : 'grid-template-rows'],
          trackTemplates[c['alignment']],
        );

        // Each inset rides its own segment, on the side that faces the edge
        // of the box, and nothing else on either segment states the main
        // axis: its track does.
        expect(
          leading[horizontal ? 'margin-inline-start' : 'margin-top'],
          spaceCss(indent),
        );
        expect(
          trailing[horizontal ? 'margin-inline-end' : 'margin-bottom'],
          spaceCss(endIndent),
        );
        final mainAxisMargins = horizontal
            ? const ['margin-inline-end', 'margin-left', 'margin-right']
            : const ['margin-bottom', 'margin-left', 'margin-right'];
        expect(
          leading.keys.where(mainAxisMargins.contains),
          isEmpty,
          reason: 'the leading segment carries the start inset only',
        );
        expect(
          trailing.keys.where(
            (property) =>
                property.startsWith('margin') &&
                property !=
                    (horizontal ? 'margin-inline-end' : 'margin-bottom'),
          ),
          isEmpty,
          reason: 'the trailing segment carries the end inset only',
        );
        for (final segment in [leading, trailing]) {
          expect(
            segment,
            isNot(contains(horizontal ? 'width' : 'height')),
            reason: 'the track states the length along the axis',
          );
          expect(
            segment.keys.where((property) => property.startsWith('flex')),
            isEmpty,
            reason: 'a flex weight on a grid item would do nothing',
          );
        }

        // The label keeps its padding along the axis, and no margin: a
        // margin on it would be a second place for an inset to hide.
        final padding = spaceCss(childPadding);
        expect(label[horizontal ? 'padding-left' : 'padding-top'], padding);
        expect(label[horizontal ? 'padding-right' : 'padding-bottom'], padding);
        expect(
          label.keys.where((property) => property.startsWith('margin')),
          isEmpty,
        );
      });
    }

    testServer('a horizontal wrapper is a grid centred across the axis, not '
        'a flex row', (tester) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(id: 'd', child: Text('OR')),
      );

      // Whole-class: `flex` anywhere would bring the margins back into the
      // space the segments share.
      expect(wrapper.classes, 'grid w-full items-center');
    });

    testServer('a vertical wrapper is a grid centred across the axis, not '
        'a flex column', (tester) async {
      final wrapper = await _wrapper(
        tester,
        const Divider(id: 'd', orientation: .vertical, child: Text('OR')),
      );

      expect(wrapper.classes, 'grid justify-items-center h-full');
    });
  });

  group('An unlabelled divider is one element that is the line itself', () {
    // The labelled wrapper is not part of it: the root carries the line's own
    // chrome. Whole strings, not substrings, so that any difference at all
    // fails.
    final stroke = strokeWidthCss(CoreDividerStyle.defaultThickness);
    final none = spaceCss(CoreDividerStyle.defaultIndent);

    testServer('plain', (tester) async {
      final line = await _rootLine(tester, const Divider(id: 'd'));

      expect(line.classes, 'shrink-0 w-full bg-outline-variant');
      expect(line.inline, {
        'height': stroke,
        'margin-inline-start': none,
        'margin-inline-end': none,
      });
    });

    testServer('inset', (tester) async {
      final line = await _rootLine(
        tester,
        const Divider(id: 'd', dividerStyle: _kIndentedStyle),
      );

      expect(line.classes, 'shrink-0 bg-outline-variant');
      expect(line.inline, {
        'height': stroke,
        'width':
            'calc(100% - ${spaceCss(_kIndent)} - ${spaceCss(_kEndIndent)})',
        'margin-inline-start': spaceCss(_kIndent),
        'margin-inline-end': spaceCss(_kEndIndent),
      });
    });

    testServer('vertical', (tester) async {
      final line = await _rootLine(
        tester,
        const Divider(id: 'd', orientation: .vertical),
      );

      expect(line.classes, 'shrink-0 h-full bg-outline-variant');
      expect(line.inline, {
        'width': stroke,
        'margin-top': none,
        'margin-bottom': none,
      });
    });

    testServer('raw colour', (tester) async {
      final line = await _rootLine(
        tester,
        const Divider(
          id: 'd',
          dividerStyle: CoreDividerStyle(color: CoreColor(0xFFFF0000)),
        ),
      );

      expect(line.classes, 'shrink-0 w-full');
      expect(line.inline, {
        'height': stroke,
        'background-color': 'rgb(255, 0, 0)',
        'margin-inline-start': none,
        'margin-inline-end': none,
      });
    });
  });

  group('Divider semantic separator (#3497)', () {
    testServer(
      'decorative (default) divider carries no role or aria-label',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: const Divider(id: 'd'),
          ),
        );
        final response = await tester.request('/');
        final node = response.document?.querySelector('#d');

        expect(node, isNotNull);
        expect(node!.attributes.containsKey('role'), isFalse);
        expect(node.attributes.containsKey('aria-label'), isFalse);
      },
    );

    testServer(
      'semantic: true exposes role="separator" and an aria-label',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: const Divider(id: 'd', semantic: true),
          ),
        );
        final response = await tester.request('/');
        final node = response.document?.querySelector('#d');

        expect(node, isNotNull);
        expect(node!.attributes['role'], 'separator');
        expect(node.attributes['aria-label'], isNotEmpty);
      },
    );
  });
}
