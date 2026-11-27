import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/chat/chat_default_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_shape_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_showcase_allocation_units.dart';

const _kRecipes = <(String, String)>[
  ('progress', 'tone'),
  ('chat', 'default'),
  ('chat', 'plain'),
  ('chat', 'tail-corner'),
  ('chat', 'tail-top'),
  ('chip', 'selected'),
  ('chip', 'variant'),
  ('chip', 'shape'),
  ('chip', 'cast-motion'),
  ('chip', 'prefix'),
  ('skeleton', 'default'),
  ('step-item', 'default'),
];

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: 800,
        height: 600,
        child: SingleChildScrollView(
          child: KeyedSubtree(key: capture, child: result),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  // Skeleton and Progress may keep ticking normally. Never settle a pulse.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

ShowcaseAllocationBoxSourceBinding _bind(GlobalKey key, Widget result) =>
    bindShowcaseAllocationBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: BoxObservationSourceSpec.showcaseAllocationHost,
    )!;

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets('$recipe/$dark binds all original mounted seats', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.$1]!(recipe.$2);
        final capture = GlobalKey();
        await _mount(tester, result, capture, dark: dark);
        final binding = _bind(capture, result);
        final raw = binding.allOriginalSuppliedSlots;
        final seats = binding.allOriginalMountedSeats;
        expect(raw.length, seats.length);
        expect(Set<Element>.identity()..addAll(seats), hasLength(seats.length));
        expect(binding.scope.foreignBoundaries, orderedEquals(seats));
        for (var i = 0; i < raw.length; i++) {
          expect(seats[i].widget, same(raw[i]));
          Element? parent;
          seats[i].visitAncestorElements((ancestor) {
            parent = ancestor;
            return false;
          });
          expect(parent, same(binding.fieldUnitElement));
          expect(
            () => binding.scope.requireOwned(seats[i]),
            throwsA(isA<BoxObservationError>()),
          );
        }
        final actual = binding.readDeclaredAbsence();
        expect(actual.quantity, PaddingQuantityKind.declaredNoOwnPadding);
        expect(actual.value, EdgeInsets.zero);
        expect(actual.owner, same(binding.fieldUnitElement));
        expect(actual.frameOwner, same(binding.frameSource));
        expect(actual.producer, same(binding.registryResultElement));
        expect(actual.paddingElement, isNull);
        expect(binding.readActualPadding, throwsA(isA<BoxObservationError>()));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('repeated raw identity retains distinct mounted seats', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['chip']!('variant');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final canonical = _bind(capture, result);
    expect(canonical.allOriginalSuppliedSlots, hasLength(11));
    expect(
      Set<Element>.identity()..addAll(canonical.allOriginalMountedSeats),
      hasLength(11),
    );
    final owner = canonical.fieldUnitElement;
    final declaration = owner.widget as Column;
    final original = declaration.children[3];
    final seat = canonical.allOriginalMountedSeats[3];
    // Separate const source locations need not intern in debug builds. This
    // adversarial fixture explicitly repeats one original foreign input in
    // the same current public declaration and updates its actual mounted seats.
    final repeated = declaration.children[1];
    expect(original, isNot(same(repeated)));
    expect(Widget.canUpdate(original, repeated), true);
    try {
      declaration.children[3] = repeated;
      owner.owner!.buildScope(seat, () => seat.update(repeated));
      await tester.pump();
      expect(
        canonical.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
      final binding = _bind(capture, result);
      final raw = binding.allOriginalSuppliedSlots;
      final seats = binding.allOriginalMountedSeats;
      expect(raw, hasLength(11));
      expect(binding.fieldUnitElement.widget, same(declaration));
      expect(raw[3], same(raw[1]));
      expect(seats[3].widget, same(raw[1]));
      expect(seats[1].widget, same(raw[1]));
      expect(seats[3], isNot(same(seats[1])));
      expect(
        seats[3].findRenderObject(),
        isNot(same(seats[1].findRenderObject())),
      );
      expect(Set<Element>.identity()..addAll(seats), hasLength(raw.length));
      final records =
          binding.readDeclaredAbsence().generatedSlots.single['rawSlots']!
              as List;
      expect(records, hasLength(raw.length));
      expect((records[3] as Map)['sameSourceAsEarlierSeat'], 1);
      // Hash integers are provenance only; distinctness uses actual identities.
      for (var i = 0; i < records.length; i++) {
        expect(
          (records[i] as Map)['mountedElement'],
          identityHashCode(seats[i]),
        );
      }
    } finally {
      declaration.children[3] = original;
      owner.owner!.buildScope(seat, () => seat.update(original));
      await tester.pump();
    }
    expect(
      _bind(capture, result).readDeclaredAbsence().quantity,
      PaddingQuantityKind.declaredNoOwnPadding,
    );
  });

  for (final mutation in ['drop', 'reorder', 'extra repeated occurrence']) {
    testWidgets('$mutation raw input cannot produce an absence value', (
      tester,
    ) async {
      final result = kFlutterPreviewRegistry['chip']!('variant');
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final binding = _bind(capture, result);
      final children = (binding.fieldUnitElement.widget as Column).children;
      final original = List<Widget>.of(children);
      try {
        if (mutation == 'drop') children.removeLast();
        if (mutation == 'reorder') {
          final first = children[0];
          children[0] = children[1];
          children[1] = first;
        }
        if (mutation == 'extra repeated occurrence') children.add(children[1]);
        expect(
          binding.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
      } finally {
        children
          ..clear()
          ..addAll(original);
      }
      binding.validateExistingCurrentBinding();
    });
  }

  testWidgets('actual renderer reorder rejects despite unchanged raw Widgets', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['chip']!('variant');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    final render = binding.fieldUnitElement.renderObject! as RenderFlex;
    final children = <RenderBox>[];
    render.visitChildren((child) => children.add(child as RenderBox));
    try {
      render.move(children[0], after: children[1]);
      expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    } finally {
      render.move(children[0]);
    }
    binding.validateExistingCurrentBinding();
  });

  testWidgets('foreign renderer substituted at the host edge cannot own it', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['chip']!('shape');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    final render = binding.fieldUnitElement.renderObject! as RenderFlex;
    final original = render.firstChild!;
    final replacement = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 7, height: 9),
    );
    try {
      render
        ..remove(original)
        ..insert(replacement);
      expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    } finally {
      render
        ..remove(replacement)
        ..insert(original);
      replacement.dispose();
    }
    binding.validateExistingCurrentBinding();
  });

  testWidgets('altered Scope boundaries cannot hide a raw occurrence', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['chat']!('default');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    final last = binding.scope.foreignBoundaries.removeLast();
    try {
      expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    } finally {
      binding.scope.foreignBoundaries.add(last);
    }
    binding.validateExistingCurrentBinding();
  });

  testWidgets('copied registry Widget is not the original mounted result', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['chip']!('shape');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final copy = ChipShapeExample(key: UniqueKey());
    expect(() => _bind(capture, copy), throwsA(isA<BoxObservationError>()));
  });

  testWidgets('unknown subclass build is not replayed or accepted', (
    tester,
  ) async {
    var builds = 0;
    final result = _UnknownShowcase(() => builds++);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(builds, 1);
    expect(() => _bind(capture, result), throwsA(isA<BoxObservationError>()));
    expect(builds, 1);
  });

  testWidgets(
    'same Example Element with a new themed output '
    'invalidates only held binding',
    (tester) async {
      final result = kFlutterPreviewRegistry['chip']!('shape');
      final capture = GlobalKey();
      final dark = ValueNotifier<bool>(false);
      try {
        await tester.pumpWidget(
          ValueListenableBuilder<bool>(
            valueListenable: dark,
            builder: (context, value, child) => buildTestApp(
              SizedBox(
                width: 800,
                height: 600,
                child: KeyedSubtree(key: capture, child: result),
              ),
              theme: coui.ThemeData.fromCore(
                value
                    ? coui.CoreThemePresets.dark
                    : coui.CoreThemePresets.light,
              ),
            ),
          ),
        );
        await tester.pump();
        final held = _bind(capture, result);
        final example = held.registryResultElement;
        final previousHostWidget = held.fieldUnitElement.widget;
        dark.value = true;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final current = _bind(capture, result);
        expect(current.registryResultElement, same(example));
        expect(current.fieldUnitElement, same(held.fieldUnitElement));
        // ChipShapeExample itself depends on Theme.of and creates a fresh Row.
        // Prove the real rebuild before asking the held binding to reject it.
        expect(
          current.fieldUnitElement.widget,
          isNot(same(previousHostWidget)),
        );
        expect(held.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
        expect(
          _bind(capture, result).readDeclaredAbsence().quantity,
          PaddingQuantityKind.declaredNoOwnPadding,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        dark.dispose();
      }
    },
  );

  testWidgets('unmounted original source never becomes zero', (tester) async {
    final result = kFlutterPreviewRegistry['chat']!('plain');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
  });

  testWidgets('required nullable SizedBox slot is checked before observation', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['step-item']!('default');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    final owner = binding.fieldUnitElement;
    final original = owner.widget as SizedBox;
    try {
      owner.owner!.buildScope(owner, () {
        owner.update(SizedBox(width: original.width, height: original.height));
      });
      expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    } finally {
      owner.owner!.buildScope(owner, () => owner.update(original));
      await tester.pump();
    }
    // The old immutable binding intentionally stays stale after a rebuild;
    // a fresh source must prove the current original child again.
    expect(
      _bind(capture, result).readDeclaredAbsence().quantity,
      PaddingQuantityKind.declaredNoOwnPadding,
    );
  });
}

class _UnknownShowcase extends ChatDefaultExample {
  const _UnknownShowcase(this.onBuild);
  final VoidCallback onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Row(children: [Text('not the audited producer')]);
  }
}
