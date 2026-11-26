import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.element(tag: 'div', children: []);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedToggleGroup _resolve(
  BuildContext context, {
  bool enabled = true,
  CoreToggleGroupStyle? style,
  CoreComponentSize size = CoreComponentSize.md,
  CoreAxis direction = CoreAxis.horizontal,
}) => resolveToggleGroup(
  context,
  enabled: enabled,
  size: size,
  direction: direction,
  toggleGroupStyle: style,
);

const _items = [
  CoreToggleGroupItem<String, Component>(value: 'am', label: 'AM'),
  CoreToggleGroupItem<String, Component>(value: 'pm', label: 'PM'),
];

ToggleGroup<String> _group({
  String? value = 'am',
  void Function(String)? onChanged,
  bool? enabled,
  CoreToggleGroupStyle? style,
  List<CoreToggleGroupItem<String, Component>> items = _items,
}) => ToggleGroup<String>(
  items: items,
  value: value,
  onChanged: onChanged,
  enabled: enabled,
  toggleGroupStyle: style,
);

void main() {
  group('ToggleGroup resolver (Web)', () {
    testComponents('a disabled selected label keeps its chosen weight', (
      tester,
    ) async {
      final result = _resolve(
        _themedContext(tester),
        enabled: false,
        style: const CoreToggleGroupStyle(
          selectedFontWeight: 600,
          disabledLabelTextStyle: CoreTextStyle(fontWeight: 800, fontSize: 19),
        ),
      );
      expect(
        result.itemSelected.inlineStyles!.properties['font-weight'],
        '600',
      );
      expect(
        result.itemUnselected.inlineStyles!.properties['font-weight'],
        '800',
      );
      expect(
        result.itemSelected.inlineStyles!.properties['font-size'],
        '1.1875rem',
      );
      expect(result.labelGhost.inlineStyles!.properties['font-weight'], '600');
    });

    testComponents('the track is the content surface at the group fill', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));

      final classes = resolved.root.className.split(' ');
      expect(classes, contains('bg-surface-container'));
      expect(classes, isNot(contains('bg-surface-container-high')));
      final raw = resolved.root.inlineStyles!.properties;
      // The md inset is 4 on all four sides — the same emit every
      // `CoreEdgeInsets` takes.
      expect(
        raw['padding'],
        const CoreEdgeInsets.all(CoreSpace.space4).toValue(),
      );
      expect(raw['border-radius'], isNotNull);
    });

    testComponents('the chosen face is raised and carries the xs shadow', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));

      expect(resolved.itemSelected.className, contains('bg-surface-raised'));
      expect(
        resolved.itemSelected.inlineStyles!.properties['box-shadow'],
        'var(--shadow-xs)',
      );
      // An unchosen segment has no fill class and no shadow.
      expect(resolved.itemUnselected.className, isNot(contains('bg-')));
      expect(
        resolved.itemUnselected.inlineStyles!.properties.containsKey(
          'box-shadow',
        ),
        isFalse,
      );
    });

    testComponents('a disabled group is flat: disabled fills, no shadow, '
        'disabled ink for both states', (tester) async {
      final resolved = _resolve(_themedContext(tester), enabled: false);

      expect(resolved.root.className, contains('bg-disabled-container'));
      expect(
        resolved.itemSelected.className,
        contains('bg-surface-container-high'),
      );
      expect(
        resolved.itemSelected.inlineStyles!.properties['box-shadow'],
        'none',
      );
      expect(
        resolved.itemSelected.className,
        contains('text-disabled-content'),
      );
      expect(
        resolved.itemUnselected.className,
        contains('text-disabled-content'),
      );
      // The chosen label keeps its weight.
      expect(
        resolved.itemSelected.inlineStyles!.properties['font-weight'],
        '${CoreToggleGroupStyle.defaultSelectedFontWeight}',
      );
    });

    testComponents('every segment publishes the hover state layer, chosen '
        'and unchosen alike', (tester) async {
      final resolved = _resolve(_themedContext(tester));

      for (final item in [resolved.itemSelected, resolved.itemUnselected]) {
        expect(item.className.split(' '), contains(kStateLayerHoverMarker));
        expect(
          item.inlineStyles!.properties[kStateLayerHoverVar],
          'rgb(var(--coui-on-surface) / 3%)',
        );
      }
      // The face is untouched: the layer rides a background-image rule.
      expect(
        resolved.itemSelected.className,
        contains('bg-surface-raised'),
      );
    });

    testComponents('a disabled group publishes no layer', (tester) async {
      final resolved = _resolve(_themedContext(tester), enabled: false);

      for (final item in [resolved.itemSelected, resolved.itemUnselected]) {
        expect(
          item.className.split(' '),
          isNot(contains(kStateLayerHoverMarker)),
        );
        expect(
          item.inlineStyles!.properties.containsKey(kStateLayerHoverVar),
          isFalse,
        );
      }
    });

    testComponents('the layer colour and weight follow the style slots', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreToggleGroupStyle(
          stateLayerColor: CoreColor.token(CoreColors.primary),
          stateLayer: CoreStateLayer(
            hover: CoreOpacity.opacity16,
            focus: CoreOpacity.opacity16,
            pressed: CoreOpacity.opacity16,
          ),
        ),
      );

      expect(
        resolved.itemUnselected.inlineStyles!.properties[kStateLayerHoverVar],
        'rgb(var(--coui-primary) / 16%)',
      );
    });

    testComponents('a style override reaches the emitted chrome', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreToggleGroupStyle(
          selectedShadow: [],
          itemHeight: 40,
        ),
      );

      expect(
        resolved.itemSelected.inlineStyles!.properties['box-shadow'],
        'none',
      );
      expect(
        resolved.itemSelected.inlineStyles!.properties['height'],
        '${40 / kRemDivisor}rem',
      );
    });
  });

  group('ToggleGroup fillWidth (Web)', () {
    testComponents('fillWidth: a full-width flex track, cells share it', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveToggleGroup(
        context,
        enabled: true,
        fillWidth: true,
      );
      final root = resolved.root.className.split(' ');
      expect(root, containsAll(['flex', 'w-full']));
      expect(root, isNot(contains('inline-flex')));
      expect(
        resolved.root.inlineStyles!.properties['box-sizing'],
        'border-box',
      );
      expect(resolved.inner.className, contains('w-full'));
      expect(resolved.itemHost.inlineStyles!.properties['flex'], '1 1 0%');
      expect(resolved.itemSelected.className, contains('w-full'));
    });

    testComponents('the default hugs its cells and adds no host styles', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveToggleGroup(context, enabled: true);
      expect(resolved.root.className, contains('inline-flex'));
      expect(resolved.root.className, isNot(contains('w-full')));
      expect(resolved.itemHost.inlineStyles, isNull);
      expect(
        resolved.itemSelected.className,
        isNot(contains('w-full')),
      );
    });
  });

  group('ToggleGroup DOM (Web)', () {
    testComponents('is a radiogroup of radios that report the chosen one', (
      tester,
    ) async {
      pumpWithTheme(tester, _group(onChanged: (_) {}));

      final radios = find
          .byType(Clickable)
          .evaluate()
          .map((e) => e.component as Clickable)
          .toList();
      expect(radios, hasLength(2));
      expect(radios.map((r) => r.componentAttributes['role']), [
        'radio',
        'radio',
      ]);
      expect(radios.map((r) => r.componentAttributes['aria-checked']), [
        'true',
        'false',
      ]);
      expect(radios.map((r) => r.componentAttributes['aria-label']), [
        'AM',
        'PM',
      ]);
      // Roving: the chosen radio is the single tab stop.
      expect(radios.map((r) => r.componentAttributes['tabindex']), [
        '0',
        '-1',
      ]);
    });

    testComponents('a tap on a radio reports its value', (tester) async {
      String? changed;
      pumpWithTheme(tester, _group(onChanged: (v) => changed = v));

      final pm = find.byType(Clickable).evaluate().last.component as Clickable;
      pm.onPressed!();
      expect(changed, 'pm');
    });

    testComponents('the group keeps the arrow-key handler only while '
        'enabled', (tester) async {
      pumpWithTheme(tester, _group(onChanged: (_) {}));
      final root = find.tag('div').evaluate().first.component as DomComponent;
      expect(root.events, contains('keydown'));
      expect(root.attributes!['role'], 'radiogroup');
      expect(root.attributes!.containsKey('aria-disabled'), isFalse);
    });

    testComponents('without onChanged the group is inert and announced '
        'disabled', (tester) async {
      pumpWithTheme(tester, _group());

      final root = find.tag('div').evaluate().first.component as DomComponent;
      expect(root.attributes!['aria-disabled'], 'true');
      expect(root.events?.containsKey('keydown') ?? false, isFalse);
      final radios = find
          .byType(Clickable)
          .evaluate()
          .map((e) => e.component as Clickable)
          .toList();
      expect(radios.every((r) => r.onPressed == null), isTrue);
      expect(radios.every((r) => !r.enabled), isTrue);
      // No roving stop: the disabled radios take no tab stop of their own.
      expect(
        radios.every(
          (r) => r.componentAttributes['data-roving-item'] == null,
        ),
        isTrue,
      );
    });

    testComponents('enabled: false wins over onChanged', (tester) async {
      pumpWithTheme(tester, _group(onChanged: (_) {}, enabled: false));

      final pm = find.byType(Clickable).evaluate().last.component as Clickable;
      expect(pm.onPressed, isNull);
      expect(pm.enabled, isFalse);
    });

    testComponents('an icon-only segment keeps its accessible name', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _group(
          onChanged: (_) {},
          items: const [
            CoreToggleGroupItem(
              value: 'am',
              label: 'Morning',
              icon: Icon(LucideIcons.sun),
              showLabel: false,
            ),
          ],
        ),
      );

      expect(find.text('Morning'), findsNothing);
      expect(find.tag('svg'), findsOneComponent);
      final radio =
          find.byType(Clickable).evaluate().single.component as Clickable;
      expect(radio.componentAttributes['aria-label'], 'Morning');
    });

    testComponents('a label segment renders the visible label and its '
        'ghost twin', (tester) async {
      pumpWithTheme(tester, _group(onChanged: (_) {}));
      expect(find.text('AM'), findsNComponents(2));
    });

    testComponents('withStyle merges a patch', (tester) async {
      final group = _group(onChanged: (_) {})
          .withStyle(const CoreToggleGroupStyle(itemHeight: 40))
          .withStyle(const CoreToggleGroupStyle(itemSpacing: 6));
      expect(group.toggleGroupStyle!.itemHeight, 40);
      expect(group.toggleGroupStyle!.itemSpacing, 6);
    });

    testComponents('trailing renders inside the track after the last segment', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ToggleGroup<String>(
          items: _items,
          value: 'am',
          onChanged: (_) {},
          trailing: const Component.element(
            tag: 'i',
            attributes: {'data-trailing': 'yes'},
            children: [],
          ),
        ),
      );
      expect(find.tag('i'), findsOneComponent);
      expect(find.byType(Clickable), findsNComponents(2));
    });
  });

  group('ToggleGroup size (Web)', () {
    testComponents('md is the 32 cell, sm is the 26 cell', (tester) async {
      final context = _themedContext(tester);
      expect(
        _resolve(context).itemSelected.inlineStyles!.properties['height'],
        '${32 / kRemDivisor}rem',
      );
      expect(
        _resolve(
          context,
          size: CoreComponentSize.sm,
        ).itemSelected.inlineStyles!.properties['height'],
        '${26 / kRemDivisor}rem',
      );
      expect(
        _resolve(
          context,
          size: CoreComponentSize.sm,
        ).itemUnselected.inlineStyles!.properties['height'],
        '${26 / kRemDivisor}rem',
      );
    });

    testComponents('sm moves the inset, the corner and the segment inset', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final mdRoot = _resolve(context).root.inlineStyles!.properties;
      final smResolved = _resolve(context, size: CoreComponentSize.sm);
      final smRoot = smResolved.root.inlineStyles!.properties;
      const side = '${3 / kRemDivisor}rem';
      expect(smRoot['padding'], '$side $side $side $side');
      expect(
        smRoot['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius8).toValue(),
      );
      expect(
        mdRoot['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius10).toValue(),
      );
      final md = _resolve(context).itemSelected.inlineStyles!.properties;
      final sm = smResolved.itemSelected.inlineStyles!.properties;
      // The segment corner is shared; the segment inset is 2 across at md
      // and none at sm.
      expect(sm['border-radius'], md['border-radius']);
      expect(
        md['padding'],
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space2).toValue(),
      );
      expect(sm['padding'], CoreEdgeInsets.zero.toValue());
    });

    testComponents('a segment is never narrower than it is tall', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final (size, side) in [
        (CoreComponentSize.md, 32),
        (CoreComponentSize.sm, 26),
      ]) {
        final raw = _resolve(
          context,
          size: size,
        ).itemUnselected.inlineStyles!.properties;
        expect(raw['min-width'], '${side / kRemDivisor}rem');
        expect(raw['min-width'], raw['height']);
      }
    });

    testComponents('sm labels state labelMedium, md labels labelLarge', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final md = _resolve(context).itemUnselected.className;
      final sm = _resolve(
        context,
        size: CoreComponentSize.sm,
      ).itemUnselected.className;
      expect(md, contains('text-label-large'));
      expect(sm, contains('text-label-medium'));
      expect(sm, isNot(contains('text-label-large')));
    });

    testComponents('an explicit itemHeight outranks the size row', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        size: CoreComponentSize.sm,
        style: const CoreToggleGroupStyle(itemHeight: 40),
      );
      expect(
        resolved.itemSelected.inlineStyles!.properties['height'],
        '${40 / kRemDivisor}rem',
      );
    });

    testComponents('the component hands its size to the resolver', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ToggleGroup<String>(
          items: _items,
          value: 'am',
          onChanged: (_) {},
          size: CoreComponentSize.sm,
        ),
      );
      final radios = find
          .byType(Clickable)
          .evaluate()
          .map((e) => e.component as Clickable)
          .toList();
      for (final radio in radios) {
        final cell = radio.child! as DomComponent;
        expect(cell.styles!.properties['height'], '${26 / kRemDivisor}rem');
      }
    });
  });

  group('ToggleGroup direction (Web)', () {
    testComponents('horizontal (the default) keeps the centred row', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));
      expect(resolved.inner.className, contains('inline-flex'));
      expect(resolved.inner.className, isNot(contains('flex-col')));
    });

    testComponents('vertical is a stretching column with the same gap', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final h = _resolve(context);
      final v = _resolve(context, direction: CoreAxis.vertical);
      expect(v.inner.className.split(' '), containsAll(['flex', 'flex-col']));
      expect(v.inner.className, contains('items-stretch'));
      expect(v.inner.className, isNot(contains('w-full')));
      // Spacing, track inset and segment chrome are the horizontal ones.
      expect(
        v.inner.inlineStyles!.properties['gap'],
        h.inner.inlineStyles!.properties['gap'],
      );
      expect(
        v.root.inlineStyles!.properties['padding'],
        h.root.inlineStyles!.properties['padding'],
      );
      expect(v.itemSelected.className, contains('w-full'));
      expect(v.itemHost.inlineStyles, isNull);
    });

    testComponents('vertical sm adds up to 3 + 26 + 2 + 26 + 3 = 60', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final v = _resolve(
        context,
        size: CoreComponentSize.sm,
        direction: CoreAxis.vertical,
      );
      final cell = v.itemSelected.inlineStyles!.properties['height'];
      expect(cell, '${26 / kRemDivisor}rem');
      expect(
        v.inner.inlineStyles!.properties['gap'],
        spaceCss(CoreToggleGroupStyle.defaultItemSpacing),
      );
      expect(
        v.root.inlineStyles!.properties['padding'],
        contains('${3 / kRemDivisor}rem'),
      );
      expect(
        3 + 26 + CoreToggleGroupStyle.defaultItemSpacing + 26 + 3,
        60,
      );
    });

    testComponents('vertical fillWidth is a full-width column', (
      tester,
    ) async {
      final resolved = resolveToggleGroup(
        _themedContext(tester),
        enabled: true,
        direction: CoreAxis.vertical,
        fillWidth: true,
      );
      expect(resolved.inner.className, contains('w-full'));
      expect(resolved.inner.className, contains('flex-col'));
      // The row's equal-share flex would size the column's height.
      expect(resolved.itemHost.inlineStyles, isNull);
    });

    testComponents('the component hands its direction to the resolver', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ToggleGroup<String>(
          items: _items,
          value: 'am',
          onChanged: (_) {},
          direction: CoreAxis.vertical,
        ),
      );
      expect(find.byType(ToggleGroup<String>), findsOneComponent);
      final hasColumn = find.byComponentPredicate(
        (c) => c is DomComponent && (c.classes ?? '').contains('flex-col'),
      );
      expect(hasColumn, findsOneComponent);
    });
  });
}
