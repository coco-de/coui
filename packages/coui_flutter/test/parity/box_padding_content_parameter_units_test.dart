import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_medium_example.dart';
import 'package:docs_core/previews/examples/flutter/kbd/kbd_single_example.dart';
import 'package:docs_core/previews/examples/flutter/refresh_trigger/refresh_trigger_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_content_parameter_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const BoxObservationSourceSpec _kCap =
    BoxObservationSourceSpec.kbdSingleKeycapContentInset;
const BoxObservationSourceSpec _kToolbar =
    BoxObservationSourceSpec.appBarMediumToolbarContentInset;
const BoxObservationSourceSpec _kViewport =
    BoxObservationSourceSpec.docsRefreshViewportContentInset;

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

BoxPaddingObservation _read(ContentParameterBoxSourceBinding binding) {
  binding.validateCurrentConstruction();
  return binding.readerId == 'outlined-content-v1'
      ? observeOutlinedContainerContentPadding(
          primitive: binding.paddingSource,
          declaringScope: binding.scope,
        )
      : observeSourceOwnedRenderPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        );
}

class _UnknownKbd extends coui.Kbd {
  const _UnknownKbd() : super(keys: const ['Esc']);
}

void main() {
  const recipes =
      <({String component, String variant, BoxObservationSourceSpec source})>[
        (component: 'kbd', variant: 'single', source: _kCap),
        (component: 'app-bar', variant: 'medium', source: _kToolbar),
        (component: 'refresh-trigger', variant: 'default', source: _kViewport),
      ];
  // Four component subunits and two documentation viewport inputs. These are
  // six source witnesses, not six fixes of legacy component-root padding.
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.component}/${recipe.variant} dark=$dark source', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.component]!(
          recipe.variant == 'default' ? null : recipe.variant,
        );
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            KeyedSubtree(key: key, child: result),
            theme: coui.ThemeData.fromCore(
              dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final binding = bindContentParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: recipe.source,
        )!;
        expect(binding.registryResultElement.widget, same(result));
        expect(binding.scope.producer, same(binding.registryResultElement));
        final observation = _read(binding);
        if (recipe.component == 'refresh-trigger') {
          expect(
            binding.paddingSource.widget.runtimeType,
            coui.OutlinedContainer,
          );
          expect(binding.fieldUnitElement, same(binding.paddingSource));
          expect(binding.readerId, 'outlined-content-v1');
          expect(
            binding.authority,
            contains('Documentation viewport inset only'),
          );
        } else {
          expect(binding.paddingSource.widget.runtimeType, Padding);
          expect(binding.fieldUnitElement, isNot(same(binding.paddingSource)));
          final raw = binding.paddingSource.renderObject! as RenderPadding;
          expect(observation.value, raw.padding.resolve(raw.textDirection));
          expect(binding.readerId, 'current-render-padding-v1');
        }
        for (final boundary in binding.scope.foreignBoundaries) {
          for (final foreign in boxElements(boundary)) {
            expect(
              () => binding.scope.requireOwned(foreign),
              _error('FOREIGN_SUPPLIED_CONTENT'),
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final cap in [true, false]) {
    testWidgets(
      'owned theme changes current ${cap ? 'cap' : 'toolbar'} inset',
      (
        tester,
      ) async {
        final amount = ValueNotifier<double>(coui.CoreSpace.space8);
        addTearDown(amount.dispose);
        final key = GlobalKey();
        final Widget result = cap
            ? const KbdSingleExample()
            : const AppBarMediumExample();
        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<double>(
              valueListenable: amount,
              child: KeyedSubtree(key: key, child: result),
              builder: (_, space, child) => coui.Theme(
                data: coui.ThemeData.fromCore(coui.CoreThemePresets.light)
                    .copyWith(
                      coreComponentTheme: () => coui.CoreComponentTheme(
                        kbd: cap
                            ? coui.CoreKbdTheme(
                                style: coui.CoreKbdStyle(
                                  keyPadding: coui.CoreEdgeInsets.all(space),
                                ),
                              )
                            : null,
                        appBar: cap
                            ? null
                            : coui.CoreAppBarTheme(
                                style: coui.CoreAppBarStyle(
                                  padding: coui.CoreEdgeInsets.all(space),
                                ),
                              ),
                      ),
                    ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final binding = bindContentParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: cap ? _kCap : _kToolbar,
        )!;
        final before = _read(binding).value;
        final frameWidget = binding.fieldUnitElement.widget;
        amount.value = coui.CoreSpace.space16;
        await tester.pumpAndSettle();
        expect(binding.fieldUnitElement.widget, isNot(same(frameWidget)));
        final after = _read(binding);
        expect(after.value, isNot(before));
        final raw = binding.paddingSource.renderObject! as RenderPadding;
        expect(after.value, raw.padding.resolve(raw.textDirection));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final recipe in recipes) {
    testWidgets(
      'same-mounted ${recipe.component} new input invalidates witness',
      (
        tester,
      ) async {
        final inputKey = UniqueKey();
        Widget input() => switch (recipe.component) {
          'kbd' => KbdSingleExample(key: inputKey),
          'app-bar' => AppBarMediumExample(key: inputKey),
          _ => RefreshTriggerDefaultExample(key: inputKey),
        };
        final current = ValueNotifier<Widget>(input());
        addTearDown(current.dispose);
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, value, _) => KeyedSubtree(key: key, child: value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        ContentParameterBoxSourceBinding bind() =>
            bindContentParameterBoxSource(
              captureRoot: key.currentContext! as Element,
              registryResult: current.value,
              source: recipe.source,
            )!;
        final old = bind();
        final oldElement = old.registryResultElement;
        current.value = input();
        await tester.pumpAndSettle();
        expect(old.registryResultElement, same(oldElement));
        expect(oldElement.mounted, true);
        expect(oldElement.widget, same(current.value));
        expect(
          old.validateCurrentConstruction,
          _error('STALE_CONTENT_PARAMETER_CONSTRUCTION'),
        );
        expect(() => _read(bind()), returnsNormally);
      },
    );
  }

  testWidgets(
    'raw omitted AppBar slot duplicates are rejected before filtering',
    (
      tester,
    ) async {
      final hidden = coui.Text('omitted', key: UniqueKey());
      final result = coui.AppBar(
        variant: coui.CoreAppBarVariant.medium,
        header: hidden,
        subtitle: hidden,
        child: const coui.Text('visible'),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pumpAndSettle();
      expect(find.byWidget(hidden), findsNothing);
      expect(
        () => bindContentParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _kToolbar,
        ),
        _error('DUPLICATE_OWNER'),
      );
    },
  );

  testWidgets('foreign title padding changes do not change toolbar inset', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(4);
    addTearDown(amount.dispose);
    final key = GlobalKey();
    final titleKey = GlobalKey();
    late Widget result;
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: amount,
          builder: (_, value, _) {
            result = coui.AppBar(
              variant: coui.CoreAppBarVariant.medium,
              title: Padding(
                key: titleKey,
                padding: EdgeInsets.all(value),
                child: const coui.Text('foreign title'),
              ),
            );
            return KeyedSubtree(key: key, child: result);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    ContentParameterBoxSourceBinding bind() => bindContentParameterBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kToolbar,
    )!;
    final before = _read(bind()).value;
    final foreign = titleKey.currentContext! as Element;
    amount.value = 12;
    await tester.pumpAndSettle();
    expect(titleKey.currentContext, same(foreign));
    expect((foreign.widget as Padding).padding, const EdgeInsets.all(12));
    final after = bind();
    expect(_read(after).value, before);
    expect(
      () => after.scope.requireOwned(foreign),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
  });

  testWidgets(
    'unknown, multi-key, icon, wrong toolbar and generic viewport reject',
    (
      tester,
    ) async {
      final cases = <(Widget, BoxObservationSourceSpec)>[
        (const _UnknownKbd(), _kCap),
        (const coui.Kbd(keys: ['Ctrl', 'S']), _kCap),
        (const coui.Kbd(keys: []), _kCap),
        (const coui.Kbd.icon(keyContent: coui.Text('foreign')), _kCap),
        (const coui.AppBar(title: coui.Text('standard')), _kToolbar),
        (const coui.OutlinedContainer(child: coui.Text('caller')), _kViewport),
      ];
      for (final (result, source) in cases) {
        await tester.pumpWidget(const SizedBox.shrink());
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(KeyedSubtree(key: key, child: result)),
        );
        await tester.pumpAndSettle();
        expect(
          () => bindContentParameterBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: source,
          ),
          throwsA(isA<BoxObservationError>()),
        );
      }
    },
  );

  testWidgets('closed source tuple and capture/result identity are required', (
    tester,
  ) async {
    const result = KbdSingleExample();
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    for (final change in [
      {'schemaVersion': 99},
      {'quantityId': 'unknown'},
      {'nativeAdapterId': 'unknown'},
      {'webAdapterId': 'unknown'},
    ]) {
      expect(
        () => bindContentParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: BoxObservationSourceSpec.fromJson({
            ..._kCap.toJson(),
            ...change,
          }),
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
    expect(
      () => bindContentParameterBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: KbdSingleExample(key: UniqueKey()),
        source: _kCap,
      ),
      _error('MISMATCHED_CONTENT_PARAMETER_RESULT'),
    );
    final unknown = BoxObservationSourceSpec.fromJson({
      ..._kCap.toJson(),
      'logicalUnitId': 'unknown',
    });
    expect(
      bindContentParameterBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: unknown,
      ),
      isNull,
    );
  });
}
