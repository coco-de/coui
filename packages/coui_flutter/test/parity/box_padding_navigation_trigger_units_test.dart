import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_navigation_trigger_units.dart';
import 'box_padding_observation.dart';

const _recipes = <({String component, String variant})>[
  (component: 'command-search', variant: 'default'),
  (component: 'navigation-bar', variant: 'default'),
  (component: 'navigation-bar', variant: 'rail'),
  (component: 'navigation-bar', variant: 'sidebar'),
  (component: 'dock', variant: 'default'),
];
BoxObservationSourceSpec _source(String c) => switch (c) {
  'command-search' => BoxObservationSourceSpec.commandSearchTriggerContentInset,
  'navigation-bar' => BoxObservationSourceSpec.navigationBarItemsContentInset,
  'dock' => BoxObservationSourceSpec.dockBarContentInset,
  _ => throw StateError(c),
};
Future<GlobalKey> _mount(
  WidgetTester t,
  Widget widget, {
  bool dark = false,
  double width = 800,
}) async {
  await t.pumpWidget(const SizedBox.shrink());
  final key = GlobalKey();
  await t.pumpWidget(
    buildTestApp(
      SizedBox(
        width: width,
        height: 520,
        child: Center(
          child: KeyedSubtree(key: key, child: widget),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 32));
  await t.pump(const Duration(milliseconds: 32));
  return key;
}

NavigationTriggerBoxSourceBinding _bind(GlobalKey key, Widget w, String c) =>
    bindNavigationTriggerBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: w,
      source: _source(c),
    )!;
Widget _foreign(double p) => Padding(
  padding: EdgeInsets.all(p),
  child: const SizedBox(width: 8, height: 8),
);
coui.NavigationBar _navigation({
  Widget? header,
  Widget? footer,
  bool vertical = false,
  List<coui.CoreNavigationBarItem<Widget>>? items,
}) => coui.NavigationBar(
  mode: vertical
      ? coui.CoreNavigationBarMode.rail
      : coui.CoreNavigationBarMode.bar,
  header: header,
  footer: footer,
  selectedIndex: 0,
  navigationBarStyle: const coui.CoreNavigationBarStyle(
    padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
  ),
  items:
      items ??
      [
        coui.CoreNavigationBarItem.destination(
          icon: _foreign(71),
          label: 'one',
          badge: _foreign(83),
        ),
        coui.CoreNavigationBarItem.destination(
          icon: _foreign(97),
          label: 'two',
        ),
      ],
);

class _UnknownCommand extends coui.CommandSearch {
  const _UnknownCommand() : super();
}

class _UnknownDock extends coui.Dock {
  const _UnknownDock() : super(items: const []);
}

void main() {
  for (final recipe in _recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        'actual registry ${recipe.component}/${recipe.variant}/$dark',
        (t) async {
          final w = kFlutterPreviewRegistry[recipe.component]!(recipe.variant);
          final key = await _mount(t, w, dark: dark);
          final b = _bind(key, w, recipe.component)
            ..validateExistingCurrentBinding();
          expect(b.registryResultElement.widget, same(w));
          expect(b.scope.producer, same(b.registryResultElement));
          b.scope.requireOwned(b.fieldUnitElement);
          b.scope.requireOwned(b.paddingSource);
          b.scope.requireOwned(b.frameSource);
          final v = b.readActualPadding();
          expect(v.quantity, PaddingQuantityKind.frameworkOwnParameter);
          expect(v.owner, same(b.paddingSource));
          expect(v.frameOwner, same(b.frameSource));
          for (final foreign in b.scope.foreignBoundaries) {
            expect(
              () => b.scope.requireOwned(foreign),
              throwsA(isA<BoxObservationError>()),
            );
          }
        },
      );
    }
  }
  for (final shortcut in [false, true]) {
    testWidgets('trigger arbitrary four sides and foreign slots $shortcut', (
      t,
    ) async {
      var callbacks = 0;
      final w = coui.CommandSearch(
        leading: _foreign(71),
        shortcut: shortcut ? _foreign(83) : null,
        onPressed: () => callbacks++,
        commandSearchStyle: const coui.CoreCommandSearchStyle(
          padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
        ),
      );
      final key = await _mount(t, w);
      final b = _bind(key, w, 'command-search');
      expect(
        b.readActualPadding().value,
        const EdgeInsets.fromLTRB(3, 5, 7, 11),
      );
      expect(b.scope.foreignBoundaries.length, shortcut ? 2 : 1);
      expect(callbacks, 0);
    });
  }
  for (final framed in [false, true]) {
    for (final vertical in [false, true]) {
      testWidgets('nav current items/footer allocation $framed/$vertical', (
        t,
      ) async {
        final w = _navigation(
          header: framed ? _foreign(31) : null,
          footer: framed ? _foreign(37) : null,
          vertical: vertical,
        );
        final key = await _mount(t, w);
        final b = _bind(key, w, 'navigation-bar');
        expect(
          b.readActualPadding().value,
          const EdgeInsets.fromLTRB(3, 5, 7, 11),
        );
        expect(b.paddingSource.renderObject, isA<RenderPadding>());
        expect(b.frameSource.widget, isA<Container>());
        expect(b.scope.foreignBoundaries.length, framed ? 5 : 3);
      });
    }
  }
  testWidgets('nav overflow is read from mounted scroll branch', (t) async {
    final w = _navigation(
      items: [
        for (var i = 0; i < 12; i++)
          coui.CoreNavigationBarItem.destination(
            icon: _foreign(1 + i.toDouble()),
            label: 'destination $i',
          ),
      ],
    );
    final key = await _mount(t, w, width: 180);
    final b = _bind(key, w, 'navigation-bar');
    expect(b.readActualPadding().value, const EdgeInsets.fromLTRB(3, 5, 7, 11));
    expect(b.paddingSource.renderObject, isA<RenderPadding>());
    expect(b.scope.foreignBoundaries.length, 12);
  });
  for (final zero in [false, true]) {
    testWidgets('Dock bar only excludes inner clearance and border $zero', (
      t,
    ) async {
      final w = coui.Dock(
        items: [
          coui.CoreDockItemData<Widget>(icon: _foreign(71), label: 'one'),
        ],
        dockStyle: coui.CoreDockStyle(
          borderWidth: 3,
          padding: zero
              ? coui.CoreEdgeInsets.zero
              : const coui.CoreEdgeInsets.fromLTRB(3, 5, 17, 19),
        ),
      );
      final key = await _mount(t, w);
      final b = _bind(key, w, 'dock');
      final bar = b.paddingSource.widget as Container;
      final value = b.readActualPadding();
      expect(b.paddingSource, same(b.frameSource));
      // Actual existing Container parameter is authoritative. The authored
      // asymmetric input can produce different N/W sides; never sum Row.
      expect(
        value.value,
        bar.padding!.resolve(Directionality.of(b.paddingSource)),
      );
      expect(
        value.currentRenderPadding - value.allocatedDecorationInsets,
        value.value,
      );
      expect(value.value.top, 0);
      expect(value.value.bottom, 0);
      expect(value.paddingElement, isNotNull);
      expect(b.scope.foreignBoundaries.length, 1);
    });
  }
  testWidgets(
    'duplicate raw trigger references reject before rendering omission',
    (t) async {
      final shared = _foreign(3);
      final w = coui.CommandSearch(leading: shared, shortcut: shared);
      final key = await _mount(t, w);
      expect(
        () => _bind(key, w, 'command-search'),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets('navigation header and item icon duplicate rejects', (t) async {
    final shared = _foreign(1);
    final w = _navigation(
      header: shared,
      items: [
        coui.CoreNavigationBarItem.destination(icon: shared, label: 'one'),
      ],
    );
    final key = await _mount(t, w);
    expect(
      () => _bind(key, w, 'navigation-bar'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('Dock complete ordered icon bag rejects duplicates', (t) async {
    final shared = _foreign(2);
    final w = coui.Dock(
      items: [
        coui.CoreDockItemData<Widget>(icon: shared),
        coui.CoreDockItemData<Widget>(icon: shared),
      ],
    );
    final key = await _mount(t, w);
    expect(() => _bind(key, w, 'dock'), throwsA(isA<BoxObservationError>()));
  });
  for (final (component, unknown) in <(String, Widget)>[
    ('command-search', const _UnknownCommand()),
    ('dock', const _UnknownDock()),
  ]) {
    testWidgets('unknown concrete producer $component holds', (t) async {
      final key = await _mount(t, unknown);
      expect(
        () => _bind(key, unknown, component),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }
  testWidgets(
    'held binding rejects live replacement with same capture element',
    (t) async {
      final current = ValueNotifier<Widget>(
        coui.CommandSearch(leading: _foreign(31)),
      );
      addTearDown(current.dispose);
      final key = GlobalKey();
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 320,
            child: ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, w, _) => KeyedSubtree(key: key, child: w),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 32));
      final original = current.value;
      final b = _bind(key, original, 'command-search');
      final capture = key.currentContext;
      current.value = coui.CommandSearch(leading: _foreign(97));
      await t.pump();
      expect(key.currentContext, same(capture));
      expect(b.readActualPadding, throwsA(isA<BoxObservationError>()));
    },
  );
}
