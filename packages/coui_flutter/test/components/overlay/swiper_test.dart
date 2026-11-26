import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Theme(data: material.ThemeData(), child: child),
);

/// Wraps every route (including pushed overlay routes on the root
/// `Navigator`) with the CoUI `Theme` via `MaterialApp.builder`, so a
/// `Swiper` overlay route can resolve `Theme.of` — mirroring `CoUIApp`
/// providing the theme above the navigator in production.
material.Widget _buildThemedApp(material.Widget child) => material.MaterialApp(
  builder: (context, built) => Theme(
    data: ThemeData(),
    // The app-shell backdrop host — the swipe engine scrubs its ghost
    // panel through this layer (mirroring CoUIApp's CoUILayer).
    child: DrawerBackdropLayer(child: built!),
  ),
  home: child,
);

void main() {
  group('Swiper', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .drawer,
            position: .left,
            overlayContent: material.Text('overlay-content'),
            child: material.Text('child-content'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('child-content'), findsOneWidget);
    });

    testWidgets('renders with drawer variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .drawer,
            position: .left,
            overlayContent: material.SizedBox(),
            child: material.Text('child-drawer'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Swiper), findsOneWidget);
      expect(find.text('child-drawer'), findsOneWidget);
    });

    testWidgets('renders with sheet variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .sheet,
            position: .bottom,
            overlayContent: material.SizedBox(),
            child: material.Text('child-sheet'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Swiper), findsOneWidget);
      expect(find.text('child-sheet'), findsOneWidget);
    });

    testWidgets('renders with position top', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .sheet,
            position: .top,
            overlayContent: material.SizedBox(),
            child: material.Text('child-top'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Swiper), findsOneWidget);
    });

    testWidgets('renders with position right', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .drawer,
            position: .right,
            overlayContent: material.SizedBox(),
            child: material.Text('child-right'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Swiper), findsOneWidget);
    });

    testWidgets('renders with enabled false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            enabled: false,
            variant: .drawer,
            position: .left,
            overlayContent: material.SizedBox(),
            child: material.Text('disabled-child'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('disabled-child'), findsOneWidget);
    });

    testWidgets('renders with style params via swiperStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            barrierDismissible: true,
            showDragHandle: true,
            variant: .drawer,
            position: .left,
            swiperStyle: CoreSwiperStyle(
              drawerStyle: CoreDrawerStyle(panelWidth: 320),
            ),
            overlayContent: material.SizedBox(),
            child: material.Text('themed-child'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Swiper), findsOneWidget);
      expect(find.text('themed-child'), findsOneWidget);
    });

    testWidgets(
      'drag-to-open scrubs the panel with the finger and snaps open '
      'past the half threshold; the open panel can be swiped shut',
      (tester) async {
        var opens = 0;
        var closes = 0;
        await tester.pumpWidget(
          _buildThemedApp(
            Swiper(
              position: .left,
              onOpenChanged: (isOpen) => isOpen ? opens++ : closes++,
              overlayContent: const material.Text('overlay'),
              child: const material.SizedBox(width: 400, height: 400),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Passing the axis slop mounts the ghost panel immediately
        // (no fling gate) …
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Swiper)),
        );
        await gesture.moveBy(const material.Offset(20, 0));
        await tester.pump();
        expect(find.text('overlay'), findsOneWidget);

        // … drag UPDATES scrub it 1:1 (panel width 256 → 200 px pull
        // is past the half-open threshold) …
        await gesture.moveBy(const material.Offset(200, 0));
        await tester.pump();
        // … and release past the threshold springs fully open and
        // commits the real drawer route (open event fires once).
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('overlay'), findsOneWidget);
        expect(opens, 1);

        // Swipe the open panel shut toward its edge — inherited from
        // the composed drawer's drag-to-dismiss.
        await tester.fling(
          find.text('overlay'),
          const material.Offset(-160, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('overlay'), findsNothing);
        expect(closes, 1);
      },
    );

    testWidgets(
      'a second swipe after an aborted one scrubs again (fresh ticker '
      'per gesture)',
      (tester) async {
        await tester.pumpWidget(
          _buildThemedApp(
            Swiper(
              position: .left,
              overlayContent: const material.Text('overlay'),
              child: const material.SizedBox(width: 400, height: 400),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // First swipe — aborted under the threshold.
        var gesture = await tester.startGesture(
          tester.getCenter(find.byType(Swiper)),
        );
        await gesture.moveBy(const material.Offset(60, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('overlay'), findsNothing);

        // Second swipe — must scrub a fresh ghost without throwing
        // (a Single ticker provider would assert on the second
        // controller) and commit past the threshold.
        gesture = await tester.startGesture(
          tester.getCenter(find.byType(Swiper)),
        );
        await gesture.moveBy(const material.Offset(20, 0));
        await tester.pump();
        await gesture.moveBy(const material.Offset(200, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('overlay'), findsOneWidget);
      },
    );

    testWidgets(
      'releasing a drag below the half threshold snaps the panel shut',
      (tester) async {
        var opens = 0;
        var closes = 0;
        await tester.pumpWidget(
          _buildThemedApp(
            Swiper(
              position: .left,
              onOpenChanged: (isOpen) => isOpen ? opens++ : closes++,
              overlayContent: const material.Text('overlay'),
              child: const material.SizedBox(width: 400, height: 400),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Swiper)),
        );
        await gesture.moveBy(const material.Offset(20, 0));
        await tester.pump();
        // The ghost panel is scrubbing …
        expect(find.text('overlay'), findsOneWidget);
        // … but only ~60 px of a 256 px panel — under the 0.5
        // threshold, so release slides it back shut without ever
        // committing (no open/close events for an aborted swipe).
        await gesture.moveBy(const material.Offset(40, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('overlay'), findsNothing);
        expect(opens, 0);
        expect(closes, 0);
      },
    );

    testWidgets('overlay content is hidden until opened', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Swiper(
            variant: .drawer,
            position: .left,
            overlayContent: material.Text('overlay'),
            child: material.SizedBox(width: 400, height: 400),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Starts closed (open: false) — the overlay content is not mounted.
      expect(find.text('overlay'), findsNothing);
      expect(find.byType(Swiper), findsOneWidget);
    });

    testWidgets(
      'flipping the controlled `open` to true does not throw '
      'setState-during-build',
      (tester) async {
        // Reproduces the reported bug: a button `setState(_open = true)`
        // rebuilds the parent, whose reconcile pass runs the Swiper's
        // `didUpdateWidget`, which used to push the overlay `Navigator`
        // route synchronously — throwing
        // `setState()/markNeedsBuild() called during build`.
        var open = false;
        await tester.pumpWidget(
          _buildThemedApp(
            material.StatefulBuilder(
              builder: (context, setState) => material.Column(
                children: [
                  material.ElevatedButton(
                    onPressed: () => setState(() => open = true),
                    child: const material.Text('Open swiper'),
                  ),
                  Swiper(
                    open: open,
                    variant: .drawer,
                    position: .left,
                    overlayContent: const material.Text('overlay'),
                    child: const material.SizedBox(width: 400, height: 400),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open swiper'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('overlay'), findsOneWidget);
      },
    );
  });
}
