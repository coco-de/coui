import 'package:coui_web/coui_web.dart';
// filter_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/control/filter/filter_style.dart';
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

ResolvedFilter _resolve(BuildContext context, {CoreFilterStyle? style}) =>
    resolveFilter(context, variant: .segmented, filterStyle: style);

Filter<String> _filter({
  required List<CoreFilterItem<String, Component>> items,
  String? groupValue,
  bool showResetButton = false,
  VoidCallback? onReset,
}) => Filter<String>(
  groupValue: groupValue,
  items: items,
  onValueChanged: (_) {},
  onReset: onReset,
  showResetButton: showResetButton,
);

void main() {
  group('Filter segment icon / label box (Web)', () {
    testComponents(
      'icon-only segment renders the icon slot and no label box — the '
      'label survives only as the accessible name',
      (tester) async {
        pumpWithTheme(
          tester,
          _filter(
            groupValue: 'done',
            items: [
              const CoreFilterItem(
                value: 'done',
                label: 'Done',
                icon: Icon(LucideIcons.check),
                showLabel: false,
              ),
            ],
          ),
        );

        // The label is not painted (no label box, no ghost twin) …
        expect(find.text('Done'), findsNothing);
        // … but the icon is, once.
        expect(find.tag('svg'), findsOneComponent);
        // … and the segment keeps its accessible name.
        final radio =
            find.byType(Clickable).evaluate().single.component as Clickable;
        expect(radio.componentAttributes['aria-label'], 'Done');
        expect(radio.componentAttributes['role'], 'radio');
      },
    );

    testComponents(
      'label segment renders the label box (visible label + ghost twin) '
      'and no icon slot',
      (tester) async {
        pumpWithTheme(
          tester,
          _filter(
            groupValue: 'all',
            items: const [CoreFilterItem(value: 'all', label: 'All')],
          ),
        );

        // Visible label + invisible selected-weight twin.
        expect(find.text('All'), findsNComponents(2));
        expect(find.tag('svg'), findsNothing);
      },
    );

    testComponents(
      'a caller-supplied Icon with no style takes the per-state icon size '
      'from the ambient IconTheme (16 px, not the 24 px Icon default)',
      (tester) async {
        pumpWithTheme(
          tester,
          _filter(
            groupValue: 'done',
            items: [
              const CoreFilterItem(
                value: 'done',
                label: 'Done',
                icon: Icon(LucideIcons.check),
                showLabel: false,
              ),
            ],
          ),
        );

        final iconElement =
            find.tag('svg').evaluate().single.component as DomComponent;
        final size = CoreToggleGroupStyle.defaultSelectedIconStyle.size!;
        expect(
          iconElement.styles?.properties['font-size'],
          '${size / kRemDivisor}rem',
        );
      },
    );

    testComponents(
      'the segments are a composed ToggleGroup carrying the forwarded '
      'toggleGroupStyle — the track and the segment geometry are not '
      'restated by the Filter',
      (tester) async {
        pumpWithTheme(
          tester,
          _filter(
            groupValue: 'all',
            items: const [CoreFilterItem(value: 'all', label: 'All')],
          ),
        );

        final group =
            find.byType(ToggleGroup<String>).evaluate().single.component
                as ToggleGroup<String>;
        expect(group.toggleGroupStyle, const CoreToggleGroupStyle());
        expect(group.trailing, isNull);
        expect(group.enabled, isTrue);
      },
    );

    testComponents(
      'the deprecated flat track / segment fields still reach the group, '
      'and the toggleGroupStyle slot wins over them',
      (tester) async {
        final resolved = _resolve(
          _themedContext(tester),
          style: const CoreFilterStyle(
            // Deliberately the deprecated fields: they are what this test
            // pins to still reach the group.
            // ignore: deprecated_member_use, the fold of the old fields is under test.
            itemHeight: CoreSize.size40,
            // ignore: deprecated_member_use, the fold of the old fields is under test.
            labelPadding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space4,
            ),
            toggleGroupStyle: CoreToggleGroupStyle(itemHeight: CoreSize.size48),
          ),
        );

        expect(resolved.toggleGroupStyle.itemHeight, CoreSize.size48);
        expect(
          resolved.toggleGroupStyle.labelPadding,
          const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4),
        );
      },
    );
  });

  group('Filter hairline and trailing row (Web)', () {
    testComponents(
      'the hairline is a 16 px box around a vertical Divider and the '
      'trailing row is a flex row with the trailing gap',
      (tester) async {
        final resolved = _resolve(_themedContext(tester));

        expect(
          resolved.dividerBox.inlineStyles!.properties['height'],
          pinnedLengthCss(CoreFilterStyle.defaultDividerHeight),
        );
        expect(
          resolved.root.inlineStyles!.properties['gap'],
          spaceCss(CoreFilterStyle.defaultTrailingSpacing),
        );
        // 6 from the last segment, of which the group's own 2 is already
        // there: only the difference rides on the trailing row, as the
        // same expression of the two spacings the density axis moves.
        final leading = spaceCss(CoreFilterStyle.defaultDividerLeadingSpacing);
        final groupGap = spaceCss(CoreToggleGroupStyle.defaultItemSpacing);
        final none = spaceCss(CoreSpace.space0);
        expect(
          resolved.root.inlineStyles!.properties['padding-inline-start'],
          'max($none, calc($leading - $groupGap))',
        );
        expect(resolved.dividerStyle, CoreFilterStyle.defaultDividerStyle);
        expect(
          resolved.dividerStyle.color,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(resolved.dividerStyle.thickness, CoreStrokeWidth.stroke1);
      },
    );

    testComponents('the hairline shows only while the reset button does', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _filter(
          groupValue: 'all',
          items: const [CoreFilterItem(value: 'all', label: 'All')],
        ),
      );
      expect(find.byType(Divider), findsNothing);

      pumpWithTheme(
        tester,
        _filter(
          groupValue: 'all',
          showResetButton: true,
          onReset: () {},
          items: const [CoreFilterItem(value: 'all', label: 'All')],
        ),
      );
      final divider =
          find.byType(Divider).evaluate().single.component as Divider;
      expect(divider.orientation, CoreDividerOrientation.vertical);
    });

    testComponents(
      'a disabled filter disables the group and the reset button',
      (tester) async {
        pumpWithTheme(
          tester,
          Filter<String>(
            groupValue: 'all',
            items: const [CoreFilterItem(value: 'all', label: 'All')],
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
            enabled: false,
          ),
        );

        final group =
            find.byType(ToggleGroup<String>).evaluate().single.component
                as ToggleGroup<String>;
        expect(group.enabled, isFalse);
        expect(group.onChanged, isNull);
        final button =
            find.byType(Button).evaluate().single.component as Button;
        expect(button.onPressed, isNull);
      },
    );
  });

  group('Filter hairline spacing (Web)', () {
    testComponents('the leading distance and the trailing gap are separate', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreFilterStyle(
          dividerLeadingSpacing: CoreSpace.space12,
          trailingSpacing: CoreSpace.space4,
        ),
      );
      final styles = resolved.root.inlineStyles!.properties;
      final none = spaceCss(CoreSpace.space0);
      expect(styles['gap'], spaceCss(CoreSpace.space4));
      expect(
        styles['padding-inline-start'],
        'max($none, calc(${spaceCss(CoreSpace.space12)}'
        ' - ${spaceCss(CoreToggleGroupStyle.defaultItemSpacing)}))',
      );
    });

    testComponents('an enabled reset glyph takes the onSurfaceVariant ink', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Filter<String>(
          groupValue: 'all',
          items: const [CoreFilterItem(value: 'all', label: 'All')],
          onValueChanged: (_) {},
          onReset: () {},
          showResetButton: true,
        ),
      );
      final button =
          find.tag('button').evaluate().single.component as DomComponent;
      expect(
        button.classes,
        contains('text-${CoreColors.onSurfaceVariant.name}'),
      );
    });

    testComponents('the hairline is outlineVariant enabled and '
        'disabledOutline disabled', (tester) async {
      final context = _themedContext(tester);
      expect(
        resolveFilter(
          context,
          variant: .segmented,
        ).dividerStyle.color,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        resolveFilter(
          context,
          variant: .segmented,
          enabled: false,
        ).dividerStyle.color,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      const custom = CoreColor.token(CoreColors.primary);
      expect(
        resolveFilter(
          context,
          variant: .segmented,
          enabled: false,
          filterStyle: const CoreFilterStyle(disabledDividerColor: custom),
        ).dividerStyle.color,
        custom,
      );
    });

    testComponents('a disabled filter paints the hairline in disabledOutline', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Filter<String>(
          groupValue: 'all',
          items: const [CoreFilterItem(value: 'all', label: 'All')],
          onValueChanged: (_) {},
          onReset: () {},
          showResetButton: true,
          enabled: false,
        ),
      );
      final divider =
          find.byType(Divider).evaluate().single.component as Divider;
      expect(
        divider.dividerStyle?.color,
        const CoreColor.token(CoreColors.disabledOutline),
      );
    });

    testComponents('a disabled reset glyph takes the disabledContent ink', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Filter<String>(
          groupValue: 'all',
          items: const [CoreFilterItem(value: 'all', label: 'All')],
          onValueChanged: (_) {},
          onReset: () {},
          showResetButton: true,
          enabled: false,
        ),
      );
      final button =
          find.tag('button').evaluate().single.component as DomComponent;
      expect(
        button.classes,
        contains('disabled:text-${CoreColors.disabledContent.name}'),
      );
      expect(button.styles?.properties['color'], isNull);
    });
  });

  group('Filter reset affordance (Web)', () {
    testComponents(
      'the reset button is a ghost · sm · square Button carrying the '
      'resolved resetButtonStyle',
      (tester) async {
        pumpWithTheme(
          tester,
          _filter(
            groupValue: 'all',
            showResetButton: true,
            onReset: () {},
            items: const [CoreFilterItem(value: 'all', label: 'All')],
          ),
        );

        final button =
            find.byType(Button).evaluate().single.component as Button;
        expect(button.variant, CoreButtonVariant.ghost);
        expect(button.size, CoreComponentSize.sm);
        expect(button.shape, CoreButtonShape.square);
        expect(
          button.buttonStyle?.width,
          CoreFilterStyle.defaultResetButtonStyle.width,
        );
        expect(
          button.buttonStyle?.height,
          CoreFilterStyle.defaultResetButtonStyle.height,
        );
      },
    );

    testComponents('no reset button without onReset', (tester) async {
      pumpWithTheme(
        tester,
        _filter(
          groupValue: 'all',
          showResetButton: true,
          items: const [CoreFilterItem(value: 'all', label: 'All')],
        ),
      );

      expect(find.byType(Button), findsNothing);
    });
  });

  group('Filter size (Web)', () {
    testComponents('size defaults to md and reaches the composed group', (
      tester,
    ) async {
      for (final size in [null, CoreComponentSize.sm]) {
        pumpWithTheme(
          tester,
          size == null
              ? _filter(
                  items: const [CoreFilterItem(value: 'a', label: 'A')],
                )
              : Filter<String>(
                  groupValue: null,
                  items: const [CoreFilterItem(value: 'a', label: 'A')],
                  onValueChanged: (_) {},
                  size: size,
                ),
        );
        final group =
            find.byType(ToggleGroup<String>).evaluate().single.component
                as ToggleGroup<String>;
        expect(group.size, size ?? CoreComponentSize.md);
      }
    });

    testComponents('sm sizes the reset button 26 square and the hairline 14', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final md = resolveFilter(context, variant: .segmented);
      final sm = resolveFilter(
        context,
        variant: .segmented,
        size: CoreComponentSize.sm,
      );
      expect(md.resetButtonStyle.width, 32);
      expect(md.resetButtonStyle.height, 32);
      expect(sm.resetButtonStyle.width, 26);
      expect(sm.resetButtonStyle.height, 26);
      expect(
        sm.resetButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(sm.resetButtonStyle.leadingIconStyle?.size, CoreIconSize.size14);
      expect(
        md.resetButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
      expect(md.resetButtonStyle.leadingIconStyle?.size, CoreIconSize.size16);
      expect(
        md.dividerBox.inlineStyles!.properties['height'],
        pinnedLengthCss(16),
      );
      expect(
        sm.dividerBox.inlineStyles!.properties['height'],
        pinnedLengthCss(14),
      );
    });
  });

  group('Filter fillWidth (Web)', () {
    Iterable<DomComponent> elements() => find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent);

    List<String> classesOf(DomComponent element) =>
        (element.classes ?? '').split(' ');

    const twoItems = [
      CoreFilterItem<String, Component>(value: 'a', label: 'A'),
      CoreFilterItem<String, Component>(value: 'b', label: 'B'),
    ];

    testComponents(
      'fillWidth hands the composed group a full-width track whose segments '
      'take equal shares, and the trailing row keeps its own width',
      (tester) async {
        pumpWithTheme(
          tester,
          Filter<String>(
            groupValue: 'a',
            items: twoItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
            fillWidth: true,
          ),
        );

        final group =
            find.byType(ToggleGroup<String>).evaluate().single.component
                as ToggleGroup<String>;
        expect(group.fillWidth, isTrue);

        final track = elements().singleWhere(
          (e) => e.attributes?['role'] == 'radiogroup',
        );
        expect(classesOf(track), containsAll(['flex', 'w-full']));
        expect(classesOf(track), isNot(contains('inline-flex')));

        final segments = elements()
            .where((e) => e.attributes?['role'] == 'radio')
            .toList();
        expect(segments, hasLength(2));
        for (final segment in segments) {
          expect(segment.styles?.properties['flex'], '1 1 0%');
        }

        // The trailing row — the element that carries the room in front of
        // the hairline — takes no share: it stays as wide as its content.
        final trailing = elements().singleWhere(
          (e) => e.styles?.properties['padding-inline-start'] != null,
        );
        expect(classesOf(trailing), contains('inline-flex'));
        expect(trailing.styles?.properties['flex'], isNull);
      },
    );

    testComponents('fillWidth defaults to false: the track hugs its segments', (
      tester,
    ) async {
      pumpWithTheme(tester, _filter(groupValue: 'a', items: twoItems));

      final filter =
          find.byType(Filter<String>).evaluate().single.component
              as Filter<String>;
      expect(filter.fillWidth, isFalse);
      final group =
          find.byType(ToggleGroup<String>).evaluate().single.component
              as ToggleGroup<String>;
      expect(group.fillWidth, isFalse);

      final track = elements().singleWhere(
        (e) => e.attributes?['role'] == 'radiogroup',
      );
      expect(classesOf(track), contains('inline-flex'));
      expect(classesOf(track), isNot(contains('w-full')));
      for (final segment in elements().where(
        (e) => e.attributes?['role'] == 'radio',
      )) {
        expect(segment.styles?.properties['flex'], isNull);
      }
    });

    test('copyWith and the style chain keep fillWidth', () {
      final filter = Filter<String>(
        groupValue: null,
        items: twoItems,
        onValueChanged: (_) {},
        fillWidth: true,
      );
      expect(filter.copyWith().fillWidth, isTrue);
      expect(filter.radius16.primary.fillWidth, isTrue);
      expect(filter.copyWith(fillWidth: false).fillWidth, isFalse);
    });
  });
}
