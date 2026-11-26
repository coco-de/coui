import 'package:coui_web/coui_web.dart';
// Neither style file is re-exported whole by the barrel (resolvers are
// internal chrome) — import them directly for resolver-level assertions.
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveTimePicker` / `resolveFocusOutline` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// Every segment `<input>` the picker's panel holds, in panel order.
///
/// The panel only mounts once it opens, and this harness has no DOM to open
/// it with (`web.Event` cannot be constructed off the browser). `Popover`
/// keeps the built panel as a plain field, though, so the composition can be
/// read straight off it.
List<DomComponent> _segmentInputs() {
  final popover = find.byType(Popover).evaluate().single.component as Popover;
  final found = <DomComponent>[];
  void visit(Component node) {
    if (node is TypographyTierScope) {
      visit(node.child);
      return;
    }
    if (node is DomComponent) {
      if (node.tag == 'input') {
        found.add(node);
        return;
      }
      (node.children ?? const <Component>[]).forEach(visit);
    }
  }

  visit(popover.content);
  return found;
}

/// The [index]-th segment `<input>`.
DomComponent _segmentInput(int index) => _segmentInputs()[index];

void main() {
  group('TimePicker segment tile and focused face', () {
    // #6201: the edited segment draws a 2 px inside border, so the digits
    // are `headlineMedium` (28) — `display-small` (44) overran the 64x60 cell.
    testComponents('the digits are the headline-medium role, rest and edited', (
      tester,
    ) async {
      final resolved = resolveTimePicker(_themedContext(tester));
      for (final input in [
        resolved.segmentInput,
        resolved.segmentInputFocused,
      ]) {
        final classes = input.className.split(' ');
        expect(classes, contains('text-headline-medium'));
        expect(classes, isNot(contains('text-display-small')));
      }
    });

    testComponents('the tile is 64x60 with corner 10 and a filled face', (
      tester,
    ) async {
      final input = resolveTimePicker(_themedContext(tester)).segmentInput;
      final styles = input.inlineStyles!.properties;

      expect(styles['width'], '${64 / 16}rem');
      expect(styles['height'], '${60 / 16}rem');
      expect(styles['border-radius'], contains('--coui-radius-10'));
      expect(
        styles['background-color'],
        contains('--coui-surface-container-high'),
      );
    });

    testComponents('the edited segment swaps to the primaryContainer face', (
      tester,
    ) async {
      final resolved = resolveTimePicker(_themedContext(tester));
      final rest = resolved.segmentInput.inlineStyles!.properties;
      final face = resolved.segmentInputFocused.inlineStyles!.properties;

      expect(face['background-color'], contains('--coui-primary-container'));
      expect(face['color'], contains('--coui-on-primary-container'));
      expect(face['background-color'], isNot(rest['background-color']));
      // Same classes and size — only the face changes.
      expect(
        resolved.segmentInputFocused.className,
        resolved.segmentInput.className,
      );
      expect(face['width'], rest['width']);
      expect(face['height'], rest['height']);
    });

    testComponents(
      'the edited segment wears a 2px primaryText inside border in place of '
      'its resting one, the rest keep theirs',
      (tester) async {
        final resolved = resolveTimePicker(_themedContext(tester));
        final rest = resolved.segmentInput.inlineStyles!.properties;
        final face = resolved.segmentInputFocused.inlineStyles!.properties;

        expect(face['border-color'], contains('--coui-primary-text'));
        expect(face['border-width'], 'var(--coui-stroke-width-2)');
        expect(rest.containsKey('border-width'), isFalse);
        expect(rest['border-color'], isNot(face['border-color']));
        // The border sits on the same `<input>` and the tile keeps its size —
        // an inside border, not a ring around it.
        expect(face['width'], rest['width']);
        expect(face['height'], rest['height']);
      },
    );

    testComponents('the focused border follows an override', (tester) async {
      final face = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(
          segmentFocusedBorderColor: CoreColor.token(CoreColors.error),
          segmentFocusedBorderWidth: CoreStrokeWidth.stroke3,
        ),
      ).segmentInputFocused.inlineStyles!.properties;

      expect(face['border-color'], contains('--coui-error'));
      expect(face['border-width'], 'var(--coui-stroke-width-3)');
    });

    testComponents('the am/pm toggle states its track one step up the panel', (
      tester,
    ) async {
      const high = CoreColor.token(CoreColors.surfaceContainerHigh);
      final rest = resolveTimePicker(_themedContext(tester));
      expect(rest.amPmToggleStyle.backgroundColor, high);
      // A caller's toggle override merges over the slot default — the track
      // stays unless the caller states one.
      final over = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(
          amPmToggleStyle: CoreToggleGroupStyle(
            selectedColor: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      expect(over.amPmToggleStyle.backgroundColor, high);
      expect(
        over.amPmToggleStyle.selectedColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    testComponents('the focused face follows an override', (tester) async {
      final resolved = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(
          segmentFocusedSurfaceColor: CoreColor.token(CoreColors.error),
          segmentFocusedContentColor: CoreColor.token(CoreColors.onError),
        ),
      );
      final face = resolved.segmentInputFocused.inlineStyles!.properties;

      expect(face['background-color'], contains('--coui-error'));
      expect(face['color'], contains('--coui-on-error'));
    });

    testComponents('no segment is wrapped in a FocusOutline ring', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TimePicker(value: '14:30:45', showSeconds: true),
      );

      final inputs = _segmentInputs();
      expect(inputs, hasLength(3), reason: 'hour, minute, second');
      final popover =
          find.byType(Popover).evaluate().single.component as Popover;
      var rings = 0;
      void visit(Component node) {
        if (node is FocusOutline) rings += 1;
        if (node is TypographyTierScope) visit(node.child);
        if (node is DomComponent) {
          (node.children ?? const <Component>[]).forEach(visit);
        }
      }

      visit(popover.content);
      expect(rings, 0);
    });

    testComponents(
      'the AM/PM column sits beside the segments, aligned to their top',
      (tester) async {
        final resolved = resolveTimePicker(_themedContext(tester));

        // The row tops its children, so the vertical ToggleGroup's top is
        // the segment boxes' top — no centring box of its own.
        expect(
          resolved.segmentRow.className.split(' '),
          containsAll(<String>['flex', 'flex-row', 'items-start']),
        );
        expect(resolved.amPmToggle.className.split(' '), ['flex']);
        expect(resolved.amPmToggle.inlineStyles, isNull);
        expect(
          CoreTimePickerContract.defaultAmPmToggleDirection,
          CoreAxis.vertical,
        );
        expect(
          CoreTimePickerContract.defaultAmPmToggleSize,
          CoreComponentSize.sm,
        );
      },
    );
  });

  // A hovered segment wears a state layer over its tile: the layer colour
  // (`onSurface` at the ramp's hover weight) is published on the `<input>`
  // and the shared `ThemeConfig` rule lays it as a `background-image` over
  // the tile's own `background-color` — the face and the border are not
  // touched, and the edited segment takes it too.
  group('TimePicker segment hover state layer', () {
    testComponents(
      'the segment publishes the hover layer and carries the marker; its '
      'border has no hover step',
      (tester) async {
        final input = resolveTimePicker(_themedContext(tester)).segmentInput;

        expect(input.className.split(' '), contains(kStateLayerHoverMarker));
        expect(
          input.inlineStyles?.properties[kStateLayerHoverVar],
          'rgb(var(--coui-on-surface) / 3%)',
        );
        expect(
          input.className.split(' ').where((c) => c.contains('hover:')),
          isEmpty,
          reason: 'no border step on hover any more',
        );
      },
    );

    testComponents('the edited segment takes the same layer over its face', (
      tester,
    ) async {
      final focused = resolveTimePicker(
        _themedContext(tester),
      ).segmentInputFocused;

      expect(
        focused.inlineStyles?.properties[kStateLayerHoverVar],
        'rgb(var(--coui-on-surface) / 3%)',
      );
      // The layer is a background-image; the face colour is still the
      // primary-container fill.
      expect(
        focused.inlineStyles?.properties['background-color'],
        contains('primary-container'),
      );
    });

    testComponents('the layer colour and weight follow the style slots', (
      tester,
    ) async {
      final input = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(
          segmentStateLayerColor: CoreColor.token(CoreColors.primary),
          segmentStateLayer: CoreStateLayer(
            hover: CoreOpacity.opacity16,
            focus: CoreOpacity.opacity16,
            pressed: CoreOpacity.opacity16,
          ),
        ),
      ).segmentInput;

      expect(
        input.inlineStyles?.properties[kStateLayerHoverVar],
        'rgb(var(--coui-primary) / 16%)',
      );
    });

    testComponents('a disabled picker publishes no layer', (tester) async {
      final input = resolveTimePicker(
        _themedContext(tester),
        enabled: false,
      ).segmentInput;

      expect(
        input.className.split(' '),
        isNot(contains(kStateLayerHoverMarker)),
      );
      expect(
        input.inlineStyles?.properties.containsKey(kStateLayerHoverVar),
        isFalse,
      );
    });

    testComponents('the rendered segments carry the layer', (tester) async {
      pumpWithTheme(tester, const TimePicker(value: '14:30'));

      for (var i = 0; i < 2; i++) {
        final input = _segmentInput(i);
        expect(
          (input.classes ?? '').split(' '),
          contains(kStateLayerHoverMarker),
        );
        expect(
          input.styles?.properties[kStateLayerHoverVar],
          'rgb(var(--coui-on-surface) / 3%)',
        );
      }
    });

    testComponents(
      'the popover panel takes corner 12 and its edge from Popup',
      (tester) async {
        final context = _themedContext(tester);
        final panel = resolveTimePicker(context).popoverStyle?.panelStyle;
        expect(panel?.borderRadius, isNull);
        expect(panel?.borderColor, isNull);
        expect(panel?.padding, const CoreEdgeInsets.all(CoreSpace.space16));
      },
    );
  });

  // The trigger is a read-only `TextField` — the DatePicker / Select input
  // look — and the am/pm choice is one `ToggleGroup`, not two buttons.
  // The colon between two segments is punctuation, not a digit: its own
  // role (`headlineSmall` at medium) and the quieter `onSurfaceSubtle`,
  // centred in a box as tall as a segment tile.
  group('TimePicker segment separator', () {
    /// The `:` separator `<div>` the open panel renders.
    DomComponent separatorElement() {
      final popover =
          find.byType(Popover).evaluate().single.component as Popover;
      DomComponent? found;
      void visit(Component node) {
        if (found != null) return;
        if (node is TypographyTierScope) {
          visit(node.child);
          return;
        }
        if (node is DomComponent) {
          final children = node.children ?? const <Component>[];
          if (children.length == 1 &&
              children.single is Text &&
              (children.single as Text).data == ':') {
            found = node;
            return;
          }
          children.forEach(visit);
        }
      }

      visit(popover.content);
      return found!;
    }

    testComponents('draws headlineSmall at medium in onSurfaceSubtle', (
      tester,
    ) async {
      pumpWithTheme(tester, const TimePicker(value: '14:30'));
      final separator = separatorElement();
      final styles = separator.styles!.properties;

      expect(separator.classes, 'text-headline-small');
      expect(styles['font-weight'], '500');
      expect(styles['color'], 'rgb(var(--coui-on-surface-subtle))');
      // Centred in a box as tall as the 60 segment tile.
      expect(styles['height'], '${60 / 16}rem');
      expect(styles['align-items'], 'center');
    });

    testComponents("follows its own fields, not the digits' role", (
      tester,
    ) async {
      final resolved = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(
          separatorTypography: CoreTextStyle.token(CoreTextStyles.titleLarge),
          separatorColor: CoreColor.token(CoreColors.error),
          valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
        ),
      );
      final styles = resolved.separator.inlineStyles!.properties;

      expect(resolved.separator.className, 'text-title-large');
      expect(styles['color'], 'rgb(var(--coui-error))');
      expect(styles.containsKey('font-size'), isFalse);
    });
  });

  group('TimePicker trigger and am/pm toggle', () {
    TextField field() =>
        find.byType(TextField).evaluate().single.component as TextField;

    testComponents('the trigger is one read-only TextField, no Button', (
      tester,
    ) async {
      pumpWithTheme(tester, const TimePicker(value: '14:30'));

      expect(field().readOnly, isTrue);
      expect(field().showCursor, isFalse);
      expect(field().value, '14:30');
      expect(field().suffix, isA<Icon>());
      expect(
        find.byType(Button).evaluate().where((e) {
          final button = e.component as Button;
          return button.variant == CoreButtonVariant.outline;
        }),
        isEmpty,
      );
    });

    testComponents('the root fills the parent — no fixed trigger width', (
      tester,
    ) async {
      final resolved = resolveTimePicker(_themedContext(tester));

      expect(resolved.root.inlineStyles, isNull);
      expect(resolved.root.className, 'grid');
    });

    testComponents('triggerHeight and the pressed-only layer reach the field', (
      tester,
    ) async {
      final resolved = resolveTimePicker(
        _themedContext(tester),
        timePickerStyle: const CoreTimePickerStyle(triggerHeight: 56),
      );

      expect(resolved.triggerStyle.height, 56);
      expect(
        resolved.triggerStyle.stateLayer,
        CoreTimePickerStyle.defaultTriggerStyle.stateLayer,
      );
    });

    testComponents('a disabled picker leaves the text colours to the field', (
      tester,
    ) async {
      final resolved = resolveTimePicker(
        _themedContext(tester),
        enabled: false,
      );

      expect(resolved.triggerStyle.valueStyle, isNull);
      expect(resolved.triggerStyle.placeholderStyle, isNull);
    });

    testComponents('12-hour mode composes one ToggleGroup for am/pm', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TimePicker(value: '14:30', use24HourFormat: false),
      );
      await tester.pump();
      await tester.click(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('aria-haspopup') ?? false),
          description: 'popover trigger',
        ),
      );
      await tester.pump();

      final groups = find.byType(ToggleGroup<bool>).evaluate().toList();
      expect(groups, hasLength(1));
      final group = groups.single.component as ToggleGroup<bool>;
      expect(group.value, isTrue, reason: '14:30 is after noon');
      expect(group.items.map((item) => item.label), ['AM', 'PM']);
      expect(group.size, CoreComponentSize.sm);
    });

    testComponents('24-hour mode has no am/pm toggle', (tester) async {
      pumpWithTheme(
        tester,
        const TimePicker(value: '14:30', use24HourFormat: true),
      );
      await tester.pump();
      await tester.click(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('aria-haspopup') ?? false),
          description: 'popover trigger',
        ),
      );
      await tester.pump();

      expect(find.byType(ToggleGroup<bool>).evaluate(), isEmpty);
      expect(
        find.text('Cancel'),
        findsOneComponent,
        reason: 'the panel is open',
      );
    });
  });
}
