// The text a field paints is three tiers — value `on-surface`, label
// `on-surface-variant`, helper · affix · disabled label `on-surface-subtle`.
//
// `coui_core/test/input_text_colour_tiers_test.dart` pins the tokens. This
// file pins that the Flutter resolvers hand them to the widgets and that the
// widgets paint them: that `TextArea` stops pushing its value ink over the
// label (the enabled label is the composed `FormLabel`'s own colour), that it
// forwards its disabled-label tint, that its prefix / suffix glyph colour is
// one slot read in every state and not the helper's, and that a `FormField`
// — which cannot hand `enabled` to its label — mutes the label through its
// overlay. Colours are compared as resolved tokens, so the claim is "this
// slot is that tier", not "this is the number the palette happens to hold".

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(
      data: const ThemeData(),
      child: SingleChildScrollView(child: child),
    ),
  ),
  localizationsDelegates: const [
    CoUILocalizationsDelegate.delegate,
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

/// Runs [read] inside a themed build so a resolver sees a real [Theme].
Future<T> _resolve<T>(
  WidgetTester tester,
  T Function(BuildContext context) read,
) async {
  late T result;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          result = read(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

/// The colour a token paints under the test theme.
Color _tone(BuildContext context, CoreColorToken token) => Theme.of(
  context,
).colorScheme.resolve(CoreColor.token(token)).toValue();

/// The colour a token paints under the test theme, read off a widget that is
/// already on screen.
Color _toneAt(WidgetTester tester, Finder at, CoreColorToken token) =>
    _tone(tester.element(at), token);

TextStyle? _paintedStyleOf(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style;

const Set<WidgetState> _rest = {};
const Set<WidgetState> _disabled = {WidgetState.disabled};

void main() {
  group('TextField', () {
    testWidgets('the helper and the affix glyph and text are subtle, the '
        'disabled label tint is forwarded', (tester) async {
      late Color subtle;
      final r = await _resolve(tester, (context) {
        subtle = _tone(context, CoreColors.onSurfaceSubtle);
        return resolveTextField(
          context,
          hasError: false,
          enabled: true,
          size: CoreComponentSize.md,
        );
      });

      expect(r.descriptionTextStyle.color, subtle);
      expect(r.affixTextStyle.color, subtle);
      expect(r.leadingIconTheme.resolve(_rest).color, subtle);
      expect(r.trailingIconTheme.resolve(_rest).color, subtle);
      // Disabled does not move the glyph: the value text is what says "off".
      expect(r.leadingIconTheme.resolve(_disabled).color, subtle);
      expect(
        r.labelFormLabelStyle.disabledColor,
        CoreTextFieldStyle.defaultLabelDisabledColor,
      );
      expect(
        r.labelFormLabelStyle.disabledColor!.token,
        CoreColors.onSurfaceSubtle,
      );
    });

    testWidgets('an enabled label is on-surface-variant, a disabled one is '
        'on-surface-subtle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(label: 'On', description: 'help'),
              TextField(label: 'Off', enabled: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedStyleOf(tester, find.text('On'))!.color,
        _toneAt(tester, find.text('On'), CoreColors.onSurfaceVariant),
      );
      expect(
        _paintedStyleOf(tester, find.text('Off'))!.color,
        _toneAt(tester, find.text('Off'), CoreColors.onSurfaceSubtle),
      );
      expect(
        _paintedStyleOf(tester, find.text('help'))!.color,
        _toneAt(tester, find.text('help'), CoreColors.onSurfaceSubtle),
      );
    });
  });

  group('TextArea', () {
    Future<ResolvedTextArea> resolveArea(
      WidgetTester tester, {
      bool hasError = false,
      bool enabled = true,
      CoreTextAreaStyle? style,
    }) => _resolve(
      tester,
      (context) => resolveTextArea(
        context,
        hasError: hasError,
        enabled: enabled,
        size: CoreComponentSize.md,
        textAreaStyle: style,
      ),
    );

    testWidgets('the helper and the affix glyph are subtle, in every state', (
      tester,
    ) async {
      late Color subtle;
      final r = await _resolve(tester, (context) {
        subtle = _tone(context, CoreColors.onSurfaceSubtle);
        return resolveTextArea(
          context,
          hasError: false,
          size: CoreComponentSize.md,
        );
      });

      expect(r.descriptionTextStyle.color, subtle);
      for (final states in [
        _rest,
        _disabled,
        const {WidgetState.focused},
      ]) {
        expect(
          r.leadingIconTheme.resolve(states).color,
          subtle,
          reason: '$states leading',
        );
        expect(
          r.trailingIconTheme.resolve(states).color,
          subtle,
          reason: '$states trailing',
        );
      }
    });

    testWidgets('the value ink does not reach the label', (
      tester,
    ) async {
      final r = await resolveArea(tester);
      // Nothing stated: the enabled label is the composed FormLabel's own
      // colour, the one a TextField beside it paints.
      expect(r.labelFormLabelStyle.labelStyle, isNull);

      final error = await resolveArea(tester, hasError: true);
      expect(error.labelFormLabelStyle.labelStyle, isNull);

      // A caller's own label style still reaches the label whole.
      const own = CoreTextStyle(color: CoreColor(0xFF010203));
      final styled = await resolveArea(
        tester,
        style: const CoreTextAreaStyle(labelStyle: own),
      );
      expect(styled.labelFormLabelStyle.labelStyle, own);
    });

    testWidgets('the disabled-label tint is forwarded and overridable', (
      tester,
    ) async {
      final r = await resolveArea(tester);
      expect(
        r.labelFormLabelStyle.disabledColor,
        CoreTextAreaStyle.defaultLabelDisabledColor,
      );

      const tint = CoreColor(0xFF0A0B0C);
      final styled = await resolveArea(
        tester,
        style: const CoreTextAreaStyle(labelDisabledColor: tint),
      );
      expect(styled.labelFormLabelStyle.disabledColor, tint);
    });

    testWidgets('affixColor moves the glyphs and not the helper, '
        'helperTextColor moves the helper and not the glyphs', (tester) async {
      late Color subtle;
      const red = CoreColor(0xFFAA0000);
      final affix = await _resolve(tester, (context) {
        subtle = _tone(context, CoreColors.onSurfaceSubtle);
        return resolveTextArea(
          context,
          hasError: false,
          size: CoreComponentSize.md,
          textAreaStyle: const CoreTextAreaStyle(affixColor: red),
        );
      });
      expect(affix.leadingIconTheme.resolve(_rest).color, red.toValue());
      expect(affix.trailingIconTheme.resolve(_disabled).color, red.toValue());
      expect(affix.descriptionTextStyle.color, subtle);

      final helper = await resolveArea(
        tester,
        style: const CoreTextAreaStyle(helperTextColor: red),
      );
      expect(helper.descriptionTextStyle.color, red.toValue());
      expect(helper.leadingIconTheme.resolve(_rest).color, subtle);
    });

    testWidgets('rendered: an enabled label is on-surface-variant, a disabled '
        'one is on-surface-subtle, the helper is subtle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextArea(label: 'On', description: 'help'),
              TextArea(label: 'Off', enabled: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedStyleOf(tester, find.text('On'))!.color,
        _toneAt(tester, find.text('On'), CoreColors.onSurfaceVariant),
      );
      expect(
        _paintedStyleOf(tester, find.text('Off'))!.color,
        _toneAt(tester, find.text('Off'), CoreColors.onSurfaceSubtle),
      );
      expect(
        _paintedStyleOf(tester, find.text('help'))!.color,
        _toneAt(tester, find.text('help'), CoreColors.onSurfaceSubtle),
      );
    });

    testWidgets('the label beside a TextField is the same colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(label: 'Field'),
              TextArea(label: 'Area'),
              TextField(label: 'FieldOff', enabled: false),
              TextArea(label: 'AreaOff', enabled: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedStyleOf(tester, find.text('Area'))!.color,
        _paintedStyleOf(tester, find.text('Field'))!.color,
      );
      expect(
        _paintedStyleOf(tester, find.text('AreaOff'))!.color,
        _paintedStyleOf(tester, find.text('FieldOff'))!.color,
      );
    });
  });

  group('FormLabel and FormField', () {
    testWidgets('a bare FormLabel is on-surface-variant, disabled is its '
        'own disabled ink', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              FormLabel(label: Text('On')),
              FormLabel(label: Text('Off'), enabled: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedStyleOf(tester, find.text('On'))!.color,
        _toneAt(tester, find.text('On'), CoreColors.onSurfaceVariant),
      );
      expect(
        _paintedStyleOf(tester, find.text('Off'))!.color,
        _toneAt(tester, find.text('Off'), CoreColors.disabledContent),
      );
    });

    testWidgets('a FormField label is on-surface-variant, and mutes to '
        'on-surface-subtle when the field is disabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              FormField(label: 'On', child: SizedBox.shrink()),
              FormField(label: 'Off', enabled: false, child: SizedBox.shrink()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final on = _paintedStyleOf(tester, find.text('On'))!.color;
      final off = _paintedStyleOf(tester, find.text('Off'))!.color;
      expect(on, _toneAt(tester, find.text('On'), CoreColors.onSurfaceVariant));
      expect(
        off,
        _toneAt(tester, find.text('Off'), CoreColors.onSurfaceSubtle),
      );
      // The overlay is the whole of the disabled signal here, so the two
      // must not be one colour.
      expect(off, isNot(on));
    });

    testWidgets('the FormField label beside a TextField label reads the '
        'same colour, enabled and disabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              const FormField(label: 'FF', child: SizedBox.shrink()),
              TextField(label: 'TF'),
              const FormField(
                label: 'FFOff',
                enabled: false,
                child: SizedBox.shrink(),
              ),
              TextField(label: 'TFOff', enabled: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedStyleOf(tester, find.text('FF'))!.color,
        _paintedStyleOf(tester, find.text('TF'))!.color,
      );
      expect(
        _paintedStyleOf(tester, find.text('FFOff'))!.color,
        _paintedStyleOf(tester, find.text('TFOff'))!.color,
      );
    });
  });
}
