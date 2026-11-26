// The size axis has to reach the text, not just the box.
//
// `size_map_completeness_test.dart` asks whether every `CoreComponentSize`
// member has a row at all. This asks the next question down: whether the
// row it finds actually says anything about the label. Those are different
// failures — a complete map whose every entry states the same typography
// is a size axis that moves the control and leaves the words behind, and
// the completeness check reads it as green.
//
// That is the state this file was written against. The box scaled 12→24
// across six steps while every label resolved to the role's own size, so
// an `xl2` checkbox drew a 24px box next to the same text an `xs` one did.
// Nothing failed: `defaultsBySize` was complete, the label had a default,
// and the resolver merged it correctly — it merged a table that said
// nothing about labels.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The six sizes in ladder order — `CoreComponentSize.values` is
/// declaration order, which is not guaranteed to be ascending, and an
/// ascent check that reads them in the wrong order proves nothing.
const List<CoreComponentSize> _ascending = [
  CoreComponentSize.xs,
  CoreComponentSize.sm,
  CoreComponentSize.md,
  CoreComponentSize.lg,
  CoreComponentSize.xl,
  CoreComponentSize.xl2,
];

/// The label style a resolver actually ends up with for [size], with no
/// caller override — the same three-step chain both platforms run
/// (`defaultLabelStyle` → size row → instance override). Reading the raw
/// table entry instead would not catch a resolver that never consults it.
CoreTextStyle _resolvedLabel(CoreComponentSize size) =>
    CoreCheckboxStyle.defaultLabelStyle.merge(
      CoreCheckboxStyle.defaultsBySize[size]!.labelStyle,
    );

CoreTextStyle _resolvedDescription(CoreComponentSize size) =>
    CoreCheckboxStyle.defaultDescriptionStyle.merge(
      CoreCheckboxStyle.defaultsBySize[size]!.descriptionStyle,
    );

void main() {
  group('every size row states a label size', () {
    for (final size in _ascending) {
      test('${size.name} — label and description both carry a fontSize', () {
        expect(
          CoreCheckboxStyle.defaultsBySize[size]!.labelStyle?.fontSize,
          isNotNull,
          reason:
              '${size.name} states no label size, so it inherits the role '
              'and this size draws the same text as every other one',
        );
        expect(
          CoreCheckboxStyle.defaultsBySize[size]!.descriptionStyle?.fontSize,
          isNotNull,
          reason: '${size.name} states no description size',
        );
      });
    }
  });

  group("the ladder is Button's and the text follows the box", () {
    test('the resolved label size is the Button ladder', () {
      // 12 / 13 / 14 / 16 / 16 / 16 — the six steps the canvas measures on
      // every selection control. From `sm` up they are the steps `Button`
      // states for its label; the equal rungs at the top (lg = xl = xl2)
      // are the ladder, not a defect: a checkbox beside a button of the
      // same tier reads at the same size. `xs` is left out of the
      // comparison: Button's `xs` label is its own role.
      final sizes = _ascending.map((s) => _resolvedLabel(s).fontSize!).toList();

      expect(sizes, [
        CoreFontSize.s12,
        CoreFontSize.s13,
        CoreFontSize.s14,
        CoreFontSize.s16,
        CoreFontSize.s16,
        CoreFontSize.s16,
      ]);
      // Button states its ladder as a role per size; read the role's
      // size back so the two ladders are compared as numbers.
      double buttonLabel(CoreComponentSize s) => CoreButtonStyle
          .defaultsBySize[s]!
          .labelStyle!
          .token!
          .read(CoreTypography.coui)
          .fontSize!;
      final shared = _ascending.where((s) => s != CoreComponentSize.xs);
      expect(
        [for (final s in shared) _resolvedLabel(s).fontSize!],
        [for (final s in shared) buttonLabel(s)],
        reason: "the checkbox label ladder drifted from Button's",
      );
    });

    test('the box ladder ascends and the label never descends', () {
      // Not "the label is N% of the box" — that would pin a ratio nobody
      // decided. The box strictly steps; the label steps or holds, never
      // steps back — a larger control does not draw smaller words.
      for (var i = 1; i < _ascending.length; i++) {
        final prevBox =
            CoreCheckboxStyle.defaultsBySize[_ascending[i - 1]]!.boxSize!;
        final currBox =
            CoreCheckboxStyle.defaultsBySize[_ascending[i]]!.boxSize!;
        final prevLabel = _resolvedLabel(_ascending[i - 1]).fontSize!;
        final currLabel = _resolvedLabel(_ascending[i]).fontSize!;

        expect(
          currBox,
          greaterThan(prevBox),
          reason: 'box ladder itself broke at ${_ascending[i].name}',
        );
        expect(
          currLabel,
          greaterThanOrEqualTo(prevLabel),
          reason: 'the box grew at ${_ascending[i].name} and the label shrank',
        );
      }
    });

    test('md label is 14 — the one size the canvas states', () {
      // The anchor the whole ladder was placed against. If the canvas is
      // ever re-measured this is the assertion that should be argued
      // with, not the six-step shape above it.
      expect(_resolvedLabel(CoreComponentSize.md).fontSize, CoreFontSize.s14);
    });
  });

  group('the description sits under the label, never over it', () {
    for (final size in _ascending) {
      test('${size.name} — description does not out-size the label', () {
        final labelSize = _resolvedLabel(size).fontSize!;
        final descriptionSize = _resolvedDescription(size).fontSize!;

        expect(
          descriptionSize,
          lessThanOrEqualTo(labelSize),
          reason:
              'a supporting line drawn larger than the thing it supports '
              'inverts the hierarchy at ${size.name}',
        );
      });
    }

    test('the resolved description ladder is 11 / 12 / 13 / 14 / 14 / 14', () {
      // One step under the label from `xs` to `lg`, then the description
      // holds at 14 while the label holds at 16. The rows state the size
      // alone (no role), so this reads the chain a resolver runs.
      expect(
        [for (final s in _ascending) _resolvedDescription(s).fontSize!],
        [
          CoreFontSize.s11,
          CoreFontSize.s12,
          CoreFontSize.s13,
          CoreFontSize.s14,
          CoreFontSize.s14,
          CoreFontSize.s14,
        ],
      );
    });

    test('the description never descends as the control grows', () {
      for (var i = 1; i < _ascending.length; i++) {
        expect(
          _resolvedDescription(_ascending[i]).fontSize,
          greaterThanOrEqualTo(
            _resolvedDescription(_ascending[i - 1]).fontSize!,
          ),
          reason: 'a larger control does not draw a smaller supporting line',
        );
      }
    });

    test('and the foreground separates them at every size', () {
      // If the colours ever collapse, the two lines are told apart by
      // nothing but a size step (and `lg` / `xl` / `xl2` hold the same
      // description size) — the foreground is what keeps them apart.
      expect(
        CoreCheckboxStyle.defaultDescriptionStyle.color,
        isNot(CoreCheckboxStyle.defaultLabelStyle.color),
      );
    });
  });

  group('the size row carries only the step, not the whole style', () {
    // The rows state `fontSize` alone; role and colour come from the two
    // defaults. If a row ever grew a colour it would silently override
    // the per-state foreground both resolvers bind after this merge —
    // including the disabled one, which is how a disabled checkbox would
    // start drawing an enabled-coloured label.
    for (final size in _ascending) {
      test('${size.name} — no colour on the size row', () {
        expect(
          CoreCheckboxStyle.defaultsBySize[size]!.labelStyle?.color,
          isNull,
          reason: 'a colour here outranks the per-state foreground',
        );
        expect(
          CoreCheckboxStyle.defaultsBySize[size]!.descriptionStyle?.color,
          isNull,
        );
      });
    }

    test('the merge keeps the role and the colour from the defaults', () {
      final resolved = _resolvedLabel(CoreComponentSize.xl2);

      expect(resolved.color, CoreCheckboxStyle.defaultLabelStyle.color);
      expect(resolved.token, isNotNull, reason: 'role token was dropped');
      expect(resolved.fontSize, CoreFontSize.s16);
    });
  });
}
