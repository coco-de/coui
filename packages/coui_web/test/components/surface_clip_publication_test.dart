// A surface that clips its own content cannot simply say how wide its border
// is: the band is an absolutely placed pseudo-element, a clip stops at the
// padding box, and a band widened over the border would sit in the part the
// clip removes — it would vanish rather than reach the edge.
//
// So where a material draws its own edge — the border is then a transparent
// spacer, not a line — the surface lets the material fold the spacer into its
// padding. It states its `border-style` through `--coui-surface-edge-style`,
// owes a matching padding through `--coui-surface-clip-pad`, and the stylesheet
// sets the style to `none` and the fold flag to `1`: the box is the size it was
// and the content stands where it stood, but the padding box the clip stops at
// is the border box, so the band at `inset: 0` is on the outer edge. Nothing
// touches `overflow`, so this is the same in every browser. The style, not the
// width, is what folds: a width would be transitioned while the padding that
// replaces it jumped. Every other style leaves the hooks unset, and unset they
// change nothing.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';
import '../helpers/surface_fold.dart';

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

/// Every surface the widget rendered that says it clips.
List<DomComponent> _clipping() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((d) {
      final classes = (d.classes ?? '').split(' ');
      return classes.contains(kWebSurfaceMarker) &&
          classes.contains(kWebSurfaceClipMarker);
    })
    .toList();

/// The padding owed, as a surface that states padding adds it to every side.
final String _owed = 'var($kWebSurfaceClipPadVar,${spaceCss(0)})';

String _treatment(
  CoreSurfaceStyleId id,
  CoreSurfaceRole role, {
  int depth = 0,
}) => ThemeConfig.defaults().surfaceStyleTreatmentBlock(
  id,
  CoreSurfaceRecipe.of(id).surfaceFor(role),
  role: role,
  depth: depth,
);

String _scope(CoreSurfaceRole role) => switch (role) {
  CoreSurfaceRole.content => kWebSurfaceRoleContent,
  CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
};

/// The selector the stylesheet states the fold for one role under.
String _marked(CoreSurfaceRole role) =>
    '[data-coui-style="liquidGlass"] '
    '.$kWebSurfaceMarker.${_scope(role)}.$kWebSurfaceClipMarker';

/// What a surface that clips states so a material can fold its border: the
/// style through the hook, and the padding owed — the border's own width
/// scaled by the fold flag. Returns the border width it states.
String _statedFold(Map<String, String> inline) {
  final width = inline['border-width']!;
  expect(
    inline['border-style'],
    'var($kWebSurfaceEdgeStyleVar,solid)',
    reason: 'the style is the hook, which falls back to what it drew',
  );
  expect(
    inline[kWebSurfaceClipPadVar],
    'calc($width * var($kWebSurfaceFoldVar,0))',
    reason: 'the padding owed is exactly the border the hook can fold',
  );
  // The uniform width of the band is never stated: with the border folded the
  // band's inset is zero, and with it kept the band is not drawn.
  expect(inline.containsKey(kWebSurfaceBleedVar), isFalse);

  return width;
}

void main() {
  group('the stylesheet folds the border only where it is a spacer', () {
    for (final role in CoreSurfaceRole.values) {
      test('the ${role.name} fold sets the hooks on the marked surface', () {
        final css = _treatment(CoreSurfaceStyleId.liquidGlass, role);

        expect(
          css,
          contains(
            '${_marked(role)}'
            '{$kWebSurfaceEdgeStyleVar:none;$kWebSurfaceFoldVar:1;}',
          ),
        );
      });

      test(
        'and a surface that states no padding gets it, at no specificity',
        () {
          // A padding the caller gives — a class or an inline value — still
          // wins and takes the whole inset on itself.
          final css = _treatment(CoreSurfaceStyleId.liquidGlass, role);

          expect(
            css,
            contains(
              ':where(${_marked(role)})'
              '{padding:var($kWebSurfaceClipPadVar,0px);}',
            ),
          );
        },
      );

      test('forced colours and more contrast get the border back', () {
        // Both want a line there, and a zeroed width would draw none.
        final css = _treatment(CoreSurfaceStyleId.liquidGlass, role);

        for (final media in ['forced-colors:active', 'prefers-contrast:more']) {
          expect(
            css,
            contains(
              '@media ($media){'
              '${_marked(role)}'
              '{$kWebSurfaceEdgeStyleVar:initial;'
              '$kWebSurfaceFoldVar:initial;}}',
            ),
            reason: media,
          );
        }
      });

      test('a nested level does not say it a second time', () {
        // The rule at depth zero already matches a surface at any depth.
        final css = _treatment(CoreSurfaceStyleId.liquidGlass, role, depth: 1);

        expect(css, isNot(contains(kWebSurfaceFoldVar)));
      });

      test('and the clip is the one the component drew', () {
        // Nothing here moves the clip, so no engine has to support a way of
        // moving it.
        final css = _treatment(CoreSurfaceStyleId.liquidGlass, role);

        expect(css, isNot(contains('overflow-clip-margin')));
        expect(css, isNot(contains('overflow:clip')));
        expect(css, isNot(contains('@supports')));
      });
    }

    for (final id in CoreSurfaceStyleId.values.where(
      (id) => id != CoreSurfaceStyleId.liquidGlass,
    )) {
      test('${id.name} leaves the border the component drew', () {
        // A visible border is a line, not a spacer: folding it would lose it.
        for (final role in CoreSurfaceRole.values) {
          expect(
            _treatment(id, role),
            isNot(contains('$kWebSurfaceFoldVar:1')),
            reason: '${id.name} ${role.name}',
          );
        }
      });
    }

    test('every marked surface starts from the border it drew', () {
      // The hook inherits: a clipping surface nested in a folded one would
      // otherwise read its ancestor's zero and lose its own border.
      expect(
        ThemeConfig.defaults().cssVariables,
        allOf(
          contains('$kWebSurfaceEdgeStyleVar:initial;'),
          contains('$kWebSurfaceFoldVar:initial;'),
        ),
      );
    });
  });

  group('a surface that clips says so, and states its border as a hook', () {
    testComponents('an outlined container', (tester) async {
      pumpWithTheme(
        tester,
        const OutlinedContainer(child: Component.text('x')),
      );

      final boxes = _clipping();
      expect(boxes, hasLength(1));
      final inline = boxes.single.styles!.properties;
      expect(
        _statedFold(inline),
        strokeWidthCss(CoreOutlinedContainerStyle.defaultBorderWidth),
      );
      // It states no padding of its own, so it adds none: the stylesheet gives
      // it the folded border's width, and a caller's padding wins over that.
      expect(inline.containsKey('padding'), isFalse);
    });

    testComponents('an outlined container with padding adds what it owes', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const OutlinedContainer(
          containerStyle: CoreOutlinedContainerStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
          child: Component.text('x'),
        ),
      );

      final inline = _clipping().single.styles!.properties;
      expect(
        inline['padding'],
        'calc(${spaceCss(CoreSpace.space8)} + $_owed)',
      );
      expect(unfoldSurfaceEdge(inline['padding']!), spaceCss(CoreSpace.space8));
    });

    testComponents('a directional padding is added side by side', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const OutlinedContainer(
          containerStyle: CoreOutlinedContainerStyle(
            padding: CoreEdgeInsets.directional(
              start: 4,
              top: 8,
              end: 16,
              bottom: 24,
            ),
          ),
          child: Component.text('x'),
        ),
      );

      final inline = _clipping().single.styles!.properties;
      for (final (property, side) in [
        ('padding-inline-start', 4.0),
        ('padding-block-start', 8.0),
        ('padding-inline-end', 16.0),
        ('padding-block-end', 24.0),
      ]) {
        expect(
          inline[property],
          'calc(${spaceCss(side)} + $_owed)',
          reason: property,
        );
      }
    });

    testComponents('one that does not clip states a plain border', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const OutlinedContainer(
          containerStyle: CoreOutlinedContainerStyle(clipBehavior: .none),
          child: Component.text('x'),
        ),
      );

      expect(_clipping(), isEmpty);
    });

    testComponents('a popup', (tester) async {
      pumpWithTheme(tester, const Popup(children: [Component.text('x')]));

      final panels = _clipping();
      expect(panels, hasLength(1));
      final inline = panels.single.styles!.properties;
      expect(
        _statedFold(inline),
        strokeWidthCss(CorePopupStyle.defaultBorderWidth),
      );
      // A Popup measures its padding from the outer edge, so it takes the
      // border it actually keeps out of it — folded, that is nothing, and the
      // padding is the whole inset.
      expect(
        inline['padding'],
        contains('var($kWebSurfaceClipPadVar,'),
      );
    });

    testComponents('a command palette', (tester) async {
      final resolved = resolveCommand(_themedContext(tester));
      final classes = resolved.root.className.split(' ');
      final inline = resolved.root.inlineStyles?.properties ?? const {};

      expect(classes, contains(kWebSurfaceClipMarker));
      _statedFold(inline);
      expect(inline.containsKey('padding'), isFalse);
    });

    testComponents('a phone input', (tester) async {
      pumpWithTheme(tester, const PhoneInput());

      final frames = _clipping();
      expect(frames, hasLength(1));
      final inline = frames.single.styles!.properties;
      _statedFold(inline);
      // Whatever padding it states, it adds what it owes.
      if (inline.containsKey('padding')) {
        expect(
          inline['padding'],
          contains('var($kWebSurfaceClipPadVar,${spaceCss(0)})'),
        );
      }
    });

    testComponents('a window panel', (tester) async {
      pumpWithTheme(tester, const WindowPanel(child: Component.text('x')));

      final frames = _clipping();
      expect(frames, hasLength(1));
      final inline = frames.single.styles!.properties;
      _statedFold(inline);
      expect(inline.containsKey('padding'), isFalse);
    });
  });
}
