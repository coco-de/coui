import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// A material opacity every test below states explicitly — the API this
/// helper mirrors ([ThemeData.copyWith]) can only *set* an opacity, not
/// switch one off, so every call site here states one rather than relying
/// on a null branch nothing exercises.
const _kMaterialOpacity = 0.6;

/// The alpha tolerance `closeTo` checks below fold through.
const _kAlphaTolerance = 0.01;

/// The opacity `nestedSurfaces` states one level of nesting deep.
const _kNestedOpacity = 0.3;

/// The opacity a hand-built `functionalSurface` states.
const _kFunctionalOpacity = 0.4;

/// A hand-built theme whose flat surface fields reach `Theme.of(context)`
/// verbatim.
///
/// `applySurfaceStyle` folds a preset onto a base theme, but the default
/// preset (`.defaultId`, what `pumpTestApp` uses when `surfaceStyle` is
/// omitted) states identity on all four axes and returns `base` unchanged
/// — the same "theme built by hand" pattern
/// `surface_treatment_transport_test.dart` documents. Building the
/// material this way, rather than through `CoreSurfaceStyleId.liquidGlass`,
/// keeps these tests independent of whatever numbers that preset happens
/// to author today.
ThemeData _handBuilt({
  required double surfaceOpacity,
  bool surfaceDrawsOwnEdge = false,
  CoreSurfaceEdgeSheen? surfaceSheen,
  CoreSurfaceToken? functionalSurface,
  Map<CoreSurfaceRole, List<CoreSurfaceToken>>? nestedSurfaces,
}) => .fromCore(CoreThemePresets.light).copyWith(
  surfaceOpacity: () => surfaceOpacity,
  surfaceSheen: () => surfaceSheen,
  surfaceDrawsOwnEdge: () => surfaceDrawsOwnEdge,
  functionalSurface: () => functionalSurface,
  nestedSurfaces: () => nestedSurfaces,
);

/// A minimal edge sheen — `ThemeData._contentMaterial` folds
/// `surfaceDrawsOwnEdge` into the assembled token only when a sheen is
/// also present (mirrors `CoreSurfaceToken`'s own assert: a material that
/// claims its own edge and paints no band leaves no boundary at all).
const _kSheen = CoreSurfaceEdgeSheen(
  width: 1,
  lightColor: CoreColor.token(CoreColors.outline),
  darkColor: CoreColor.token(CoreColors.outline),
);

BoxDecoration _decoration(WidgetTester tester, {required Key key}) {
  // Button's own chrome `AnimatedContainer` is the one carrying a
  // `decoration` — `Clickable`'s engage-shift wrapper (present whenever
  // the active style states a diagonal-offset vocabulary, e.g.
  // neo-brutalism) is a sibling `AnimatedContainer` that only ever sets
  // `transform`, never `decoration` (mirrors `button_hover_engage_test
  // .dart`'s `shiftTransform`, the same disambiguation the other way).
  final container = tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .firstWhere((w) => w.decoration != null);
  return container.decoration! as BoxDecoration;
}

void main() {
  group('non-glass presets — content role stays a no-op', () {
    for (final style in const [
      CoreSurfaceStyleId.defaultStyle,
      CoreSurfaceStyleId.neoBrutalism,
      CoreSurfaceStyleId.claymorphism,
      CoreSurfaceStyleId.neumorphism,
    ]) {
      testWidgets('${style.name}: primary idle fill is fully opaque', (
        tester,
      ) async {
        // None of these presets state a content-role material — this
        // pins that wiring the material seat into Button did not give
        // any of them one by accident.
        await pumpTestApp(
          tester,
          Button(
            key: const ValueKey('b'),
            onPressed: () {},
            child: const Text('Submit'),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: style,
        );
        await tester.pump();

        expect(_decoration(tester, key: const ValueKey('b')).color!.a, 1.0);
      });
    }
  });

  group('a hand-built content-role material scales every state', () {
    testWidgets(
      'idle / disabled fold the same opacity into whichever token each '
      'state already authors',
      (tester) async {
        await pumpTestApp(
          tester,
          const Column(
            children: [
              // primary idle authors an opaque `primary` token.
              Button(
                key: ValueKey('idle'),
                child: Text('idle'),
              ),
              // primary disabled authors an opaque `surfaceContainerHigh`
              // token — a *different* token from idle, so this also pins
              // that the fold isn't hardcoded to one field.
              Button(key: ValueKey('disabled'), child: Text('disabled')),
            ],
          ),
          theme: _handBuilt(surfaceOpacity: _kMaterialOpacity),
        );
        await tester.pump();

        expect(
          _decoration(tester, key: const ValueKey('idle')).color!.a,
          closeTo(_kMaterialOpacity, _kAlphaTolerance),
        );
        expect(
          _decoration(tester, key: const ValueKey('disabled')).color!.a,
          closeTo(_kMaterialOpacity, _kAlphaTolerance),
        );
      },
    );

    testWidgets('a fully transparent variant is unaffected — 0 stays 0', (
      tester,
    ) async {
      // `ghost` authors backgroundColor at opacity 0. Scaling zero by
      // anything is still zero — the material must not lift a fill a
      // variant deliberately stated as absent.
      await pumpTestApp(
        tester,
        const Button(
          key: ValueKey('b'),
          variant: .ghost,
          child: Text('Ghost'),
        ),
        theme: _handBuilt(surfaceOpacity: _kMaterialOpacity),
      );
      await tester.pump();

      expect(_decoration(tester, key: const ValueKey('b')).color!.a, 0.0);
    });
  });

  group('drawsOwnEdge suppresses the border colour, never the width', () {
    testWidgets('outline variant loses its stroke colour but keeps width', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Button(
          key: ValueKey('b'),
          variant: .outline,
          child: Text('Outline'),
        ),
        theme: _handBuilt(
          surfaceOpacity: 1,
          surfaceDrawsOwnEdge: true,
          surfaceSheen: _kSheen,
        ),
      );
      await tester.pump();

      final decoration = _decoration(tester, key: const ValueKey('b'));
      final border = decoration.border! as Border;
      expect(
        border.top.color.a,
        0.0,
        reason:
            'the material draws its own edge — the component stroke '
            'colour must go transparent',
      );
      expect(
        border.top.width,
        greaterThan(0),
        reason:
            'suppression is colour-only — a zeroed width would '
            'shrink the box by 2px per axis on a style swap that is '
            'supposed to change paint alone',
      );
    });

    testWidgets('a stroke the caller states gives way too', (tester) async {
      // The Web twin's rule clears an inline caller colour with
      // `!important`, and every `OutlinedContainer` surface suppresses the
      // merged colour — so a stated border is no exception here either.
      await pumpTestApp(
        tester,
        Button(
          key: const ValueKey('b'),
          variant: .outline,
          buttonStyle: const CoreButtonStyle(
            borderColor: CoreColor.token(CoreColors.primary),
          ),
          onPressed: () {},
          child: const Text('Outline'),
        ),
        theme: _handBuilt(
          surfaceOpacity: 1,
          surfaceDrawsOwnEdge: true,
          surfaceSheen: _kSheen,
        ),
      );
      await tester.pump();

      final border =
          _decoration(tester, key: const ValueKey('b')).border! as Border;
      expect(border.top.color.a, 0.0);
      expect(border.top.width, greaterThan(0));
    });

    testWidgets('a button that rests unfilled keeps a stroke it states', (
      tester,
    ) async {
      // Suppression is what a band pays for. A button that rests unfilled
      // takes no material, so it draws no band and its stroke is the only
      // boundary it has — the Web twin carries no surface marker for the
      // style rule to clear, so it keeps the stroke the same way.
      await pumpTestApp(
        tester,
        Button(
          key: const ValueKey('b'),
          variant: .ghost,
          buttonStyle: const CoreButtonStyle(
            borderColor: CoreColor.token(CoreColors.outline),
            borderWidth: CoreStrokeWidth.stroke1,
          ),
          onPressed: () {},
          child: const Text('Ghost'),
        ),
        theme: _handBuilt(
          surfaceOpacity: 1,
          surfaceDrawsOwnEdge: true,
          surfaceSheen: _kSheen,
        ),
      );
      await tester.pump();

      final border =
          _decoration(tester, key: const ValueKey('b')).border! as Border;
      expect(border.top.color.a, greaterThan(0));
    });

    testWidgets(
      'no material states at all leaves the outline border exactly as '
      'authored',
      (tester) async {
        await pumpTestApp(
          tester,
          const Button(
            key: ValueKey('b'),
            variant: .outline,
            child: Text('Outline'),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
        );
        await tester.pump();

        final border =
            _decoration(tester, key: const ValueKey('b')).border! as Border;
        expect(border.top.color.a, greaterThan(0));
      },
    );
  });

  group('nesting depth reaches the ambient material', () {
    testWidgets(
      'a button directly in the tree reads depth 0; one under an ambient '
      'SurfaceDepth reads the nested entry',
      (tester) async {
        // `SurfaceDepth` is only inserted by `SurfaceBlur`, which
        // `OutlinedContainer` wraps its body in *conditionally* — only
        // when the container's own resolved material states blur or
        // sheen (`outlined_container.dart`: `if ((blurSigma != null &&
        // blurSigma > 0) || sheen != null)`). A `Card` whose material
        // states neither (every non-glass preset, and this test's own
        // `_handBuilt` with only `surfaceOpacity` set) never increments
        // depth for its child — that gap is a property of the
        // depth-tracking mechanism itself, not of this wiring, and is
        // out of scope for #4360. So this test drives `SurfaceDepth`
        // directly, the same ambient signal an upstream blurred/sheened
        // surface would leave, to isolate what this task actually
        // changed: that Button's resolver reads it at all.
        const nestedToken = CoreSurfaceToken(
          type: .flat,
          opacity: CoreSurfaceOpacity.same(_kNestedOpacity),
        );
        await pumpTestApp(
          tester,
          const Column(
            children: [
              Button(key: ValueKey('depth0'), child: Text('depth0')),
              SurfaceDepth(
                depth: 1,
                child: Button(key: ValueKey('depth1'), child: Text('depth1')),
              ),
            ],
          ),
          theme: _handBuilt(
            surfaceOpacity: 1,
            nestedSurfaces: {
              .content: [nestedToken],
              // Exhaustive on purpose — a nesting entry with nothing to
              // say for the functional role states that explicitly
              // rather than by omission.
              .functional: const [],
            },
          ),
        );
        await tester.pump();

        expect(
          _decoration(tester, key: const ValueKey('depth0')).color!.a,
          closeTo(1.0, _kAlphaTolerance),
          reason: 'depth 0 reads the base content material (opacity 1)',
        );
        expect(
          _decoration(tester, key: const ValueKey('depth1')).color!.a,
          closeTo(_kNestedOpacity, _kAlphaTolerance),
          reason: 'nested one level deep reads the nestedSurfaces entry',
        );
      },
    );

    testWidgets(
      'a real Card in between does not reset the ambient depth it did '
      'not itself increment',
      (tester) async {
        // Card composes `OutlinedContainer`, which only inserts
        // `SurfaceBlur` — the depth-incrementing widget — when *its own*
        // resolved material states blur or sheen. Under this hand-built
        // theme it states neither, so Card is transparent to the depth
        // counter: it neither raises it nor resets it to 0. This is the
        // literal "button inside a card" composition #4360 names as the
        // first real nesting site, proving Card does not sever the
        // ambient signal a blurred/sheened ancestor further up left
        // behind (simulated here the same way as the test above).
        const nestedToken = CoreSurfaceToken(
          type: .flat,
          opacity: CoreSurfaceOpacity.same(_kNestedOpacity),
        );
        await pumpTestApp(
          tester,
          const SurfaceDepth(
            depth: 1,
            child: Card(
              body: Button(key: ValueKey('inCard'), child: Text('inCard')),
            ),
          ),
          theme: _handBuilt(
            surfaceOpacity: 1,
            nestedSurfaces: {
              .content: [nestedToken],
              .functional: const [],
            },
          ),
        );
        await tester.pump();

        expect(
          _decoration(tester, key: const ValueKey('inCard')).color!.a,
          closeTo(_kNestedOpacity, _kAlphaTolerance),
          reason:
              'Card passes the ambient depth through to its body '
              'unchanged rather than resetting it',
        );
      },
    );
  });

  group('role: .functional switches to the floating material', () {
    testWidgets(
      'a content-role button ignores functionalSurface; a functional-role '
      'one uses it',
      (tester) async {
        const functional = CoreSurfaceToken(
          type: .glass,
          opacity: CoreSurfaceOpacity.same(_kFunctionalOpacity),
        );
        await pumpTestApp(
          tester,
          const Column(
            children: [
              Button(key: ValueKey('content'), child: Text('content')),
              Button(
                key: ValueKey('functional'),
                role: .functional,
                child: Text('functional'),
              ),
            ],
          ),
          theme: _handBuilt(surfaceOpacity: 1, functionalSurface: functional),
        );
        await tester.pump();

        expect(
          _decoration(tester, key: const ValueKey('content')).color!.a,
          closeTo(1.0, _kAlphaTolerance),
        );
        expect(
          _decoration(tester, key: const ValueKey('functional')).color!.a,
          closeTo(_kFunctionalOpacity, _kAlphaTolerance),
        );
      },
    );
  });
}
