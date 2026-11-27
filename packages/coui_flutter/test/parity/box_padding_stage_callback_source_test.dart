import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_stage_callback_source.dart';

void main() {
  ValueNotifier<Widget>? currentContent;
  setUp(() => currentContent = null);
  tearDown(() => currentContent?.dispose());
  Future<StageCallbackContentBinding> mount(
    WidgetTester tester,
    StageContainer product, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    final content = Directionality(
      textDirection: direction,
      child: SizedBox(width: 800, child: product),
    );
    if (currentContent == null) {
      final state = ValueNotifier<Widget>(content);
      currentContent = state;
      await pumpTestApp(
        tester,
        ValueListenableBuilder<Widget>(
          valueListenable: state,
          builder: (_, child, _) => child,
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      );
    } else {
      currentContent!.value = content;
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return bindCurrentStageCallbackContent(
      tester.element(find.byType(StageContainer)),
    );
  }

  StageContainer product({
    Widget? child,
    EdgeInsetsGeometry? own,
    StageContainerBuilder? builder,
  }) => StageContainer(
    builder:
        builder ??
        (context, actual) => Padding(
          padding: own ?? const EdgeInsets.fromLTRB(11, 3, 7, 5),
          child: child ?? const SizedBox(width: 8, height: 8),
        ),
  );

  testWidgets('observer invokes neither public callback nor resolver again', (
    tester,
  ) async {
    var calls = 0;
    final binding = await mount(
      tester,
      product(
        builder: (context, actual) {
          calls++;
          return const Padding(
            padding: EdgeInsets.fromLTRB(11, 3, 7, 5),
            child: Padding(
              padding: EdgeInsets.all(101),
              child: SizedBox(width: 8, height: 8),
            ),
          );
        },
      ),
    );
    expect(calls, greaterThan(0));
    final before = calls;
    expect(binding.readActualPadding().toJson()['value'], [3, 7, 5, 11]);
    binding
      ..validateCurrentBinding()
      ..sourceIdentity;
    expect(calls, before);
  });

  testWidgets('foreign callback body replacement stays opaque', (tester) async {
    final body = ValueNotifier<Widget>(
      const Padding(
        padding: EdgeInsets.all(61),
        child: SizedBox(width: 8, height: 8),
      ),
    );
    addTearDown(body.dispose);
    final foreign = ValueListenableBuilder<Widget>(
      valueListenable: body,
      builder: (_, child, _) => child,
    );
    final binding = await mount(tester, product(child: foreign));
    final before = binding.bodyBoundary;
    body.value = const Padding(
      padding: EdgeInsets.all(83),
      child: SizedBox(width: 9, height: 9),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(binding.bodyBoundary, same(before));
    expect(
      tester
          .widgetList<Padding>(find.byType(Padding))
          .any((p) => p.padding == const EdgeInsets.all(83)),
      true,
    );
    binding.validateCurrentBinding();
    expect(binding.readActualPadding().toJson()['value'], [3, 7, 5, 11]);
  });

  testWidgets('installed actual RenderPadding parameter swap is stale', (
    tester,
  ) async {
    final binding = await mount(tester, product());
    final render =
        (binding.paddingSource as RenderObjectElement).renderObject
            as RenderPadding;
    final before = render.padding;
    render.padding = const EdgeInsets.all(29);
    expect(
      identical(before, render.padding),
      false,
      reason: 'negative precondition requires installed public parameter',
    );
    expect(binding.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
    render.padding = before;
    binding.validateCurrentBinding();
  });

  testWidgets('actual render direction mutation stales held binding', (
    tester,
  ) async {
    final binding = await mount(
      tester,
      product(own: const EdgeInsetsDirectional.fromSTEB(11, 3, 7, 5)),
    );
    final render =
        (binding.paddingSource as RenderObjectElement).renderObject
            as RenderPadding;
    final before = render.textDirection;
    render.textDirection = before == TextDirection.rtl
        ? TextDirection.ltr
        : TextDirection.rtl;
    expect(render.textDirection, isNot(before));
    expect(binding.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
    render.textDirection = before;
    binding.validateCurrentBinding();
  });

  testWidgets('normal equal-value rebuild has a fresh valid binding', (
    tester,
  ) async {
    final old = await mount(tester, product());
    final oldInput = old.stage.widget;
    final current = await mount(tester, product());
    expect(
      identical(current.stage.widget, oldInput),
      false,
      reason: 'negative precondition: actual current Stage widget changed',
    );
    expect(old.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
    expect(current.readActualPadding().toJson()['value'], [3, 7, 5, 11]);
  });
  testWidgets('normal callback and child replacement invalidates old binding', (
    tester,
  ) async {
    final old = await mount(tester, product());
    final oldInput = old.stage.widget;
    final current = await mount(
      tester,
      product(
        builder: (context, actual) => const Padding(
          padding: EdgeInsets.fromLTRB(11, 3, 7, 5),
          child: SizedBox(width: 17, height: 13),
        ),
      ),
    );
    expect(
      identical(current.stage.widget, oldInput),
      false,
      reason: 'negative precondition: replacement callback actually mounted',
    );
    expect(old.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
    current.validateCurrentBinding();
  });
  testWidgets('detached original prefix is rejected', (tester) async {
    final old = await mount(tester, product());
    currentContent!.value = const SizedBox();
    await tester.pumpAndSettle();
    expect(
      old.stage.mounted,
      false,
      reason: 'negative precondition: original Stage really detached',
    );
    expect(old.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
  });
  testWidgets('unexpected callback wrapper cannot choose its first Padding', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      SizedBox(
        width: 800,
        child: product(
          builder: (context, actual) => const Column(
            children: [
              Padding(
                padding: EdgeInsets.all(19),
                child: SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        ),
      ),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      () => bindCurrentStageCallbackContent(
        tester.element(find.byType(StageContainer)),
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });
}
