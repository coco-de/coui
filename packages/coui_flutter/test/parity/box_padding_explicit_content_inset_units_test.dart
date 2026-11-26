import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_explicit_content_inset_units.dart';
import 'box_padding_observation.dart';

const _kPump = Duration(milliseconds: 300);
const double _kForeignInset = 4;
const double _kChangedForeignInset = 12;
const double _kOwnInset = 9;
const double _kChangedOwnInset = 15;
Matcher _changed() => throwsA(isA<BoxObservationError>());

BoxObservationSourceSpec _source(String component) => switch (component) {
  'menu-item' => BoxObservationSourceSpec.menuItemRowContentInset,
  'carousel-banner' => BoxObservationSourceSpec.carouselBannerStripContentInset,
  _ => BoxObservationSourceSpec.panelHeaderContentInset,
};
BoxPaddingObservation _read(ExplicitContentInsetBoxSourceBinding binding) {
  binding.validateCurrentConstruction();
  return observeSourceOwnedRenderPadding(
    owner: binding.paddingSource,
    scope: binding.scope,
  );
}

Future<ExplicitContentInsetBoxSourceBinding> _mount(
  WidgetTester tester,
  Widget result,
  BoxObservationSourceSpec source, {
  bool dark = false,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      KeyedSubtree(key: key, child: result),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump(_kPump);
  return bindExplicitContentInsetBoxSource(
    captureRoot: key.currentContext! as Element,
    registryResult: result,
    source: source,
  )!;
}

Widget _producer(
  String component,
  List<Widget> slots, {
  double padding = _kOwnInset,
}) => switch (component) {
  'menu-item' => coui.MenuItem(
    onPressed: () {},
    menuItemStyle: coui.CoreMenuItemStyle(
      padding: coui.CoreEdgeInsets.all(padding),
    ),
    label: slots[0],
    description: slots[1],
    shortcut: slots[2],
    leading: slots[3],
    trailing: slots[4],
    mark: slots[5],
  ),
  'carousel-banner' => coui.CarouselBanner(
    carouselBannerStyle: coui.CoreCarouselBannerStyle(
      padding: coui.CoreEdgeInsets.all(padding),
    ),
    thumbnail: slots[0],
    title: slots[1],
    description: slots[2],
  ),
  _ => coui.PanelHeader(
    panelHeaderStyle: coui.CorePanelHeaderStyle(
      padding: coui.CoreEdgeInsets.all(padding),
    ),
    title: slots[0],
    action: slots[1],
  ),
};
int _slotCount(String component) => component == 'menu-item'
    ? 6
    : component == 'carousel-banner'
    ? 3
    : 2;
List<Widget> _slots(String component) =>
    List.generate(_slotCount(component), (i) => Text('$i'));

void main() {
  const recipes = <({String component, String variant})>[
    (component: 'menu-item', variant: 'default'),
    (component: 'menu-item', variant: 'critical'),
    (component: 'menu-item', variant: 'description'),
    (component: 'carousel-banner', variant: 'default'),
    (component: 'carousel-banner', variant: 'md'),
    (component: 'panel-header', variant: 'default'),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark registry owner',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final binding = await _mount(
            tester,
            result,
            _source(recipe.component),
            dark: dark,
          );
          final observed = _read(binding);
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.scope.producer, same(binding.registryResultElement));
          expect(binding.readerId, 'current-render-padding-v1');
          expect(observed.owner, same(binding.paddingSource));
          expect(observed.quantity, PaddingQuantityKind.frameworkOwnParameter);
          expect(binding.scope.foreignBoundaries, isNotEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final component in ['menu-item', 'carousel-banner', 'panel-header']) {
    testWidgets(
      '$component supplied slots stay foreign under child mutation',
      (tester) async {
        final value = ValueNotifier<double>(_kForeignInset);
        final keys = List.generate(_slotCount(component), (_) => GlobalKey());
        final slots = <Widget>[
          for (var i = 0; i < keys.length; i++)
            ValueListenableBuilder<double>(
              key: keys[i],
              valueListenable: value,
              builder: (context, inset, child) =>
                  Padding(padding: EdgeInsets.all(inset), child: Text('$i')),
            ),
        ];
        final result = _producer(component, slots);
        final binding = await _mount(tester, result, _source(component));
        final original = _read(binding);
        for (final key in keys) {
          expect(
            () => binding.scope.requireOwned(key.currentContext! as Element),
            _changed(),
          );
        }
        value.value = _kChangedForeignInset;
        await tester.pump(_kPump);
        for (final key in keys) {
          final actual =
              boxElements(key.currentContext! as Element)
                      .where((e) => e.widget.runtimeType == Padding)
                      .single
                      .renderObject!
                  as RenderPadding;
          expect(actual.padding, const EdgeInsets.all(_kChangedForeignInset));
        }
        final current = _read(binding);
        expect(current.owner, same(original.owner));
        expect(current.value, original.value);
        expect(tester.takeException(), isNull);
        value.dispose();
      },
    );
    testWidgets(
      '$component replacement rejects stale binding and reads fresh own input',
      (tester) async {
        final value = ValueNotifier<Widget>(
          _producer(component, _slots(component)),
        );
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<Widget>(
              valueListenable: value,
              builder: (context, current, child) =>
                  KeyedSubtree(key: key, child: current),
            ),
          ),
        );
        await tester.pump(_kPump);
        final root = key.currentContext! as Element;
        final old = bindExplicitContentInsetBoxSource(
          captureRoot: root,
          registryResult: value.value,
          source: _source(component),
        )!;
        final original = _read(old);
        expect(original.value, const EdgeInsets.all(_kOwnInset));
        value.value = _producer(
          component,
          _slots(component),
          padding: _kChangedOwnInset,
        );
        await tester.pump(_kPump);
        expect(old.validateCurrentConstruction, _changed());
        final fresh = bindExplicitContentInsetBoxSource(
          captureRoot: root,
          registryResult: value.value,
          source: _source(component),
        )!;
        expect(fresh.registryResultElement, same(old.registryResultElement));
        if (component == 'carousel-banner') {
          final widget = fresh.frameSource.widget as DecoratedBox;
          final render = fresh.frameSource.renderObject! as RenderDecoratedBox;
          expect(widget.decoration, equals(render.decoration));
          expect(widget.decoration, isNot(same(render.decoration)));
        }
        expect(_read(fresh).value, const EdgeInsets.all(_kChangedOwnInset));
        value.dispose();
      },
    );
    testWidgets('$component raw duplicated public identity rejects', (
      tester,
    ) async {
      const shared = Text('x');
      final result = _producer(
        component,
        List.filled(_slotCount(component), shared),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pump(_kPump);
      expect(
        () => bindExplicitContentInsetBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _source(component),
        ),
        _changed(),
      );
    });
  }
  testWidgets(
    'omitted shortcut duplicate is rejected before unsupported submenu branch',
    (tester) async {
      const shared = Text('x');
      const result = coui.MenuItem(
        hasSubmenu: true,
        shortcut: shared,
        leading: shared,
        label: Text('L'),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pump(_kPump);
      expect(
        () => bindExplicitContentInsetBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: BoxObservationSourceSpec.menuItemRowContentInset,
        ),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.reason,
            'raw duplicate',
            contains('unique raw'),
          ),
        ),
      );
    },
  );
  testWidgets(
    'Menu hover keeps the content Element and adds source wash',
    (tester) async {
      final result = coui.MenuItem(onPressed: () {}, label: const Text('L'));
      final binding = await _mount(
        tester,
        result,
        BoxObservationSourceSpec.menuItemRowContentInset,
      );
      final original = _read(binding);
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(find.byWidget(result)));
      await tester.pump(_kPump);
      final stacks =
          boxElements(
                binding.frameSource,
              ).where((e) => e.widget.runtimeType == coui.Stacks).single.widget
              as coui.Stacks;
      expect(stacks.children, hasLength(2));
      expect(_read(binding).owner, same(original.owner));
      expect(_read(binding).value, original.value);
      await mouse.removePointer();
      await tester.pump(_kPump);
      expect(_read(binding).owner, same(original.owner));
    },
  );
  testWidgets(
    'theme rebuild retains current generated frame source',
    (tester) async {
      final dark = ValueNotifier<bool>(false);
      final result = kFlutterPreviewRegistry['menu-item']!(null);
      final key = GlobalKey();
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: dark,
          builder: (context, current, child) => buildTestApp(
            KeyedSubtree(key: key, child: result),
            theme: coui.ThemeData.fromCore(
              current
                  ? coui.CoreThemePresets.dark
                  : coui.CoreThemePresets.light,
            ),
          ),
        ),
      );
      await tester.pump(_kPump);
      final old = bindExplicitContentInsetBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: BoxObservationSourceSpec.menuItemRowContentInset,
      )!;
      dark.value = true;
      await tester.pump(_kPump);
      final currentProducer = boxElements(
        old.registryResultElement,
      ).where((e) => e.widget.runtimeType == coui.MenuItem).single;
      final fresh = bindExplicitContentInsetBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: BoxObservationSourceSpec.menuItemRowContentInset,
      )!;
      expect(fresh.registryResultElement, same(old.registryResultElement));
      expect(currentProducer.mounted, true);
      _read(fresh);
      old.validateCurrentConstruction();
      expect(tester.takeException(), isNull);
      dark.dispose();
    },
  );
  for (final decoration in <Decoration>[
    const BoxDecoration(border: Border.fromBorderSide(BorderSide())),
    const _UnknownDecoration(),
  ]) {
    testWidgets(
      'live decoration rejects allocation: ${decoration.runtimeType}',
      (tester) async {
        final result = _producer('carousel-banner', _slots('carousel-banner'));
        final binding = await _mount(
          tester,
          result,
          BoxObservationSourceSpec.carouselBannerStripContentInset,
        );
        final render = binding.frameSource.renderObject! as RenderDecoratedBox;
        final old = render.decoration;
        render.decoration = decoration;
        expect(binding.validateCurrentConstruction, _changed());
        render.decoration = old;
        _read(binding);
      },
    );
  }
  testWidgets('current Menu Container foreground allocation fails closed', (
    tester,
  ) async {
    final result = _producer('menu-item', _slots('menu-item'));
    final binding = await _mount(
      tester,
      result,
      BoxObservationSourceSpec.menuItemRowContentInset,
    );
    final old = binding.frameSource.widget as Container;
    binding.frameSource.owner!.buildScope(binding.frameSource, () {
      binding.frameSource.update(
        Container(
          decoration: old.decoration,
          foregroundDecoration: const BoxDecoration(),
          child: old.child,
        ),
      );
    });
    expect(binding.validateCurrentConstruction, _changed());
  });
  for (final result in <Widget>[
    const _UnknownMenu(),
    const _UnknownCarousel(),
    const _UnknownPanel(),
    const SizedBox(child: coui.PanelHeader(title: Text('L'))),
  ]) {
    testWidgets('unknown subclass/wrapper rejects ${result.runtimeType}', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pump(_kPump);
      final source = result is coui.MenuItem
          ? BoxObservationSourceSpec.menuItemRowContentInset
          : result is coui.CarouselBanner
          ? BoxObservationSourceSpec.carouselBannerStripContentInset
          : BoxObservationSourceSpec.panelHeaderContentInset;
      expect(
        () => bindExplicitContentInsetBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: source,
        ),
        _changed(),
      );
    });
  }
  testWidgets('tuple/registry mismatch and disposed source reject', (
    tester,
  ) async {
    const result = coui.PanelHeader(title: Text('L'));
    final binding = await _mount(
      tester,
      result,
      BoxObservationSourceSpec.panelHeaderContentInset,
    );
    for (final field in [
      'schemaVersion',
      'quantityId',
      'nativeAdapterId',
      'webAdapterId',
    ]) {
      final raw = BoxObservationSourceSpec.panelHeaderContentInset.toJson();
      raw[field] = field == 'schemaVersion' ? 99 : 'stale';
      expect(
        () => bindExplicitContentInsetBoxSource(
          captureRoot: binding.registryResultElement,
          registryResult: result,
          source: BoxObservationSourceSpec.fromJson(raw),
        ),
        _changed(),
      );
    }
    expect(
      () => bindExplicitContentInsetBoxSource(
        captureRoot: binding.registryResultElement,
        registryResult: const coui.PanelHeader(title: Text('Other')),
        source: BoxObservationSourceSpec.panelHeaderContentInset,
      ),
      _changed(),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(binding.validateCurrentConstruction, _changed());
  });
}

class _UnknownMenu extends coui.MenuItem {
  const _UnknownMenu() : super(label: const Text('L'));
}

class _UnknownCarousel extends coui.CarouselBanner {
  const _UnknownCarousel();
}

class _UnknownPanel extends coui.PanelHeader {
  const _UnknownPanel() : super(title: const Text('L'));
}

class _UnknownDecoration extends BoxDecoration {
  const _UnknownDecoration();
}
