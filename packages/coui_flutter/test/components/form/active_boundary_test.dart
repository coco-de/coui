// The active boundary of the two text inputs — a focused field, or one that
// holds an error. By default it is the resting 1 (#5747: focus and error
// speak in colour), so nothing is added; a caller who states a wider one
// gets the part beyond the resting border drawn without moving anything.
// Most tests below state 1.5 to exercise that path.
//
// The resting 1px border stays in the layout (`Container.decoration`); the
// part beyond it is laid over the box (`Container.foregroundDecoration`) in
// the same colour. These tests read what the resolvers hand the widget and
// what the widget does with it: that the active boundary is there, that it
// meets the resting border in one colour and one corner, that it is absent
// where it must be (resting, disabled, `plain`, a chromeless composition, a
// caller who states a thicker border), and that the content stays put.

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
  T Function(BuildContext context, ThemeData theme) read, {
  Widget Function(Widget child)? wrap,
}) async {
  late T result;
  final probe = Builder(
    builder: (context) {
      result = read(context, Theme.of(context));
      return const SizedBox.shrink();
    },
  );
  await tester.pumpWidget(wrap == null ? _buildApp(probe) : wrap(probe));
  return result;
}

Color _edge(BoxDecoration decoration) => decoration.border!.top.color;

double _width(BoxDecoration decoration) => decoration.border!.top.width;

const Set<WidgetState> _focused = {WidgetState.focused};

/// A caller who states the wider active boundary — the path that draws one.
const _kWideField = CoreTextFieldStyle(
  activeBorderWidth: CoreStrokeWidth.stroke1_5,
);
const _kWideArea = CoreTextAreaStyle(
  activeBorderWidth: CoreStrokeWidth.stroke1_5,
);

void main() {
  group('TextField — the active boundary', () {
    Future<ResolvedTextField> resolveField(
      WidgetTester tester, {
      bool hasError = false,
      bool enabled = true,
      CoreTextFieldVariant? variant,
      CoreComponentSize size = CoreComponentSize.md,
      CoreTextFieldStyle? style,
      JoinItemData? joinItemData,
      Widget Function(Widget child)? wrap,
    }) => _resolve(
      tester,
      (context, theme) => resolveTextField(
        context,
        hasError: hasError,
        enabled: enabled,
        size: size,
        variant: variant,
        textFieldStyle: style ?? _kWideField,
        joinItemData: joinItemData,
      ),
      wrap: wrap,
    );

    testWidgets('by default a focused or erroring field adds nothing — '
        'the active boundary is the resting 1 (#5747)', (tester) async {
      late ResolvedTextField r;
      late ResolvedTextField error;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              r = resolveTextField(
                context,
                hasError: false,
                enabled: true,
                size: CoreComponentSize.md,
              );
              error = resolveTextField(
                context,
                hasError: true,
                enabled: true,
                size: CoreComponentSize.md,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(r.activeDecoration.resolve(_focused), isNull);
      expect(error.activeDecoration.resolve(_focused), isNull);
      expect(_width(r.decoration.resolve(_focused)), CoreStrokeWidth.stroke1);
    });

    testWidgets('a resting or hovered field adds nothing', (tester) async {
      final r = await resolveField(tester);
      expect(r.activeDecoration.resolve(const {}), isNull);
      expect(r.activeDecoration.resolve(const {WidgetState.hovered}), isNull);
    });

    testWidgets('a focused field draws 1.5 over the 1px resting border, '
        'in the colour the resting border takes on focus', (tester) async {
      final r = await resolveField(tester);
      final rest = r.decoration.resolve(_focused);
      final active = r.activeDecoration.resolve(_focused)!;

      expect(r.activeBorderWidth, CoreStrokeWidth.stroke1_5);
      expect(_width(active), CoreStrokeWidth.stroke1_5);
      // The layout border is unchanged — it is what the content sits inside.
      expect(_width(rest), CoreStrokeWidth.stroke1);
      expect(_width(r.decoration.resolve(const {})), CoreStrokeWidth.stroke1);
      // One colour, one corner: the two meet without a seam.
      expect(_edge(active), _edge(rest));
      expect(active.borderRadius, rest.borderRadius);
      // Only the boundary — no fill that would cover the content.
      expect(active.color, isNull);
    });

    // An error edge rests at the resting width and widens only while focused
    // (#5747), in the error colour.
    testWidgets('an error widens it on focus only, in the error colour', (
      tester,
    ) async {
      final r = await resolveField(tester, hasError: true);

      expect(r.activeDecoration.resolve(const {}), isNull);
      expect(r.activeDecoration.resolve(const {WidgetState.hovered}), isNull);
      for (final states in [
        _focused,
        const {WidgetState.hovered, WidgetState.focused},
      ]) {
        final a = r.activeDecoration.resolve(states)!;
        expect(_width(a), CoreStrokeWidth.stroke1_5, reason: '$states');
        expect(
          _edge(a),
          _edge(r.decoration.resolve(states)),
          reason: '$states',
        );
      }
    });

    testWidgets('disabled outranks error and focus — nothing is added', (
      tester,
    ) async {
      final disabledError = await resolveField(
        tester,
        hasError: true,
        enabled: false,
      );
      expect(
        disabledError.activeDecoration.resolve(const {WidgetState.disabled}),
        isNull,
      );
      expect(
        disabledError.activeDecoration.resolve(const {
          WidgetState.disabled,
          WidgetState.focused,
        }),
        isNull,
      );
    });

    testWidgets('the bare plain variant keeps its resting boundary', (
      tester,
    ) async {
      final r = await resolveField(tester, variant: CoreTextFieldVariant.plain);
      expect(r.activeDecoration.resolve(_focused), isNull);
    });

    testWidgets('an explicit error variant without an error widens on focus '
        'only, as the Web twin does', (tester) async {
      final r = await resolveField(tester, variant: CoreTextFieldVariant.error);
      expect(r.activeDecoration.resolve(const {}), isNull);
      final active = r.activeDecoration.resolve(_focused)!;
      expect(_width(active), CoreStrokeWidth.stroke1_5);
      expect(_edge(active), _edge(r.decoration.resolve(_focused)));
    });

    testWidgets('a caller who states only a thicker border is not thinned '
        'on focus', (tester) async {
      final r = await resolveField(
        tester,
        style: const CoreTextFieldStyle(borderWidth: CoreStrokeWidth.stroke2),
      );
      expect(r.activeDecoration.resolve(_focused), isNull);
      expect(_width(r.decoration.resolve(_focused)), CoreStrokeWidth.stroke2);
    });

    testWidgets('a caller who states the active width draws that width', (
      tester,
    ) async {
      final r = await resolveField(
        tester,
        style: const CoreTextFieldStyle(
          activeBorderWidth: CoreStrokeWidth.stroke3,
        ),
      );
      expect(r.activeBorderWidth, CoreStrokeWidth.stroke3);
      expect(_width(r.activeDecoration.resolve(_focused)!), 3);
      // The resting border stays 1.
      expect(_width(r.decoration.resolve(_focused)), CoreStrokeWidth.stroke1);
    });

    testWidgets('a chromeless composition has no boundary to widen', (
      tester,
    ) async {
      // What ChipInput / FormattedInput / PhoneInput state: a zero-width,
      // transparent boundary in every state.
      final r = await resolveField(
        tester,
        style: CoreChipInputStyle.chromelessFieldStyle,
      );
      expect(r.activeDecoration.resolve(_focused), isNull);
      expect(r.activeDecoration.resolve(const {}), isNull);

      final chromelessError = await resolveField(
        tester,
        hasError: true,
        style: CoreChipInputStyle.chromelessFieldStyle,
      );
      expect(chromelessError.activeDecoration.resolve(const {}), isNull);
    });

    testWidgets('a hosting Join squares the active boundary like the box', (
      tester,
    ) async {
      const join = JoinItemData(
        borderRadius: BorderRadius.zero,
        coreBorderRadius: CoreBorderRadius.zero,
      );
      final r = await resolveField(tester, joinItemData: join);
      expect(r.decoration.resolve(_focused).borderRadius, BorderRadius.zero);
      expect(
        r.activeDecoration.resolve(_focused)!.borderRadius,
        BorderRadius.zero,
      );
    });

    testWidgets('a stroke floor lifts both widths to one — nothing to add', (
      tester,
    ) async {
      // Under a style whose stroke floor is above both steps the resting and
      // the active boundary are one width, so the overlay has nothing to do.
      late ResolvedTextField r;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
          home: Builder(
            builder: (context) {
              r = resolveTextField(
                context,
                hasError: false,
                enabled: true,
                size: CoreComponentSize.md,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(_width(r.decoration.resolve(_focused)), CoreStrokeWidth.stroke4);
      expect(r.activeBorderWidth, CoreStrokeWidth.stroke4);
      expect(r.activeDecoration.resolve(_focused), isNull);
    });

    testWidgets('the affix icon takes the size of its row', (tester) async {
      const expected = {
        CoreComponentSize.xs: 12.0,
        CoreComponentSize.sm: 14.0,
        CoreComponentSize.md: 16.0,
        CoreComponentSize.lg: 18.0,
        CoreComponentSize.xl: 20.0,
        CoreComponentSize.xl2: 24.0,
      };
      for (final entry in expected.entries) {
        final r = await resolveField(tester, size: entry.key);
        expect(
          r.leadingIconTheme.resolve(const {}).size,
          entry.value,
          reason: '${entry.key}',
        );
        expect(
          r.trailingIconTheme.resolve(const {}).size,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('6 under the label and 6 over the helper', (tester) async {
      final r = await resolveField(tester);
      expect(r.labelPadding, const EdgeInsets.only(bottom: 6));
      expect(r.descriptionPadding, const EdgeInsets.only(top: 6));
    });

    testWidgets('focusing the field lays the boundary over the box and '
        'moves nothing', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: SizedBox(
              width: 240,
              child: TextField(
                focusNode: node,
                initialValue: 'Hello',
                textFieldStyle: _kWideField,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = find.byWidgetPredicate(
        (w) => w is material.Container && w.decoration is BoxDecoration,
      );
      final text = find.byType(EditableText);
      final restTextPos = tester.getTopLeft(text);
      final restBoxSize = tester.getSize(box.first);
      expect(_foregroundOverBox(tester), isNull);

      node.requestFocus();
      await tester.pumpAndSettle();

      final overlay = _foregroundOverBox(tester);
      expect(overlay, isNotNull);
      expect(_width(overlay!), CoreStrokeWidth.stroke1_5);
      expect(tester.getTopLeft(text), restTextPos);
      expect(tester.getSize(box.first), restBoxSize);
    });

    testWidgets('an error adds nothing before the field is ever focused', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: SizedBox(
              width: 240,
              child: TextField(
                errorText: 'Required',
                textFieldStyle: _kWideField,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_foregroundOverBox(tester), isNull);
    });
  });

  group('TextArea — the active boundary', () {
    Future<ResolvedTextArea> resolveArea(
      WidgetTester tester, {
      bool hasError = false,
      bool enabled = true,
      CoreComponentSize size = CoreComponentSize.md,
      CoreTextAreaStyle? style,
    }) => _resolve(
      tester,
      (context, theme) => resolveTextArea(
        context,
        hasError: hasError,
        enabled: enabled,
        size: size,
        textAreaStyle: style ?? _kWideArea,
      ),
    );

    testWidgets('a resting or hovered area adds nothing', (tester) async {
      final r = await resolveArea(tester);
      expect(r.activeDecoration.resolve(const {}), isNull);
      expect(r.activeDecoration.resolve(const {WidgetState.hovered}), isNull);
    });

    testWidgets('a focused area draws 1.5 over the 1px resting border, in '
        'the same colour and corner', (tester) async {
      final r = await resolveArea(tester);
      final rest = r.decoration.resolve(_focused);
      final active = r.activeDecoration.resolve(_focused)!;

      expect(r.activeBorderWidth, CoreStrokeWidth.stroke1_5);
      expect(_width(active), CoreStrokeWidth.stroke1_5);
      expect(_width(rest), CoreStrokeWidth.stroke1);
      expect(_edge(active), _edge(rest));
      expect(active.borderRadius, rest.borderRadius);
      expect(active.color, isNull);
    });

    testWidgets('an error widens it on focus only; disabled outranks it', (
      tester,
    ) async {
      final error = await resolveArea(tester, hasError: true);
      expect(error.activeDecoration.resolve(const {}), isNull);
      final a = error.activeDecoration.resolve(_focused)!;
      expect(_width(a), CoreStrokeWidth.stroke1_5);
      expect(_edge(a), _edge(error.decoration.resolve(_focused)));

      final disabled = await resolveArea(
        tester,
        hasError: true,
        enabled: false,
      );
      expect(
        disabled.activeDecoration.resolve(const {WidgetState.disabled}),
        isNull,
      );
    });

    testWidgets('a caller who states only a thicker border is not thinned '
        'on focus; one who states the active width draws it', (tester) async {
      final thick = await resolveArea(
        tester,
        style: const CoreTextAreaStyle(borderWidth: CoreStrokeWidth.stroke2),
      );
      expect(thick.activeDecoration.resolve(_focused), isNull);

      final wide = await resolveArea(
        tester,
        style: const CoreTextAreaStyle(
          activeBorderWidth: CoreStrokeWidth.stroke3,
        ),
      );
      expect(_width(wide.activeDecoration.resolve(_focused)!), 3);
      expect(
        _width(wide.decoration.resolve(_focused)),
        CoreStrokeWidth.stroke1,
      );
    });

    testWidgets('the resting border goes through the stroke floor, like the '
        "field's", (tester) async {
      late ResolvedTextArea r;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
          home: Builder(
            builder: (context) {
              r = resolveTextArea(
                context,
                hasError: false,
                size: CoreComponentSize.md,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(_width(r.decoration.resolve(const {})), CoreStrokeWidth.stroke4);
      expect(r.activeBorderWidth, CoreStrokeWidth.stroke4);
      expect(r.activeDecoration.resolve(_focused), isNull);
    });

    testWidgets("the affix icon takes the field's icon size at every size", (
      tester,
    ) async {
      for (final size in CoreComponentSize.values) {
        final r = await resolveArea(tester, size: size);
        final field = await _resolve(
          tester,
          (context, theme) => resolveTextField(
            context,
            hasError: false,
            enabled: true,
            size: size,
          ),
        );
        expect(
          r.leadingIconTheme.resolve(const {}).size,
          field.leadingIconTheme.resolve(const {}).size,
          reason: '$size',
        );
      }
    });

    testWidgets('focusing the area lays the boundary over the box and moves '
        'nothing', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: SizedBox(
              width: 240,
              child: TextArea(
                focusNode: node,
                rows: 3,
                initialValue: 'Hello',
                textAreaStyle: _kWideArea,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = find.byWidgetPredicate(
        (w) => w is material.Container && w.decoration is BoxDecoration,
      );
      final text = find.byType(EditableText);
      final restTextPos = tester.getTopLeft(text);
      final restBoxSize = tester.getSize(box.first);
      expect(_foregroundOverBox(tester), isNull);

      node.requestFocus();
      await tester.pumpAndSettle();

      final overlay = _foregroundOverBox(tester);
      expect(overlay, isNotNull);
      expect(_width(overlay!), CoreStrokeWidth.stroke1_5);
      // The box does not grow with its rows, and the text does not move.
      expect(tester.getTopLeft(text), restTextPos);
      expect(tester.getSize(box.first), restBoxSize);
    });
  });
}

/// The foreground decoration of the field box's [material.Container], or
/// `null` when none is laid over it.
BoxDecoration? _foregroundOverBox(WidgetTester tester) {
  final containers = tester
      .widgetList<material.Container>(
        find.byWidgetPredicate(
          (w) => w is material.Container && w.decoration is BoxDecoration,
        ),
      )
      .toList();
  for (final c in containers) {
    final fg = c.foregroundDecoration;
    if (fg is BoxDecoration) return fg;
  }
  return null;
}
