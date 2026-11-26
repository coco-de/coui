// The radio item's description line and the `card` variant's tile, read off
// the markup the Web twin renders — the same claims the Flutter test reads
// off its widget tree.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/radio_group/radio_group.dart';
import 'package:coui_web/src/components/form/radio_group/radio_group_style.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show RawText, div;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

String _bg(CoreColor color) => 'bg-${color.tailwindColor}';
String _border(CoreColor color) => 'border-${color.tailwindColor}';
String _ink(CoreColor color) => 'text-${color.tailwindColor}';

Set<String> _classSet(DomComponent dom) => (dom.classes ?? '')
    .split(RegExp(r'\s+'))
    .where((c) => c.isNotEmpty)
    .toSet();

List<DomComponent> _doms(bool Function(DomComponent dom) test) => [
  for (final element
      in find
          .byComponentPredicate((c) => c is DomComponent && test(c))
          .evaluate())
    element.component as DomComponent,
];

/// The `<label>` roots, in option order.
List<DomComponent> _labels() => _doms((dom) => dom.tag == 'label');

/// The element whose classes say it is the description line.
DomComponent _descriptionSpan(String role) => _doms(
  (dom) => dom.tag == 'span' && _classSet(dom).contains('text-$role'),
).single;

/// Every halo / state layer — the elements the scoped rules raise.
List<DomComponent> _layers() =>
    _doms((dom) => _classSet(dom).contains(kRadioHaloMarker));

List<Gap> _gaps() => [
  for (final element in find.byType(Gap).evaluate()) element.component as Gap,
];

Component _card({
  String? groupValue = 'a',
  CoreComponentSize size = CoreComponentSize.md,
  bool enabled = true,
}) => Radio(
  value: 'a',
  groupValue: groupValue,
  label: 'Alpha',
  description: 'First choice',
  enabled: enabled,
  groupVariant: CoreRadioGroupVariant.card,
  groupSize: size,
  onChanged: (_) {},
);

void main() {
  for (final enabled in [true, false]) {
    testComponents(
      'explicit selected padding uses selected border in flow $enabled',
      (tester) async {
        const selectedPadding = CoreEdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        );
        pumpWithTheme(
          tester,
          RadioGroup(
            value: 'a',
            enabled: enabled,
            onChanged: (_) {},
            variant: CoreRadioGroupVariant.card,
            radioGroupStyle: const CoreRadioGroupStyle(
              tilePadding: CoreEdgeInsets.all(8),
              tileSelectedPadding: selectedPadding,
              tileSelectedBorderWidth: 1.5,
            ),
            options: const [
              (value: 'a', label: 'Alpha'),
              (value: 'b', label: 'Beta'),
            ],
          ),
        );
        await tester.pump();
        final labels = _labels();
        expect(
          labels.first.styles!.properties['padding'],
          selectedPadding.toValue(),
        );
        expect(
          labels.first.styles!.properties['border-width'],
          strokeWidthCss(1.5),
        );
        expect(labels.first.styles!.properties['box-shadow'], isNull);
        expect(
          labels.last.styles!.properties['padding'],
          const CoreEdgeInsets.all(8).toValue(),
        );
        expect(
          labels.last.styles!.properties['border-width'],
          strokeWidthCss(1),
        );
      },
    );
  }
  group('description', () {
    testComponents('stacks under the label in its own role and foreground', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Radio(
          value: 'a',
          groupValue: 'a',
          label: 'Alpha',
          description: 'Supporting line',
          onChanged: (_) {},
        ),
      );
      await tester.pump();

      expect(find.text('Supporting line'), findsOneComponent);
      final root = _labels().single;
      // Top-aligned once there are two lines.
      expect(_classSet(root), containsAll(['inline-flex', 'items-start']));
      expect(_classSet(root), isNot(contains('items-center')));

      final column = _doms(
        (dom) => dom.tag == 'span' && _classSet(dom).contains('flex-col'),
      ).single;
      expect(
        _classSet(column),
        containsAll(['flex', 'items-start', 'min-w-0']),
      );
      // `md` — body-small, the quieter foreground.
      final description = _descriptionSpan('body-small');
      expect(
        _classSet(description),
        contains(_ink(CoreRadioGroupStyle.defaultDescriptionStyle.color!)),
      );
      // The label↔description gap is Checkbox's 2, an explicit `Gap`.
      expect(
        _gaps().where((g) => g.gapStyle?.size == CoreSpace.space2),
        hasLength(1),
      );
    });

    testComponents('the description role follows the size ladder', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Radio(
          value: 'a',
          label: 'A',
          description: 'D',
          groupSize: CoreComponentSize.lg,
        ),
      );
      await tester.pump();
      expect(_descriptionSpan('body-medium'), isNotNull);
    });

    testComponents('the description role at xs is body-xs', (tester) async {
      pumpWithTheme(
        tester,
        const Radio(
          value: 'a',
          label: 'A',
          description: 'D',
          groupSize: CoreComponentSize.xs,
        ),
      );
      await tester.pump();
      expect(_descriptionSpan('body-xs'), isNotNull);
    });

    testComponents('a disabled description dims with the label', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Radio(value: 'a', label: 'A', description: 'D', enabled: false),
      );
      await tester.pump();

      expect(
        _classSet(_descriptionSpan('body-small')),
        contains('text-disabled-content'),
      );
      expect(_classSet(_labels().single), contains('text-disabled-content'));
    });

    testComponents('a suffix with no label fills the label slot — over '
        'the description, 2 px above it, not beside the column', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Radio(
          value: 'a',
          groupValue: 'a',
          description: 'Supporting line',
          suffix: const Component.element(tag: 'i', classes: 'test-suffix'),
          onChanged: (_) {},
        ),
      );
      await tester.pump();

      final suffix = _doms((dom) => dom.tag == 'i').single;
      final column = _doms(
        (dom) => dom.tag == 'span' && _classSet(dom).contains('flex-col'),
      ).single;
      final children = column.children!;
      expect(children, hasLength(3));
      expect(children[0], same(suffix));
      expect(children[1], isA<Gap>());
      expect((children[1] as Gap).gapStyle?.size, CoreSpace.space2);
      // Not a sibling of the column in the row.
      expect(_labels().single.children, isNot(contains(suffix)));
    });

    testComponents("a label and a suffix share the label slot's row, over "
        'the description', (tester) async {
      pumpWithTheme(
        tester,
        Radio(
          value: 'a',
          groupValue: 'a',
          label: 'Alpha',
          description: 'Supporting line',
          suffix: const Component.element(tag: 'i', classes: 'test-suffix'),
          onChanged: (_) {},
        ),
      );
      await tester.pump();

      final suffix = _doms((dom) => dom.tag == 'i').single;
      final column = _doms(
        (dom) => dom.tag == 'span' && _classSet(dom).contains('flex-col'),
      ).single;
      final children = column.children!;
      expect(children, hasLength(3));
      final line = children[0] as DomComponent;
      expect(_classSet(line), containsAll(['flex', 'items-center', 'min-w-0']));
      expect(line.children, hasLength(2));
      expect(line.children!.last, same(suffix));
      expect(children[1], isA<Gap>());
      expect((children[1] as Gap).gapStyle?.size, CoreSpace.space2);
      expect(_labels().single.children, isNot(contains(suffix)));
    });

    testComponents('without a description the suffix stays a row sibling', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Radio(
          value: 'a',
          groupValue: 'a',
          label: 'Alpha',
          suffix: const Component.element(tag: 'i', classes: 'test-suffix'),
          onChanged: (_) {},
        ),
      );
      await tester.pump();

      final suffix = _doms((dom) => dom.tag == 'i').single;
      expect(_labels().single.children, contains(suffix));
      expect(_doms((dom) => _classSet(dom).contains('flex-col')), isEmpty);
    });

    testComponents('a row without a description keeps its markup', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Radio(value: 'a', groupValue: 'a', label: 'A', onChanged: (_) {}),
      );
      await tester.pump();

      final root = _labels().single;
      expect(root.classes, startsWith('inline-flex items-center '));
      expect(_classSet(root), isNot(contains('overflow-hidden')));
      expect(
        _doms((dom) => _classSet(dom).contains('flex-col')),
        isEmpty,
      );
      // Still the halo around the circle and the circular ring.
      expect(_layers(), hasLength(1));
      final outline =
          find.byType(FocusOutline).evaluate().single.component as FocusOutline;
      expect(outline.shape, CoreFocusOutlineShape.circle);
    });
  });

  group('card', () {
    testComponents('the root is the tile — padding, corner, the resting '
        'width in flow, the selected face and border', (tester) async {
      pumpWithTheme(tester, _card());
      await tester.pump();

      final tile = _labels().single;
      final classes = _classSet(tile);
      expect(classes, containsAll(['flex', 'relative', 'overflow-hidden']));
      expect(
        classes,
        containsAll([
          _bg(CoreRadioGroupStyle.defaultTileSelectedBackgroundColor),
          _border(CoreRadioGroupStyle.defaultTileSelectedBorderColor),
        ]),
      );
      // An enabled tile is a component surface, like the ring.
      expect(
        classes,
        containsAll(webSurfaceMarkerFor(CoreSurfaceRole.content)),
      );
      expect(classes, contains(kControlShadowRestMarker));

      final styles = tile.styles!.properties;
      expect(
        styles['padding'],
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space10,
          horizontal: CoreSpace.space12,
        ).toValue(),
      );
      expect(
        styles['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius10).toValue(),
      );
      expect(
        styles['border-width'],
        strokeWidthCss(CoreRadioGroupStyle.defaultTileBorderWidth),
      );
      expect(styles['border-style'], 'solid');
      // The selected stroke's extra width is painted inward as an inset
      // shadow in the border's colour — no layout, so nothing shifts — ahead
      // of the cast the style contributes.
      expect(
        styles['box-shadow'],
        'inset 0 0 0 calc('
        '${strokeWidthCss(CoreRadioGroupStyle.defaultTileSelectedBorderWidth)}'
        ' - ${strokeWidthCss(CoreRadioGroupStyle.defaultTileBorderWidth)}) '
        '${CoreRadioGroupStyle.defaultTileSelectedBorderColor.toValue()}, '
        '$kControlShadowVar',
      );

      // The tile's indicator — the 18 px ring.
      final circle = _doms((dom) => dom.attributes?['role'] == 'radio').single;
      expect(circle.styles!.properties['width'], '${CoreSize.size18 / 16}rem');
      expect(
        circle.styles!.properties['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke5),
      );
    });

    testComponents('an unselected tile rests on its face and hairline', (
      tester,
    ) async {
      pumpWithTheme(tester, _card(groupValue: 'b'));
      await tester.pump();

      final classes = _classSet(_labels().single);
      expect(
        classes,
        containsAll([
          _bg(CoreRadioGroupStyle.defaultTileBackgroundColor),
          _border(CoreRadioGroupStyle.defaultTileBorderColor),
        ]),
      );
      expect(
        classes,
        isNot(
          contains(_border(CoreRadioGroupStyle.defaultTileSelectedBorderColor)),
        ),
      );
      // Same in-flow width and padding as the selected tile, and no inset
      // stroke — picking a tile moves nothing.
      final styles = _labels().single.styles!.properties;
      expect(
        styles['border-width'],
        strokeWidthCss(CoreRadioGroupStyle.defaultTileBorderWidth),
      );
      expect(
        styles['padding'],
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space10,
          horizontal: CoreSpace.space12,
        ).toValue(),
      );
      expect(styles.containsKey('box-shadow'), isFalse);
    });

    testComponents('the title is label-large at md — the card role, not the '
        "size row's size", (tester) async {
      pumpWithTheme(tester, _card());
      await tester.pump();

      final tile = _labels().single;
      expect(_classSet(tile), contains('text-label-large'));
      expect(tile.styles!.properties.containsKey('font-size'), isFalse);
      expect(tile.styles!.properties.containsKey('font-weight'), isFalse);
      expect(_descriptionSpan('body-xs'), isNotNull);
    });

    testComponents("the title is label-xl at the role's weight from lg, with "
        'no size overlay', (tester) async {
      pumpWithTheme(tester, _card(size: CoreComponentSize.lg));
      await tester.pump();

      final tile = _labels().single;
      expect(_classSet(tile), contains('text-label-xl'));
      // The plain `lg` row would overlay 16 here.
      expect(tile.styles!.properties.containsKey('font-size'), isFalse);
      expect(tile.styles!.properties.containsKey('font-weight'), isFalse);
      expect(_descriptionSpan('body-small'), isNotNull);
      expect(
        tile.styles!.properties['padding'],
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space12,
          horizontal: CoreSpace.space14,
        ).toValue(),
      );
      expect(
        tile.styles!.properties['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
      );
    });

    testComponents('the state layer is the whole tile, under the row, raised '
        'by the same rules', (tester) async {
      pumpWithTheme(tester, _card());
      await tester.pump();

      // One layer — the tile's; the circle wears no halo.
      final layers = _layers();
      expect(layers, hasLength(1));
      final layer = layers.single;
      expect(_classSet(layer), containsAll(['absolute', 'inset-0']));
      expect(_classSet(layer), contains('pointer-events-none'));
      // Rests at 0 through a class — an inline `opacity` would beat the
      // scoped `:hover` rule below and the wash would never show.
      expect(_classSet(layer), contains('opacity-0'));
      expect(layer.styles?.properties.containsKey('opacity') ?? false, isFalse);
      expect(_classSet(layer), contains('bg-on-surface'));

      final tile = _labels().single;
      final children = tile.children!;
      // The layer comes before the positioned row, so the row paints over.
      final layerIndex = children.indexWhere(
        (c) => c is DomComponent && _classSet(c).contains(kRadioHaloMarker),
      );
      final bodyIndex = children.indexWhere(
        (c) =>
            c is DomComponent &&
            c.tag == 'span' &&
            _classSet(c).contains('relative'),
      );
      expect(layerIndex, isNonNegative);
      expect(bodyIndex, greaterThan(layerIndex));

      final scope = RegExp(
        'co-radio-sl-[0-9a-z]+',
      ).firstMatch(tile.classes!)?.group(0);
      expect(scope, isNotNull);
      final css =
          (find.tag('style').evaluate().single.component as DomComponent)
              .children!
              .whereType<RawText>()
              .single
              .text;
      expect(css, contains('.$scope:hover .$kRadioHaloMarker{opacity:0.08;}'));
    });

    testComponents('the focus ring goes around the tile, on its corner', (
      tester,
    ) async {
      pumpWithTheme(tester, _card());
      await tester.pump();

      final outlines = find.byType(FocusOutline).evaluate().toList();
      // One ring — around the tile, none around the circle.
      expect(outlines, hasLength(1));
      final outline = outlines.single.component as FocusOutline;
      expect(outline.shape, CoreFocusOutlineShape.rectangle);
      expect(
        outline.focusOutlineStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius10),
      );
      expect(
        outline.child,
        isA<DomComponent>().having((c) => c.tag, 'tag', 'label'),
      );
    });

    testComponents('a disabled tile keeps its face and width, takes the '
        'disabled outline, and is no surface', (tester) async {
      pumpWithTheme(tester, _card(enabled: false));
      await tester.pump();

      final classes = _classSet(_labels().single);
      expect(
        classes,
        containsAll([
          _bg(CoreRadioGroupStyle.defaultTileSelectedBackgroundColor),
          'border-disabled-outline',
        ]),
      );
      // The selected width, inset in the disabled outline's colour.
      expect(
        _labels().single.styles!.properties['box-shadow'],
        startsWith('inset 0 0 0 calc('),
      );
      expect(
        _labels().single.styles!.properties['box-shadow'],
        contains(
          const CoreColor.token(CoreColors.disabledOutline).toValue(),
        ),
      );
      expect(classes, isNot(contains(kWebSurfaceMarker)));
      expect(classes, contains('text-disabled-content'));
      expect(
        _classSet(_descriptionSpan('body-xs')),
        contains('text-disabled-content'),
      );
      // A disabled row wears no state-layer scope and ships no rule.
      expect(find.tag('style'), findsNothing);
    });

    testComponents('a row of cards keeps each tile at its own height', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          value: 'a',
          onChanged: (_) {},
          variant: CoreRadioGroupVariant.card,
          orientation: CoreRadioGroupOrientation.horizontal,
          options: const [
            (value: 'a', label: 'Alpha'),
            (value: 'b', label: 'Beta'),
          ],
        ),
      );
      await tester.pump();

      final group = _doms((dom) => dom.attributes?['role'] == 'radiogroup');
      expect(_classSet(group.single), containsAll(['flex-row', 'items-start']));
      expect(_labels(), hasLength(2));
      // Each tile carries the md row's gap to its neighbour.
      expect(
        group.single.styles?.properties['gap'],
        spaceCss(CoreSpace.space8),
      );
    });

    testComponents('a plain row of radios keeps its stretch', (tester) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          value: 'a',
          onChanged: (_) {},
          orientation: CoreRadioGroupOrientation.horizontal,
          options: const [(value: 'a', label: 'Alpha')],
        ),
      );
      await tester.pump();

      final group = _doms((dom) => dom.attributes?['role'] == 'radiogroup');
      expect(group.single.classes, 'flex flex-row flex-wrap');
    });
  });
  group('a radio passed as child reads the group', () {
    // The only way to put a description on a tile is a `child` radio, so a
    // child that ignored the group would draw a plain row at md. The
    // Flutter radio has no parameters for any of this — it reads its group.
    Component childGroup({
      String? value = 'b',
      CoreComponentSize size = CoreComponentSize.md,
      bool? enabled,
      CoreRadioGroupStyle? radioGroupStyle,
      String? name,
      CoreValueChanged<String?>? onChanged,
    }) => RadioGroup(
      value: value,
      onChanged: onChanged ?? (_) {},
      enabled: enabled,
      variant: CoreRadioGroupVariant.card,
      size: size,
      radioGroupStyle: radioGroupStyle,
      name: name,
      child: const div([
        Radio(value: 'a', label: 'Alpha', description: 'First'),
        Radio(value: 'b', label: 'Beta', description: 'Second'),
      ]),
    );

    List<DomComponent> circles() =>
        _doms((dom) => dom.attributes?['role'] == 'radio');

    testComponents('draws tiles at the group size and reads its selection', (
      tester,
    ) async {
      pumpWithTheme(tester, childGroup(size: CoreComponentSize.lg));
      await tester.pump();

      final tiles = _labels();
      expect(tiles, hasLength(2));
      for (final tile in tiles) {
        expect(
          tile.styles!.properties['padding'],
          const CoreEdgeInsets.symmetric(
            vertical: CoreSpace.space12,
            horizontal: CoreSpace.space14,
          ).toValue(),
        );
      }
      expect(
        [for (final c in circles()) c.attributes!['aria-checked']],
        ['false', 'true'],
      );
      expect(
        _classSet(tiles.last),
        contains(_bg(CoreRadioGroupStyle.defaultTileSelectedBackgroundColor)),
      );
    });

    testComponents('a pick reaches the group callback', (tester) async {
      final picked = <String?>[];
      pumpWithTheme(tester, childGroup(onChanged: picked.add));
      await tester.pump();

      await tester.click(
        find
            .byComponentPredicate(
              (c) => c is DomComponent && c.attributes?['role'] == 'radio',
            )
            .first,
      );

      expect(picked, contains('a'));
    });

    testComponents('a disabled group disables its child radios', (
      tester,
    ) async {
      pumpWithTheme(tester, childGroup(enabled: false));
      await tester.pump();

      for (final circle in circles()) {
        expect(circle.attributes!['aria-disabled'], 'true');
        expect(circle.attributes!['tabindex'], '-1');
      }
    });

    testComponents("the group's style and form name reach the tiles", (
      tester,
    ) async {
      const face = CoreColor.token(CoreColors.surfaceContainerHighest);
      pumpWithTheme(
        tester,
        childGroup(
          radioGroupStyle: const CoreRadioGroupStyle(
            tileBackgroundColor: face,
          ),
          name: 'plan',
        ),
      );
      await tester.pump();

      expect(_classSet(_labels().first), contains(_bg(face)));
      final inputs = _doms((dom) => dom.tag == 'input');
      expect(inputs, hasLength(2));
      expect(inputs.map((i) => i.attributes!['name']), everyElement('plan'));
    });
  });
}
