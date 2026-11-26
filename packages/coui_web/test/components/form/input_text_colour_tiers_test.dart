// The text a field paints is three tiers — value `on-surface`, label
// `on-surface-variant`, helper · affix · disabled label `on-surface-subtle`.
//
// `coui_core/test/input_text_colour_tiers_test.dart` pins the tokens. This
// file pins that the Web resolvers put them on the right element as the right
// class: that `TextArea` does not push its value ink over the label, that
// it forwards its disabled-label tint, that the prefix / suffix glyph colour
// is its own slot (the helper's colour is not reused for it, so recolouring
// one never moves the other), and that a `FormField` — which does not hand
// `enabled` to its label — mutes the label through its overlay. The Flutter
// twin makes the same claims in `coui_flutter`'s file of the same name.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/form_field/form_field_style.dart';
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

ResolvedTextField _field(
  BuildContext context, {
  bool enabled = true,
  CoreTextFieldStyle? style,
}) => resolveTextField(
  context,
  scopeId: 'tf',
  size: CoreComponentSize.md,
  expands: false,
  hasError: false,
  enabled: enabled,
  textFieldStyle: style,
);

ResolvedTextArea _area(
  BuildContext context, {
  bool enabled = true,
  CoreTextAreaStyle? style,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: false,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  enabled: enabled,
  textAreaStyle: style,
);

/// The label `<label>` chrome a field raw-forwards its `formLabelStyle` to.
ResolvedFormLabel _label(
  BuildContext context,
  CoreFormLabelStyle? forwarded, {
  required bool enabled,
}) => resolveFormLabel(
  context,
  size: CoreComponentSize.md,
  enabled: enabled,
  formLabelStyle: forwarded,
);

/// The `text-*` colour classes of [className], leaving the typography role
/// classes (`text-label-*`, `text-body-*` …) out.
Set<String> _colours(String className) => className
    .split(' ')
    .where(
      (c) =>
          c.startsWith('text-') &&
          !RegExp(
            '^text-(display|headline|title|body|label|code)-',
          ).hasMatch(c),
    )
    .toSet();

void main() {
  group('TextField', () {
    testComponents('the helper and the affix slots carry on-surface-subtle', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _field(context);

      expect(_colours(r.description.className), {'text-on-surface-subtle'});
      expect(_colours(r.leadingSlot.className), {'text-on-surface-subtle'});
      expect(_colours(r.trailingSlot.className), {'text-on-surface-subtle'});
    });

    testComponents('an enabled label is on-surface-variant, a disabled one is '
        'on-surface-subtle', (tester) async {
      final context = _themedContext(tester);

      final on = _label(
        context,
        _field(context).formLabelStyle,
        enabled: true,
      );
      final off = _label(
        context,
        _field(context, enabled: false).formLabelStyle,
        enabled: false,
      );
      expect(_colours(on.root.className), {'text-on-surface-variant'});
      expect(_colours(off.root.className), {'text-on-surface-subtle'});
    });
  });

  group('TextArea', () {
    testComponents('the helper carries on-surface-subtle, and so does the '
        'affix slot', (tester) async {
      final context = _themedContext(tester);
      final r = _area(context);

      expect(_colours(r.description.className), {'text-on-surface-subtle'});
      expect(_colours(r.affixSlot.className), {'text-on-surface-subtle'});
    });

    testComponents('the value ink does not reach the label', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final r = _area(context);

      // Nothing stated: the enabled label is the composed FormLabel's own
      // colour — the one a TextField beside it paints.
      expect(r.formLabelStyle.labelStyle, isNull);
      expect(
        _colours(
          _label(context, r.formLabelStyle, enabled: true).root.className,
        ),
        {'text-on-surface-variant'},
      );

      // A caller's own label style still reaches the label whole.
      const own = CoreTextStyle(color: CoreColor.token(CoreColors.primary));
      final styled = _area(
        context,
        style: const CoreTextAreaStyle(labelStyle: own),
      );
      expect(styled.formLabelStyle.labelStyle, own);
      expect(
        _colours(
          _label(context, styled.formLabelStyle, enabled: true).root.className,
        ),
        {'text-primary'},
      );
    });

    testComponents('a disabled label is on-surface-subtle, the same tint a '
        'TextField forwards', (tester) async {
      final context = _themedContext(tester);

      final off = _label(
        context,
        _area(context, enabled: false).formLabelStyle,
        enabled: false,
      );
      expect(_colours(off.root.className), {'text-on-surface-subtle'});

      // …and a caller's tint reaches it.
      final tinted = _label(
        context,
        _area(
          context,
          enabled: false,
          style: const CoreTextAreaStyle(
            labelDisabledColor: CoreColor.token(CoreColors.error),
          ),
        ).formLabelStyle,
        enabled: false,
      );
      expect(_colours(tinted.root.className), {'text-error'});
    });

    testComponents('affixColor moves the glyphs and not the helper, '
        'helperTextColor moves the helper and not the glyphs', (tester) async {
      final context = _themedContext(tester);

      final affix = _area(
        context,
        style: const CoreTextAreaStyle(
          affixColor: CoreColor.token(CoreColors.error),
        ),
      );
      expect(_colours(affix.affixSlot.className), {'text-error'});
      expect(_colours(affix.description.className), {'text-on-surface-subtle'});

      final helper = _area(
        context,
        style: const CoreTextAreaStyle(
          helperTextColor: CoreColor.token(CoreColors.error),
        ),
      );
      expect(_colours(helper.description.className), {'text-error'});
      expect(_colours(helper.affixSlot.className), {'text-on-surface-subtle'});
    });

    testComponents('the glyph colour does not change when the area is '
        'disabled', (tester) async {
      final context = _themedContext(tester);

      expect(
        _colours(_area(context, enabled: false).affixSlot.className),
        _colours(_area(context).affixSlot.className),
      );
    });

    testComponents('a raw affix or helper colour is not dropped — it rides '
        'the inline style, where it has no class to ride', (tester) async {
      final context = _themedContext(tester);
      const raw = CoreColor(0xFF00FF00);

      final affix = _area(
        context,
        style: const CoreTextAreaStyle(affixColor: raw),
      );
      expect(_colours(affix.affixSlot.className), isEmpty);
      expect(affix.affixSlot.inlineStyles!.properties['color'], raw.toValue());

      final helper = _area(
        context,
        style: const CoreTextAreaStyle(helperTextColor: raw),
      );
      expect(_colours(helper.description.className), isEmpty);
      expect(
        helper.description.inlineStyles!.properties['color'],
        raw.toValue(),
      );

      // The description slot's own colour outranks the helper colour, as it
      // does on Flutter.
      const slotColor = CoreColor(0xFF112233);
      final both = _area(
        context,
        style: const CoreTextAreaStyle(
          helperTextColor: raw,
          descriptionStyle: CoreTextStyle(color: slotColor),
        ),
      );
      expect(
        both.description.inlineStyles!.properties['color'],
        slotColor.toValue(),
      );
    });

    testComponents('the label beside a TextField is the same colour, enabled '
        'and disabled', (tester) async {
      final context = _themedContext(tester);

      for (final enabled in [true, false]) {
        expect(
          _colours(
            _label(
              context,
              _area(context, enabled: enabled).formLabelStyle,
              enabled: enabled,
            ).root.className,
          ),
          _colours(
            _label(
              context,
              _field(context, enabled: enabled).formLabelStyle,
              enabled: enabled,
            ).root.className,
          ),
          reason: 'enabled: $enabled',
        );
      }
    });
  });

  group('FormLabel and FormField', () {
    testComponents('a bare FormLabel is on-surface-variant, disabled is its '
        'own disabled ink', (tester) async {
      final context = _themedContext(tester);

      expect(
        _colours(_label(context, null, enabled: true).root.className),
        {'text-on-surface-variant'},
      );
      expect(
        _colours(_label(context, null, enabled: false).root.className),
        {'text-disabled-content'},
      );
    });

    testComponents('a FormField label mutes to on-surface-subtle when the '
        'field is disabled — the overlay is its whole disabled signal', (
      tester,
    ) async {
      final context = _themedContext(tester);

      // FormField does not hand `enabled` to the label (Web, like Flutter),
      // so the label is resolved enabled with the overlay forwarded.
      final on = _label(
        context,
        resolveFormField(context, enabled: true).formLabelStyle,
        enabled: true,
      );
      final off = _label(
        context,
        resolveFormField(context, enabled: false).formLabelStyle,
        enabled: true,
      );
      expect(_colours(on.root.className), {'text-on-surface-variant'});
      expect(_colours(off.root.className), {'text-on-surface-subtle'});
    });

    testComponents('the FormField label beside a TextField label reads the '
        'same colour, enabled and disabled', (tester) async {
      final context = _themedContext(tester);

      expect(
        _colours(
          _label(
            context,
            resolveFormField(context, enabled: true).formLabelStyle,
            enabled: true,
          ).root.className,
        ),
        _colours(
          _label(
            context,
            _field(context).formLabelStyle,
            enabled: true,
          ).root.className,
        ),
      );
      expect(
        _colours(
          _label(
            context,
            resolveFormField(context, enabled: false).formLabelStyle,
            enabled: true,
          ).root.className,
        ),
        _colours(
          _label(
            context,
            _field(context, enabled: false).formLabelStyle,
            enabled: false,
          ).root.className,
        ),
      );
    });
  });
}
