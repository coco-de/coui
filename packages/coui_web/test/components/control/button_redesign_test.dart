import 'package:coui_web/coui_web.dart';
// button_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// What the redesigned `Button` emits on Web, read from the resolver's
/// class list and scoped rules rather than from the style it was given.
///
/// The Flutter twin has the same file; the claims are the same ones:
/// secondary is a tonal fill that washes on hover and press, destructive is
/// a filled control, focus is the resting look plus the ring, and a
/// disabled label is one ink on every variant.
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

/// The two rows that fold focus into hover on purpose (`useFocusedAsHover`).
const Set<CoreButtonVariant> _kFocusIsHover = {
  CoreButtonVariant.menu,
  CoreButtonVariant.menubar,
};

ResolvedButton _resolve(
  BuildContext context,
  CoreButtonVariant variant, {
  CoreComponentSize size = CoreComponentSize.md,
  CoreButtonStyle? style,
}) => resolveButton(
  context,
  variant: variant,
  size: size,
  shape: CoreButtonShape.rectangle,
  expanded: false,
  buttonStyle: style,
);

List<String> _classes(ResolvedButton resolved) =>
    resolved.root.className.split(' ');

String _name(CoreColorToken token) => CoreColor.token(token).tailwindColor;

void main() {
  group('secondary is a tonal fill', () {
    testComponents(
      'rests on secondaryContainer with onSecondaryContainer ink',
      (
        tester,
      ) async {
        final classes = _classes(
          _resolve(_themedContext(tester), CoreButtonVariant.secondary),
        );

        expect(classes, contains('bg-${_name(CoreColors.secondaryContainer)}'));
        expect(
          classes,
          contains('text-${_name(CoreColors.onSecondaryContainer)}'),
        );
        // The retired container-swap classes are not emitted.
        expect(
          classes,
          isNot(contains('hover:bg-${_name(CoreColors.secondaryHover)}')),
        );
        expect(
          classes,
          isNot(contains('active:bg-${_name(CoreColors.secondaryPressed)}')),
        );
      },
    );

    testComponents('hover and pressed are a wash, not a swapped fill', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final rules = resolveButtonRules(
        context,
        scopeId: 'b',
        variant: CoreButtonVariant.secondary,
      ).css.replaceAll(' ', '');
      final ink = CoreColors.onSecondaryContainer.name;

      expect(rules, contains('#b:hover{background-color:color-mix('));
      expect(rules, contains('rgb(var(--coui-$ink))3%'));
      expect(rules, contains('#b:active{background-color:color-mix('));
      expect(rules, contains('rgb(var(--coui-$ink))12%'));
    });
  });

  group('tonal is secondary with the brand container pair', () {
    testComponents('rests on primaryContainer with onPrimaryContainer ink', (
      tester,
    ) async {
      final classes = _classes(
        _resolve(_themedContext(tester), CoreButtonVariant.tonal),
      );

      expect(classes, contains('bg-${_name(CoreColors.primaryContainer)}'));
      expect(classes, contains('text-${_name(CoreColors.onPrimaryContainer)}'));
      expect(classes.where((c) => c.startsWith('border-')), isEmpty);
    });

    testComponents('hover and pressed are a wash of the brand ink', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final rules = resolveButtonRules(
        context,
        scopeId: 'b',
        variant: CoreButtonVariant.tonal,
      ).css.replaceAll(' ', '');
      final ink = CoreColors.onPrimaryContainer.name;

      expect(rules, contains('#b:hover{background-color:color-mix('));
      expect(rules, contains('rgb(var(--coui-$ink))3%'));
      expect(rules, contains('#b:active{background-color:color-mix('));
      expect(rules, contains('rgb(var(--coui-$ink))12%'));
    });
  });

  group('outline draws the pale boundary', () {
    testComponents('the stroke is outlineVariant, not outline', (
      tester,
    ) async {
      final classes = _classes(
        _resolve(_themedContext(tester), CoreButtonVariant.outline),
      );

      expect(classes, contains('border-${_name(CoreColors.outlineVariant)}'));
      expect(classes, isNot(contains('border-${_name(CoreColors.outline)}')));
    });
  });

  group('destructive is tinted at rest and filled under the pointer', () {
    testComponents('errorContainer at rest, onErrorContainer ink, no stroke', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.destructive,
      );
      final classes = _classes(resolved);

      expect(classes, contains('bg-${_name(CoreColors.errorContainer)}'));
      expect(classes, contains('text-${_name(CoreColors.onErrorContainer)}'));
      expect(classes, isNot(contains('border')));
      expect(classes.where((c) => c.startsWith('border-')), isEmpty);
    });

    testComponents('hover is error, pressed is errorPressed, both with onError '
        'ink', (tester) async {
      final classes = _classes(
        _resolve(_themedContext(tester), CoreButtonVariant.destructive),
      );

      expect(classes, contains('hover:bg-${_name(CoreColors.error)}'));
      expect(classes, contains('active:bg-${_name(CoreColors.errorPressed)}'));
      expect(classes, contains('hover:text-${_name(CoreColors.onError)}'));
      expect(classes, contains('active:text-${_name(CoreColors.onError)}'));
    });

    testComponents('disabled is the disabled container with no stroke', (
      tester,
    ) async {
      final classes = _classes(
        _resolve(_themedContext(tester), CoreButtonVariant.destructive),
      );

      expect(
        classes,
        contains('disabled:bg-${_name(CoreColors.disabledContainer)}'),
      );
      expect(
        classes.where((c) => c.startsWith('disabled:border-')),
        isEmpty,
      );
    });
  });

  group('focus is the resting look plus the ring', () {
    for (final variant in CoreButtonVariant.values) {
      if (_kFocusIsHover.contains(variant)) continue;

      testComponents('${variant.name} emits no focus colour', (tester) async {
        final context = _themedContext(tester);
        final classes = _classes(_resolve(context, variant));

        // A `focus-visible:` colour class is a second look for focus; the
        // ring (`focus-visible:outline-*`) is the only focus statement.
        final colourClasses = classes.where(
          (c) =>
              c.startsWith('focus-visible:bg-') ||
              c.startsWith('focus-visible:text-') ||
              c.startsWith('focus-visible:border-') ||
              c.startsWith('focus:bg-') ||
              c.startsWith('focus:text-') ||
              c.startsWith('focus:border-'),
        );
        expect(colourClasses, isEmpty, reason: variant.name);

        final rules = resolveButtonRules(
          context,
          scopeId: 'b',
          variant: variant,
        ).css;
        // No wash weight is drawn for focus either.
        expect(
          rules.replaceAll(' ', '').contains('#b:focus-visible{background'),
          isFalse,
          reason: variant.name,
        );
      });
    }

    for (final variant in _kFocusIsHover) {
      testComponents('${variant.name} folds focus into hover, on purpose', (
        tester,
      ) async {
        final classes = _classes(_resolve(_themedContext(tester), variant));

        expect(classes.where((c) => c.startsWith('focus:bg-')), isNotEmpty);
      });
    }

    testComponents('the ring itself is still emitted', (tester) async {
      final classes = _classes(
        _resolve(_themedContext(tester), CoreButtonVariant.primary),
      );

      expect(
        classes.where((c) => c.startsWith('focus-visible:outline-')),
        isNotEmpty,
      );
    });
  });

  group('a disabled label is one ink on every variant', () {
    for (final variant in CoreButtonVariant.values) {
      testComponents('${variant.name} is disabledContent', (tester) async {
        final classes = _classes(_resolve(_themedContext(tester), variant));

        expect(
          classes,
          contains('disabled:text-${_name(CoreColors.disabledContent)}'),
        );
      });
    }
  });

  group('the xs label', () {
    testComponents('is the 12px role', (tester) async {
      final context = _themedContext(tester);
      final xs = _resolve(
        context,
        CoreButtonVariant.primary,
        size: CoreComponentSize.xs,
      );

      // The role that carries 12px is the typography scale's to decide, so
      // read the size back from the role the row states.
      final role = CoreButtonStyle
          .defaultsBySize[CoreComponentSize.xs]!
          .labelStyle!
          .token!;
      expect(role.read(CoreTypography.coui).fontSize, CoreFontSize.s12);
      expect(_classes(xs), contains('text-${role.name}'));
      expect(
        _classes(xs),
        isNot(contains('text-${CoreTextStyles.labelMedium.name}')),
      );
    });
  });
}
