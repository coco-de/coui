// A control's resting edge is its only boundary: it rests on `outline`, and
// the glyph-entry fields step to `on-surface` under the pointer.
//
// Classes are compared whole. `border-outline` is a prefix of
// `border-outline-variant`, so a substring check passes for the hairline tone
// this change moved the controls off.

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

Set<String> _classesOf(String? classes) =>
    (classes ?? '').split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toSet();

ResolvedTextField _field(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
}) => resolveTextField(
  context,
  scopeId: 'tf',
  size: CoreComponentSize.md,
  expands: false,
  hasError: hasError,
  enabled: enabled,
  variant: hasError
      ? CoreTextFieldVariant.error
      : CoreTextFieldVariant.defaultVariant,
);

ResolvedTextArea _area(
  BuildContext context, {
  bool hasError = false,
  bool enabled = true,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: hasError,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  enabled: enabled,
);

void main() {
  group('TextField', () {
    // The wrapper is the box and takes focus through `focus-within:`, which
    // Tailwind emits BEFORE `hover:` — a plain `hover:` class would beat the
    // focus tint while the pointer sits over a focused field. The wrapper's
    // hover step excludes focus in the selector.
    testComponents(
      'rests on outline-variant and steps to outline on hover (#5747)',
      (
        tester,
      ) async {
        final classes = _classesOf(
          _field(_themedContext(tester)).affixWrapper.className,
        );
        expect(classes, contains('border-outline-variant'));
        expect(classes, isNot(contains('border-outline')));
        expect(
          classes,
          contains('[&:hover:not(:focus-within)]:border-outline'),
        );
        expect(classes, contains('focus-within:border-primary'));
        expect(classes, isNot(contains('hover:border-on-surface')));
      },
    );

    testComponents('error outranks hover — the pointer keeps the error edge', (
      tester,
    ) async {
      final classes = _classesOf(
        _field(
          _themedContext(tester),
          hasError: true,
        ).affixWrapper.className,
      );
      expect(classes, contains('border-error'));
      expect(classes, contains('[&:hover:not(:focus-within)]:border-error'));
      expect(classes, isNot(contains('hover:border-on-surface')));
    });

    testComponents('disabled states its own edge and keeps the pointer off', (
      tester,
    ) async {
      final field = _field(_themedContext(tester), enabled: false);
      expect(
        _classesOf(field.affixWrapper.className),
        contains('border-disabled-outline'),
      );
      expect(
        _classesOf(field.input.className),
        contains('disabled:pointer-events-none'),
      );
    });

    testComponents('the input paints no box of its own', (tester) async {
      final classes = _classesOf(
        _field(_themedContext(tester)).input.className,
      );
      expect(classes, contains('border-0'));
      expect(classes, contains('bg-transparent'));
      expect(classes.where((c) => c.startsWith('hover:border')), isEmpty);
      expect(
        classes.where((c) => c.startsWith('focus-visible:border')),
        isEmpty,
      );
    });
  });

  group('TextArea', () {
    testComponents(
      'rests on outline-variant and steps to outline on hover (#5747)',
      (
        tester,
      ) async {
        final classes = _classesOf(
          _area(_themedContext(tester)).affixWrapper.className,
        );
        expect(classes, contains('border-outline-variant'));
        expect(classes, isNot(contains('border-outline')));
        expect(
          classes,
          contains('[&:hover:not(:focus-within)]:border-outline'),
        );
      },
    );

    testComponents('error outranks hover', (tester) async {
      final classes = _classesOf(
        _area(_themedContext(tester), hasError: true).affixWrapper.className,
      );
      expect(classes, contains('border-error'));
      expect(classes, contains('[&:hover:not(:focus-within)]:border-error'));
      expect(classes, isNot(contains('hover:border-on-surface')));
    });
    testComponents('focus outranks hover on the wrapper', (tester) async {
      final classes = _classesOf(
        _area(_themedContext(tester)).affixWrapper.className,
      );
      expect(classes, contains('focus-within:border-primary'));
      expect(
        classes,
        contains('[&:hover:not(:focus-within)]:border-outline'),
      );
      expect(classes, isNot(contains('hover:border-on-surface')));
    });
  });
}
