// A surface that keeps a border says how wide it is (`--coui-surface-bleed`),
// so the material's edge band reaches the outside of the border instead of
// sitting one border inside it — where the Flutter twin's sheen, painted over
// the whole box, is already drawn.
//
// The invariant is one line per component: the element that carries the
// surface marker and draws the border also publishes the width, and the value
// is that border's. Hosts that clip their own content are not in this list —
// the clip stops at the padding box, so a variable there would make the band
// vanish rather than reach the edge.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Every element the widget rendered that carries the surface marker.
List<DomComponent> _surfaces() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((d) => (d.classes ?? '').split(' ').contains(kWebSurfaceMarker))
    .toList();

/// The width a surface publishes, or null when it publishes none.
String? _bleedOf(DomComponent d) => d.styles?.properties[kWebSurfaceBleedVar];

const _kFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
];

void main() {
  group('a surface with a border publishes its width', () {
    testComponents('an outline button says the width its border-width states', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(
          variant: CoreButtonVariant.outline,
          child: const Component.text('x'),
        ),
      );

      final surfaces = _surfaces();
      expect(surfaces, hasLength(1));
      final inline = surfaces.single.styles!.properties;
      expect(inline[kWebSurfaceBleedVar], inline['border-width']);
      expect(inline['border-width'], isNot(strokeWidthCss(0)));
    });

    testComponents('a ghost button has no border to say', (tester) async {
      pumpWithTheme(
        tester,
        Button(
          variant: CoreButtonVariant.ghost,
          child: const Component.text('x'),
        ),
      );

      // Either not a surface at all, or a surface that keeps no line.
      for (final d in _surfaces()) {
        final width = d.styles?.properties['border-width'];
        if (width == null || width == strokeWidthCss(0)) {
          expect(_bleedOf(d) ?? strokeWidthCss(0), strokeWidthCss(0));
        }
      }
    });

    testComponents('a key cap says its hairline', (tester) async {
      pumpWithTheme(tester, const Kbd(keys: ['Esc']));

      final caps = _surfaces();
      expect(caps, isNotEmpty);
      for (final cap in caps) {
        expect(
          _bleedOf(cap),
          cap.styles!.properties['border-width'],
          reason: 'a key cap is the surface, the row is layout',
        );
      }
    });

    testComponents('a tag says its line', (tester) async {
      pumpWithTheme(tester, const Tag(child: Component.text('Design')));

      final tags = _surfaces();
      expect(tags, hasLength(1));
      expect(
        _bleedOf(tags.single),
        tags.single.styles!.properties['border-width'],
      );
    });

    testComponents('a checkbox at rest says the line of its box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Checkbox(onChanged: (_) {}, size: CoreComponentSize.xs),
      );

      final boxes = _surfaces();
      expect(boxes, hasLength(1));
      expect(
        _bleedOf(boxes.single),
        strokeWidthCss(CoreCheckboxStyle.defaultBoxBorderWidth),
      );
    });

    testComponents('an object input says the line of its box', (tester) async {
      pumpWithTheme(tester, const ObjectInput(fields: _kFields));

      final boxes = _surfaces();
      expect(boxes, hasLength(1));
      expect(
        _bleedOf(boxes.single),
        boxes.single.styles!.properties['border-width'],
      );
    });

    testComponents('an item picker says the line of its panel', (tester) async {
      pumpWithTheme(tester, const ItemPicker(items: ['a']));

      final panels = _surfaces();
      expect(panels, isNotEmpty);
      expect(
        _bleedOf(panels.first),
        panels.first.styles!.properties['border-width'],
      );
    });

    testComponents('a multi answer card says the line of its box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MultiAnswerCard(
          value: 'a',
          selected: true,
          child: Text('Option'),
        ),
      );

      final cards = _surfaces();
      expect(cards, isNotEmpty);
      for (final card in cards) {
        expect(
          _bleedOf(card),
          card.styles!.properties['border-width'],
        );
      }
    });

    testComponents('a menubar says the line of its bar', (tester) async {
      pumpWithTheme(
        tester,
        const Menubar(menus: [CoreMenubarMenu(label: 'File')]),
      );

      final bars = _surfaces();
      expect(bars, hasLength(1));
      expect(
        _bleedOf(bars.single),
        bars.single.styles!.properties['border-width'],
      );
    });

    testComponents(
      'a bottom action bar says its top hairline on the top edge',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          BottomActionBar(
            primaryAction: Button(child: const Component.text('x')),
          ),
        );

        final bars = _surfaces()
            .where((d) => d.styles?.properties[kWebSurfaceBleedTopVar] != null)
            .toList();
        expect(bars, hasLength(1));
        final inline = bars.single.styles!.properties;
        expect(inline[kWebSurfaceBleedTopVar], inline['border-top-width']);
        // Only the top has a line to reach over — the uniform width is never
        // stated, so the other three edges keep the box's own.
        expect(inline.containsKey(kWebSurfaceBleedVar), isFalse);
      },
    );

    testComponents('a bottom action bar without its hairline says nothing', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        BottomActionBar(
          showDivider: false,
          primaryAction: Button(child: const Component.text('x')),
        ),
      );

      for (final d in _surfaces()) {
        expect(
          d.styles?.properties.containsKey(kWebSurfaceBleedTopVar),
          isFalse,
        );
      }
    });

    testComponents(
      'a dock says its line, on every edge, at the width it states',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const Dock(
            dockStyle: CoreDockStyle(borderWidth: 3),
            items: [
              CoreDockItemData<Component>(
                label: 'Home',
                icon: Icon(LucideIcons.house),
              ),
            ],
          ),
        );

        final bars = _surfaces()
            .where((d) => d.styles?.properties[kWebSurfaceBleedVar] != null)
            .toList();
        expect(bars, hasLength(1));
        final inline = bars.single.styles!.properties;
        expect(inline[kWebSurfaceBleedVar], strokeWidthCss(3));
        expect(inline['border-width'], strokeWidthCss(3));
        // The line is on every edge, so no single edge is stated.
        expect(inline.containsKey(kWebSurfaceBleedTopVar), isFalse);
      },
    );

    testComponents('a floating dock keeps its line and says it', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Dock(
          dockStyle: CoreDockStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [
            CoreDockItemData<Component>(
              label: 'Home',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      final bars = _surfaces()
          .where((d) => d.styles?.properties[kWebSurfaceBleedVar] != null)
          .toList();
      expect(bars, hasLength(1));
      for (final d in _surfaces()) {
        expect(
          d.styles?.properties.containsKey(kWebSurfaceBleedTopVar),
          isFalse,
        );
        expect(d.styles?.properties.containsKey('border-top-width'), isFalse);
      }
    });

    testComponents(
      'a banner says the rule it closes with, on its bottom edge',
      (
        tester,
      ) async {
        pumpWithTheme(tester, Banner(message: const Component.text('Message')));

        final banners = _surfaces()
            .where((d) => d.styles?.properties['border-bottom-width'] != null)
            .toList();
        expect(banners, hasLength(1));
        final inline = banners.single.styles!.properties;
        expect(
          inline[kWebSurfaceBleedBottomVar],
          inline['border-bottom-width'],
        );
        // Only the bottom edge keeps a line, so only the bottom edge is stated.
        expect(inline.containsKey(kWebSurfaceBleedVar), isFalse);
        expect(inline.containsKey(kWebSurfaceBleedTopVar), isFalse);
      },
    );

    testComponents('a banner that states no rule says nothing', (tester) async {
      for (final emphasis in CoreBannerEmphasis.values) {
        pumpWithTheme(
          tester,
          Banner(
            message: const Component.text('Message'),
            emphasis: emphasis,
          ),
        );

        for (final d in _surfaces()) {
          final inline = d.styles?.properties ?? const <String, String>{};
          expect(
            inline.containsKey(kWebSurfaceBleedBottomVar),
            inline.containsKey('border-bottom-width'),
            reason: '${emphasis.name}: the rule and its bleed go together',
          );
        }
      }
    });

    testComponents('a header says its hairline on its bottom edge', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Scaffold(
          headers: [AppBar(title: Text('Title'))],
          child: Text('Body'),
        ),
      );

      final headers = _surfaces()
          .where((d) => d.styles?.properties[kWebSurfaceBleedBottomVar] != null)
          .toList();
      expect(headers, hasLength(1));
      final inline = headers.single.styles!.properties;
      expect(inline[kWebSurfaceBleedBottomVar], inline['border-bottom-width']);
      expect(inline.containsKey(kWebSurfaceBleedVar), isFalse);
    });

    testComponents('a boxed tab pane says the border of its card', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TabPane(
          tabs: const [CoreTabItem<Component>(label: 'One')],
          selectedIndex: 0,
          onChanged: (index) {},
        ),
      );

      final cards = _surfaces()
          .where((d) => d.styles?.properties[kWebSurfaceBleedVar] != null)
          .toList();
      expect(cards, hasLength(1));
      final inline = cards.single.styles!.properties;
      expect(inline[kWebSurfaceBleedVar], inline['border-width']);
    });

    testComponents('a bar with no border draws no box and says nothing', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Menubar(border: false, menus: [CoreMenubarMenu(label: 'File')]),
      );

      expect(_surfaces(), isEmpty);
    });

    testComponents('an upcoming step indicator says the line of its ring', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Steps(
          items: [
            CoreStepData(title: 'a'),
            CoreStepData(title: 'b'),
          ],
        ),
      );

      final rings = _surfaces().where(
        (d) => d.styles?.properties['border-width'] != null,
      );
      expect(rings, isNotEmpty);
      for (final ring in rings) {
        expect(_bleedOf(ring), ring.styles!.properties['border-width']);
      }
    });
  });
}
