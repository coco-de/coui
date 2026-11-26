import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A specific CoUI [Icon]. `find.byIcon` takes Flutter's `IconData`; this
/// kit's `Icon` carries an [IconName], so the predicate form is what the
/// display suites already use.
Finder _iconFinder(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

const _kMaxStackedEntries = 5;
const _kToastLocationCount = 6;
const _kChildText = 'toast child';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('ToastLocation enum', () {
    test('has six values', () {
      expect(ToastLocation.values, hasLength(_kToastLocationCount));
    });

    test('contains all expected locations', () {
      expect(
        ToastLocation.values,
        containsAll([
          ToastLocation.bottomCenter,
          ToastLocation.bottomLeft,
          ToastLocation.bottomRight,
          ToastLocation.topCenter,
          ToastLocation.topLeft,
          ToastLocation.topRight,
        ]),
      );
    });

    group('alignment properties', () {
      test('bottomCenter has Alignment.bottomCenter', () {
        expect(
          ToastLocation.bottomCenter.alignment,
          equals(Alignment.bottomCenter),
        );
      });

      test('bottomLeft has Alignment.bottomLeft', () {
        expect(
          ToastLocation.bottomLeft.alignment,
          equals(Alignment.bottomLeft),
        );
      });

      test('bottomRight has Alignment.bottomRight', () {
        expect(
          ToastLocation.bottomRight.alignment,
          equals(Alignment.bottomRight),
        );
      });

      test('topCenter has Alignment.topCenter', () {
        expect(
          ToastLocation.topCenter.alignment,
          equals(Alignment.topCenter),
        );
      });

      test('topLeft has Alignment.topLeft', () {
        expect(ToastLocation.topLeft.alignment, equals(Alignment.topLeft));
      });

      test('topRight has Alignment.topRight', () {
        expect(
          ToastLocation.topRight.alignment,
          equals(Alignment.topRight),
        );
      });
    });

    group('childrenAlignment properties', () {
      test('bottom locations stack upward (topCenter)', () {
        expect(
          ToastLocation.bottomCenter.childrenAlignment,
          equals(Alignment.topCenter),
        );
        expect(
          ToastLocation.bottomLeft.childrenAlignment,
          equals(Alignment.topCenter),
        );
        expect(
          ToastLocation.bottomRight.childrenAlignment,
          equals(Alignment.topCenter),
        );
      });

      test('top locations stack downward (bottomCenter)', () {
        expect(
          ToastLocation.topCenter.childrenAlignment,
          equals(Alignment.bottomCenter),
        );
        expect(
          ToastLocation.topLeft.childrenAlignment,
          equals(Alignment.bottomCenter),
        );
        expect(
          ToastLocation.topRight.childrenAlignment,
          equals(Alignment.bottomCenter),
        );
      });
    });
  });

  group('ExpandMode enum', () {
    test('has two values', () {
      expect(ExpandMode.values, hasLength(2));
    });

    test('contains alwaysExpanded', () {
      expect(ExpandMode.values, contains(ExpandMode.alwaysExpanded));
    });

    test('contains expandOnHover', () {
      expect(ExpandMode.values, contains(ExpandMode.expandOnHover));
    });
  });

  group('ToastLayer', () {
    testWidgets('renders child widget', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const ToastLayer(
            child: material.Text(_kChildText),
          ),
        ),
      );

      expect(find.text(_kChildText), findsOneWidget);
    });

    testWidgets('renders with custom expandMode', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const ToastLayer(
            expandMode: .alwaysExpanded,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(ToastLayer), findsOneWidget);
    });

    testWidgets('renders with custom maxStackedEntries', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const ToastLayer(
            maxStackedEntries: _kMaxStackedEntries,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(ToastLayer), findsOneWidget);
    });

    testWidgets('child is accessible inside ToastLayer', (tester) async {
      const childKey = material.Key('toast-child');

      final _ = await tester.pumpWidget(
        _buildApp(
          const ToastLayer(
            child: material.SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });
  });

  // The tone lives on a 16px mark, not on the fill — all three variants
  // share one raised surface. So "which variant" is answered by which
  // glyph is on screen, and `neutral` answers it by having none.
  group('Toast leading glyph', () {
    testWidgets('a bare Toast draws none', (tester) async {
      // `defaultVariant` moved off the success variant. A toast that names
      // no variant used to draw a green check — asserting an outcome its
      // caller never stated.
      await tester.pumpWidget(
        _buildApp(const material.Center(child: Toast(message: 'Saved'))),
      );
      await tester.pumpAndSettle();

      expect(_iconFinder(LucideIcons.circleCheck), findsNothing);
      expect(_iconFinder(LucideIcons.circleAlert), findsNothing);
    });

    testWidgets('success draws the check', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Toast(message: 'Saved', variant: CoreToastVariant.success),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_iconFinder(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('destructive draws the alert', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Toast(
              message: 'Saved',
              variant: CoreToastVariant.destructive,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_iconFinder(LucideIcons.circleAlert), findsOneWidget);
      // Not both — the two toned variants are told apart by which mark is
      // there, so a toast showing either the wrong one or an extra one is
      // showing the wrong variant.
      expect(_iconFinder(LucideIcons.circleCheck), findsNothing);
    });
  });

  // `showIcon` is the caller's off switch for the glyph the variant picked:
  // the glyph and the gap after it leave together, and the text opens at the
  // panel's inset. The default draws exactly what a toast always drew.
  group('Toast showIcon', () {
    /// How far the message starts from the panel's left edge, in a 400-wide
    /// slot, for [toast].
    Future<double> messageStart(WidgetTester tester, Toast toast) async {
      await tester.pumpWidget(
        _buildApp(
          material.Center(child: material.SizedBox(width: 400, child: toast)),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.text(toast.message)).dx -
          tester.getTopLeft(find.byType(Toast)).dx;
    }

    test('is on by default, from the contract', () {
      expect(const Toast(message: 'Saved').showIcon, isTrue);
      expect(CoreToastContract.defaultShowIcon, isTrue);
      expect(
        const Toast(
          message: 'Saved',
          variant: CoreToastVariant.success,
        ).showIcon,
        isTrue,
      );
    });

    for (final (variant, glyph) in [
      (CoreToastVariant.success, LucideIcons.circleCheck),
      (CoreToastVariant.destructive, LucideIcons.circleAlert),
    ]) {
      testWidgets('false drops the ${variant.name} glyph and the gap after '
          'it — the message starts at the panel inset', (tester) async {
        final withIcon = await messageStart(
          tester,
          Toast(message: 'Saved', variant: variant),
        );
        expect(_iconFinder(glyph), findsOneWidget);

        final without = await messageStart(
          tester,
          Toast(message: 'Saved', variant: variant, showIcon: false),
        );
        expect(_iconFinder(glyph), findsNothing);

        final theme = Theme.of(tester.element(find.byType(Toast)));
        final inset = CoreToastStyle.defaultPanelPadding.left;
        expect(without, moreOrLessEquals(inset * theme.scaling));
        // The glyph and its gap are exactly what the message moved by.
        final glyphAndGap =
            CoreToastStyle.defaultIconStyle.size! +
            CoreToastStyle.defaultIconContentGapStyle.size!;
        expect(
          withIcon - without,
          moreOrLessEquals(glyphAndGap * theme.scaling),
        );
      });
    }

    testWidgets('an explicit true draws what the default draws', (
      tester,
    ) async {
      final byDefault = await messageStart(
        tester,
        const Toast(message: 'Saved', variant: CoreToastVariant.success),
      );
      final explicit = await messageStart(
        tester,
        const Toast(
          message: 'Saved',
          variant: CoreToastVariant.success,
        ).copyWith(showIcon: true),
      );

      expect(explicit, byDefault);
      expect(_iconFinder(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('changes nothing on neutral — it has no glyph to drop', (
      tester,
    ) async {
      final on = await messageStart(tester, const Toast(message: 'Saved'));
      final off = await messageStart(
        tester,
        const Toast(message: 'Saved', showIcon: false),
      );

      expect(off, on);
      expect(_iconFinder(LucideIcons.circleCheck), findsNothing);
      expect(_iconFinder(LucideIcons.circleAlert), findsNothing);
    });

    testWidgets('keeps the description, the action and the dismiss button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: material.SizedBox(
              width: 400,
              child: Toast(
                message: 'Saved',
                description: 'Your changes have been saved.',
                variant: CoreToastVariant.success,
                showIcon: false,
                action: const material.SizedBox(
                  key: material.ValueKey('action'),
                  width: 40,
                  height: 24,
                ),
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Your changes have been saved.'), findsOneWidget);
      expect(find.byKey(const material.ValueKey('action')), findsOneWidget);
      expect(_iconFinder(LucideIcons.x), findsOneWidget);
      expect(_iconFinder(LucideIcons.circleCheck), findsNothing);
    });

    test('copyWith carries showIcon', () {
      const toast = Toast(message: 'Saved', showIcon: false);

      expect(toast.copyWith(message: 'New').showIcon, isFalse);
      expect(toast.copyWith(showIcon: true).showIcon, isTrue);
    });
  });

  _actionForegroundTests();

  group('Toast close button', () {
    testWidgets('tap invokes onDismiss', (tester) async {
      // Regression: the close button used to hang outside the content
      // Stack's bounds (negative Position offsets), so Flutter hit-testing
      // never reached it — taps and hovers were dead while the glyph was
      // still painted (clip disabled).
      var dismissed = false;

      final _ = await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(
              message: 'Saved',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By glyph, not by type. A toast now draws two icons — the variant's
      // leading mark and the close ✕ — so `byType(Icon)` finds both and
      // `tap` would refuse the ambiguity.
      await tester.tap(_iconFinder(LucideIcons.x));
      expect(dismissed, isTrue);
    });

    // #6214: Toast states no close-glyph size, so the ✕ takes the `md`
    // square button's own (`iconShapeIconStyle`, 18) — the glyph Banner's
    // dismiss draws too. Read off the rendered icon, not the style.
    testWidgets('glyph is the md square button glyph (18)', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(message: 'Saved', onDismiss: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final closeIcon = _iconFinder(LucideIcons.x);
      expect(closeIcon, findsOneWidget);
      expect(tester.getSize(closeIcon), const material.Size(18, 18));
    });

    testWidgets('glyph rests on inverse-on-surface at 70 % and moves to full '
        'inverse-on-surface on hover', (tester) async {
      // Hover highlights only fire in traditional highlight mode — the
      // test binding defaults to touch.
      material.FocusManager.instance.highlightStrategy = .alwaysTraditional;
      final _ = await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(message: 'Saved', onDismiss: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The close ✕ specifically. `byType(Icon)` would also match the
      // variant's leading glyph, whose colour comes from the variant row
      // and does not move.
      final closeIcon = _iconFinder(LucideIcons.x);
      expect(closeIcon, findsOneWidget);

      material.Color effectiveColor() =>
          material.IconTheme.of(tester.element(closeIcon)).color!;

      // The text colour at 70 % — `toast_contrast_test.dart` composites it
      // over the fill, and here it is what the glyph actually receives.
      final resting = effectiveColor();
      final full = _tokenColorAt(
        tester,
        closeIcon,
        CoreColors.inverseOnSurface,
      );
      expect(resting.toARGB32() & 0xFFFFFF, full.toARGB32() & 0xFFFFFF);
      expect(resting.a, moreOrLessEquals(CoreOpacity.opacity70, epsilon: 0.01));
      final slab = _tokenColorAt(tester, closeIcon, CoreColors.inverseSurface);
      expect(
        _contrast(material.Color.alphaBlend(resting, slab), slab),
        greaterThanOrEqualTo(_kNonTextMinimumContrast),
        reason: 'WCAG 1.4.11 for the resting close glyph on the toast fill',
      );

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: material.Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(closeIcon));
      await tester.pumpAndSettle();

      final hovered = effectiveColor();
      expect(
        hovered,
        _tokenColorAt(tester, closeIcon, CoreColors.inverseOnSurface),
      );
      expect(hovered, isNot(resting));
    });
  });
}

// WCAG 1.4.3 — the ratio the ledger measured on the canvas (2.11 : 1) and
// the floor it has to clear. Computed from the rendered colours rather than
// asserted as a token name, because the token name was never the bug: every
// piece of this was "correctly" tokenised and the label still vanished.
const _kMinimumContrast = 4.5;

// WCAG 1.4.11 — a glyph has to be made out, not read.
const _kNonTextMinimumContrast = 3.0;

double _contrast(material.Color a, material.Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The colour a `Button` label actually paints with — `Button` hands its
/// foreground down through `DefaultTextStyle.merge`, so the style the label
/// element sees is the resolved one.
material.Color _labelColorOf(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style.color!;

material.Color _tokenColorAt(
  WidgetTester tester,
  Finder at,
  CoreColorToken token,
) => Theme.of(
  tester.element(at),
).colorScheme.resolve(CoreColor.token(token)).toValue();

void _actionForegroundTests() {
  group('Toast action foreground', () {
    // What this pins: a `Button` is built against the page surface, and the
    // toast states what legible means on its own slab. The toast injects its
    // variant foreground under the action, the way it does under the close
    // button.
    testWidgets('a plain Button action reads on the slab', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(
              message: 'Saved',
              action: Button(
                variant: CoreButtonVariant.plain,
                onPressed: () {},
                child: const Text('Undo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toast = find.byType(Toast);
      final label = _labelColorOf(tester, 'Undo');
      expect(
        label,
        _tokenColorAt(tester, toast, CoreColors.inverseOnSurface),
        reason: 'the action wears the variant foreground',
      );
      final slab = _tokenColorAt(
        tester,
        toast,
        CoreColors.inverseSurface,
      );
      expect(
        _contrast(label, slab),
        greaterThanOrEqualTo(_kMinimumContrast),
        reason: 'WCAG AA on the toast fill',
      );
    });

    testWidgets('a plain action is 6 wider than its label on each side', (
      tester,
    ) async {
      // `plain` sits flush with its label, so on the slab the wash was the
      // word wide — a highlighter stroke rather than a button (#6214).
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(
              message: 'Saved',
              action: Button(
                size: CoreComponentSize.xs,
                variant: CoreButtonVariant.plain,
                onPressed: () {},
                child: const Text('Undo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.getSize(find.byType(Button).first);
      final label = tester.getSize(find.text('Undo'));
      expect(button.width - label.width, CoreSpace.space6 * 2);
    });

    testWidgets('an outline action keeps its own inset on the slab', (
      tester,
    ) async {
      // The inline inset is `plain`'s alone (#6214): an `xs` outline is as
      // wide in a toast as outside one.
      Button outline() => Button(
        size: CoreComponentSize.xs,
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('Undo'),
      );
      await tester.pumpWidget(_buildApp(material.Center(child: outline())));
      await tester.pumpAndSettle();
      final alone = tester.getSize(find.byType(Button)).width;

      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(message: 'Saved', action: outline()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Button).first).width, alone);
    });

    testWidgets('the close button is the md row square — a 40 circle', (
      tester,
    ) async {
      // Same affordance as Banner's dismiss: on the rectangle shape the inset
      // around the 16 glyph drew the wash as a tall pill (#6214).
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Toast(message: 'Saved', onDismiss: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final close = tester.widget<Button>(find.byType(Button).last);
      expect(close.shape, CoreButtonShape.square);
      expect(
        tester.getSize(find.byType(Button).last),
        const material.Size(CoreControlSize.heightMd, CoreControlSize.heightMd),
      );
    });

    testWidgets('the close button sits on the panel centre line', (
      tester,
    ) async {
      // Pinned 8 below the top, the 40 circle sank 4 below the message's
      // centre on a one-line toast; it centres in the panel's height instead,
      // and stays there when a description makes the toast taller (#6214).
      for (final description in <String?>[null, '변경 사항을 저장했어요.']) {
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: Toast(
                message: 'Saved',
                description: description,
                onDismiss: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final panel = tester.getRect(find.byType(Toast));
        final close = tester.getRect(find.byType(Button).last);
        expect(
          close.center.dy,
          closeTo(panel.center.dy, 0.01),
          reason: 'description: $description',
        );
        expect(panel.right - close.right, CoreSpace.space8);
      }
    });

    testWidgets('the outlined and ghost variants read too', (
      tester,
    ) async {
      // One assertion per variant so the failing one is named.
      for (final variant in [
        CoreButtonVariant.outline,
        CoreButtonVariant.ghost,
      ]) {
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: Toast(
                message: 'Saved',
                action: Button(
                  variant: variant,
                  onPressed: () {},
                  child: const Text('Undo'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final slab = _tokenColorAt(
          tester,
          find.byType(Toast),
          CoreColors.inverseSurface,
        );
        expect(
          _contrast(_labelColorOf(tester, 'Undo'), slab),
          greaterThanOrEqualTo(_kMinimumContrast),
          reason: '$variant on the toast slab',
        );
      }
    });

    testWidgets('outside a toast the same Button keeps its own foreground', (
      tester,
    ) async {
      // The control: if `Button.plain` itself had turned
      // `inverse-on-surface`, the assertions above would pass for a reason
      // that breaks every plain button on every page.
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: Button(
              variant: CoreButtonVariant.plain,
              onPressed: () {},
              child: const Text('Undo'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _labelColorOf(tester, 'Undo'),
        isNot(
          _tokenColorAt(
            tester,
            find.byType(Button),
            CoreColors.inverseOnSurface,
          ),
        ),
      );
    });

    testWidgets(
      'the caller still wins — slot over injection, own style over slot',
      (
        tester,
      ) async {
        // Merge order is the whole contract: injected < toastStyle slot <
        // the action's own buttonStyle. Both halves are asserted because the
        // slot used to be the one thing the Flutter widget never read.
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: Toast(
                message: 'Saved',
                toastStyle: const CoreToastStyle(
                  actionButtonStyle: CoreButtonStyle(
                    foregroundColor: CoreColor.token(CoreColors.primary),
                  ),
                ),
                action: Button(
                  variant: CoreButtonVariant.plain,
                  onPressed: () {},
                  child: const Text('Undo'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          _labelColorOf(tester, 'Undo'),
          _tokenColorAt(tester, find.byType(Toast), CoreColors.primary),
          reason: 'toastStyle.actionButtonStyle wins over the injected default',
        );

        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: Toast(
                message: 'Saved',
                toastStyle: const CoreToastStyle(
                  actionButtonStyle: CoreButtonStyle(
                    foregroundColor: CoreColor.token(CoreColors.primary),
                  ),
                ),
                action: Button(
                  variant: CoreButtonVariant.plain,
                  onPressed: () {},
                  buttonStyle: const CoreButtonStyle(
                    foregroundColor: CoreColor.token(CoreColors.error),
                  ),
                  child: const Text('Undo'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          _labelColorOf(tester, 'Undo'),
          _tokenColorAt(tester, find.byType(Toast), CoreColors.error),
          reason: "the action's own buttonStyle wins over the toast slot",
        );
      },
    );
  });

  group('Toast panel shadow', () {
    const scaledLayer = (
      offsetX: 3.0,
      offsetY: 4.0,
      blurRadius: 8.0,
      spreadRadius: 1.0,
      opacity: 1.0,
      inset: false,
    );

    Future<ResolvedToast> resolveUnder(
      WidgetTester tester, {
      required double scaling,
      CoreToastStyle? toastStyle,
    }) async {
      late ResolvedToast resolved;
      await tester.pumpWidget(
        _buildApp(
          Theme(
            data: ThemeData(scaling: scaling),
            child: Builder(
              builder: (context) {
                resolved = resolveToast(
                  context,
                  variant: CoreToastVariant.defaultVariant,
                  dismissible: false,
                  toastStyle: toastStyle,
                );

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      return resolved;
    }

    testWidgets('default stack goes through the shared blur → σ conversion', (
      tester,
    ) async {
      final resolved = await resolveUnder(tester, scaling: 1);
      const authored = CoreToastStyle.defaultPanelBoxShadow;

      expect(resolved.shadow, hasLength(authored.length));
      for (var i = 0; i < authored.length; i++) {
        expect(
          resolved.shadow[i].blurRadius,
          cssBlurRadiusToFlutter(authored[i].blurRadius),
        );
        expect(
          resolved.shadow[i].offset,
          Offset(authored[i].offsetX, authored[i].offsetY),
        );
        expect(resolved.shadow[i].spreadRadius, authored[i].spreadRadius);
      }
    });

    testWidgets('scaling sizes both offsets, the blur and the spread', (
      tester,
    ) async {
      const scaling = 2.0;
      final resolved = await resolveUnder(
        tester,
        scaling: scaling,
        toastStyle: const CoreToastStyle(panelBoxShadow: [scaledLayer]),
      );
      final layer = resolved.shadow.single;

      expect(
        layer.offset,
        Offset(
          scaledLayer.offsetX * scaling,
          scaledLayer.offsetY * scaling,
        ),
      );
      expect(
        layer.blurRadius,
        cssBlurRadiusToFlutter(scaledLayer.blurRadius * scaling),
      );
      // The raw CSS radius would paint a heavier Gaussian than the Web
      // mirror — the conversion must actually move the value.
      expect(layer.blurRadius, isNot(scaledLayer.blurRadius * scaling));
      expect(layer.spreadRadius, scaledLayer.spreadRadius * scaling);
    });
  });
}
