import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/chat/chat_primary_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Border,
        BoxDecoration,
        Column,
        Element,
        GlobalKey,
        KeyedSubtree,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_chat_bubble_units.dart';
import 'box_padding_observation.dart';

const BoxObservationSourceSpec _kSource =
    BoxObservationSourceSpec.docsChatSingleBubble;
const _kVariants = [
  'accent',
  'error',
  'info',
  'neutral',
  'primary',
  'secondary',
  'success',
  'warning',
];
Matcher _error(String code) =>
    throwsA(isA<BoxObservationError>().having((e) => e.code, 'code', code));
BoxPaddingObservation _read(ChatBubbleBoxSourceBinding binding) {
  binding.validateCurrentConstruction();
  return observeSourceOwnedRenderPadding(
    owner: binding.paddingSource,
    scope: binding.scope,
  );
}

void main() {
  for (final variant in _kVariants) {
    for (final dark in [false, true]) {
      testWidgets('official $variant dark=$dark body source', (tester) async {
        final result = kFlutterPreviewRegistry['chat']!(variant);
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
        final binding = bindChatBubbleBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _kSource,
        )!;
        expect(binding.registryResultElement.widget, same(result));
        expect(binding.fieldUnitElement, same(binding.frameSource));
        expect(binding.scope.foreignBoundaries, hasLength(1));
        expect(binding.readerId, 'current-render-padding-v1');
        final raw = binding.paddingSource.renderObject! as RenderPadding;
        final observation = _read(binding);
        expect(observation.owner, same(binding.paddingSource));
        expect(observation.value, raw.padding.resolve(raw.textDirection));
        expect(observation.quantity, PaddingQuantityKind.frameworkOwnParameter);
        for (final foreign in boxElements(
          binding.scope.foreignBoundaries.single,
        )) {
          expect(
            () => binding.scope.requireOwned(foreign),
            _error('FOREIGN_SUPPLIED_CONTENT'),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('owned theme changes current padding without changing inputs', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(coui.CoreSpace.space12);
    addTearDown(amount.dispose);
    final key = GlobalKey();
    const result = ChatPrimaryExample();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: amount,
          child: KeyedSubtree(key: key, child: result),
          builder: (_, space, child) => coui.Theme(
            data: coui.ThemeData.fromCore(coui.CoreThemePresets.light).copyWith(
              coreComponentTheme: () => coui.CoreComponentTheme(
                chatBubble: coui.CoreChatBubbleTheme(
                  style: coui.CoreChatBubbleStyle(
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
    final binding = bindChatBubbleBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kSource,
    )!;
    final before = _read(binding).value;
    final frameWidget = binding.frameSource.widget;
    amount.value = coui.CoreSpace.space24;
    await tester.pumpAndSettle();
    expect(binding.frameSource.widget, isNot(same(frameWidget)));
    final after = _read(binding);
    expect(after.value, isNot(before));
    final actual = binding.paddingSource.renderObject! as RenderPadding;
    expect(after.value, actual.padding.resolve(actual.textDirection));
    expect(binding.registryResultElement.widget, same(result));
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-mounted new Example invalidates held input witness', (
    tester,
  ) async {
    final key = GlobalKey();
    final inputKey = UniqueKey();
    final before = ChatPrimaryExample(key: inputKey);
    final after = ChatPrimaryExample(key: inputKey);
    final current = ValueNotifier<Widget>(before);
    addTearDown(current.dispose);
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, value, _) => KeyedSubtree(key: key, child: value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final binding = bindChatBubbleBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: before,
      source: _kSource,
    )!;
    current.value = after;
    await tester.pumpAndSettle();
    expect(binding.registryResultElement.mounted, true);
    expect(binding.registryResultElement.widget, same(after));
    expect(
      binding.validateCurrentConstruction,
      _error('STALE_CHAT_BUBBLE_CONSTRUCTION'),
    );
    final fresh = bindChatBubbleBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: after,
      source: _kSource,
    )!;
    expect(fresh.registryResultElement, same(binding.registryResultElement));
    expect(_read(fresh).owner, same(fresh.paddingSource));
    expect(tester.takeException(), isNull);
  });

  for (final missing in [false, true]) {
    testWidgets('changed single source child missing=$missing rejects', (
      tester,
    ) async {
      const result = ChatPrimaryExample();
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pumpAndSettle();
      final binding = bindChatBubbleBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _kSource,
      )!;
      final columns = <Element>[];
      binding.registryResultElement.visitChildren(columns.add);
      final column = columns.single;
      final original = (column.widget as Column).children.single;
      // Deliberate mounted-source mutation, not a legal public Example input.
      tester.binding.buildOwner!.buildScope(column, () {
        column.update(Column(children: missing ? [] : [original, original]));
      });
      await tester.pumpAndSettle();
      expect(
        () => bindChatBubbleBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _kSource,
        ),
        throwsA(isA<BoxObservationError>()),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('actual frame border allocation change is rejected', (
    tester,
  ) async {
    const result = ChatPrimaryExample();
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    final binding = bindChatBubbleBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kSource,
    )!;
    final render = binding.frameSource.renderObject! as RenderDecoratedBox;
    final original = render.decoration;
    render.decoration = BoxDecoration(border: Border.all());
    expect(
      binding.validateCurrentConstruction,
      _error('CHAT_BODY_BORDER_ALLOCATION_CHANGED'),
    );
    render.decoration = original;
    expect(_read(binding).owner, same(binding.paddingSource));
  });

  for (final result in <Widget>[
    const coui.Chat(bubble: coui.ChatBubble(child: coui.Text('caller'))),
    const coui.ChatBubble(child: coui.Text('caller')),
    const _UnknownExample(),
  ]) {
    testWidgets('arbitrary ${result.runtimeType} is not an Example authority', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindChatBubbleBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _kSource,
        ),
        _error('UNREGISTERED_CHAT_BUBBLE_EXAMPLE'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mismatched source tuple and result do not infer a body', (
    tester,
  ) async {
    const result = ChatPrimaryExample();
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final wrong = BoxObservationSourceSpec.fromJson({
      ..._kSource.toJson(),
      'nativeAdapterId': 'unknown-v99',
    });
    expect(
      () => bindChatBubbleBoxSource(
        captureRoot: root,
        registryResult: result,
        source: wrong,
      ),
      _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
    );
    expect(
      () => bindChatBubbleBoxSource(
        captureRoot: root,
        registryResult: ChatPrimaryExample(key: UniqueKey()),
        source: _kSource,
      ),
      _error('MISMATCHED_CHAT_EXAMPLE_RESULT'),
    );
  });
}

class _UnknownExample extends ChatPrimaryExample {
  const _UnknownExample();
}
