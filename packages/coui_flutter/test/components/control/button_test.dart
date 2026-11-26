import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Swaps one child for another at the same position in the tree, so the
/// replaced widget's `State` survives and its implicit animations see a
/// prop change rather than a fresh mount.
///
/// Re-pumping the harness cannot do this: the shell mounts its child
/// through an `Overlay`'s `initialEntries`, which is read once.
class _Swap extends StatefulWidget {
  const _Swap(this.initial, {super.key});

  final Widget initial;

  @override
  State<_Swap> createState() => _SwapState();
}

class _SwapState extends State<_Swap> {
  late Widget child = widget.initial;

  void swap(Widget next) => setState(() => child = next);

  @override
  Widget build(BuildContext context) => child;
}

/// The button's chrome container — the one whose padding and decoration
/// `Button` animates together.
///
/// Identified by carrying padding at all: the button's other decorated
/// boxes (focus ring, shadow layer) state none. Asserting there is
/// exactly one keeps a future tree change from silently redirecting these
/// measurements at a different box.
Container _chromeContainer(WidgetTester tester) {
  final padded = tester
      .widgetList<Container>(find.byType(Container))
      .where((container) => container.padding != null)
      .toList();
  expect(padded, hasLength(1), reason: 'the chrome container moved.');
  return padded.single;
}

BoxDecoration _chromeDecoration(WidgetTester tester) =>
    _chromeContainer(tester).decoration! as BoxDecoration;

double _chromeRadius(WidgetTester tester) => _chromeDecoration(
  tester,
).borderRadius!.resolve(TextDirection.ltr).topLeft.x;

double _chromeLeftPadding(WidgetTester tester) =>
    _chromeContainer(tester).padding!.resolve(TextDirection.ltr).left;

double _chromeBorderWidth(WidgetTester tester) =>
    _chromeDecoration(tester).border!.top.width;

/// Rebuilds [host]'s button as [next] and stops halfway through the
/// chrome transition.
Future<void> _pumpHalfway(
  WidgetTester tester,
  GlobalKey<_SwapState> host,
  Widget next,
) async {
  host.currentState!.swap(next);
  // The frame the change lands on still shows the outgoing value — the
  // controller restarts from zero here.
  await tester.pump();
  await tester.pump(CoreButtonStyle.defaultAnimationDuration ~/ 2);
}

void main() {
  group('Button', () {
    testWidgets('dashed border renders through the dash slots', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          onPressed: () {},
          buttonStyle: const CoreButtonStyle(dashedBorder: true),
          child: const Text('Dashed'),
        ),
      );

      // The dashed wrapper mounts and lays out without throwing — the
      // resolver feeds `dashLength`/`dashSpacing` (CoreDashedBorder
      // defaults) into the painter.
      expect(find.byType(DashedContainer), findsOneWidget);
    });

    testWidgets('renders with primary style', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('Primary'),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('renders with secondary style', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.secondary,
          onPressed: () {},
          child: const Text('Secondary'),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('renders with outline style', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('Outline'),
        ),
      );

      expect(find.text('Outline'), findsOneWidget);
    });

    testWidgets('renders with ghost style', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.ghost,
          onPressed: () {},
          child: const Text('Ghost'),
        ),
      );

      expect(find.text('Ghost'), findsOneWidget);
    });

    testWidgets('renders with destructive style', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.destructive,
          onPressed: () {},
          child: const Text('Delete'),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('fires onPressed callback on tap', (tester) async {
      var pressed = false;
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => pressed = true,
          child: const Text('Tap Me'),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('href without onPressed is an enabled link, not dead', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Button(href: '/contact', child: Text('Contact')),
      );

      final data = tester.getSemantics(find.text('Contact')).getSemanticsData();
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isEnabled, isNot(isFalse));
      expect(data.linkUrl, Uri.parse('/contact'));
    });

    testWidgets('does not fire onPressed when disabled', (tester) async {
      var pressed = false;
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => pressed = true,
          enabled: false,
          child: const Text('Disabled'),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('renders leading and trailing widgets', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          leading: const Icon(LucideIcons.plus),
          trailing: const Icon(LucideIcons.arrowRight),
          child: const Text('With Icons'),
        ),
      );

      expect(find.text('With Icons'), findsOneWidget);
      expect(find.byType(Icon), findsNWidgets(2));
    });

    testWidgets('does not fire callback when onPressed is null', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Button(
          variant: CoreButtonVariant.primary,
          child: Text('No Action'),
        ),
      );

      expect(find.text('No Action'), findsOneWidget);
    });
  });

  group('ToggleController', () {
    test('default value is false', () {
      final controller = ToggleController();

      expect(controller.value, isFalse);

      controller.dispose();
    });

    test('accepts initial value', () {
      final controller = ToggleController(true);

      expect(controller.value, isTrue);

      controller.dispose();
    });

    test('toggle flips value', () {
      final controller = ToggleController(false);

      controller.toggle();
      expect(controller.value, isTrue);

      controller.toggle();
      expect(controller.value, isFalse);

      controller.dispose();
    });

    test('notifies listeners on toggle', () {
      final controller = ToggleController(false);
      var notified = false;
      void handleNotified() => notified = true;
      controller.addListener(handleNotified);

      controller.toggle();

      expect(notified, isTrue);

      controller.removeListener(handleNotified);
      controller.dispose();
    });
  });

  // The behaviour the Web twin imitates (#4202). Web cannot prove a
  // browser interpolates anything — its tests only reach the emitted CSS —
  // so the reference these measurements pin has to be pinned here, or the
  // thing the Web emit is copying can change without anything noticing.
  group('Button chrome transition', () {
    testWidgets('a shape change eases the radius rather than snapping it', (
      tester,
    ) async {
      final host = GlobalKey<_SwapState>();
      await pumpTestApp(
        tester,
        _Swap(
          key: host,
          Button(onPressed: () {}, child: const Text('X')),
        ),
      );
      final start = _chromeRadius(tester);

      await _pumpHalfway(
        tester,
        host,
        Button(
          onPressed: () {},
          shape: CoreButtonShape.circle,
          child: const Text('X'),
        ),
      );
      final midway = _chromeRadius(tester);

      await tester.pumpAndSettle();
      final end = _chromeRadius(tester);

      expect(end, isNot(start), reason: 'the shapes share a radius.');
      expect(midway, greaterThan(start));
      expect(midway, lessThan(end));
    });

    testWidgets('and eases the padding on the same frame', (tester) async {
      final host = GlobalKey<_SwapState>();
      await pumpTestApp(
        tester,
        _Swap(
          key: host,
          Button(onPressed: () {}, child: const Text('X')),
        ),
      );
      final start = _chromeLeftPadding(tester);

      await _pumpHalfway(
        tester,
        host,
        Button(
          onPressed: () {},
          shape: CoreButtonShape.circle,
          child: const Text('X'),
        ),
      );
      final midway = _chromeLeftPadding(tester);

      await tester.pumpAndSettle();
      final end = _chromeLeftPadding(tester);

      expect(end, isNot(start), reason: 'the shapes share a padding.');
      expect(midway, lessThan(start));
      expect(midway, greaterThan(end));
    });

    testWidgets('and eases the border width, which the issue left out', (
      tester,
    ) async {
      // Border width rides `BoxDecoration.border`, so the same
      // `AnimatedContainer` lerps it — a Web fix scoped to radius and
      // padding would leave this one property still snapping.
      const thin = CoreButtonStyle(borderWidth: CoreStrokeWidth.stroke1);
      const thick = CoreButtonStyle(borderWidth: CoreStrokeWidth.stroke8);
      final host = GlobalKey<_SwapState>();
      await pumpTestApp(
        tester,
        _Swap(
          key: host,
          Button(
            onPressed: () {},
            variant: CoreButtonVariant.outline,
            buttonStyle: thin,
            child: const Text('X'),
          ),
        ),
      );
      final start = _chromeBorderWidth(tester);

      await _pumpHalfway(
        tester,
        host,
        Button(
          onPressed: () {},
          variant: CoreButtonVariant.outline,
          buttonStyle: thick,
          child: const Text('X'),
        ),
      );
      final midway = _chromeBorderWidth(tester);

      await tester.pumpAndSettle();
      final end = _chromeBorderWidth(tester);

      expect(end, isNot(start));
      expect(midway, greaterThan(start));
      expect(midway, lessThan(end));
    });

    testWidgets('disableTransition snaps instead — the Web zero clock', (
      tester,
    ) async {
      final host = GlobalKey<_SwapState>();
      await pumpTestApp(
        tester,
        _Swap(
          key: host,
          Button(
            onPressed: () {},
            disableTransition: true,
            child: const Text('X'),
          ),
        ),
      );

      await _pumpHalfway(
        tester,
        host,
        Button(
          onPressed: () {},
          disableTransition: true,
          shape: CoreButtonShape.circle,
          child: const Text('X'),
        ),
      );
      final midway = _chromeRadius(tester);

      await tester.pumpAndSettle();
      expect(midway, _chromeRadius(tester));
    });
  });
}
