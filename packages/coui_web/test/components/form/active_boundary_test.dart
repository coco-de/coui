// The active boundary of the two text inputs on Web — a focused field, or one
// that holds an error. By default it is the resting 1 (#5747), so nothing is
// added; a caller who states a wider one gets the difference drawn without
// moving anything. Most tests below state 1.5 to exercise that path.
//
// The resting `border` stays in the layout (and in forced-colours mode,
// which recolours borders but draws no shadows); the part beyond it is an
// inset `box-shadow` of the *difference* between the two widths, so the
// content does not move. The error variant is a build-time state and rides
// the element inline; the focus half is a pseudo-state: the box that draws
// the boundary carries a marker class and publishes the layer inline on a
// custom property, and one global `ThemeConfig` rule paints it on focus — so
// no field needs an id or a `<style>` element for its boundary.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

/// The difference of the two stroke variables, floored at zero — what the
/// spread of the inset shadow reads for a [rest] and an [active] width.
String _inset(double rest, double active) =>
    'max(0px, calc(${strokeWidthCss(active)} - ${strokeWidthCss(rest)}))';

/// A caller who states the wider active boundary — the path that draws one.
const _kWideField = CoreTextFieldStyle(
  activeBorderWidth: CoreStrokeWidth.stroke1_5,
);
const _kWideArea = CoreTextAreaStyle(
  activeBorderWidth: CoreStrokeWidth.stroke1_5,
);

/// The stated 1 → 1.5 difference.
final String _kDefaultInset = _inset(
  CoreStrokeWidth.stroke1,
  CoreStrokeWidth.stroke1_5,
);

ResolvedTextField _field(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
  CoreTextFieldVariant? variant,
  CoreTextFieldStyle? style,
}) => resolveTextField(
  context,
  scopeId: 'tf',
  size: CoreComponentSize.md,
  expands: false,
  hasError: hasError,
  enabled: enabled,
  variant: variant,
  textFieldStyle: style ?? _kWideField,
);

String _fieldRules(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
  CoreTextFieldVariant? variant,
  CoreTextFieldStyle? style,
}) => resolveTextFieldRules(
  context,
  scopeId: 'tf',
  stateLayerId: 'box',
  hasError: hasError,
  enabled: enabled,
  variant: variant,
  textFieldStyle: style ?? _kWideField,
).css;

ResolvedTextArea _area(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
  CoreTextAreaStyle? style,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: hasError,
  enabled: enabled,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  textAreaStyle: style ?? _kWideArea,
);

String _areaRules(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
  CoreTextAreaStyle? style,
}) => resolveTextAreaRules(
  context,
  scopeId: 'ta',
  hasError: hasError,
  enabled: enabled,
  textAreaStyle: style ?? _kWideArea,
).css;

String? _shadow(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties['box-shadow'];

/// The focused boundary's layer the box publishes for the shared rule.
String? _focusLayer(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties[kActiveBoundaryVar];

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

/// The active-boundary markers a box carries — compared whole, so a box
/// that picks up the other pseudo's marker as well fails.
List<String> _markers(WebElementChrome chrome) => _classes(
  chrome,
).where((c) => c.startsWith('coui-active-boundary')).toList();

/// Expects [chrome] neither marked nor publishing a layer — and so left
/// untouched by the shared rule on focus.
void _expectUnmarked(WebElementChrome chrome, {String? reason}) {
  expect(_markers(chrome), isEmpty, reason: reason);
  expect(_focusLayer(chrome), isNull, reason: reason);
}

/// The class-level shadow sources of this kit — markers whose shared rules
/// write `box-shadow`, and Tailwind shadow / ring utilities. None may sit on
/// a text input box, or it would meet the active-boundary rule at equal
/// specificity and the stylesheet order would decide.
final List<String> _kShadowSources = [
  kControlShadowRestMarker,
  kControlShadowPressMarker,
  kSurfaceRimLiftMarker,
  kFocusBandMarker,
];

void _expectNoShadowSource(WebElementChrome chrome, {String? reason}) {
  for (final c in _classes(chrome)) {
    final utility = c.split(':').last;
    expect(_kShadowSources, isNot(contains(c)), reason: reason);
    expect(
      utility == 'shadow' ||
          utility.startsWith('shadow-') ||
          utility == 'ring' ||
          utility.startsWith('ring-'),
      isFalse,
      reason: '$reason: $c',
    );
  }
}

/// The focused-boundary layer for the default focus colour.
final String _kDefaultFocusLayer =
    'inset 0 0 0 $_kDefaultInset rgb(var(--coui-primary))';

/// The one rule in the shared stylesheet that paints the focused boundary.
const String _kGlobalRule =
    '.$kActiveBoundaryMarker:focus-visible,'
    '.$kActiveBoundaryWithinMarker:focus-within{'
    'box-shadow:var($kActiveBoundaryVar);}';

/// Every element the widget rendered.
Iterable<DomComponent> _elements() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// Expects the widget rendered no id-bearing element and no `<style>` — the
/// focused boundary needs neither. An id reaches the DOM either as the
/// component's own `id` or as an `id` attribute (the `<input>` takes it
/// that way), so both are read.
void _expectNoScope() {
  expect(find.tag('style').evaluate(), isEmpty);
  expect(
    _elements().where((d) => d.id != null || d.attributes?['id'] != null),
    isEmpty,
  );
}

void main() {
  group('the helper behind both inputs', () {
    test('adds nothing when the active width is no wider than the resting', () {
      expect(activeBoundaryInsetCss(rest: 1, active: 1), isNull);
      expect(activeBoundaryInsetCss(rest: 2, active: 1.5), isNull);
    });

    test('is the difference of the two stroke variables, floored at zero', () {
      expect(
        activeBoundaryInsetCss(rest: 1, active: 1.5),
        'max(0px, calc(var(--coui-stroke-width-1_5) - '
        'var(--coui-stroke-width-1)))',
      );
    });
  });

  // An error edge rests at the resting width and widens only while focused
  // (#5747): the error rides the same focused layer, in its own tone.
  group('TextField — the error boundary widens on focus only', () {
    testComponents('an error rests at the resting width and widens on focus '
        'in the error tone', (tester) async {
      final context = _themedContext(tester);
      final r = _field(context, hasError: true);

      expect(_shadow(r.affixWrapper), isNull);
      expect(_markers(r.affixWrapper), [kActiveBoundaryWithinMarker]);
      expect(
        _focusLayer(r.affixWrapper),
        'inset 0 0 0 $_kDefaultInset rgb(var(--coui-error))',
      );
      // The border is still there and still 1 — the shadow is the extra.
      expect(
        r.affixWrapper.inlineStyles!.properties['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke1),
      );
      expect(r.affixWrapper.className.split(' '), contains('border'));
      // The borderless input inside is not the box.
      expect(_shadow(r.input), isNull);
      _expectUnmarked(r.input);
    });

    testComponents('a resting field has no inline shadow', (tester) async {
      final context = _themedContext(tester);
      expect(_shadow(_field(context).affixWrapper), isNull);
      expect(_shadow(_field(context).input), isNull);
    });

    testComponents('disabled outranks error — nothing is added', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _field(context, hasError: true, enabled: false);
      expect(_shadow(r.input), isNull);
      expect(_shadow(r.affixWrapper), isNull);
    });

    testComponents('the plain variant keeps its resting boundary', (
      tester,
    ) async {
      final context = _themedContext(tester);
      // `plain` never wears the error variant's shadow, nor the focus marker.
      final r = _field(context, variant: CoreTextFieldVariant.plain);
      expect(_shadow(r.affixWrapper), isNull);
      expect(_focusLayer(r.affixWrapper), isNull);
      expect(
        _classes(r.affixWrapper),
        isNot(contains(kActiveBoundaryWithinMarker)),
      );
    });

    testComponents('an explicit error variant without an error still takes '
        'the focused boundary, as the Flutter twin does', (tester) async {
      final context = _themedContext(tester);
      const error = CoreTextFieldVariant.error;
      // No `hasError`: the field is not showing the error chrome, so it has
      // no inline shadow at rest...
      expect(_shadow(_field(context, variant: error).affixWrapper), isNull);
      // ...and focus is the one thing that widens its boundary.
      final resting = _field(context, variant: error);
      expect(_markers(resting.affixWrapper), [kActiveBoundaryWithinMarker]);
      expect(
        _focusLayer(resting.affixWrapper),
        'inset 0 0 0 $_kDefaultInset rgb(var(--coui-error))',
      );
      // Holding an error changes nothing at rest — the same focused layer.
      final errored = _field(context, variant: error, hasError: true);
      expect(_shadow(errored.affixWrapper), isNull);
      expect(_markers(errored.affixWrapper), [kActiveBoundaryWithinMarker]);
    });

    testComponents('a thicker resting border is not thinned; a stated active '
        'width is the difference', (tester) async {
      final context = _themedContext(tester);
      const thick = CoreTextFieldStyle(borderWidth: CoreStrokeWidth.stroke2);
      expect(
        _shadow(_field(context, hasError: true, style: thick).affixWrapper),
        isNull,
      );
      expect(_focusLayer(_field(context, style: thick).affixWrapper), isNull);

      const wide = CoreTextFieldStyle(
        activeBorderWidth: CoreStrokeWidth.stroke3,
      );
      final wideInset = _inset(
        CoreStrokeWidth.stroke1,
        CoreStrokeWidth.stroke3,
      );
      expect(
        _focusLayer(
          _field(context, hasError: true, style: wide).affixWrapper,
        ),
        'inset 0 0 0 $wideInset rgb(var(--coui-error))',
      );
      expect(
        _focusLayer(_field(context, style: wide).affixWrapper),
        'inset 0 0 0 $wideInset rgb(var(--coui-primary))',
      );
    });

    testComponents('a chromeless composition draws no boundary at all', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const chromeless = CoreChipInputStyle.chromelessFieldStyle;
      expect(
        _shadow(
          _field(context, hasError: true, style: chromeless).affixWrapper,
        ),
        isNull,
      );
      final resting = _field(context, style: chromeless);
      expect(_focusLayer(resting.affixWrapper), isNull);
      expect(
        _classes(resting.affixWrapper),
        isNot(contains(kActiveBoundaryWithinMarker)),
      );
      expect(_fieldRules(context, style: chromeless), isEmpty);
    });
  });

  group('TextField — the focused boundary rides a marker and a layer', () {
    testComponents('the field marks its wrapper for :focus-within', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _field(context);
      expect(_markers(r.affixWrapper), [kActiveBoundaryWithinMarker]);
      expect(_focusLayer(r.affixWrapper), _kDefaultFocusLayer);
      // The borderless input inside is not the box.
      _expectUnmarked(r.input);
    });

    testComponents('a stated focus colour is the layer colour — raw included', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const green = CoreColor(0xFF00FF00);
      final r = _field(
        context,
        style: const CoreTextFieldStyle(
          focusBorderColor: green,
          activeBorderWidth: CoreStrokeWidth.stroke1_5,
        ),
      );
      expect(_markers(r.affixWrapper), [kActiveBoundaryWithinMarker]);
      expect(
        _focusLayer(r.affixWrapper),
        'inset 0 0 0 $_kDefaultInset rgb(0, 255, 0)',
      );
    });

    testComponents('no marker where there is no focused boundary to widen', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const cases = {
        'disabled (cannot take focus)': (
          hasError: false,
          enabled: false,
          variant: null,
          style: null,
        ),
        'thicker resting border': (
          hasError: false,
          enabled: true,
          variant: null,
          style: CoreTextFieldStyle(borderWidth: CoreStrokeWidth.stroke2),
        ),
        'transparent focus colour': (
          hasError: false,
          enabled: true,
          variant: null,
          style: CoreTextFieldStyle(focusBorderColor: CoreColor.transparent),
        ),
        'chromeless': (
          hasError: false,
          enabled: true,
          variant: null,
          style: CoreChipInputStyle.chromelessFieldStyle,
        ),
        'plain': (
          hasError: false,
          enabled: true,
          variant: CoreTextFieldVariant.plain,
          style: null,
        ),
      };
      for (final MapEntry(key: name, value: c) in cases.entries) {
        final r = _field(
          context,
          hasError: c.hasError,
          enabled: c.enabled,
          variant: c.variant,
          style: c.style,
        );
        _expectUnmarked(r.input, reason: name);
        _expectUnmarked(r.affixWrapper, reason: name);
      }
    });

    testComponents('no other class-level box-shadow source sits on the box', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final hasError in [false, true]) {
        final r = _field(context, hasError: hasError);
        final reason = 'hasError: $hasError';
        _expectNoShadowSource(r.input, reason: reason);
        _expectNoShadowSource(r.affixWrapper, reason: reason);
      }
    });

    testComponents('the boundary writes no scoped rule — the default rules '
        'are empty', (tester) async {
      final context = _themedContext(tester);
      expect(_fieldRules(context), isEmpty);
      expect(
        _fieldRules(context, variant: CoreTextFieldVariant.error),
        isEmpty,
      );
    });
  });

  group('the shared stylesheet paints the layer', () {
    test('one global rule reads the layer on focus', () {
      final css = ThemeConfig.defaults().cssVariables;
      expect(css, contains(_kGlobalRule));
      expect(
        _kGlobalRule,
        '.coui-active-boundary:focus-visible,'
        '.coui-active-boundary-within:focus-within{'
        'box-shadow:var(--coui-active-boundary);}',
      );
    });
  });

  group('rows and spacing the twins read from Core', () {
    testComponents('the TextField icon takes the size of its row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const expected = {
        CoreComponentSize.sm: 14.0,
        CoreComponentSize.md: 16.0,
        CoreComponentSize.lg: 18.0,
        CoreComponentSize.xl: 20.0,
        CoreComponentSize.xl2: 24.0,
      };
      for (final entry in expected.entries) {
        final r = resolveTextField(
          context,
          scopeId: 'tf',
          size: entry.key,
          expands: false,
          hasError: false,
          enabled: true,
        );
        expect(r.leadingIconStyle.size, entry.value, reason: '${entry.key}');
        expect(r.trailingIconStyle.size, entry.value, reason: '${entry.key}');
      }
    });

    testComponents('the TextArea icon takes the TextField icon at every size', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        // `Icon` sizes itself from the Core row; the resolver only forwards
        // the font size of the affix slot.
        final area = resolveTextArea(
          context,
          size: size,
          expandableHeight: false,
          expandableWidth: false,
          hasError: false,
          obscureText: false,
          obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
        );
        final field = resolveTextField(
          context,
          scopeId: 'tf',
          size: size,
          expands: false,
          hasError: false,
          enabled: true,
        );
        expect(
          area.affixSlot.inlineStyles!.properties['font-size'],
          '${field.leadingIconStyle.size! / 16}rem',
          reason: '$size',
        );
      }
    });

    testComponents('6 under the TextField label and over its helper', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _field(context);
      expect(
        r.labelHost.inlineStyles!.properties['margin'],
        const CoreEdgeInsets.only(bottom: CoreSpace.space6).toValue(),
      );
      expect(
        r.description.inlineStyles!.properties['margin'],
        const CoreEdgeInsets.only(top: CoreSpace.space6).toValue(),
      );
    });

    testComponents('6 under the TextArea label and over its helper', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _area(context);
      expect(r.labelGapStyle.size, CoreSpace.space6);
      expect(r.descriptionGapStyle.size, CoreSpace.space6);
    });
  });

  group('TextField — the widget needs no id or <style> for it', () {
    testComponents('a bare field puts the marker on the wrapper', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextField(textFieldStyle: _kWideField));

      final box = _elements().where(
        (d) =>
            (d.classes ?? '').split(' ').contains(kActiveBoundaryWithinMarker),
      );
      expect(box, hasLength(1));
      expect(
        box.single.styles!.properties[kActiveBoundaryVar],
        _kDefaultFocusLayer,
      );
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.classes!.split(' '), isNot(contains(kActiveBoundaryMarker)));
      _expectNoScope();
    });

    testComponents('a field with a prefix puts the marker on the wrapper', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextField(prefix: Text('kg'), textFieldStyle: _kWideField),
      );

      final box = _elements().where(
        (d) =>
            (d.classes ?? '').split(' ').contains(kActiveBoundaryWithinMarker),
      );
      expect(box, hasLength(1));
      expect(
        box.single.styles!.properties[kActiveBoundaryVar],
        _kDefaultFocusLayer,
      );
      _expectNoScope();
    });

    testComponents('a raw focus colour needs neither either', (tester) async {
      pumpWithTheme(
        tester,
        const TextField(
          textFieldStyle: CoreTextFieldStyle(
            focusBorderColor: CoreColor(0xFF00FF00),
          ),
        ),
      );
      _expectNoScope();
    });
  });

  group('TextArea — the error boundary widens on focus only', () {
    testComponents('an error rests at the resting width and widens on focus '
        'on the wrapper', (tester) async {
      final context = _themedContext(tester);
      final r = _area(context, hasError: true);

      expect(_shadow(r.affixWrapper), isNull);
      expect(
        _focusLayer(r.affixWrapper),
        'inset 0 0 0 $_kDefaultInset rgb(var(--coui-error))',
      );
      expect(
        r.affixWrapper.inlineStyles!.properties['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke1),
      );
      // The `<textarea>` inside draws no boundary of its own.
      expect(_shadow(r.textarea), isNull);
      expect(r.textarea.inlineStyles!.properties['border-width'], '0');
    });

    testComponents('resting and disabled areas have none; a thicker border '
        'is not thinned', (tester) async {
      final context = _themedContext(tester);
      expect(_shadow(_area(context).affixWrapper), isNull);
      expect(
        _shadow(_area(context, hasError: true, enabled: false).affixWrapper),
        isNull,
      );
      expect(
        _shadow(
          _area(
            context,
            hasError: true,
            style: const CoreTextAreaStyle(
              borderWidth: CoreStrokeWidth.stroke2,
            ),
          ).affixWrapper,
        ),
        isNull,
      );
    });
  });

  group('TextArea — the focused boundary rides a marker and a layer', () {
    testComponents('the area marks its wrapper for :focus-within', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _area(context);
      expect(_markers(r.affixWrapper), [kActiveBoundaryWithinMarker]);
      expect(_focusLayer(r.affixWrapper), _kDefaultFocusLayer);
      _expectUnmarked(r.textarea);
    });

    testComponents('a disabled area carries no marker; nor a thicker '
        'resting border', (tester) async {
      final context = _themedContext(tester);
      const cases = {
        'disabled': (hasError: false, enabled: false, style: null),
        'thicker resting border': (
          hasError: false,
          enabled: true,
          style: CoreTextAreaStyle(borderWidth: CoreStrokeWidth.stroke2),
        ),
        'transparent focus colour': (
          hasError: false,
          enabled: true,
          style: CoreTextAreaStyle(focusBorderColor: CoreColor.transparent),
        ),
      };
      for (final MapEntry(key: name, value: c) in cases.entries) {
        final r = _area(
          context,
          hasError: c.hasError,
          enabled: c.enabled,
          style: c.style,
        );
        _expectUnmarked(r.textarea, reason: name);
        _expectUnmarked(r.affixWrapper, reason: name);
      }
    });

    testComponents('no other class-level box-shadow source sits on the box', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final hasError in [false, true]) {
        final r = _area(context, hasError: hasError);
        final reason = 'hasError: $hasError';
        _expectNoShadowSource(r.textarea, reason: reason);
        _expectNoShadowSource(r.affixWrapper, reason: reason);
      }
    });

    testComponents('a raw focus colour is the layer colour', (tester) async {
      final context = _themedContext(tester);
      final r = _area(
        context,
        style: const CoreTextAreaStyle(
          focusBorderColor: CoreColor(0xFF00FF00),
          activeBorderWidth: CoreStrokeWidth.stroke1_5,
        ),
      );
      expect(
        _focusLayer(r.affixWrapper),
        'inset 0 0 0 $_kDefaultInset rgb(0, 255, 0)',
      );
    });

    testComponents('the default rules are empty; a raw selection tint keeps '
        'its ::selection rule', (tester) async {
      final context = _themedContext(tester);
      expect(_areaRules(context), isEmpty);
      final css = _areaRules(
        context,
        style: const CoreTextAreaStyle(selectionColor: CoreColor(0xFF00FF00)),
      );
      expect(css, contains('#ta::selection'));
      expect(css, isNot(contains('box-shadow')));
    });
  });

  group('TextArea — the widget needs no id or <style> for it', () {
    testComponents('a bare area puts the marker on the wrapper', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextArea(textAreaStyle: _kWideArea));

      final box = _elements().where(
        (d) =>
            (d.classes ?? '').split(' ').contains(kActiveBoundaryWithinMarker),
      );
      expect(box, hasLength(1));
      // The `<textarea>` inside is not the box and carries no marker.
      final area =
          find.tag('textarea').evaluate().single.component as DomComponent;
      expect(area.classes!.split(' '), isNot(contains(kActiveBoundaryMarker)));
      _expectNoScope();
    });

    testComponents('an affixed area puts the marker on the same wrapper', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextArea(prefix: Text('kg'), textAreaStyle: _kWideArea),
      );

      final box = _elements().where(
        (d) =>
            (d.classes ?? '').split(' ').contains(kActiveBoundaryWithinMarker),
      );
      expect(box, hasLength(1));
      _expectNoScope();
    });
  });
}
