import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_scope_extensions.dart';
import 'box_padding_source_bindings.dart';

Widget _app(Widget child) => buildTestApp(
  child,
  theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
);

AdditionalBoxProducerSource _describe(GlobalKey key) =>
    describeAdditionalBoxProducerSource(key.currentContext! as Element)!;

BoxProducerScope _scope(Element producer, AdditionalBoxProducerSource source) =>
    BoxProducerScope(
      producer: producer,
      suppliedSlots: source.supplied.where(
        (input) => !source.sourceOmitted.any(
          (omission) => identical(input, omission.widget),
        ),
      ),
    );

EdgeInsets _ownPrimitivePadding(Element primitive) =>
    observeOutlinedContainerContentPadding(
      primitive: primitive,
      declaringScope: BoxProducerScope(
        producer: primitive,
        suppliedSlots: [?(primitive.widget as coui.OutlinedContainer).child],
      ),
    ).value;

void main() {
  for (final recipe in <({String name, Widget Function(Key key) build})>[
    (
      name: 'MockupCode',
      build: (key) => coui.MockupCode(key: key, lines: const []),
    ),
    (
      name: 'ItemPicker',
      build: (key) => coui.ItemPicker(
        key: key,
        items: const ['One'],
        showSearch: false,
      ),
    ),
    (
      name: 'ObjectInput',
      build: (key) => coui.ObjectInput(
        key: key,
        fields: const [
          coui.CoreObjectInputField(key: 'one', placeholder: 'A'),
        ],
      ),
    ),
  ]) {
    testWidgets('${recipe.name} binds its declared shared frame route', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(_app(recipe.build(key)));
      final source = _describe(key);
      expect(
        source.outlinedFrame!.primitive.widget,
        isA<coui.OutlinedContainer>(),
      );
      expect(source.sourceOmitted, isEmpty);
    });
  }

  testWidgets('direct data-only producer binds its actual build return', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(coui.CodeDiff(key: key, lines: const [])),
    );
    final source = _describe(key);
    expect(source.supplied, isEmpty);
    expect(source.sourceOmitted, isEmpty);
    expect(
      source.outlinedFrame!.primitive.widget,
      isA<coui.OutlinedContainer>(),
    );
    expect(
      BoxProducerScope.contains(
        key.currentContext! as Element,
        source.outlinedFrame!.primitive,
      ),
      isTrue,
    );
  });

  testWidgets('Fieldset includes scalar and list inputs before its own frame', (
    tester,
  ) async {
    final key = GlobalKey();
    const legend = coui.OutlinedContainer(child: Text('Legend'));
    const description = coui.OutlinedContainer(
      child: Text('Description'),
    );
    const child = coui.OutlinedContainer(child: Text('Field'));
    await tester.pumpWidget(
      _app(
        coui.Fieldset(
          key: key,
          legend: legend,
          description: description,
          children: const [child],
        ),
      ),
    );
    final source = _describe(key);
    expect(source.supplied, [same(legend), same(description), same(child)]);
    final scope = _scope(key.currentContext! as Element, source)
      ..requireOwned(source.outlinedFrame!.primitive);
    for (final input in source.supplied) {
      expect(
        () => scope.requireOwned(tester.element(find.byWidget(input))),
        throwsA(isA<BoxObservationError>()),
      );
    }
  });

  testWidgets('foreign padding changes do not change the owned primitive', (
    tester,
  ) async {
    final key = GlobalKey();
    final padding = ValueNotifier<double>(4);
    addTearDown(padding.dispose);
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<double>(
          valueListenable: padding,
          builder: (_, value, _) => coui.MockupBrowser(
            key: key,
            child: coui.OutlinedContainer(
              containerStyle: coui.CoreOutlinedContainerStyle(
                padding: coui.CoreEdgeInsets.all(value),
              ),
              child: const SizedBox(width: 40, height: 20),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeProducer = key.currentContext!;
    final before = _describe(key);
    expect(
      _ownPrimitivePadding(
        tester.element(find.byWidget(before.supplied.single)),
      ),
      const EdgeInsets.all(4),
    );
    final beforeValue = observeOutlinedContainerContentPadding(
      primitive: before.outlinedFrame!.primitive,
      declaringScope: _scope(key.currentContext! as Element, before),
    ).value;
    padding.value = 12;
    await tester.pumpAndSettle();
    expect(key.currentContext, same(beforeProducer));
    final after = _describe(key);
    expect(
      _ownPrimitivePadding(
        tester.element(find.byWidget(after.supplied.single)),
      ),
      const EdgeInsets.all(12),
    );
    final afterValue = observeOutlinedContainerContentPadding(
      primitive: after.outlinedFrame!.primitive,
      declaringScope: _scope(key.currentContext! as Element, after),
    ).value;
    expect(
      after.outlinedFrame!.primitive,
      same(before.outlinedFrame!.primitive),
    );
    expect(afterValue, beforeValue);
    final scope = _scope(key.currentContext! as Element, after);
    expect(
      () => scope.requireOwned(
        tester.element(find.byWidget(after.supplied.single)),
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('CodeSnippet owns its declared first stack slot, not actions', (
    tester,
  ) async {
    final key = GlobalKey();
    var copies = 0;
    const action = coui.OutlinedContainer(child: Text('Action'));
    await tester.pumpWidget(
      _app(
        coui.CodeSnippet(
          key: key,
          code: '',
          mode: 'dart',
          showCopyButton: false,
          actions: const [action],
          onCopy: () => copies++,
        ),
      ),
    );
    final before = copies;
    final source = _describe(key);
    expect(source.supplied, [same(action)]);
    expect(source.outlinedFrame!.primitive.widget, isNot(same(action)));
    expect(copies, before);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('nested Command item Widget inputs stay foreign', (tester) async {
    final key = GlobalKey();
    var selections = 0;
    const icon = coui.OutlinedContainer(child: Text('Icon'));
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: coui.Command(
            key: key,
            onSelect: (_) => selections++,
            groups: const [
              coui.CoreCommandGroup(
                items: [
                  coui.CoreCommandItem(value: 'one', label: 'One', icon: icon),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final source = _describe(key);
    expect(source.supplied, [same(icon)]);
    final scope = _scope(key.currentContext! as Element, source);
    expect(
      () => scope.requireOwned(tester.element(find.byWidget(icon))),
      throwsA(isA<BoxObservationError>()),
    );
    expect(selections, 0);
  });

  testWidgets('an absent supplied action has no guessed omission', (
    tester,
  ) async {
    final key = GlobalKey();
    const absent = coui.OutlinedContainer(child: Text('Absent'));
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: coui.Command(
            key: key,
            emptyAction: absent,
            groups: const [
              coui.CoreCommandGroup(
                items: [
                  coui.CoreCommandItem(value: 'one', label: 'One'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      () => _describe(key),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNRESOLVED_SUPPLIED_SLOT',
        ),
      ),
    );
  });

  testWidgets('unknown duplicate-source subclass cannot select a first frame', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(_app(_DuplicatingSnippet(key: key)));
    expect(
      describeAdditionalBoxProducerSource(key.currentContext! as Element),
      isNull,
    );
  });

  testWidgets('missing actual build return is a source error', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(_app(_MissingDiff(key: key)));
    expect(
      describeAdditionalBoxProducerSource(key.currentContext! as Element),
      isNull,
    );
  });

  testWidgets('subclass foreign Widget input cannot become a data-only frame', (
    tester,
  ) async {
    final key = GlobalKey();
    const foreign = coui.OutlinedContainer(child: Text('Foreign slot'));
    await tester.pumpWidget(_app(_ForeignDiff(key: key, foreign: foreign)));
    expect(find.byWidget(foreign), findsOneWidget);
    expect(
      describeAdditionalBoxProducerSource(key.currentContext! as Element),
      isNull,
    );
  });

  testWidgets(
    'only the declared TrendChart data branch may omit its empty slot',
    (
      tester,
    ) async {
      final key = GlobalKey();
      const empty = coui.OutlinedContainer(child: Text('Empty'));
      const summary = Text('Summary');
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            height: 300,
            child: coui.TrendChart(
              key: key,
              points: [
                coui.CoreTrendPoint(date: DateTime(2026), value: 1),
                coui.CoreTrendPoint(date: DateTime(2026, 2), value: 2),
              ],
              summary: summary,
              empty: empty,
            ),
          ),
        ),
      );
      final source = _describe(key);
      expect(source.supplied, [same(summary), same(empty)]);
      expect(source.sourceOmitted.single.widget, same(empty));
      expect(find.byWidget(empty), findsNothing);
      expect(source.outlinedFrame, isNull);
    },
  );

  testWidgets('known wrappers cannot adopt a supplied OutlinedContainer', (
    tester,
  ) async {
    final key = GlobalKey();
    const foreign = coui.OutlinedContainer(child: Text('Foreign'));
    await tester.pumpWidget(
      _app(coui.AspectRatioBox(key: key, ratio: 2, child: foreign)),
    );
    final source = _describe(key);
    expect(source.supplied, [same(foreign)]);
    expect(source.outlinedFrame, isNull);
    expect(
      () => _scope(key.currentContext! as Element, source).requireOwned(
        tester.element(find.byWidget(foreign)),
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('unknown Widget builder is not called again by observation', (
    tester,
  ) async {
    final key = GlobalKey();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        Builder(
          key: key,
          builder: (_) {
            calls++;
            return const SizedBox();
          },
        ),
      ),
    );
    final before = calls;
    expect(
      describeAdditionalBoxProducerSource(key.currentContext! as Element),
      isNull,
    );
    expect(calls, before);
  });
}

class _MissingDiff extends coui.CodeDiff {
  const _MissingDiff({super.key}) : super(lines: const []);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _DuplicatingSnippet extends coui.CodeSnippet {
  const _DuplicatingSnippet({super.key})
    : super(code: '', mode: 'dart', showCopyButton: false);

  @override
  State<coui.CodeSnippet> createState() => _SnippetState();
}

class _ForeignDiff extends coui.CodeDiff {
  const _ForeignDiff({required this.foreign, super.key})
    : super(lines: const []);

  final Widget foreign;

  @override
  Widget build(BuildContext context) => foreign;
}

class _SnippetState extends State<coui.CodeSnippet> {
  @override
  Widget build(BuildContext context) {
    const frame = coui.OutlinedContainer(child: Text('Generated'));
    return Semantics(
      child: const coui.Stacks(children: [frame, frame]),
    );
  }
}
