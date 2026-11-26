// A control's resting edge is its only boundary: it rests on `outline`, and
// the glyph-entry fields step to `on-surface` under the pointer. These tests
// read what the resolvers hand the widgets, so they pin the painted colours
// rather than the Core tokens alone.
//
// Ladder for a boxed field: `disabled > error > focus > hover > rest`.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
);

/// Runs [read] inside a themed build so a resolver sees a real [Theme].
Future<T> _resolve<T>(
  WidgetTester tester,
  T Function(BuildContext context, ThemeData theme) read,
) async {
  late T result;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          result = read(context, Theme.of(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

Color _token(ThemeData theme, CoreColorToken name) =>
    theme.colorScheme.resolve(CoreColor.token(name)).toValue();

Color _edge(BoxDecoration decoration) => decoration.border!.top.color;

/// Whether [decoration] paints any edge at all. A box that states no border
/// width is handed no [Border] (a zero-width `BorderSide` is a one-pixel
/// hairline on Flutter, not "no border"), so a missing border paints nothing;
/// a present one paints unless every side is transparent or unstyled.
bool _paintsEdge(BoxDecoration? decoration) {
  final border = decoration?.border;
  if (border == null) return false;
  final sides = border is Border
      ? [border.top, border.right, border.bottom, border.left]
      : [
          (border as BorderDirectional).top,
          border.start,
          border.bottom,
          border.end,
        ];
  return sides.any(
    (side) => side.style != BorderStyle.none && side.color.a > 0,
  );
}

void main() {
  group('TextField — rest / hover / focus / error / disabled', () {
    Future<({WidgetStateProperty<BoxDecoration> d, ThemeData theme})> field(
      WidgetTester tester, {
      bool hasError = false,
      bool enabled = true,
    }) async {
      late WidgetStateProperty<BoxDecoration> decoration;
      final theme = await _resolve(tester, (context, theme) {
        decoration = resolveTextField(
          context,
          hasError: hasError,
          enabled: enabled,
          size: CoreComponentSize.md,
          variant: hasError
              ? CoreTextFieldVariant.error
              : CoreTextFieldVariant.defaultVariant,
        ).decoration;
        return theme;
      });
      return (d: decoration, theme: theme);
    }

    testWidgets('rests on outline-variant and steps to outline under the '
        'pointer (#5747)', (
      tester,
    ) async {
      final r = await field(tester);
      expect(
        _edge(r.d.resolve(const {})),
        _token(r.theme, CoreColors.outlineVariant),
      );
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered})),
        _token(r.theme, CoreColors.outline),
      );
    });

    testWidgets('focus outranks hover', (tester) async {
      final r = await field(tester);
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered, WidgetState.focused})),
        _token(r.theme, CoreColors.primary),
      );
    });

    testWidgets('error outranks hover — the pointer does not soften it', (
      tester,
    ) async {
      final r = await field(tester, hasError: true);
      expect(_edge(r.d.resolve(const {})), _token(r.theme, CoreColors.error));
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered})),
        _token(r.theme, CoreColors.error),
      );
    });

    testWidgets(
      'disabled draws the disabled outline whatever the pointer does',
      (
        tester,
      ) async {
        final r = await field(tester, enabled: false);
        final disabled = _token(r.theme, CoreColors.disabledOutline);
        expect(_edge(r.d.resolve(const {WidgetState.disabled})), disabled);
        expect(
          _edge(r.d.resolve(const {WidgetState.disabled, WidgetState.hovered})),
          disabled,
        );
      },
    );
  });

  group('TextArea — rest / hover / focus / error', () {
    Future<({WidgetStateProperty<BoxDecoration> d, ThemeData theme})> area(
      WidgetTester tester, {
      bool hasError = false,
    }) async {
      late WidgetStateProperty<BoxDecoration> decoration;
      final theme = await _resolve(tester, (context, theme) {
        decoration = resolveTextArea(
          context,
          hasError: hasError,
          size: CoreComponentSize.md,
        ).decoration;
        return theme;
      });
      return (d: decoration, theme: theme);
    }

    testWidgets('rests on outline-variant and steps to outline under the '
        'pointer (#5747)', (
      tester,
    ) async {
      final r = await area(tester);
      expect(
        _edge(r.d.resolve(const {})),
        _token(r.theme, CoreColors.outlineVariant),
      );
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered})),
        _token(r.theme, CoreColors.outline),
      );
    });

    testWidgets('focus outranks hover', (tester) async {
      final r = await area(tester);
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered, WidgetState.focused})),
        _token(r.theme, CoreColors.primary),
      );
    });

    testWidgets('error outranks hover', (tester) async {
      final r = await area(tester, hasError: true);
      expect(
        _edge(r.d.resolve(const {WidgetState.hovered})),
        _token(r.theme, CoreColors.error),
      );
    });
  });

  // A zero-width border still paints a hairline on Flutter, so an inner
  // field that states a transparent resting and focus border but leaves the
  // hover border to the variant would draw an `on-surface` line inside its
  // container the moment the pointer crossed it. The frame owns the step.
  group('chromeless inner fields never paint a hover hairline', () {
    final chromeless = <String, CoreTextFieldStyle>{
      'ChipInput': CoreChipInputStyle.chromelessFieldStyle,
      'ObjectInput': CoreObjectInputStyle.defaultFieldInputStyle,
      'FormattedInput': CoreFormattedInputStyle.defaultSegmentInputStyle,
      'PhoneInput': CorePhoneInputStyle.chromelessFieldStyle,
    };

    for (final entry in chromeless.entries) {
      testWidgets('${entry.key} inner field', (tester) async {
        final resolved = await _resolve(
          tester,
          (context, _) => resolveTextField(
            context,
            hasError: false,
            enabled: true,
            size: CoreComponentSize.md,
            // ChipInput, ObjectInput and FormattedInput compose their field
            // as `plain`; the others still compose the default variant.
            variant: switch (entry.key) {
              'ChipInput' => CoreChipInputStyle.fieldVariant,
              'ObjectInput' => CoreObjectInputStyle.defaultFieldInputVariant,
              'FormattedInput' =>
                CoreFormattedInputStyle.defaultSegmentInputVariant,
              _ => CoreTextFieldVariant.defaultVariant,
            },
            textFieldStyle: entry.value,
          ),
        );
        // At rest and under the pointer: neither the box nor the active
        // boundary laid over it may paint an edge — the frame around the
        // field owns the boundary and its hover step.
        const states = <Set<WidgetState>>[
          {},
          {WidgetState.hovered},
        ];
        for (final state in states) {
          expect(
            _paintsEdge(resolved.decoration.resolve(state)),
            isFalse,
            reason: 'box edge in $state',
          );
          expect(
            _paintsEdge(resolved.activeDecoration.resolve(state)),
            isFalse,
            reason: 'active boundary in $state',
          );
        }
      });
    }
  });

  group('selection controls — the resting edge is outline, with no hover '
      'border of their own', () {
    const outline = CoreColor.token(CoreColors.outline);

    testWidgets('Checkbox unchecked box', (tester) async {
      final resolved = await _resolve(
        tester,
        (context, _) => resolveCheckbox(context, size: CoreComponentSize.md),
      );
      expect(resolved.uncheckedContainerStyle.borderColor, outline);
    });

    testWidgets('RadioGroup unselected ring', (tester) async {
      final resolved = await _resolve(
        tester,
        (context, _) => resolveRadioGroup(
          context,
          variant: CoreRadioGroupVariant.defaultVariant,
          size: CoreComponentSize.md,
        ),
      );
      expect(resolved.unselectedRingContainerStyle.borderColor, outline);
    });
  });

  // MultipleChoice composes a Chip per option, so its resting edge is the
  // Chip's own quiet hairline rather than a control boundary declared here
  // (the Core table in `control_boundary_outline_test` leaves it out for the
  // same reason). What still holds is that the group states no edge of its
  // own and the pointer does not step the edge — hover is the state layer.
  testWidgets('MultipleChoice unselected option rests on the Chip hairline '
      'and keeps it under the pointer', (tester) async {
    late ResolvedChip chip;
    late CoreChipStyle unselectedChipStyle;
    final theme = await _resolve(tester, (context, theme) {
      unselectedChipStyle = resolveMultipleChoice(
        context,
        enabled: true,
      ).unselectedChipStyle;
      chip = resolveChip(
        context,
        chipColor: CoreMultipleChoiceContract.defaultUnselectedChipColor,
        variant: CoreChipVariant.defaultVariant,
        size: CoreChipSize.defaultSize,
        selected: false,
        emphasis: CoreMultipleChoiceContract.defaultUnselectedChipEmphasis,
        enabled: true,
        chipStyle: unselectedChipStyle,
      );
      return theme;
    });
    expect(
      unselectedChipStyle.borderColor,
      isNull,
      reason: 'the group restates no edge — the Chip owns it',
    );
    final rest = chip.containerStyle.borderColor!.toValue();
    expect(
      rest,
      theme.colorScheme
          .resolve(CoreChipStyle.defaultLowUnselectedBorderColor)
          .toValue(),
    );
    expect(chip.hoverContainerStyle.borderColor!.toValue(), rest);
  });
}
