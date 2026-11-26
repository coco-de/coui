import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/internal/preview/flutter_stage.dart'
    show FlutterDocsSizeSpec;
import 'package:docs_core/previews/examples/flutter/breadcrumb/breadcrumb_default_example.dart';
import 'package:docs_core/previews/examples/flutter/collapsible/collapsible_default_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_chain_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_default_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_group_example.dart';
import 'package:docs_core/previews/examples/flutter/divider/divider_with_child_example.dart';
import 'package:docs_core/previews/examples/flutter/form_field/form_field_default_example.dart';
import 'package:docs_core/previews/examples/flutter/form_label/form_label_default_example.dart';
import 'package:docs_core/previews/examples/flutter/indexed_switcher/indexed_switcher_default_example.dart';
import 'package:docs_core/previews/examples/flutter/listing/listing_default_example.dart';
import 'package:docs_core/previews/examples/flutter/option_list/option_list_default_example.dart';
import 'package:docs_core/previews/examples/flutter/resizable/resizable_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_container/responsive_container_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_grid/responsive_grid_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_grid/responsive_grid_span_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_row_column/responsive_row_column_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_row_column/responsive_row_column_desktop_example.dart';
import 'package:docs_core/previews/examples/flutter/stack_layout/stack_layout_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swap/swap_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swap/swap_rotate_example.dart';
import 'package:docs_core/previews/examples/flutter/toggle_group/toggle_group_default_example.dart';
import 'package:docs_core/previews/examples/flutter/toggle_group/toggle_group_vertical_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/size_spec.dart' show docsSizeSpecFor;
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        Column,
        Container,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        RenderBox,
        SizedBox,
        StateSetter,
        StatefulBuilder,
        StatelessWidget,
        Text,
        TextEditingController,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_additive.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';
import 'chrome_node_probe.dart';
import 'parity_matrix_entry.dart';

// These are explicit test caller inputs, not component chrome defaults.
// Keep each input paired with its observed-value assertion
// when one is measured.
const double _kBubbleForeignCallerInset17 = 17;
const double _kSubclassForeignCallerInset9 = 9;
const double _kOwnedCallerSurfaceInset16 = 16;
const double _kChangedOwnedCallerSurfaceInset24 = 24;
const double _kForeignCallerInset4 = 4;
const double _kChangedForeignCallerInset12 = 12;

Widget _app(Widget child) => buildTestApp(
  child,
  theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
);

BoxProducerScope _surfaceScope(Element element) => BoxProducerScope(
  producer: element,
  suppliedSlots: [?(element.widget as coui.OutlinedContainer).child],
);

coui.OutlinedContainer _surface({
  required GlobalKey key,
  required double padding,
  Widget child = const SizedBox(width: 40, height: 20),
}) => coui.OutlinedContainer(
  key: key,
  containerStyle: coui.CoreOutlinedContainerStyle(
    padding: coui.CoreEdgeInsets.all(padding),
  ),
  child: child,
);

class _CallerChildProducer extends StatelessWidget {
  const _CallerChildProducer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _UnauditedOutlinedSource extends coui.OutlinedContainer {
  const _UnauditedOutlinedSource({required this.additionalSlot, super.key});

  final Widget additionalSlot;

  @override
  Widget build(BuildContext context) => additionalSlot;
}

class _UnauditedChatBubble extends coui.ChatBubble {
  const _UnauditedChatBubble({required this.additionalSlot, super.key})
    : super(child: const SizedBox.shrink());

  final Widget additionalSlot;

  @override
  Widget build(BuildContext context) => additionalSlot;
}

class _UnauditedLoading extends coui.Loading {
  const _UnauditedLoading({required this.additionalSlot, super.key});

  final Widget additionalSlot;

  @override
  Widget build(BuildContext context) => additionalSlot;
}

class _UnauditedSkeleton extends coui.Skeleton {
  const _UnauditedSkeleton({required this.additionalSlot, super.key});

  final Widget additionalSlot;
}

class _UnauditedTag extends coui.Tag {
  const _UnauditedTag({required this.additionalSlot, super.key})
    : super(child: const SizedBox.shrink());

  final Widget additionalSlot;

  @override
  Widget build(BuildContext context) => additionalSlot;
}

class _UnauditedMenuItem extends coui.MenuItem {
  const _UnauditedMenuItem({super.key})
    : super(label: const Text('Subclass label'));
}

class _UnauditedCarouselBanner extends coui.CarouselBanner {
  const _UnauditedCarouselBanner({super.key});
}

class _UnauditedPanelHeader extends coui.PanelHeader {
  const _UnauditedPanelHeader({super.key})
    : super(title: const Text('Subclass title'));
}

class _UnauditedCalendar extends coui.Calendar {
  const _UnauditedCalendar({super.key});
}

class _UnauditedDefinitionList extends coui.DefinitionList {
  const _UnauditedDefinitionList({super.key})
    : super(items: const <coui.CoreDefinitionEntry<Widget>>[]);
}

class _UnauditedDefinitionEntry extends coui.CoreDefinitionEntry<Widget> {
  const _UnauditedDefinitionEntry(Widget child)
    : super.rich(term: 'Subclass term', description: child);
}

// Bounds are explicit caller fixture inputs, not owner-selection criteria.
const double _kLayoutSeedWidth = 320;
const double _kLayoutSeedHeight = 240;
const _kLayoutSeedPump = Duration(milliseconds: 400);

typedef _LayoutSeedCase = ({
  String component,
  Type producerType,
  int slots,
  Widget Function(GlobalKey, List<Widget>) create,
});

Widget _layoutSeedFlex(GlobalKey key, List<Widget> slots) =>
    coui.ResponsiveRowColumn(key: key, children: slots);
Widget _layoutSeedGrid(GlobalKey key, List<Widget> slots) =>
    coui.ResponsiveGrid(key: key, responsive: false, children: slots);
Widget _layoutSeedContainer(GlobalKey key, List<Widget> slots) =>
    coui.ResponsiveContainer(key: key, child: slots.single);
Widget _layoutSeedStack(GlobalKey key, List<Widget> slots) =>
    coui.Stacks(key: key, children: slots);
Widget _layoutSeedIndexed(GlobalKey key, List<Widget> slots) =>
    coui.IndexedSwitcher(key: key, index: 1, children: slots);
Widget _layoutSeedSwap(GlobalKey key, List<Widget> slots) => coui.Swap(
  key: key,
  onToggle: (_) {},
  offContent: slots[0],
  onContent: slots[1],
);
Widget _layoutSeedDivider(GlobalKey key, List<Widget> slots) =>
    coui.Divider(key: key, child: slots.single);

const _kLayoutSeedCases = <_LayoutSeedCase>[
  (
    component: 'responsive-row-column',
    producerType: coui.ResponsiveRowColumn,
    slots: 3,
    create: _layoutSeedFlex,
  ),
  (
    component: 'responsive-grid',
    producerType: coui.ResponsiveGrid,
    slots: 3,
    create: _layoutSeedGrid,
  ),
  (
    component: 'responsive-container',
    producerType: coui.ResponsiveContainer,
    slots: 1,
    create: _layoutSeedContainer,
  ),
  (
    component: 'stack-layout',
    producerType: coui.Stacks,
    slots: 3,
    create: _layoutSeedStack,
  ),
  (
    component: 'indexed-switcher',
    producerType: coui.IndexedSwitcher,
    slots: 3,
    create: _layoutSeedIndexed,
  ),
  (
    component: 'swap',
    producerType: coui.Swap,
    slots: 2,
    create: _layoutSeedSwap,
  ),
  (
    component: 'divider',
    producerType: coui.Divider,
    slots: 1,
    create: _layoutSeedDivider,
  ),
];

Element _layoutSeedOnly(Element owner) {
  final children = <Element>[];
  owner.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact generated fixture child');
}

Element _layoutSeedChild(Element owner, Widget child) => requireOneBoxOwner(
  boxElements(owner).where((e) => identical(e.widget, child)),
  'the source-declared child Widget identity',
);
Element _layoutSeedExampleProducer(Element example, String component) {
  var producer = _layoutSeedOnly(example);
  if (component == 'indexed-switcher') {
    expect(producer.widget.runtimeType, Column);
    final sizing = _layoutSeedChild(
      producer,
      (producer.widget as Column).children[0],
    );
    expect(sizing.widget.runtimeType, SizedBox);
    producer = _layoutSeedChild(sizing, (sizing.widget as SizedBox).child!);
  } else if (component == 'stack-layout') {
    expect(producer.widget.runtimeType, SizedBox);
    producer = _layoutSeedChild(producer, (producer.widget as SizedBox).child!);
  }
  return producer;
}

List<Widget> _layoutSeedRawSlots(Widget widget) {
  if (widget is coui.ResponsiveRowColumn) {
    return widget.children;
  }
  if (widget is coui.ResponsiveGrid) {
    return widget.children;
  }
  if (widget is coui.ResponsiveContainer) {
    return [widget.child];
  }
  if (widget is coui.Stacks) {
    return widget.children;
  }
  if (widget is coui.IndexedSwitcher) {
    return widget.children;
  }
  if (widget is coui.Swap) {
    return [widget.offContent, widget.onContent];
  }
  if (widget is coui.Divider) {
    return [widget.child!];
  }
  throw StateError('No closed source fixture describes this input');
}

class _UnauditedLayoutFlex extends coui.ResponsiveRowColumn {
  const _UnauditedLayoutFlex({super.key}) : super(children: const [SizedBox()]);
}

class _UnauditedLayoutGrid extends coui.ResponsiveGrid {
  const _UnauditedLayoutGrid({super.key})
    : super(responsive: false, children: const [SizedBox()]);
}

class _UnauditedLayoutContainer extends coui.ResponsiveContainer {
  const _UnauditedLayoutContainer({super.key}) : super(child: const SizedBox());
}

class _UnauditedLayoutStack extends coui.Stacks {
  const _UnauditedLayoutStack({super.key})
    : super(children: const [SizedBox()]);
}

class _UnauditedLayoutIndexed extends coui.IndexedSwitcher {
  const _UnauditedLayoutIndexed({super.key})
    : super(children: const [SizedBox()]);
}

class _UnauditedLayoutSwap extends coui.Swap {
  const _UnauditedLayoutSwap({super.key})
    : super(offContent: const Text('off'), onContent: const Text('on'));
}

class _UnauditedLayoutDivider extends coui.Divider {
  const _UnauditedLayoutDivider({super.key})
    : super(child: const Text('label'));
}

// Bounds and insets below are explicit test caller inputs, never selectors.
const double _kParameterSeedWidth = 800;
const double _kParameterSeedHeight = 600;
const Duration _kParameterSeedPump = Duration(milliseconds: 400);

typedef _ParameterSeedCase = ({
  String name,
  Type producerType,
  int slots,
  Widget Function(GlobalKey, List<Widget>) create,
});

Widget _parameterToggle(GlobalKey key, List<Widget> slots) =>
    coui.ToggleGroup<String>(
      key: key,
      value: 'first',
      onChanged: (_) {},
      items: [
        coui.CoreToggleGroupItem<String, Widget>(
          value: 'first',
          label: 'First',
          icon: slots[0],
          showLabel: false,
        ),
        coui.CoreToggleGroupItem<String, Widget>(
          value: 'second',
          label: 'Second',
          icon: slots[1],
        ),
      ],
      trailing: slots[2],
    );
Widget _parameterField(GlobalKey key, List<Widget> slots) => coui.FormField(
  key: key,
  labelWidget: slots[0],
  labelAction: slots[1],
  child: slots[2],
);
Widget _parameterLabel(GlobalKey key, List<Widget> slots) => coui.FormLabel(
  key: key,
  label: slots[0],
  isRequired: true,
  requiredIndicator: slots[1],
);
Widget _parameterListing(GlobalKey key, List<Widget> slots) =>
    coui.Listing(key: key, children: slots);
Widget _parameterOptions(GlobalKey key, List<Widget> slots) =>
    coui.OptionList(key: key, children: slots);
Widget _parameterDisclosure(GlobalKey key, List<Widget> slots) =>
    coui.Disclosure(
      key: key,
      trigger: slots[0],
      content: slots[1],
      open: true,
    );
Widget _parameterDisclosureGroup(GlobalKey key, List<Widget> slots) =>
    coui.DisclosureGroup(key: key, items: slots);
Widget _parameterCollapsible(GlobalKey key, List<Widget> slots) =>
    coui.Collapsible(
      key: key,
      trigger: slots[0],
      content: slots[1],
      expanded: true,
    );
Widget _parameterResizable(GlobalKey key, List<Widget> slots) => coui.Resizable(
  key: key,
  panes: [
    for (final slot in slots) coui.CoreResizablePaneData<Widget>(content: slot),
  ],
);
Widget _parameterBreadcrumb(GlobalKey key, List<Widget> slots) =>
    coui.Breadcrumb(
      key: key,
      items: const [coui.CoreBreadcrumbItem(label: 'Home')],
    );

const _kParameterSeedCases = <_ParameterSeedCase>[
  (
    name: 'toggle-group',
    producerType: coui.ToggleGroup<String>,
    slots: 3,
    create: _parameterToggle,
  ),
  (
    name: 'form-field',
    producerType: coui.FormField,
    slots: 3,
    create: _parameterField,
  ),
  (
    name: 'form-label',
    producerType: coui.FormLabel,
    slots: 2,
    create: _parameterLabel,
  ),
  (
    name: 'listing',
    producerType: coui.Listing,
    slots: 2,
    create: _parameterListing,
  ),
  (
    name: 'option-list',
    producerType: coui.OptionList,
    slots: 2,
    create: _parameterOptions,
  ),
  (
    name: 'disclosure',
    producerType: coui.Disclosure,
    slots: 2,
    create: _parameterDisclosure,
  ),
  (
    name: 'disclosure-group',
    producerType: coui.DisclosureGroup,
    slots: 2,
    create: _parameterDisclosureGroup,
  ),
  (
    name: 'collapsible',
    producerType: coui.Collapsible,
    slots: 2,
    create: _parameterCollapsible,
  ),
  (
    name: 'resizable',
    producerType: coui.Resizable,
    slots: 2,
    create: _parameterResizable,
  ),
  (
    name: 'breadcrumb',
    producerType: coui.Breadcrumb,
    slots: 0,
    create: _parameterBreadcrumb,
  ),
];

List<Widget> _parameterSeedRaw(Widget widget) {
  if (widget is coui.Breadcrumb) return const [];
  if (widget is coui.ToggleGroup<String>) {
    return [for (final item in widget.items) ?item.icon, ?widget.trailing];
  }
  if (widget is coui.FormField) {
    return [?widget.labelWidget, ?widget.labelAction, ?widget.child];
  }
  if (widget is coui.FormLabel) {
    return [?widget.label, ?widget.requiredIndicator];
  }
  if (widget is coui.Listing) return widget.children;
  if (widget is coui.OptionList) return widget.children;
  if (widget is coui.Disclosure) return [?widget.trigger, widget.content];
  if (widget is coui.DisclosureGroup) return widget.items;
  if (widget is coui.Collapsible) return [widget.trigger, widget.content];
  if (widget is coui.Resizable) {
    return [for (final pane in widget.panes) pane.content];
  }
  throw StateError('No exact parameter seed fixture');
}

Element _parameterSeedExampleProducer(Element example, String component) {
  var producer = _layoutSeedOnly(example);
  if (component == 'form-field' || component == 'resizable') {
    expect(producer.widget.runtimeType, SizedBox);
    producer = _layoutSeedChild(producer, (producer.widget as SizedBox).child!);
  }
  return producer;
}

DeclaredBoxProducer _parameterSeedBind(Element element) =>
    DeclaredBoxProducer.bind(
      producer: element,
      sourceContract: 'renderer-frame-padding-v1',
    );
Matcher get _parameterSeedError => throwsA(isA<BoxObservationError>());

class _UnknownParameterToggle extends coui.ToggleGroup<String> {
  const _UnknownParameterToggle()
    : super(
        value: null,
        onChanged: null,
        items: const [
          coui.CoreToggleGroupItem<String, Widget>(
            value: 'first',
            label: 'First',
          ),
        ],
      );
}

class _UnknownParameterField extends coui.FormField {
  const _UnknownParameterField() : super(child: const SizedBox());
}

class _UnknownParameterLabel extends coui.FormLabel {
  const _UnknownParameterLabel() : super(label: const Text('Label'));
}

class _UnknownParameterListing extends coui.Listing {
  const _UnknownParameterListing() : super(children: const [SizedBox()]);
}

class _UnknownParameterOptions extends coui.OptionList {
  const _UnknownParameterOptions() : super(children: const [SizedBox()]);
}

class _UnknownParameterDisclosure extends coui.Disclosure {
  const _UnknownParameterDisclosure()
    : super(
        title: 'Title',
        open: true,
        content: const SizedBox(),
      );
}

class _UnknownParameterDisclosureGroup extends coui.DisclosureGroup {
  const _UnknownParameterDisclosureGroup() : super(items: const [SizedBox()]);
}

class _UnknownParameterCollapsible extends coui.Collapsible {
  const _UnknownParameterCollapsible()
    : super(
        trigger: const Text('Trigger'),
        content: const Text('Content'),
      );
}

class _UnknownParameterResizable extends coui.Resizable {
  const _UnknownParameterResizable()
    : super(
        panes: const [
          coui.CoreResizablePaneData<Widget>(content: SizedBox()),
        ],
      );
}

class _UnknownParameterBreadcrumb extends coui.Breadcrumb {
  const _UnknownParameterBreadcrumb()
    : super(
        items: const [
          coui.CoreBreadcrumbItem(label: 'Home'),
        ],
      );
}

class _UnknownToggleParameterRecord
    extends coui.CoreToggleGroupItem<String, Widget> {
  const _UnknownToggleParameterRecord(Widget child)
    : super(value: 'first', label: 'First', icon: child);
}

class _UnknownResizableParameterRecord
    extends coui.CoreResizablePaneData<Widget> {
  const _UnknownResizableParameterRecord(Widget child) : super(content: child);
}

class _UnknownBreadcrumbParameterRecord extends coui.CoreBreadcrumbItem {
  const _UnknownBreadcrumbParameterRecord() : super(label: 'Home');
}

void main() {
  // These tests establish only bind-time public slot declarations. A held
  // frame/absence witness must separately reject stale original inputs.
  const parameterRecipes =
      <
        ({
          String component,
          String variant,
          Type example,
          String declaration,
        })
      >[
        (
          component: 'toggle-group',
          variant: 'default',
          example: ToggleGroupDefaultExample,
          declaration: 'toggle-group',
        ),
        (
          component: 'toggle-group',
          variant: 'vertical',
          example: ToggleGroupVerticalExample,
          declaration: 'toggle-group',
        ),
        (
          component: 'form-field',
          variant: 'default',
          example: FormFieldDefaultExample,
          declaration: 'form-field',
        ),
        (
          component: 'form-label',
          variant: 'default',
          example: FormLabelDefaultExample,
          declaration: 'form-label',
        ),
        (
          component: 'listing',
          variant: 'default',
          example: ListingDefaultExample,
          declaration: 'listing',
        ),
        (
          component: 'option-list',
          variant: 'default',
          example: OptionListDefaultExample,
          declaration: 'option-list',
        ),
        (
          component: 'disclosure',
          variant: 'default',
          example: DisclosureDefaultExample,
          declaration: 'disclosure',
        ),
        (
          component: 'disclosure',
          variant: 'chain',
          example: DisclosureChainExample,
          declaration: 'disclosure',
        ),
        (
          component: 'disclosure',
          variant: 'group',
          example: DisclosureGroupExample,
          declaration: 'disclosure-group',
        ),
        (
          component: 'collapsible',
          variant: 'default',
          example: CollapsibleDefaultExample,
          declaration: 'collapsible',
        ),
        (
          component: 'resizable',
          variant: 'default',
          example: ResizableDefaultExample,
          declaration: 'resizable',
        ),
        (
          component: 'breadcrumb',
          variant: 'default',
          example: BreadcrumbDefaultExample,
          declaration: 'breadcrumb',
        ),
      ];
  for (final recipe in parameterRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} parameter slots dark=$dark',
        (tester) async {
          final actual = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          expect(actual.runtimeType, recipe.example);
          final capture = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              SizedBox(
                width: _kParameterSeedWidth,
                height: _kParameterSeedHeight,
                child: KeyedSubtree(key: capture, child: actual),
              ),
              theme: coui.ThemeData.fromCore(
                dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pump(_kParameterSeedPump);
          final example = _layoutSeedChild(
            capture.currentContext! as Element,
            actual,
          );
          final producer = _parameterSeedExampleProducer(
            example,
            recipe.component,
          );
          final fixture = _kParameterSeedCases.singleWhere(
            (f) => f.name == recipe.declaration,
          );
          expect(producer.widget.runtimeType, fixture.producerType);
          final raw = _parameterSeedRaw(producer.widget);
          final declaration = _parameterSeedBind(producer);
          expect(declaration.scope.producer, same(producer));
          expect(declaration.scope.suppliedSlots, orderedEquals(raw));
          expect(declaration.unrenderedSuppliedSlots, isEmpty);
          expect(declaration.scope.foreignBoundaries, hasLength(raw.length));
          expect(declaration.additionalOutlinedFrame, isNull);
          expect(declaration.isAdditionalSource, false);
          for (final slot in raw) {
            final actualSlot = _layoutSeedChild(producer, slot);
            expect(
              () => declaration.scope.requireOwned(actualSlot),
              _parameterSeedError,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final fixture in _kParameterSeedCases) {
    testWidgets('${fixture.name} current raw foreign bag and subtree', (
      tester,
    ) async {
      final changed = ValueNotifier<double>(_kForeignCallerInset4);
      addTearDown(changed.dispose);
      final keys = List.generate(fixture.slots, (_) => GlobalKey());
      final slots = <Widget>[
        for (final key in keys)
          ValueListenableBuilder<double>(
            key: key,
            valueListenable: changed,
            builder: (_, value, child) => Padding(
              padding: EdgeInsets.all(value),
              child: const SizedBox(width: 16, height: 12),
            ),
          ),
      ];
      final key = GlobalKey();
      final actual = fixture.create(key, slots);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: actual,
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      final producer = key.currentContext! as Element;
      final declaration = _parameterSeedBind(producer);
      expect(declaration.scope.suppliedSlots, orderedEquals(slots));
      expect(declaration.unrenderedSuppliedSlots, isEmpty);
      final foreign = [for (final key in keys) key.currentContext! as Element];
      changed.value = _kChangedForeignCallerInset12;
      await tester.pump(_kParameterSeedPump);
      for (var i = 0; i < foreign.length; i++) {
        expect(keys[i].currentContext, same(foreign[i]));
        final padding = _layoutSeedOnly(foreign[i]);
        expect(padding.widget.runtimeType, Padding);
        expect(
          (padding.widget as Padding).padding,
          const EdgeInsets.all(_kChangedForeignCallerInset12),
        );
        expect(
          () => declaration.scope.requireOwned(foreign[i]),
          _parameterSeedError,
        );
        expect(
          () => declaration.scope.requireOwned(padding),
          _parameterSeedError,
        );
      }
      final fresh = _parameterSeedBind(producer);
      expect(fresh.scope.suppliedSlots, orderedEquals(slots));
      expect(fresh.additionalOutlinedFrame, isNull);
      expect(tester.takeException(), isNull);
    });
    testWidgets('${fixture.name} same Element new input requires fresh bind', (
      tester,
    ) async {
      final key = GlobalKey();
      final firstSlots = <Widget>[
        for (var i = 0; i < fixture.slots; i++)
          SizedBox(key: GlobalKey(), width: 16, height: 12),
      ];
      final nextSlots = <Widget>[
        for (var i = 0; i < fixture.slots; i++)
          SizedBox(key: GlobalKey(), width: 24, height: 12),
      ];
      final first = fixture.create(key, firstSlots);
      final current = ValueNotifier<Widget>(first);
      addTearDown(current.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, widget, child) => widget,
            ),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      final element = key.currentContext! as Element;
      final old = _parameterSeedBind(element);
      expect(old.scope.suppliedSlots, orderedEquals(firstSlots));
      final next = fixture.create(key, nextSlots);
      expect(next, isNot(same(first)));
      current.value = next;
      await tester.pump(_kParameterSeedPump);
      expect(key.currentContext, same(element));
      expect(element.widget, same(next));
      final fresh = _parameterSeedBind(element);
      expect(fresh.scope.suppliedSlots, orderedEquals(nextSlots));
      expect(old.scope.suppliedSlots, orderedEquals(firstSlots));
      expect(fresh.additionalOutlinedFrame, isNull);
      expect(tester.takeException(), isNull);
    });
  }
  for (final fixture in _kParameterSeedCases.where((f) => f.slots > 1)) {
    testWidgets('${fixture.name} duplicate raw Widget identities reject', (
      tester,
    ) async {
      const caller = SizedBox(width: 16, height: 12);
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: fixture.create(key, List.filled(fixture.slots, caller)),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      expect(
        () => _parameterSeedBind(key.currentContext! as Element),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.code,
            'code',
            'DUPLICATE_SUPPLIED_SLOT_SOURCE',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final (caseIndex, make) in <Widget Function(GlobalKey, Widget)>[
    (key, caller) => coui.FormLabel(
      key: key,
      label: caller,
      requiredIndicator: caller,
    ),
    (key, caller) => coui.FormField(
      key: key,
      labelAction: caller,
      child: caller,
    ),
    (key, caller) => coui.Disclosure(
      key: key,
      trigger: caller,
      content: caller,
    ),
  ].indexed) {
    testWidgets('raw duplicates before omission case=$caseIndex', (
      tester,
    ) async {
      const caller = SizedBox(width: 16, height: 12);
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: make(key, caller),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      expect(
        () => _parameterSeedBind(key.currentContext! as Element),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.code,
            'code',
            'DUPLICATE_SUPPLIED_SLOT_SOURCE',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final (caseIndex, make) in <Widget Function(GlobalKey, Widget)>[
    (key, caller) => coui.FormLabel(
      key: key,
      label: const Text('Label'),
      requiredIndicator: caller,
    ),
    (key, caller) => coui.FormField(
      key: key,
      labelAction: caller,
      child: const SizedBox(),
    ),
  ].indexed) {
    testWidgets('immutable public omission case=$caseIndex retains raw input', (
      tester,
    ) async {
      final caller = SizedBox(key: GlobalKey(), width: 16, height: 12);
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: make(key, caller),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      expect(find.byWidget(caller), findsNothing);
      final declaration = _parameterSeedBind(key.currentContext! as Element);
      expect(declaration.unrenderedSuppliedSlots, [same(caller)]);
      expect(
        declaration.suppliedSlotDerivations.single['kind'],
        'source-declared-unrendered-branch',
      );
      expect(declaration.additionalOutlinedFrame, isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Disclosure current closed content is not guessed from open', (
    tester,
  ) async {
    final key = GlobalKey();
    final trigger = SizedBox(key: GlobalKey(), width: 16, height: 12);
    final content = SizedBox(key: GlobalKey(), width: 16, height: 12);
    await tester.pumpWidget(
      _app(
        coui.Disclosure(
          key: key,
          trigger: trigger,
          content: content,
        ),
      ),
    );
    await tester.pump(_kParameterSeedPump);
    expect(find.byWidget(trigger), findsOneWidget);
    expect(find.byWidget(content), findsNothing);
    expect(
      () => _parameterSeedBind(key.currentContext! as Element),
      throwsA(
        isA<BoxObservationError>().having(
          (e) => e.code,
          'code',
          'UNRESOLVED_SUPPLIED_SLOT_SOURCE',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  for (final actual in <Widget>[
    _UnknownParameterToggle(),
    const _UnknownParameterField(),
    const _UnknownParameterLabel(),
    const _UnknownParameterListing(),
    const _UnknownParameterOptions(),
    const _UnknownParameterDisclosure(),
    const _UnknownParameterDisclosureGroup(),
    const _UnknownParameterCollapsible(),
    const _UnknownParameterResizable(),
    const _UnknownParameterBreadcrumb(),
  ]) {
    testWidgets('${actual.runtimeType} unknown concrete producer rejects', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: KeyedSubtree(key: key, child: actual),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      final producer = _layoutSeedChild(key.currentContext! as Element, actual);
      expect(() => _parameterSeedBind(producer), _parameterSeedError);
      expect(tester.takeException(), isNull);
    });
  }
  for (final (caseIndex, make) in <Widget Function(GlobalKey)>[
    (key) => coui.ToggleGroup<String>(
      key: key,
      value: null,
      onChanged: null,
      items: const [_UnknownToggleParameterRecord(SizedBox())],
    ),
    (key) => coui.ToggleGroup<String>(
      key: key,
      value: null,
      onChanged: null,
      items: const <coui.CoreToggleGroupItem<String, Widget>>[
        coui.CoreToggleGroupItem<String, SizedBox>(
          value: 'first',
          label: 'First',
          icon: SizedBox(),
        ),
      ],
    ),
    (key) => coui.Resizable(
      key: key,
      panes: const [
        _UnknownResizableParameterRecord(SizedBox()),
      ],
    ),
    (key) => coui.Resizable(
      key: key,
      panes: const <coui.CoreResizablePaneData<Widget>>[
        coui.CoreResizablePaneData<SizedBox>(content: SizedBox()),
      ],
    ),
    (key) => coui.Breadcrumb(
      key: key,
      items: const [_UnknownBreadcrumbParameterRecord()],
    ),
    (key) => coui.ToggleGroup<int>(
      key: key,
      value: null,
      onChanged: null,
      items: const [
        coui.CoreToggleGroupItem<int, Widget>(
          value: 1,
          label: 'First',
        ),
      ],
    ),
  ].indexed) {
    testWidgets('unsupported producer or record shape case=$caseIndex', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kParameterSeedWidth,
            height: _kParameterSeedHeight,
            child: make(key),
          ),
        ),
      );
      await tester.pump(_kParameterSeedPump);
      expect(
        () => _parameterSeedBind(key.currentContext! as Element),
        _parameterSeedError,
      );
      expect(tester.takeException(), isNull);
    });
  }

  const layoutRecipes = <({String component, String variant, Type example})>[
    (
      component: 'responsive-row-column',
      variant: 'default',
      example: ResponsiveRowColumnDefaultExample,
    ),
    (
      component: 'responsive-row-column',
      variant: 'desktop',
      example: ResponsiveRowColumnDesktopExample,
    ),
    (
      component: 'responsive-container',
      variant: 'default',
      example: ResponsiveContainerDefaultExample,
    ),
    (
      component: 'responsive-grid',
      variant: 'default',
      example: ResponsiveGridDefaultExample,
    ),
    (
      component: 'responsive-grid',
      variant: 'span',
      example: ResponsiveGridSpanExample,
    ),
    (
      component: 'stack-layout',
      variant: 'default',
      example: StackLayoutDefaultExample,
    ),
    (
      component: 'indexed-switcher',
      variant: 'default',
      example: IndexedSwitcherDefaultExample,
    ),
    (component: 'swap', variant: 'default', example: SwapDefaultExample),
    (component: 'swap', variant: 'rotate', example: SwapRotateExample),
    (
      component: 'divider',
      variant: 'with-child',
      example: DividerWithChildExample,
    ),
  ];
  for (final recipe in layoutRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark slot refs',
        (
          tester,
        ) async {
          final actual = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          expect(actual.runtimeType, recipe.example);
          final capture = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              KeyedSubtree(key: capture, child: actual),
              theme: coui.ThemeData.fromCore(
                dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pump(_kLayoutSeedPump);
          final example = _layoutSeedChild(
            capture.currentContext! as Element,
            actual,
          );
          final producer = _layoutSeedExampleProducer(
            example,
            recipe.component,
          );
          final contract = _kLayoutSeedCases.singleWhere(
            (c) => c.component == recipe.component,
          );
          expect(producer.widget.runtimeType, contract.producerType);
          final raw = _layoutSeedRawSlots(producer.widget);
          final declaration = DeclaredBoxProducer.bind(
            producer: producer,
            sourceContract: 'renderer-frame-padding-v1',
          );
          expect(declaration.scope.suppliedSlots, orderedEquals(raw));
          expect(declaration.unrenderedSuppliedSlots, isEmpty);
          expect(declaration.scope.foreignBoundaries, hasLength(raw.length));
          expect(declaration.additionalOutlinedFrame, isNull);
          for (final slot in raw) {
            final element = _layoutSeedChild(producer, slot);
            expect(
              () => declaration.scope.requireOwned(element),
              throwsA(isA<BoxObservationError>()),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final fixture in _kLayoutSeedCases) {
    testWidgets('${fixture.component} whole foreign slots retain identity', (
      tester,
    ) async {
      final inset = ValueNotifier<double>(_kForeignCallerInset4);
      final keys = List.generate(fixture.slots, (_) => GlobalKey());
      final slots = <Widget>[
        for (var i = 0; i < keys.length; i++)
          ValueListenableBuilder<double>(
            key: keys[i],
            valueListenable: inset,
            builder: (context, value, child) => Padding(
              padding: EdgeInsets.all(value),
              child: const SizedBox(width: 12, height: 8),
            ),
          ),
      ];
      final producerKey = GlobalKey();
      final actual = fixture.create(producerKey, slots);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kLayoutSeedWidth,
            height: _kLayoutSeedHeight,
            child: actual,
          ),
        ),
      );
      await tester.pump(_kLayoutSeedPump);
      final producer = producerKey.currentContext! as Element;
      final declaration = DeclaredBoxProducer.bind(
        producer: producer,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(declaration.scope.suppliedSlots, orderedEquals(slots));
      expect(declaration.unrenderedSuppliedSlots, isEmpty);
      final heldElements = [
        for (final key in keys) key.currentContext! as Element,
      ];
      inset.value = _kChangedForeignCallerInset12;
      await tester.pump(_kLayoutSeedPump);
      for (var i = 0; i < keys.length; i++) {
        expect(keys[i].currentContext, same(heldElements[i]));
        final padding = _layoutSeedOnly(heldElements[i]);
        expect(padding.widget.runtimeType, Padding);
        expect(
          (padding.widget as Padding).padding,
          const EdgeInsets.all(_kChangedForeignCallerInset12),
        );
        expect(
          () => declaration.scope.requireOwned(heldElements[i]),
          throwsA(isA<BoxObservationError>()),
        );
        expect(
          () => declaration.scope.requireOwned(padding),
          throwsA(isA<BoxObservationError>()),
        );
      }
      final fresh = DeclaredBoxProducer.bind(
        producer: producer,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(fresh.scope.suppliedSlots, orderedEquals(slots));
      expect(fresh.scope.foreignBoundaries, orderedEquals(heldElements));
      expect(tester.takeException(), isNull);
      inset.dispose();
    });
  }
  for (final fixture in _kLayoutSeedCases.where((f) => f.slots > 1)) {
    testWidgets('${fixture.component} duplicate raw input rejects', (
      tester,
    ) async {
      const shared = SizedBox(width: 12, height: 8);
      final key = GlobalKey();
      final actual = fixture.create(key, List.filled(fixture.slots, shared));
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kLayoutSeedWidth,
            height: _kLayoutSeedHeight,
            child: actual,
          ),
        ),
      );
      await tester.pump(_kLayoutSeedPump);
      expect(
        () => DeclaredBoxProducer.bind(
          producer: key.currentContext! as Element,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.code,
            'code',
            'DUPLICATE_SUPPLIED_SLOT_SOURCE',
          ),
        ),
      );
    });
  }
  testWidgets('Swap raw duplicate rejects before unsupported flip omission', (
    tester,
  ) async {
    const shared = Text('caller');
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Swap(
          key: key,
          animation: .flip,
          onToggle: (_) {},
          offContent: shared,
          onContent: shared,
        ),
      ),
    );
    await tester.pump(_kLayoutSeedPump);
    expect(
      () => DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (e) => e.code,
          'code',
          'DUPLICATE_SUPPLIED_SLOT_SOURCE',
        ),
      ),
    );
  });
  for (final fixture in <({String label, Widget Function(GlobalKey) create})>[
    (
      label: 'Swap flip',
      create: (key) => coui.Swap(
        key: key,
        animation: .flip,
        onToggle: (_) {},
        offContent: const Text('off'),
        onContent: const Text('on'),
      ),
    ),
    (
      label: 'Swap without toggle',
      create: (key) => coui.Swap(
        key: key,
        offContent: const Text('off'),
        onContent: const Text('on'),
      ),
    ),
    (label: 'Divider without label', create: (key) => coui.Divider(key: key)),
    (
      label: 'Divider vertical label',
      create: (key) => coui.Divider(
        key: key,
        orientation: .vertical,
        child: const Text('label'),
      ),
    ),
    (
      label: 'Divider semantic label',
      create: (key) => coui.Divider(
        key: key,
        semantic: true,
        child: const Text('label'),
      ),
    ),
  ]) {
    testWidgets('unadopted layout source branch rejects: ${fixture.label}', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kLayoutSeedWidth,
            height: _kLayoutSeedHeight,
            child: fixture.create(key),
          ),
        ),
      );
      await tester.pump(_kLayoutSeedPump);
      expect(
        () => DeclaredBoxProducer.bind(
          producer: key.currentContext! as Element,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.code,
            'code',
            'UNSUPPORTED_LAYOUT_SLOT_SOURCE_BRANCH',
          ),
        ),
      );
    });
  }
  for (final fixture in <({String label, Widget Function(GlobalKey) create})>[
    (
      label: 'ResponsiveRowColumn',
      create: (key) => _UnauditedLayoutFlex(key: key),
    ),
    (label: 'ResponsiveGrid', create: (key) => _UnauditedLayoutGrid(key: key)),
    (
      label: 'ResponsiveContainer',
      create: (key) => _UnauditedLayoutContainer(key: key),
    ),
    (label: 'Stacks', create: (key) => _UnauditedLayoutStack(key: key)),
    (
      label: 'IndexedSwitcher',
      create: (key) => _UnauditedLayoutIndexed(key: key),
    ),
    (label: 'Swap', create: (key) => _UnauditedLayoutSwap(key: key)),
    (label: 'Divider', create: (key) => _UnauditedLayoutDivider(key: key)),
  ]) {
    testWidgets('unknown concrete layout source rejects: ${fixture.label}', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: _kLayoutSeedWidth,
            height: _kLayoutSeedHeight,
            child: fixture.create(key),
          ),
        ),
      );
      await tester.pump(_kLayoutSeedPump);
      expect(
        () => DeclaredBoxProducer.bind(
          producer: key.currentContext! as Element,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        throwsA(
          isA<BoxObservationError>().having(
            (e) => e.code,
            'code',
            'UNREGISTERED_CONCRETE_SOURCE_PRODUCER',
          ),
        ),
      );
    });
  }
  testWidgets('declaring Swap slots never invokes its state callback', (
    tester,
  ) async {
    var calls = 0;
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Swap(
          key: key,
          onToggle: (_) => calls++,
          offContent: const Text('off'),
          onContent: const Text('on'),
        ),
      ),
    );
    await tester.pump(_kLayoutSeedPump);
    expect(calls, 0);
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.scope.suppliedSlots, hasLength(2));
    expect(calls, 0);
  });

  for (final source
      in <
        ({
          String name,
          int slots,
          Widget Function(GlobalKey, List<Widget>) create,
        })
      >[
        (
          name: 'MenuItem',
          slots: 6,
          create: (key, slots) => coui.MenuItem(
            key: key,
            label: slots[0],
            description: slots[1],
            shortcut: slots[2],
            leading: slots[3],
            trailing: slots[4],
            mark: slots[5],
          ),
        ),
        (
          name: 'CarouselBanner',
          slots: 3,
          create: (key, slots) => coui.CarouselBanner(
            key: key,
            thumbnail: slots[0],
            title: slots[1],
            description: slots[2],
          ),
        ),
        (
          name: 'PanelHeader',
          slots: 2,
          create: (key, slots) => coui.PanelHeader(
            key: key,
            title: slots[0],
            action: slots[1],
          ),
        ),
      ]) {
    testWidgets('${source.name} preserves every supplied Widget boundary', (
      tester,
    ) async {
      final key = GlobalKey();
      final keys = List.generate(source.slots, (_) => GlobalKey());
      final slots = <Widget>[
        for (var i = 0; i < keys.length; i++)
          Padding(
            key: keys[i],
            padding: const EdgeInsets.all(_kForeignCallerInset4),
            child: Text('$i'),
          ),
      ];
      await tester.pumpWidget(_app(source.create(key, slots)));
      final declaration = DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(declaration.scope.suppliedSlots, orderedEquals(slots));
      expect(declaration.unrenderedSuppliedSlots, isEmpty);
      for (final childKey in keys) {
        expect(
          () => declaration.scope.requireOwned(
            childKey.currentContext! as Element,
          ),
          throwsA(isA<BoxObservationError>()),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('Calendar source declaration never invokes data callbacks', (
    tester,
  ) async {
    final key = GlobalKey();
    var stateCalls = 0;
    var markerCalls = 0;
    await tester.pumpWidget(
      _app(
        coui.Calendar(
          key: key,
          initialView: const coui.CoreCalendarView(2026, 1),
          stateBuilder: (_) {
            stateCalls++;
            return coui.CoreCalendarDateState.enabled;
          },
          markerBuilder: (_) {
            markerCalls++;
            return const coui.CoreCalendarMarker();
          },
        ),
      ),
    );
    final calls = (stateCalls, markerCalls);
    expect(stateCalls, greaterThan(0));
    expect(markerCalls, greaterThan(0));
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.scope.suppliedSlots, isEmpty);
    expect(declaration.scope.foreignBoundaries, isEmpty);
    expect((stateCalls, markerCalls), calls);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('DefinitionList keeps rich descriptions foreign', (tester) async {
    final key = GlobalKey();
    final childKey = GlobalKey();
    final child = Padding(
      key: childKey,
      padding: const EdgeInsets.all(_kForeignCallerInset4),
      child: const Text('Caller rich description'),
    );
    await tester.pumpWidget(
      _app(
        coui.DefinitionList(
          key: key,
          items: [
            const coui.CoreDefinitionEntry<Widget>(
              term: 'Plain term',
              description: 'Plain data',
            ),
            coui.CoreDefinitionEntry<Widget>.rich(
              term: 'Rich term',
              description: child,
            ),
          ],
        ),
      ),
    );
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.scope.suppliedSlots.single, same(child));
    expect(
      () => declaration.scope.requireOwned(childKey.currentContext! as Element),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('DefinitionList rejects an unaudited entry record', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.DefinitionList(
          key: key,
          items: const [
            _UnauditedDefinitionEntry(Text('Subclass description')),
          ],
        ),
      ),
    );
    expect(
      () => DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNREGISTERED_CONCRETE_SOURCE_RECORD',
        ),
      ),
    );
  });
  testWidgets('DefinitionList rejects repeated rich Widget identities', (
    tester,
  ) async {
    final key = GlobalKey();
    const shared = Text('Repeated caller description');
    await tester.pumpWidget(
      _app(
        coui.DefinitionList(
          key: key,
          items: const [
            coui.CoreDefinitionEntry<Widget>.rich(
              term: 'First term',
              description: shared,
            ),
            coui.CoreDefinitionEntry<Widget>.rich(
              term: 'Second term',
              description: shared,
            ),
          ],
        ),
      ),
    );
    expect(
      () => DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });
  for (final source in <({String name, Widget Function(GlobalKey) create})>[
    (name: 'MenuItem', create: (key) => _UnauditedMenuItem(key: key)),
    (
      name: 'CarouselBanner',
      create: (key) => _UnauditedCarouselBanner(key: key),
    ),
    (name: 'PanelHeader', create: (key) => _UnauditedPanelHeader(key: key)),
    (name: 'Calendar', create: (key) => _UnauditedCalendar(key: key)),
    (
      name: 'DefinitionList',
      create: (key) => _UnauditedDefinitionList(key: key),
    ),
  ]) {
    testWidgets('${source.name} requires its audited concrete input type', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(_app(source.create(key)));
      expect(
        () => DeclaredBoxProducer.bind(
          producer: key.currentContext! as Element,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        throwsA(isA<BoxObservationError>()),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final source in <({String name, Widget Function(GlobalKey) create})>[
    (name: 'Loading', create: (key) => coui.Loading(key: key)),
    (name: 'Skeleton', create: (key) => coui.Skeleton(key: key)),
  ]) {
    testWidgets('${source.name} declares data-only input slots', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(_app(source.create(key)));
      final producer = key.currentContext! as Element;
      final declaration = DeclaredBoxProducer.bind(
        producer: producer,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(declaration.scope.suppliedSlots, isEmpty);
      expect(declaration.scope.foreignBoundaries, isEmpty);
      expect(declaration.unrenderedSuppliedSlots, isEmpty);
      expect(declaration.authority, contains(source.name));
      declaration.scope.requireOwned(producer);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('a tag declares its whole supplied child as foreign', (
    tester,
  ) async {
    final key = GlobalKey();
    final childKey = GlobalKey();
    final child = Padding(
      key: childKey,
      padding: const EdgeInsets.all(_kForeignCallerInset4),
      child: const Text('Caller tag content'),
    );
    await tester.pumpWidget(_app(coui.Tag(key: key, child: child)));
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.scope.suppliedSlots.single, same(child));
    expect(
      () => declaration.scope.requireOwned(childKey.currentContext! as Element),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'FOREIGN_SUPPLIED_CONTENT',
        ),
      ),
    );
  });
  for (final source in <({String name, Widget Function(GlobalKey) create})>[
    (
      name: 'Loading',
      create: (key) => _UnauditedLoading(
        key: key,
        additionalSlot: const Text('Additional loading slot'),
      ),
    ),
    (
      name: 'Skeleton',
      create: (key) => _UnauditedSkeleton(
        key: key,
        additionalSlot: const Text('Additional skeleton slot'),
      ),
    ),
    (
      name: 'Tag',
      create: (key) => _UnauditedTag(
        key: key,
        additionalSlot: const Text('Additional tag slot'),
      ),
    ),
  ]) {
    testWidgets('${source.name} subclass cannot add undeclared Widget slots', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(_app(source.create(key)));
      expect(
        () => DeclaredBoxProducer.bind(
          producer: key.currentContext! as Element,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        throwsA(isA<BoxObservationError>()),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('a bubble declares its supplied child as foreign content', (
    tester,
  ) async {
    final key = GlobalKey();
    final childKey = GlobalKey();
    final child = Padding(
      key: childKey,
      padding: const EdgeInsets.all(_kBubbleForeignCallerInset17),
      child: const Text('Caller content'),
    );
    await tester.pumpWidget(_app(coui.ChatBubble(key: key, child: child)));
    await tester.pumpAndSettle();
    final producer = key.currentContext! as Element;
    final declaration = DeclaredBoxProducer.bind(
      producer: producer,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(identical(declaration.scope.suppliedSlots.single, child), isTrue);
    declaration.scope.requireOwned(producer);
    expect(
      () => declaration.scope.requireOwned(childKey.currentContext! as Element),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'FOREIGN_SUPPLIED_CONTENT',
        ),
      ),
    );
  });

  testWidgets('a bubble declaration does not promote an arbitrary Chat row', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Chat(
          key: key,
          bubble: const coui.ChatBubble(child: Text('Foreign row bubble')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      () => DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNREGISTERED_DECLARING_PRODUCER',
        ),
      ),
    );
  });

  testWidgets('a bubble subclass cannot hide additional caller content', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        _UnauditedChatBubble(
          key: key,
          additionalSlot: const Padding(
            padding: EdgeInsets.all(_kSubclassForeignCallerInset9),
            child: Text('Additional caller slot'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      () => DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNREGISTERED_CONCRETE_SOURCE_PRODUCER',
        ),
      ),
    );
  });

  testWidgets('the registered MockupBrowser binds its own frame', (
    tester,
  ) async {
    final key = GlobalKey();
    final childKey = GlobalKey();
    final foreign = coui.OutlinedContainer(
      key: childKey,
      child: const Text('Caller supplied content'),
    );
    await tester.pumpWidget(
      _app(coui.MockupBrowser(key: key, child: foreign)),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final declaration = DeclaredBoxProducer.bind(
      producer: root,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.isAdditionalSource, isTrue);
    final primitive = declaration.additionalOutlinedFrame!.primitive;
    declaration.scope.requireOwned(primitive);
    expect(identical(primitive, childKey.currentContext), isFalse);
    expect(
      () => declaration.scope.requireOwned(childKey.currentContext! as Element),
      throwsA(isA<BoxObservationError>()),
    );
    final observed = observeDeclaredRootPadding(
      captureRoot: root,
      declaringFinder: 'byType:MockupBrowser',
      sourceContract: 'renderer-frame-padding-v1',
      canonicalFrame: null,
    );
    expect(observed['status'], 'measured');
    final direct = observeOutlinedContainerContentPadding(
      primitive: primitive,
      declaringScope: declaration.scope,
    );
    expect(observed['ownerElement'], identityHashCode(direct.owner));
    expect(observed['declaringProducerElement'], identityHashCode(root));
  });

  testWidgets('a scope-only wrapper cannot fall back to its foreign frame', (
    tester,
  ) async {
    final key = GlobalKey();
    final childKey = GlobalKey();
    final foreign = coui.OutlinedContainer(
      key: childKey,
      child: const Text('Caller supplied content'),
    );
    await tester.pumpWidget(
      _app(coui.AspectRatioBox(key: key, ratio: 2, child: foreign)),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final declaration = DeclaredBoxProducer.bind(
      producer: root,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.isAdditionalSource, isTrue);
    expect(declaration.additionalOutlinedFrame, isNull);
    final foreignFrame = findChromeNode(
      tester,
      rootFinder: find.byKey(childKey),
    );
    expect(foreignFrame, isNotNull);
    expect(
      () => observeDeclaredRootPadding(
        captureRoot: root,
        declaringFinder: 'byType:AspectRatioBox',
        sourceContract: 'renderer-frame-padding-v1',
        canonicalFrame: foreignFrame!.renderBox,
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNRESOLVED_ADDITIONAL_OWN_FRAME_ROUTE',
        ),
      ),
    );
  });

  testWidgets(
    'an unknown subclass cannot publish an additional foreign frame',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final foreignKey = GlobalKey();
      final supplied = coui.OutlinedContainer(
        key: foreignKey,
        containerStyle: const coui.CoreOutlinedContainerStyle(
          padding: coui.CoreEdgeInsets.all(16),
        ),
      );
      await tester.pumpWidget(
        _app(_UnauditedOutlinedSource(key: key, additionalSlot: supplied)),
      );
      await tester.pumpAndSettle();
      final root = key.currentContext! as Element;
      expect(identical(foreignKey.currentContext!.widget, supplied), isTrue);
      final rejected = throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'UNREGISTERED_CONCRETE_SOURCE_PRODUCER',
        ),
      );
      expect(
        () => DeclaredBoxProducer.bind(
          producer: root,
          sourceContract: 'renderer-frame-padding-v1',
        ),
        rejected,
      );
      expect(
        () => observeOutlinedContainerContentPadding(
          primitive: root,
          declaringScope: BoxProducerScope(
            producer: root,
            suppliedSlots: const [],
          ),
        ),
        rejected,
      );
    },
  );

  testWidgets('shared source binds its current inner padding Container', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(_surface(key: key, padding: _kOwnedCallerSurfaceInset16)),
    );
    await tester.pumpAndSettle();
    final primitive = key.currentContext! as Element;
    final observed = observeOutlinedContainerContentPadding(
      primitive: primitive,
      declaringScope: _surfaceScope(primitive),
    );
    expect(observed.value, const EdgeInsets.all(_kOwnedCallerSurfaceInset16));
    expect(
      observed.currentRenderPadding,
      const EdgeInsets.all(_kOwnedCallerSurfaceInset16),
    );
    expect(observed.allocatedDecorationInsets, EdgeInsets.zero);
  });

  testWidgets('a caller-supplied primitive cannot supply the outer producer', (
    tester,
  ) async {
    final producerKey = GlobalKey();
    final surfaceKey = GlobalKey();
    await tester.pumpWidget(
      _app(
        _CallerChildProducer(
          key: producerKey,
          child: _surface(key: surfaceKey, padding: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final producer = producerKey.currentContext! as Element;
    final callerChild = (producer.widget as _CallerChildProducer).child;
    final declaringScope = BoxProducerScope(
      producer: producer,
      suppliedSlots: [callerChild],
    );
    expect(
      () => observeOutlinedContainerContentPadding(
        primitive: surfaceKey.currentContext! as Element,
        declaringScope: declaringScope,
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'FOREIGN_SUPPLIED_CONTENT',
        ),
      ),
    );
  });

  testWidgets('duplicate owner declarations produce a completeness error', (
    tester,
  ) async {
    final first = GlobalKey();
    final second = GlobalKey();
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: .min,
          children: [
            _surface(key: first, padding: 16),
            _surface(key: second, padding: 16),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      () => requireOneBoxOwner([
        first.currentContext! as Element,
        second.currentContext! as Element,
      ], 'declared surface'),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'DUPLICATE_OWNER',
        ),
      ),
    );
  });

  testWidgets('a nested foreign surface mutation leaves outer padding intact', (
    tester,
  ) async {
    final outer = GlobalKey();
    final inner = GlobalKey();
    var foreignPadding = _kForeignCallerInset4;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return _surface(
              key: outer,
              padding: _kOwnedCallerSurfaceInset16,
              child: _surface(key: inner, padding: foreignPadding),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final outerElement = outer.currentContext! as Element;
    final before = observeOutlinedContainerContentPadding(
      primitive: outerElement,
      declaringScope: _surfaceScope(outerElement),
    );
    update(() => foreignPadding = _kChangedForeignCallerInset12);
    await tester.pumpAndSettle();
    final sameOuter = outer.currentContext! as Element;
    final after = observeOutlinedContainerContentPadding(
      primitive: sameOuter,
      declaringScope: _surfaceScope(sameOuter),
    );
    final innerElement = inner.currentContext! as Element;
    final innerValue = observeOutlinedContainerContentPadding(
      primitive: innerElement,
      declaringScope: _surfaceScope(innerElement),
    );
    expect(sameOuter, same(outerElement));
    expect(after.value, before.value);
    expect(after.value, const EdgeInsets.all(_kOwnedCallerSurfaceInset16));
    expect(
      innerValue.value,
      const EdgeInsets.all(_kChangedForeignCallerInset12),
    );
  });

  testWidgets('a real owned padding change is observed on the same producer', (
    tester,
  ) async {
    final key = GlobalKey();
    var padding = _kOwnedCallerSurfaceInset16;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return _surface(key: key, padding: padding);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final element = key.currentContext! as Element;
    final before = observeOutlinedContainerContentPadding(
      primitive: element,
      declaringScope: _surfaceScope(element),
    );
    update(() => padding = _kChangedOwnedCallerSurfaceInset24);
    await tester.pumpAndSettle();
    final sameElement = key.currentContext! as Element;
    final after = observeOutlinedContainerContentPadding(
      primitive: sameElement,
      declaringScope: _surfaceScope(sameElement),
    );
    expect(sameElement, same(element));
    expect(before.value, const EdgeInsets.all(_kOwnedCallerSurfaceInset16));
    expect(
      after.value,
      const EdgeInsets.all(_kChangedOwnedCallerSurfaceInset24),
    );
    expect(after.value, isNot(before.value));
  });

  testWidgets('an unrelated widget cannot become the shared surface source', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(Container(key: key, child: const Text('Other'))),
    );
    final element = key.currentContext! as Element;
    expect(
      () => observeOutlinedContainerContentPadding(
        primitive: element,
        declaringScope: BoxProducerScope(
          producer: element,
          suppliedSlots: const [],
        ),
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'NOT_SHARED_SURFACE_PRIMITIVE',
        ),
      ),
    );
  });

  testWidgets('canonical factory excludes every supplied Button slot', (
    tester,
  ) async {
    final key = GlobalKey();
    final child = SizedBox(key: GlobalKey(), width: 20, height: 10);
    final leading = SizedBox(key: GlobalKey(), width: 10, height: 10);
    final trailing = SizedBox(key: GlobalKey(), width: 10, height: 10);
    await tester.pumpWidget(
      _app(
        coui.Button(
          key: key,
          leading: leading,
          trailing: trailing,
          onPressed: () {},
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final declaration = DeclaredBoxProducer.bind(
      producer: root,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.scope.foreignBoundaries, hasLength(3));
    expect(declaration.unrenderedSuppliedSlots, isEmpty);
    for (final slot in [child, leading, trailing]) {
      final element = tester.element(find.byWidget(slot));
      expect(
        () => declaration.scope.requireOwned(element),
        throwsA(isA<BoxObservationError>()),
      );
    }
  });

  testWidgets(
    'a mounted placeholder remains a foreign public slot even when hidden',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final placeholder = SizedBox(key: GlobalKey(), width: 10, height: 10);
      final controller = TextEditingController(text: 'Existing value');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          coui.TextField(
            key: key,
            controller: controller,
            placeholder: placeholder,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final declaration = DeclaredBoxProducer.bind(
        producer: key.currentContext! as Element,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(find.byWidget(placeholder), findsOneWidget);
      expect(declaration.unrenderedSuppliedSlots, isEmpty);
      expect(declaration.scope.foreignBoundaries, hasLength(1));
    },
  );

  testWidgets('canonical factory rejects a foreign shared surface frame', (
    tester,
  ) async {
    final rootKey = GlobalKey();
    final surfaceKey = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Button(
          key: rootKey,
          onPressed: () {},
          child: _surface(key: surfaceKey, padding: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = rootKey.currentContext! as Element;
    final foreign = surfaceKey.currentContext! as Element;
    final render = foreign.findRenderObject()! as RenderBox;
    expect(
      () => observeDeclaredRootPadding(
        captureRoot: root,
        declaringFinder: 'byType:Button',
        sourceContract: 'renderer-frame-padding-v1',
        canonicalFrame: render,
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'FOREIGN_SUPPLIED_CONTENT',
        ),
      ),
    );
  });

  testWidgets('additive zero cannot resurrect a structurally omitted role', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(Container(key: key, child: const SizedBox(width: 10, height: 10))),
    );
    final root = key.currentContext! as Element;
    const probes = [
      ParityProbeSpec(
        role: 'root',
        flutterFinder: 'byType:Container',
        fields: {'paddingPx'},
        nativeBoxSource: 'renderer-frame-padding-v1',
      ),
    ];
    final omitted = observeAdditiveBoxPadding(
      key: 'control',
      probes: probes,
      legacyRootOmitted: true,
      captureRoot: root,
      canonicalFrame: null,
    );
    final measured = observeAdditiveBoxPadding(
      key: 'control',
      probes: probes,
      legacyRootOmitted: false,
      captureRoot: root,
      canonicalFrame: null,
    );
    final omittedRole = (omitted['byRole']! as Map)['root']! as Map;
    final measuredRole = (measured['byRole']! as Map)['root']! as Map;
    expect(omittedRole['status'], 'known-structural-omission');
    expect(omittedRole.containsKey('value'), isFalse);
    expect(measuredRole['status'], 'measured');
    expect(measuredRole['value'], [0.0, 0.0, 0.0, 0.0]);
  });

  testWidgets(
    'unsupported and missing declarations never emit a padding value',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(Container(key: key, child: const SizedBox(width: 10, height: 10))),
      );
      final root = key.currentContext! as Element;
      for (final probe in [
        const ParityProbeSpec(role: 'root', flutterFinder: 'byType:Container'),
        const ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Container',
          fields: {'paddingPx'},
        ),
        const ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Container',
          fields: {'paddingPx'},
          nativeBoxSource: 'unknown-v99',
        ),
        const ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Container',
          fields: {'paddingPx'},
          nativeBoxSource: 'docs-model-frame-padding-v1',
        ),
        const ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Container',
          fields: {'paddingPx'},
          nativeBoxSource: 'docs-playground-frame-padding-v1',
        ),
        const ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Missing',
          fields: {'paddingPx'},
          nativeBoxSource: 'renderer-frame-padding-v1',
        ),
      ]) {
        final result = observeAdditiveBoxPadding(
          key: 'control',
          probes: [probe],
          legacyRootOmitted: false,
          captureRoot: root,
          canonicalFrame: null,
        );
        final role = (result['byRole']! as Map)['root']! as Map;
        expect(role['status'], 'unresolved');
        expect(role.containsKey('value'), isFalse);
      }
    },
  );

  testWidgets('an unrendered secondary action has source-declared absence', (
    tester,
  ) async {
    final key = GlobalKey();
    final secondary = SizedBox(key: GlobalKey(), width: 20, height: 10);
    await tester.pumpWidget(
      _app(
        coui.BottomActionBar(
          key: key,
          layout: .summary,
          primaryAction: const SizedBox(width: 20, height: 10),
          secondaryAction: secondary,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(find.byWidget(secondary), findsNothing);
    expect(declaration.unrenderedSuppliedSlots, [same(secondary)]);
    expect(declaration.scope.foreignBoundaries, hasLength(1));
  });

  testWidgets('typed Widget lists preserve every supplied public boundary', (
    tester,
  ) async {
    final key = GlobalKey();
    final first = SizedBox(key: GlobalKey(), width: 10, height: 10);
    final second = SizedBox(key: GlobalKey(), width: 10, height: 10);
    final trailing = SizedBox(key: GlobalKey(), width: 10, height: 10);
    await tester.pumpWidget(
      _app(
        coui.AppBar(
          key: key,
          leading: [first, second],
          trailing: [trailing],
          title: const Text('Title'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    for (final child in [first, second, trailing]) {
      expect(
        () => declaration.scope.requireOwned(
          tester.element(find.byWidget(child)),
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
  });

  testWidgets('Widget slots nested in public row data remain foreign', (
    tester,
  ) async {
    final key = GlobalKey();
    final foreignKey = GlobalKey();
    final foreign = _surface(key: foreignKey, padding: 4);
    await tester.pumpWidget(
      _app(
        coui.DescriptionCard(
          key: key,
          rows: [
            coui.DescriptionRow(
              label: 'Row',
              value: 'Accessible value',
              valueWidget: foreign,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final foreignElement = foreignKey.currentContext! as Element;
    expect(identical(foreignElement.widget, foreign), isTrue);
    expect(
      identical(
        (root.widget as coui.DescriptionCard).rows.single.valueWidget,
        foreign,
      ),
      isTrue,
    );
    expect(BoxProducerScope.contains(root, foreignElement), isTrue);
    final declaration = DeclaredBoxProducer.bind(
      producer: root,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(
      () => declaration.scope.requireOwned(foreignElement),
      throwsA(isA<BoxObservationError>()),
    );
    final frame = findChromeNode(tester, rootFinder: find.byKey(key));
    final observation = observeDeclaredRootPadding(
      captureRoot: root,
      declaringFinder: 'byType:DescriptionCard',
      sourceContract: 'renderer-frame-padding-v1',
      canonicalFrame: frame?.renderBox,
    );
    expect(observation['status'], 'measured');
    expect(observation['ownerWidgetType'], 'Container');
  });

  testWidgets('SizeSpec binds its declared frame slot instead of table cells', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        KeyedSubtree(
          key: key,
          child: FlutterDocsSizeSpec(
            component: 'button',
            spec: docsSizeSpecFor('button')!,
            attributes: const {'component': 'button'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    final frame = findChromeNode(tester, rootFinder: find.byKey(key));
    final observed = observeDeclaredRootPadding(
      captureRoot: root,
      declaringFinder: 'byType:FlutterDocsSizeSpec',
      sourceContract: 'docs-model-frame-padding-v1',
      canonicalFrame: frame?.renderBox,
    );
    expect(observed['status'], 'measured');
    expect(observed['ownerWidgetType'], 'Padding');
    expect(observed['currentRenderPadding'], [24.0, 24.0, 24.0, 24.0]);
    expect(observed['sameOwnerDecorationAllocation'], [0.0, 0.0, 0.0, 0.0]);
  });

  testWidgets('a closed Dropdown cannot borrow its supplied trigger frame', (
    tester,
  ) async {
    final key = GlobalKey();
    final triggerKey = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.DropdownMenu(
          key: key,
          trigger: _surface(key: triggerKey, padding: 4),
          items: const [coui.CoreMenuItem.action('Item')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = key.currentContext! as Element;
    expect(
      () => observeDeclaredRootPadding(
        captureRoot: root,
        declaringFinder: 'byType:DropdownMenu',
        sourceContract: 'renderer-frame-padding-v1',
        canonicalFrame:
            triggerKey.currentContext!.findRenderObject()! as RenderBox,
      ),
      throwsA(
        isA<BoxObservationError>().having(
          (error) => error.code,
          'code',
          'FOREIGN_SUPPLIED_CONTENT',
        ),
      ),
    );
  });

  testWidgets('Banner current Container padding excludes its centering gap', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Banner(
          key: key,
          message: const Text('Message'),
          bannerStyle: const coui.CoreBannerStyle(
            padding: coui.CoreEdgeInsets.all(16),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_observeUnit(tester, key, 'Banner')['value'], [
      16.0,
      16.0,
      16.0,
      16.0,
    ]);
  });

  testWidgets('Frame split content Padding excludes border and equal margin', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Frame(
          key: key,
          padding: const coui.CoreEdgeInsets.all(16),
          margin: const coui.CoreEdgeInsets.all(16),
          borderColor: const coui.CoreColor(0xff1255aa),
          borderWidth: 1,
          child: const Padding(
            padding: EdgeInsets.all(_kForeignCallerInset4),
            child: SizedBox(width: 20, height: 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final observed = _observeUnit(tester, key, 'Frame');
    expect(observed['ownerWidgetType'], 'Padding');
    expect(observed['value'], [16.0, 16.0, 16.0, 16.0]);
    expect(observed['sameOwnerDecorationAllocation'], [0.0, 0.0, 0.0, 0.0]);
  });

  testWidgets('Frame with no owned content Padding does not borrow child4', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Frame(
          key: key,
          padding: coui.CoreEdgeInsets.zero,
          borderColor: const coui.CoreColor(0xff1255aa),
          borderWidth: 1,
          child: const Padding(
            padding: EdgeInsets.all(_kForeignCallerInset4),
            child: SizedBox(width: 20, height: 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_observeUnit(tester, key, 'Frame')['value'], [0.0, 0.0, 0.0, 0.0]);
  });

  for (final medium in [false, true]) {
    testWidgets('AppBar root padding distinguishes top-row subrole: $medium', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          coui.AppBar(
            key: key,
            variant: medium ? .medium : .standard,
            title: const Text('Title'),
            appBarStyle: const coui.CoreAppBarStyle(
              padding: coui.CoreEdgeInsets.all(16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _observeUnit(tester, key, 'AppBar')['value'],
        medium ? [0.0, 0.0, 0.0, 0.0] : [16.0, 16.0, 16.0, 16.0],
      );
    });
  }

  for (final footer in [false, true]) {
    testWidgets(
      'TextArea explicit content padding preserves footer boundary: $footer',
      (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          _app(
            coui.TextArea(
              key: key,
              rows: 2,
              footer: footer
                  ? const Padding(
                      padding: EdgeInsets.all(_kForeignCallerInset4),
                      child: Text('Footer'),
                    )
                  : null,
              textAreaStyle: const coui.CoreTextAreaStyle(
                padding: coui.CoreEdgeInsets.all(16),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_observeUnit(tester, key, 'TextArea')['value'], [
          16.0,
          16.0,
          16.0,
          16.0,
        ]);
      },
    );
  }

  testWidgets('Checkbox shared source does not turn its border into padding', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(coui.Checkbox(key: key, checked: false, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(_observeUnit(tester, key, 'Checkbox')['value'], [
      0.0,
      0.0,
      0.0,
      0.0,
    ]);
  });

  testWidgets(
    'a source-copied caller Button remains outside Banner ownership',
    (tester) async {
      final rootKey = GlobalKey();
      final actionKey = GlobalKey();
      final action = coui.Button(
        key: actionKey,
        onPressed: () {},
        child: const Text('Action'),
      );
      await tester.pumpWidget(
        _app(
          coui.Banner(
            key: rootKey,
            message: const Text('Message'),
            action: action,
            bannerStyle: const coui.CoreBannerStyle(
              padding: coui.CoreEdgeInsets.all(16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final root = rootKey.currentContext! as Element;
      final actualAction = actionKey.currentContext! as Element;
      expect(identical(actualAction.widget, action), isFalse);
      final declaration = DeclaredBoxProducer.bind(
        producer: root,
        sourceContract: 'renderer-frame-padding-v1',
      );
      expect(
        declaration.scope.foreignBoundaries.any(
          (element) => identical(element, actualAction),
        ),
        isTrue,
      );
      final foreignFrame = findChromeNode(
        tester,
        rootFinder: find.byKey(actionKey),
      );
      expect(
        () => observeDeclaredRootPadding(
          captureRoot: root,
          declaringFinder: 'byType:Banner',
          sourceContract: 'renderer-frame-padding-v1',
          canonicalFrame: foreignFrame?.renderBox,
        ),
        throwsA(
          isA<BoxObservationError>().having(
            (error) => error.code,
            'code',
            'FOREIGN_SUPPLIED_CONTENT',
          ),
        ),
      );
      expect(_observeUnit(tester, rootKey, 'Banner')['value'], [
        16.0,
        16.0,
        16.0,
        16.0,
      ]);
    },
  );

  testWidgets('unused Card slots need a real source omission branch', (
    tester,
  ) async {
    final key = GlobalKey();
    final unused = SizedBox(key: GlobalKey(), width: 10, height: 10);
    await tester.pumpWidget(
      _app(
        coui.Card(key: key, body: unused, child: const Text('Legacy child')),
      ),
    );
    await tester.pumpAndSettle();
    final declaration = DeclaredBoxProducer.bind(
      producer: key.currentContext! as Element,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(find.byWidget(unused), findsNothing);
    expect(
      declaration.suppliedSlotDerivations.single['kind'],
      'source-declared-unrendered-branch',
    );
  });

  testWidgets('a hidden producer cannot silently supply an active zero value', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        coui.Frame(key: key, visible: false, child: const Text('Hidden child')),
      ),
    );
    final result = observeAdditiveBoxPadding(
      key: 'hidden',
      probes: const [
        ParityProbeSpec(
          role: 'root',
          flutterFinder: 'byType:Frame',
          fields: {'paddingPx'},
          nativeBoxSource: 'renderer-frame-padding-v1',
        ),
      ],
      legacyRootOmitted: false,
      captureRoot: key.currentContext! as Element,
      canonicalFrame: null,
    );
    final role = (result['byRole']! as Map)['root']! as Map;
    expect(role['status'], 'unresolved');
    expect(role['error'], 'UNRESOLVED_SUPPLIED_SLOT_SOURCE');
    expect(role.containsKey('value'), isFalse);
  });
}

Map<String, Object?> _observeUnit(
  WidgetTester tester,
  GlobalKey key,
  String producerType,
) {
  final frame = findChromeNode(tester, rootFinder: find.byKey(key));
  return observeDeclaredRootPadding(
    captureRoot: key.currentContext! as Element,
    declaringFinder: 'byType:$producerType',
    sourceContract: 'renderer-frame-padding-v1',
    canonicalFrame: frame?.renderBox,
  );
}
