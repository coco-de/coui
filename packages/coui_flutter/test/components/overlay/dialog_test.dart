import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kBarrierOpacity = 0.5;
const _kBorderRadiusValue = 12.0;
const _kPaddingValue = 24.0;
const _kAlmostOne = 0.9999;
const _kZoomTolerance = 0.001;
const _kBarrierColor = material.Color.fromRGBO(0, 0, 0, _kBarrierOpacity);
const _kBorderRadius = material.BorderRadius.all(
  material.Radius.circular(_kBorderRadiusValue),
);
const _kPadding = material.EdgeInsets.all(_kPaddingValue);

/// Wraps with CoUI Theme for components that require it.
material.Widget _buildCouiApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: child,
  ),
);

/// Simple MaterialApp wrapper for components that only need Flutter material.
material.Widget _buildApp(material.Widget child) =>
    material.MaterialApp(home: child);

void main() {
  group('ModalBackdropTheme', () {
    group('constructor', () {
      test('creates with all null fields by default', () {
        const theme = ModalBackdropTheme();

        expect(theme.barrierColor, isNull);
        expect(theme.borderRadius, isNull);
        expect(theme.modal, isNull);
        expect(theme.padding, isNull);
        expect(theme.surfaceClip, isNull);
      });

      test('creates with all fields populated', () {
        const theme = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          borderRadius: _kBorderRadius,
          modal: true,
          padding: _kPadding,
          surfaceClip: false,
        );

        expect(theme.barrierColor, equals(_kBarrierColor));
        expect(theme.borderRadius, equals(_kBorderRadius));
        expect(theme.modal, isTrue);
        expect(theme.padding, equals(_kPadding));
        expect(theme.surfaceClip, isFalse);
      });
    });

    group('copyWith', () {
      test('returns identical theme when no args provided', () {
        const theme = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          modal: true,
        );
        final copy = theme.copyWith();

        expect(copy, equals(theme));
      });

      test('replaces barrierColor', () {
        const theme = ModalBackdropTheme(barrierColor: _kBarrierColor);
        const newColor = material.Color.fromRGBO(255, 0, 0, 1);
        final copy = theme.copyWith(barrierColor: () => newColor);

        expect(copy.barrierColor, equals(newColor));
      });

      test('replaces borderRadius', () {
        const theme = ModalBackdropTheme(borderRadius: _kBorderRadius);
        const newRadius = material.BorderRadius.all(
          material.Radius.circular(4),
        );
        final copy = theme.copyWith(borderRadius: () => newRadius);

        expect(copy.borderRadius, equals(newRadius));
      });

      test('replaces modal', () {
        const theme = ModalBackdropTheme(modal: true);
        final copy = theme.copyWith(modal: () => false);

        expect(copy.modal, isFalse);
      });

      test('replaces padding', () {
        const theme = ModalBackdropTheme(padding: _kPadding);
        const newPadding = material.EdgeInsets.symmetric(horizontal: 8);
        final copy = theme.copyWith(padding: () => newPadding);

        expect(copy.padding, equals(newPadding));
      });

      test('replaces surfaceClip', () {
        const theme = ModalBackdropTheme(surfaceClip: true);
        final copy = theme.copyWith(surfaceClip: () => false);

        expect(copy.surfaceClip, isFalse);
      });

      test('sets field to null via getter returning null', () {
        const theme = ModalBackdropTheme(modal: true);
        final copy = theme.copyWith(modal: () => null);

        expect(copy.modal, isNull);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const themeA = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          borderRadius: _kBorderRadius,
          modal: true,
          padding: _kPadding,
          surfaceClip: false,
        );
        const themeB = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          borderRadius: _kBorderRadius,
          modal: true,
          padding: _kPadding,
          surfaceClip: false,
        );

        expect(themeA, equals(themeB));
      });

      test('not equal when barrierColor differs', () {
        const themeA = ModalBackdropTheme(barrierColor: _kBarrierColor);
        const themeB = ModalBackdropTheme(
          barrierColor: material.Color.fromRGBO(0, 0, 0, 1),
        );

        expect(themeA, isNot(equals(themeB)));
      });

      test('not equal when modal differs', () {
        const themeA = ModalBackdropTheme(modal: true);
        const themeB = ModalBackdropTheme(modal: false);

        expect(themeA, isNot(equals(themeB)));
      });

      test('equal when both have all null fields', () {
        const themeA = ModalBackdropTheme();
        const themeB = ModalBackdropTheme();

        expect(themeA, equals(themeB));
      });
    });

    group('hashCode', () {
      test('same hashCode for equal themes', () {
        const themeA = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          modal: true,
        );
        const themeB = ModalBackdropTheme(
          barrierColor: _kBarrierColor,
          modal: true,
        );

        expect(themeA.hashCode, equals(themeB.hashCode));
      });

      test('different hashCode for different themes', () {
        const themeA = ModalBackdropTheme(modal: true);
        const themeB = ModalBackdropTheme(modal: false);

        expect(themeA.hashCode, isNot(equals(themeB.hashCode)));
      });
    });
  });

  group('ModalBackdrop', () {
    testWidgets('renders child widget', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const ModalBackdrop(
            child: material.Text('modal content'),
          ),
        ),
      );

      expect(find.text('modal content'), findsOneWidget);
    });

    testWidgets('renders with modal false (returns child directly)', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: material.TextDirection.ltr,
            child: ModalBackdrop(
              modal: false,
              child: material.Text('non-modal'),
            ),
          ),
        ),
      );

      expect(find.text('non-modal'), findsOneWidget);
    });

    testWidgets('renders with modal true (uses RepaintBoundary)', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: material.TextDirection.ltr,
            child: ModalBackdrop(
              modal: true,
              child: material.Text('modal'),
            ),
          ),
        ),
      );

      expect(find.text('modal'), findsOneWidget);
      expect(find.byType(material.RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with barrierColor', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: material.TextDirection.ltr,
            child: ModalBackdrop(
              barrierColor: _kBarrierColor,
              child: material.SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ModalBackdrop), findsOneWidget);
    });

    testWidgets('renders with borderRadius', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: material.TextDirection.ltr,
            child: ModalBackdrop(
              borderRadius: _kBorderRadius,
              child: material.SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ModalBackdrop), findsOneWidget);
    });

    testWidgets('renders with padding', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: material.TextDirection.ltr,
            child: ModalBackdrop(
              padding: _kPadding,
              child: material.SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ModalBackdrop), findsOneWidget);
    });
  });

  group('ModalBackdrop.shouldClipSurface', () {
    test('returns true when surfaceOpacity is null', () {
      expect(ModalBackdrop.shouldClipSurface(null), isTrue);
    });

    test('returns true when surfaceOpacity is less than 1.0', () {
      expect(ModalBackdrop.shouldClipSurface(0), isTrue);
      expect(ModalBackdrop.shouldClipSurface(_kBarrierOpacity), isTrue);
      expect(ModalBackdrop.shouldClipSurface(_kAlmostOne), isTrue);
    });

    test('returns false when surfaceOpacity is exactly 1.0', () {
      expect(ModalBackdrop.shouldClipSurface(1), isFalse);
    });
  });

  group('ModalContainer', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            child: material.Text('container content'),
          ),
        ),
      );

      expect(find.text('container content'), findsOneWidget);
    });

    testWidgets('renders with filled true', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            filled: true,
            child: material.Text('filled'),
          ),
        ),
      );

      expect(find.text('filled'), findsOneWidget);
    });

    testWidgets('renders with borderRadius', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            borderRadius: _kBorderRadius,
            child: material.Text('bordered'),
          ),
        ),
      );

      expect(find.text('bordered'), findsOneWidget);
    });

    testWidgets('renders with borderColor', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            borderColor: material.Colors.blue,
            child: material.SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(ModalContainer), findsOneWidget);
    });

    testWidgets('renders with clipBehavior', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            clipBehavior: material.Clip.hardEdge,
            child: material.SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(ModalContainer), findsOneWidget);
    });

    testWidgets('renders with padding', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            padding: _kPadding,
            child: material.Text('padded'),
          ),
        ),
      );

      expect(find.text('padded'), findsOneWidget);
    });

    testWidgets('renders with surfaceOpacity', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            surfaceOpacity: _kBarrierOpacity,
            child: material.SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(ModalContainer), findsOneWidget);
    });

    testWidgets('renders with boxShadow', (tester) async {
      final _ = await tester.pumpWidget(
        _buildCouiApp(
          const ModalContainer(
            boxShadow: [
              material.BoxShadow(blurRadius: 4),
            ],
            child: material.SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(ModalContainer), findsOneWidget);
    });
  });

  group('ModalContainer.kFullScreenMode', () {
    test('is a Symbol', () {
      expect(ModalContainer.kFullScreenMode, isA<Symbol>());
    });

    test('has expected value', () {
      expect(
        ModalContainer.kFullScreenMode,
        equals(#modal_surface_card_fullscreen),
      );
    });
  });

  group('Dialog barrier dismiss (pointerdown target rule)', () {
    // Barrier dismiss must key on where the press STARTED: a gesture
    // that begins on the panel content and releases over the barrier
    // (text selection / slider drags) must not dismiss, while a press
    // that starts and ends on the barrier still does. Web enforces the
    // same rule via BarrierPressTracker; Flutter's ModalBarrier only
    // reacts to pointers that went down on the barrier itself — this
    // guards that parity against a custom-barrier regression.
    Future<void> pumpAndOpenDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Scaffold(
              body: material.Center(
                child: material.Builder(
                  builder: (context) => material.GestureDetector(
                    onTap: () => unawaited(
                      showDialog<void>(
                        context: context,
                        builder: (_) => const Dialog(
                          title: material.Text('Title'),
                          content: material.Text('dialog content'),
                        ),
                      ),
                    ),
                    child: const material.Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('dialog content'), findsOneWidget);
    }

    testWidgets(
      'drag starting on panel content released over the barrier '
      'does not dismiss',
      (tester) async {
        await pumpAndOpenDialog(tester);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('dialog content')),
        );
        // Release far outside the centered panel — over the barrier.
        await gesture.moveTo(material.Offset.zero);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('dialog content'), findsOneWidget);
      },
    );

    testWidgets(
      'press starting and ending on the barrier still dismisses',
      (tester) async {
        await pumpAndOpenDialog(tester);

        await tester.tapAt(material.Offset.zero);
        await tester.pumpAndSettle();

        expect(find.text('dialog content'), findsNothing);
      },
    );
  });

  group('Dialog text colours come from the Core defaults', () {
    // Each text slot paints its own Core typography default — the title
    // `defaultTitleStyle`, the body `defaultContentStyle` — and the panel
    // foreground (`defaultsByVariant.foregroundColor`) is only what the
    // rest of the panel inherits. The Web twin emits the same three from
    // the same three fields; reading the colour the text actually inherits
    // is what holds Flutter to them.
    Future<ResolvedColorScheme> pumpOpenDialog(
      WidgetTester tester, {
      CoreDialogStyle? dialogStyle,
    }) async {
      late ResolvedColorScheme scheme;
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Scaffold(
              body: material.Builder(
                builder: (context) {
                  scheme = Theme.of(context).colorScheme;
                  return material.GestureDetector(
                    onTap: () => unawaited(
                      showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                          leading: const material.Icon(material.Icons.info),
                          title: const material.Text('Title'),
                          trailing: const material.Text('Aside'),
                          content: const material.Text('Body'),
                          dialogStyle: dialogStyle,
                        ),
                      ),
                    ),
                    child: const material.Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return scheme;
    }

    material.Color? inheritedColor(WidgetTester tester, String text) =>
        material.DefaultTextStyle.of(
          tester.element(find.text(text)),
        ).style.color;

    material.Color resolve(ResolvedColorScheme scheme, CoreColor color) =>
        scheme.resolve(color).toValue();

    testWidgets('body paints defaultContentStyle colour (onSurfaceVariant)', (
      tester,
    ) async {
      final scheme = await pumpOpenDialog(tester);

      final body = inheritedColor(tester, 'Body');
      expect(
        body,
        resolve(scheme, CoreDialogStyle.defaultContentStyle.color!),
      );
      expect(
        body,
        isNot(
          resolve(scheme, CoreDialogStyle.defaultsByVariant.foregroundColor),
        ),
        reason: 'body fell back to the panel foreground',
      );
    });

    testWidgets('title paints defaultTitleStyle colour', (tester) async {
      final scheme = await pumpOpenDialog(tester);

      expect(
        inheritedColor(tester, 'Title'),
        resolve(scheme, CoreDialogStyle.defaultTitleStyle.color!),
      );
    });

    testWidgets('a slot that states no colour inherits the panel foreground', (
      tester,
    ) async {
      final scheme = await pumpOpenDialog(tester);
      final foreground = resolve(
        scheme,
        CoreDialogStyle.defaultsByVariant.foregroundColor,
      );

      expect(inheritedColor(tester, 'Aside'), foreground);
      expect(
        material.IconTheme.of(
          tester.element(find.byIcon(material.Icons.info)),
        ).color,
        foreground,
      );
    });

    testWidgets('a contentStyle colour override still wins', (tester) async {
      const override = CoreColor.token(CoreColors.error);
      final scheme = await pumpOpenDialog(
        tester,
        dialogStyle: const CoreDialogStyle(
          contentStyle: CoreTextStyle(color: override),
        ),
      );

      expect(inheritedColor(tester, 'Body'), resolve(scheme, override));
    });

    testWidgets('colour-less overrides keep each default colour', (
      tester,
    ) async {
      final scheme = await pumpOpenDialog(
        tester,
        dialogStyle: const CoreDialogStyle(
          titleStyle: CoreTextStyle(fontWeight: CoreFontWeight.regular),
          contentStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(
        inheritedColor(tester, 'Title'),
        resolve(scheme, CoreDialogStyle.defaultTitleStyle.color!),
      );
      expect(
        inheritedColor(tester, 'Body'),
        resolve(scheme, CoreDialogStyle.defaultContentStyle.color!),
      );
    });
  });

  group('Dialog bare mount dispose (#4627)', () {
    testWidgets(
      'replacing the tree after a bare open Dialog does not touch '
      'unmounted context',
      (tester) async {
        material.Widget app(material.Widget child) => Theme(
          data: const ThemeData(),
          child: material.MaterialApp(home: child),
        );
        await tester.pumpWidget(
          app(
            // `open` defaults to true — a bare, open Dialog.
            const Dialog(
              title: material.Text('Title'),
              content: material.Text('bare'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(app(const material.SizedBox()));
        await tester.pump();
      },
    );
  });

  group('Dialog open zoom', () {
    // The curve runs on the raw 0..1 route progress and the scale range is
    // applied after it. Curving a parent already remapped to start..end
    // evaluated the curve only on that tail, where ease-out is flat — the
    // panel opened at ~1.0 and the zoom never showed.
    testWidgets('starts at the resolved start scale and eases to the end', (
      tester,
    ) async {
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Builder(
              builder: (context) => material.GestureDetector(
                onTap: () => unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const Dialog(content: material.Text('zoom content')),
                  ),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();

      double scale() => tester
          .widget<material.ScaleTransition>(
            find
                .ancestor(
                  of: find.text('zoom content'),
                  matching: find.byType(material.ScaleTransition),
                )
                .first,
          )
          .scale
          .value;

      expect(
        scale(),
        closeTo(CoreDialogStyle.defaultScaleAnimationStart, _kZoomTolerance),
      );

      await tester.pumpAndSettle();
      expect(
        scale(),
        closeTo(CoreDialogStyle.defaultScaleAnimationEnd, _kZoomTolerance),
      );
    });
  });
}
