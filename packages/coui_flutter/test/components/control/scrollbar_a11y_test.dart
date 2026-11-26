import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show SemanticsFlag, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kItemCount = 50;
const _kItemHeight = 40.0;

/// Side of the square viewport every test pumps the bar into — short
/// enough that [_kItemCount] items overflow it, so there is always a
/// scroll range for the node to report a position within.
const _kViewportSide = 300.0;

/// Drag long enough to reach the end of the list from anywhere in it, so a
/// test that scrolls can assert the exact value it lands on rather than a
/// direction.
const _kDragToEnd = Offset(0, -2000);

/// Where an unscrolled thumb sits — just inside the trailing edge, a little
/// below the top of the track.
const _kThumbGrabInset = 4.0;
const _kThumbGrabDrop = 20.0;

/// Short pull on the thumb: far enough to move the list well past zero,
/// short enough to stay inside the track.
const _kThumbPull = Offset(0, 100);

Widget _list([ScrollController? controller]) => ListView.builder(
  controller: controller,
  itemBuilder: (_, index) =>
      SizedBox(height: _kItemHeight, child: Text('Item $index')),
  itemCount: _kItemCount,
);

/// Bounds [child] to the shared [_kViewportSide] square.
Widget _boxed(Widget child) =>
    SizedBox(width: _kViewportSide, height: _kViewportSide, child: child);

/// Walks the current semantics tree for the first node flagged
/// [SemanticsFlag.isSlider] — the phantom accessibility node
/// `Scrollbar` adds alongside the wrapped scrollable's own semantics.
SemanticsNode? _findSliderNode(WidgetTester tester) {
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (found != null) return;
    if (node.getSemanticsData().flagsCollection.isSlider) {
      found = node;
      return;
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root =
      tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root != null) visit(root);
  return found;
}

/// Scrolls the wrapped list to its end.
///
/// `kind` is not decoration: desktop `ScrollBehavior.dragDevices` excludes
/// [PointerDeviceKind.mouse], so a default drag on a desktop variant moves
/// the list zero pixels. A test that scrolled with a mouse would pass
/// while never walking the path it exists to cover.
Future<void> _dragListToEnd(WidgetTester tester) => tester.drag(
  find.byType(ListView),
  _kDragToEnd,
);

/// Pumps a controller-less bar inside a real route and walks it through the
/// lifecycle the fade-in path traverses, returning whatever exception was
/// pending after each step keyed by that step's name.
///
/// Sampling after every step is what makes the result readable.
/// [WidgetTester.takeException] returns only the *first* pending exception
/// and is not drained by `expect`, so a throw during the scroll would
/// otherwise surface against the settle that follows it — which is exactly
/// the misattribution that made this path look like a drag bug (#4000).
Future<Map<String, Object?>> _exceptionsByStage(
  WidgetTester tester, {
  required bool interactive,
  required CoreScrollbarVisibility visibility,
}) async {
  final byStage = <String, Object?>{};

  // A real route, so the ambient `PrimaryScrollController` exists — the
  // controller `RawScrollbar` falls back to when the bar lends it nothing.
  // Without a route the fallback is null and the shape under test is a
  // different one.
  await tester.pumpWidget(
    material.MaterialApp(
      home: buildTestApp(
        _boxed(
          Scrollbar(
            visibility: visibility,
            interactive: interactive,
            child: _list(),
          ),
        ),
      ),
    ),
  );
  byStage['pump'] = tester.takeException();
  await tester.pumpAndSettle();
  byStage['settle'] = tester.takeException();

  await _dragListToEnd(tester);
  byStage['scroll'] = tester.takeException();
  await tester.pumpAndSettle();
  byStage['settle-after-scroll'] = tester.takeException();

  return byStage;
}

void main() {
  group('Scrollbar accessibility (#3494)', () {
    for (final visibility in CoreScrollbarVisibility.values) {
      testWidgets(
        'phantom ${visibility.name} slider never covers the content '
        'viewport (#5265)',
        (tester) async {
          final handle = tester.ensureSemantics();
          final controller = ScrollController();
          addTearDown(controller.dispose);
          var selected = false;
          await pumpTestApp(
            tester,
            _boxed(
              Scrollbar(
                controller: controller,
                visibility: visibility,
                child: ListView(
                  controller: controller,
                  children: [
                    material.TextButton(
                      onPressed: () => selected = true,
                      child: const Text('Select cat'),
                    ),
                    for (var i = 0; i < _kItemCount; i++)
                      SizedBox(height: _kItemHeight, child: Text('Item $i')),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final node = _findSliderNode(tester)!;
          final viewport = tester.getSize(find.byType(ListView));
          // Flutter Web turns this node into an HTML range input. A full
          // viewport-sized rectangle intercepts browser clicks even though
          // the Flutter render box itself is pointer-transparent.
          expect(node.rect.width, lessThan(viewport.width / 100));
          expect(node.rect.height, lessThan(viewport.height / 100));
          expect(node.getSemanticsData().value, '0%');
          expect(node.getSemanticsData().hasAction(.increase), isTrue);
          await tester.tap(find.text('Select cat'));
          expect(selected, isTrue);
          tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
            node.id,
            .increase,
          );
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(0));
          handle.dispose();
        },
      );
    }

    testWidgets(
      'exposes a slider-shaped node whose value tracks the scroll '
      'position live',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(controller: controller, child: _list(controller)),
          ),
        );
        await tester.pumpAndSettle();

        final atStart = _findSliderNode(tester);
        expect(atStart, isNotNull);
        expect(atStart!.getSemanticsData().value, '0%');

        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();

        final atEnd = _findSliderNode(tester);
        expect(atEnd, isNotNull);
        expect(atEnd!.getSemanticsData().value, '100%');

        handle.dispose();
      },
    );

    testWidgets(
      'the accessibility increase action scrolls the wrapped list '
      'forward',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(controller: controller, child: _list(controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.position.pixels, 0);

        final sliderNode = _findSliderNode(tester);
        expect(sliderNode, isNotNull);
        expect(
          sliderNode!.getSemanticsData().hasAction(.increase),
          isTrue,
        );

        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          sliderNode.id,
          .increase,
        );
        await tester.pumpAndSettle();

        expect(controller.position.pixels, greaterThan(0));

        handle.dispose();
      },
    );

    testWidgets(
      'a non-interactive scrollbar omits the increase/decrease actions',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              controller: controller,
              interactive: false,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final sliderNode = _findSliderNode(tester);
        expect(sliderNode, isNotNull);
        final data = sliderNode!.getSemanticsData();
        expect(data.hasAction(.increase), isFalse);
        expect(data.hasAction(.decrease), isFalse);

        handle.dispose();
      },
    );
  });

  // The three tests above all hand `Scrollbar` an explicit controller, and
  // the harness has no `Navigator`, so `PrimaryScrollController` never
  // enters the picture. That left every controller-less shape — including
  // the one the class dartdoc shows — with zero coverage, and on desktop
  // that shape reached no accessibility node at all: `PrimaryScrollController
  // .shouldInherit` is false off mobile, so the wrapped `ListView` attaches
  // to nothing an ambient lookup could find.
  group('Scrollbar accessibility without an explicit controller (#3980)', () {
    testWidgets(
      'reports the position on desktop when no controller is passed to '
      'either the bar or the list',
      (tester) async {
        final handle = tester.ensureSemantics();

        await pumpTestApp(
          tester,
          _boxed(Scrollbar(child: _list())),
        );
        await tester.pumpAndSettle();

        final atStart = _findSliderNode(tester);
        expect(atStart, isNotNull);
        expect(atStart!.getSemanticsData().value, '0%');

        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(_findSliderNode(tester)!.getSemanticsData().value, '100%');

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'reports the position on desktop inside a route, where the ambient '
      'PrimaryScrollController exists but the list never attaches to it',
      (tester) async {
        final handle = tester.ensureSemantics();

        // A real route, so the ambient `PrimaryScrollController` the
        // desktop path used to look for actually exists here.
        await tester.pumpWidget(
          material.MaterialApp(
            home: buildTestApp(
              _boxed(
                Scrollbar(child: _list()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Guards the premise: on desktop the list is *not* attached to the
        // route's PrimaryScrollController, so an ambient lookup finds a
        // controller with no clients. A node that exists only because the
        // list happened to attach would not prove anything.
        final primary = PrimaryScrollController.maybeOf(
          tester.element(find.byType(ListView)),
        );
        expect(primary, isNotNull);
        expect(primary!.hasClients, isFalse);

        final node = _findSliderNode(tester);
        expect(node, isNotNull);
        expect(node!.getSemanticsData().value, '0%');

        // Everything above holds without the list ever moving, and that was
        // the whole of this test until #4000: it proved a node exists, not
        // that the bar survives being used. The fade-in the bar runs when
        // the list first scrolls is a different code path, and inside a
        // route it used to reach `RawScrollbar`'s validation with the
        // ambient `PrimaryScrollController` — which has no clients here, as
        // asserted above — and assert.
        //
        // Keyed by stage rather than asserted inline: `takeException`
        // surrenders one exception per call and `expect` does not drain it,
        // so a bare pair of assertions reports whichever stage threw under
        // whichever line runs first. The map keeps the failure pointing at
        // the step that produced it.
        final byStage = <String, Object?>{};
        await _dragListToEnd(tester);
        byStage['scroll'] = tester.takeException();
        await tester.pumpAndSettle();
        byStage['settle-after-scroll'] = tester.takeException();
        expect(byStage, {'scroll': null, 'settle-after-scroll': null});

        // The scroll has to have landed, or the two expectations above are
        // claims about a path this test never walked.
        expect(_findSliderNode(tester)!.getSemanticsData().value, '100%');

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'reports the position of the list that owns its own controller, which '
      'the bar never sees',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          // Note: `controller` reaches the list, never the bar.
          _boxed(Scrollbar(child: _list(controller))),
        );
        await tester.pumpAndSettle();

        final node = _findSliderNode(tester);
        expect(node, isNotNull);
        expect(node!.getSemanticsData().value, '0%');

        // The increase action has to move the list the bar actually paints,
        // not some other position it happened to find.
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          .increase,
        );
        await tester.pumpAndSettle();
        expect(controller.position.pixels, greaterThan(0));

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // Both snippets in the `Scrollbar` class dartdoc, run as written. A
    // documented shape that renders no accessibility node is a documented
    // way to ship an inaccessible scrollbar, so the documentation is held
    // to the same bar as the code and has to be edited together with it.
    testWidgets(
      'the first class dartdoc example reaches an accessibility node',
      (tester) async {
        final handle = tester.ensureSemantics();

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              axis: CoreScrollbarAxis.vertical,
              child: _list(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_findSliderNode(tester), isNotNull);

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'the always-visible class dartdoc example reaches an accessibility '
      'node',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            // Spelled the way the dartdoc spells it — the point of these
            // two tests is that the documented shape works as written.
            // ignore: prefer_shorthands_with_enums
            Scrollbar(
              visibility: CoreScrollbarVisibility.always,
              controller: controller,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_findSliderNode(tester), isNotNull);

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });

  // The route test above now scrolls, which covers this path for exactly one
  // shape: auto visibility, interactive, vertical. The other seven
  // combinations were pinned by nothing at all, and the symptom that opened
  // #4000 moved between them as the bar changed — it fired on the scroll and
  // the settle for `auto` and `thin`, on the first pump for `always`, and
  // never for `hidden`. Walking all eight means a regression names the
  // combination it broke instead of the first one someone happens to run.
  group(
    'Scrollbar without a controller, across interactive x visibility (#4000)',
    () {
      for (final interactive in [true, false]) {
        for (final visibility in CoreScrollbarVisibility.values) {
          // `always` is the one combination that still throws, and it throws
          // at the first pump rather than on the scroll. `RawScrollbar`
          // schedules that validation from `didChangeDependencies`, so it
          // runs in the post-frame queue of the very first frame — measurably
          // before the first `ScrollMetricsNotification`, which is the
          // earliest moment this bar can learn which scrollable it wraps.
          // There is nothing to lend yet, and no ordering the bar controls
          // changes that.
          //
          // It is a diagnostic, not a broken bar. The whole call sits inside
          // `assert(...)`, so nothing is even scheduled in release, and from
          // the second frame the bar is fully live without a controller — the
          // test after this group drags its thumb at rest and moves the list.
          // What the assert does cost is a widget test: any test that pumps
          // this shape fails on the untaken exception unless it passes a
          // controller or takes it.
          //
          // Pinned as a throw rather than skipped. Skipping would leave the
          // one combination that behaves differently as the one combination
          // nothing describes, which is how it stayed invisible until now. If
          // it is ever fixed, this expectation is what fails — the fix should
          // arrive as a deliberate edit here, not as a silent change.
          final assertsOnFirstFrame = visibility == .always;
          final stageDescription = assertsOnFirstFrame
              ? 'asserts at the first pump, and nowhere else'
              : 'stays clean through scroll and settle';

          testWidgets(
            'interactive: $interactive, visibility: ${visibility.name} — '
            '$stageDescription',
            (tester) async {
              final handle = tester.ensureSemantics();

              final byStage = await _exceptionsByStage(
                tester,
                interactive: interactive,
                visibility: visibility,
              );

              expect(
                byStage['pump'],
                assertsOnFirstFrame ? isNotNull : isNull,
                reason: assertsOnFirstFrame
                    ? 'always is validated before the bar has heard from a '
                          'scrollable, so it raises one debug diagnostic here'
                    : 'nothing may throw while the bar is merely built',
              );
              // Whatever the first frame did, the steps this issue was filed
              // about are the ones after it.
              expect(byStage['settle'], isNull);
              expect(byStage['scroll'], isNull);
              expect(byStage['settle-after-scroll'], isNull);

              // ...and the list really moved, so "clean" describes a path
              // that was walked rather than one that was never entered.
              expect(
                _findSliderNode(tester)!.getSemanticsData().value,
                '100%',
              );

              handle.dispose();
            },
            variant: TargetPlatformVariant.desktop(),
          );
        }
      }
    },
  );

  // The matrix above pins that `always` throws on its first frame. On its own
  // that sentence reads as "always is broken without a controller", and it is
  // not — so on its own it is also the wrong thing to pin. A change that
  // silenced the assert by never showing the thumb (overriding
  // `RawScrollbar`'s `showScrollbar`, say) would satisfy every expectation in
  // that matrix while turning `always` into `auto`, and nothing would notice.
  //
  // These two say what the matrix cannot: the bar is live from the second
  // frame, and `always` still means always. They are a pair on purpose —
  // `auto` is what a suppressed `always` would look like, so pinning `always`
  // alone could not tell the two apart.
  group('Scrollbar always is live without a controller (#4000)', () {
    Future<double> dragThumbAtRest(
      WidgetTester tester,
      CoreScrollbarVisibility visibility,
    ) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: buildTestApp(
            _boxed(Scrollbar(visibility: visibility, child: _list())),
          ),
        ),
      );
      // `always` announces itself here; that is the matrix's subject, not
      // this test's. Taking it keeps this test measuring the thumb.
      tester.takeException();
      await tester.pumpAndSettle();

      // Grab the top of the track, hard against the trailing edge — where an
      // unscrolled thumb sits. A faded thumb ignores the pointer entirely, so
      // this same gesture separates a visible bar from an invisible one.
      final box = tester.getRect(find.byType(Scrollbar));
      await tester.dragFrom(
        Offset(box.right - _kThumbGrabInset, box.top + _kThumbGrabDrop),
        _kThumbPull,
      );
      await tester.pumpAndSettle();

      return tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(Scrollbar),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
    }

    testWidgets(
      'its thumb is grabbable at rest, so the assert is a diagnostic rather '
      'than a missing bar',
      (tester) async {
        expect(
          await dragThumbAtRest(tester, .always),
          greaterThan(0),
        );
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'auto, by contrast, has faded by then and ignores the same gesture',
      (tester) async {
        expect(await dragThumbAtRest(tester, .auto), 0);
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });

  // `hidden` used to return the wrapped scrollable before the bar was
  // built at all, so the accessibility node went with the thumb. That is
  // the one mode where a sighted user has no position cue either, which
  // makes it the last mode that should drop the non-visual one — and the
  // Web twin never did, so the pair also disagreed.
  group('Scrollbar accessibility under hidden visibility (#3983)', () {
    testWidgets(
      'a hidden scrollbar still reports the position, and the value stays '
      'live as the area scrolls',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              visibility: .hidden,
              controller: controller,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final atStart = _findSliderNode(tester);
        expect(atStart, isNotNull);
        expect(atStart!.getSemanticsData().value, '0%');

        // "The area still scrolls" is half of what `hidden` promises, so
        // the announced value has to follow it — a node frozen at 0%
        // would pass a presence check and still tell the user nothing.
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(_findSliderNode(tester)!.getSemanticsData().value, '100%');

        handle.dispose();
      },
    );

    testWidgets(
      'a hidden scrollbar can still be driven by the increase action',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              visibility: .hidden,
              controller: controller,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.position.pixels, 0);

        final node = _findSliderNode(tester);
        expect(node, isNotNull);
        expect(
          node!.getSemanticsData().hasAction(.increase),
          isTrue,
        );

        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          .increase,
        );
        await tester.pumpAndSettle();

        expect(controller.position.pixels, greaterThan(0));

        handle.dispose();
      },
    );

    testWidgets(
      'hidden and non-interactive still reports the position, without '
      'advertising an operation',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              visibility: .hidden,
              interactive: false,
              controller: controller,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Parked mid-range on purpose. At 0% the node withholds
        // `decrease` for a reason that has nothing to do with
        // `interactive` — there is nowhere below to go — so asserting its
        // absence at the top proves nothing about this flag. Both
        // directions have somewhere to go from here.
        controller.jumpTo(controller.position.maxScrollExtent / 2);
        await tester.pumpAndSettle();

        final node = _findSliderNode(tester);
        expect(node, isNotNull);
        final data = node!.getSemanticsData();
        // The position is still readable — `interactive` gates operating
        // the bar, never reading it.
        expect(data.value, '50%');
        expect(data.hasAction(.increase), isFalse);
        expect(data.hasAction(.decrease), isFalse);

        handle.dispose();
      },
    );

    // Guards the premise of the test above: at this same mid-range
    // position an interactive bar offers both directions, so their
    // absence there is `interactive` and not the scroll extent.
    testWidgets(
      'an interactive bar at the same position offers both directions',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              visibility: .hidden,
              controller: controller,
              child: _list(controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        controller.jumpTo(controller.position.maxScrollExtent / 2);
        await tester.pumpAndSettle();

        final data = _findSliderNode(tester)!.getSemanticsData();
        expect(data.value, '50%');
        expect(data.hasAction(.increase), isTrue);
        expect(data.hasAction(.decrease), isTrue);

        handle.dispose();
      },
    );

    // The other reason the node withholds its actions: content that fits
    // has nowhere to go, so a step would be advertised and then refused.
    // Nothing exercised this branch before, which left `canStep`'s second
    // conjunct free to be deleted.
    testWidgets(
      'content that fits reports a position but advertises no step',
      (tester) async {
        final handle = tester.ensureSemantics();

        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              child: ListView(
                children: const [SizedBox(height: _kItemHeight)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final node = _findSliderNode(tester);
        expect(node, isNotNull);
        final data = node!.getSemanticsData();
        expect(data.value, '0%');
        expect(data.hasAction(.increase), isFalse);
        expect(data.hasAction(.decrease), isFalse);

        handle.dispose();
      },
    );

    // Presence must not depend on the visibility mode at all. Asserting
    // the modes one at a time is what let `hidden` be the odd one out for
    // as long as it was: three of them were covered and the fourth was
    // simply never pumped.
    for (final visibility in CoreScrollbarVisibility.values) {
      testWidgets(
        'visibility ${visibility.name} reaches an accessibility node',
        (tester) async {
          final handle = tester.ensureSemantics();
          final controller = ScrollController();
          addTearDown(controller.dispose);

          await pumpTestApp(
            tester,
            _boxed(
              Scrollbar(
                visibility: visibility,
                controller: controller,
                child: _list(controller),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final node = _findSliderNode(tester);
          expect(
            node,
            isNotNull,
            reason:
                'visibility ${visibility.name} hides pixels, not the '
                'accessibility node',
          );
          expect(node!.getSemanticsData().value, '0%');

          handle.dispose();
        },
      );
    }
  });

  // Gaining the accessibility node cost the `hidden` branch a wrapper it
  // never had, and the first version of that wrapper loosened the child's
  // constraints — a shrink-wrapping scrollable that had filled a 300px box
  // silently collapsed to its 50px content. Nothing in the semantics tests
  // could see it. These pin the constraints each mode hands its child, in
  // both directions: the numbers differ between modes for a reason that
  // predates this work (the painted branch has always sat under a loose
  // stack), and neither number may move without someone choosing to move
  // it.
  group('Scrollbar layout is untouched by the accessibility node (#3983)', () {
    // `always` is excluded: it needs a controller to drive
    // `thumbVisibility`, and a controller changes what is being measured.
    //
    // Every mode hands its child the box the bar was given. `RawScrollbar`
    // is layout-transparent, so a bar — painted or not — must not change what
    // its scrollable is asked to be: loosening a tight box left the
    // scrollable as wide as its widest line while the box around it stayed
    // full width (see scrollbar_cross_axis_fill_test.dart).
    const measured = <CoreScrollbarVisibility, double>{
      .auto: _kViewportSide,
      .thin: _kViewportSide,
      .hidden: _kViewportSide,
    };

    measured.forEach((visibility, expectedSide) {
      testWidgets(
        'visibility ${visibility.name} hands its child '
        '${expectedSide.toInt()}px',
        (tester) async {
          await pumpTestApp(
            tester,
            _boxed(
              Scrollbar(
                visibility: visibility,
                child: const SingleChildScrollView(
                  child: SizedBox(
                    height: _kItemHeight,
                    width: _kItemHeight,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.getSize(find.byType(SingleChildScrollView)),
            Size(expectedSide, expectedSide),
          );
        },
      );
    });
  });

  // `interactive` used to reach the painted bar and the accessibility node
  // through one value (`RawScrollbarState.enableGestures`). Splitting the
  // node out gave it a second, independent consumer — and the a11y tests
  // above only watch one of them, so the pointer half could be rewired to
  // a constant and every one of them would still pass.
  group('Scrollbar interactive still gates the painted thumb (#3983)', () {
    Future<double> dragThumbBy(
      WidgetTester tester, {
      required bool interactive,
    }) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await pumpTestApp(
        tester,
        _boxed(
          Scrollbar(
            visibility: .always,
            interactive: interactive,
            controller: controller,
            child: _list(controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Grab where the thumb sits: the top of the track, hard against the
      // trailing edge of the box.
      final box = tester.getRect(find.byType(Scrollbar));
      await tester.dragFrom(
        Offset(box.right - 4, box.top + 20),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      return controller.position.pixels;
    }

    testWidgets('an interactive bar scrolls when its thumb is dragged', (
      tester,
    ) async {
      expect(await dragThumbBy(tester, interactive: true), greaterThan(0));
    });

    testWidgets('a non-interactive bar does not', (tester) async {
      expect(await dragThumbBy(tester, interactive: false), 0);
    });
  });
}
