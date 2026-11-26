import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/internal/preview/flutter_card_view.dart'
    show FlutterDocsCardView;
import 'package:docs_core/internal/preview/flutter_stage.dart'
    show DocsStage, FlutterDocsSizeSpec;
import 'package:flutter/rendering.dart'
    show RenderBox, RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Align,
        AnimatedContainer,
        BoxDecoration,
        Center,
        Column,
        Container,
        DecoratedBox,
        EdgeInsets,
        Element,
        KeyedSubtree,
        Padding,
        RenderObjectElement,
        Row,
        SafeArea,
        SizedBox,
        Widget,
        Wrap;

import 'box_padding_observation.dart';
import 'box_padding_scope_extensions.dart';

/// Binds the shared surface's actual frame/content implementation.
///
/// The outer declaring producer must own the primitive before any supplied
/// content boundary. A foreign caller surface cannot become the producer's
/// frame merely because that surface owns its own internal Containers.
BoxPaddingObservation observeOutlinedContainerContentPadding({
  required Element primitive,
  required BoxProducerScope declaringScope,
}) {
  declaringScope.requireOwned(primitive);
  final widget = primitive.widget;
  if (widget is! coui.OutlinedContainer) {
    throw const BoxObservationError(
      'NOT_SHARED_SURFACE_PRIMITIVE',
      'The declared source is not the shared OutlinedContainer.',
    );
  }
  requireConcreteBoxSourceType(widget, coui.OutlinedContainer);
  final ownScope = BoxProducerScope(
    producer: primitive,
    suppliedSlots: [?widget.child],
  );
  final candidates = <Element>[];
  final frames = <Element, Element>{};

  void visit(Element element) {
    if (ownScope.foreignBoundaries.any((e) => identical(e, element))) return;
    if (element.widget is AnimatedContainer) {
      final outerCurrent = evaluatedAnimatedContainer(element);
      final outerChild = (outerCurrent.widget as Container).child;
      if (outerChild is AnimatedContainer) {
        final innerAnimation = elementOfDeclaredChild(outerCurrent, outerChild);
        final innerCurrent = evaluatedAnimatedContainer(innerAnimation);
        final innerChild = (innerCurrent.widget as Container).child;
        final forwardsSuppliedChild = widget.child == null
            ? innerChild == null
            : innerChild is KeyedSubtree &&
                  identical(innerChild.child, widget.child);
        if (forwardsSuppliedChild) {
          candidates.add(innerCurrent);
          frames[innerCurrent] = outerCurrent;
        }
      }
    }
    element.visitChildren(visit);
  }

  visit(primitive);
  final owner = requireOneBoxOwner(
    candidates,
    'the shared surface current padding Container',
  );
  ownScope.requireOwned(owner);
  declaringScope.requireOwned(owner);
  if (widget.child case final child?) {
    final keyed = (owner.widget as Container).child! as KeyedSubtree;
    final keyedElement = elementOfDeclaredChild(owner, keyed);
    final suppliedElement = elementOfDeclaredChild(keyedElement, child);
    if (!ownScope.foreignBoundaries.any((e) => identical(e, suppliedElement))) {
      throw const BoxObservationError(
        'SHARED_SURFACE_CONTENT_BOUNDARY_CHANGED',
        'The inner current Container does not forward the same supplied child.',
      );
    }
  }
  return observeCurrentContainerPadding(
    owner: owner,
    scope: declaringScope,
  ).withFrameOwner(frames[owner]!);
}

/// Scope declarations enumerate actual public Widget slots of known producers.
/// An unregistered producer is unsupported, never treated as having no slots.
class DeclaredBoxProducer {
  DeclaredBoxProducer._({
    required this.element,
    required this.scope,
    required this.unrenderedSuppliedSlots,
    required this.authority,
    required this.suppliedSlotDerivations,
    required this.isAdditionalSource,
    this.additionalOutlinedFrame,
  });

  factory DeclaredBoxProducer.bind({
    required Element producer,
    required String sourceContract,
    Widget? docsSceneConstructorResult,
  }) {
    final widget = producer.widget;
    _requireSourceContract(
      producer: producer,
      sourceContract: sourceContract,
      docsSceneConstructorResult: docsSceneConstructorResult,
    );
    final List<Widget> slots;
    final String authority;
    AdditionalBoxProducerSource? additional;
    if (widget is coui.OutlinedContainer) {
      requireConcreteBoxSourceType(widget, coui.OutlinedContainer);
      slots = [?widget.child];
      authority = 'OutlinedContainer.child';
    } else if (widget is coui.Button) {
      requireConcreteBoxSourceType(widget, coui.Button);
      slots = [widget.child, ?widget.leading, ?widget.trailing];
      authority = 'Button.child/leading/trailing';
    } else if (widget is coui.Progress) {
      requireConcreteBoxSourceType(widget, coui.Progress);
      slots = [?widget.label, ?widget.valueLabel, ?widget.caption];
      authority = 'Progress.label/valueLabel/caption';
    } else if (widget is coui.TextField) {
      requireConcreteBoxSourceType(widget, coui.TextField);
      slots = [?widget.placeholder, ?widget.prefix, ?widget.suffix];
      authority = 'TextField.placeholder/prefix/suffix';
    } else if (widget is coui.TextArea) {
      requireConcreteBoxSourceType(widget, coui.TextArea);
      slots = [?widget.prefix, ?widget.suffix, ?widget.footer];
      authority = 'TextArea.prefix/suffix/footer';
    } else if (widget is coui.BottomActionBar) {
      requireConcreteBoxSourceType(widget, coui.BottomActionBar);
      slots = [
        widget.primaryAction,
        ?widget.secondaryAction,
        ?widget.description,
        ?widget.summaryLabel,
        ?widget.summaryValue,
      ];
      authority = 'BottomActionBar public action/description/summary slots';
    } else if (widget is coui.Avatar) {
      requireConcreteBoxSourceType(widget, coui.Avatar);
      slots = [?widget.child, ?widget.badge];
      authority = 'Avatar.child/badge';
    } else if (widget is coui.DescriptionCard) {
      requireConcreteBoxSourceType(widget, coui.DescriptionCard);
      slots = [
        ?widget.titleLeading,
        ?widget.titleTrailing,
        ?widget.bottomAction,
        for (final row in widget.rows) ...[
          ?row.valueWidget,
          ?row.leading,
          ?row.trailing,
        ],
      ];
      authority =
          'DescriptionCard public slots and DescriptionRow Widget slots';
    } else if (widget is coui.Stat) {
      requireConcreteBoxSourceType(widget, coui.Stat);
      slots = [?widget.icon];
      authority = 'Stat.icon';
    } else if (widget is coui.NumberInput) {
      requireConcreteBoxSourceType(widget, coui.NumberInput);
      slots = const [];
      authority =
          'NumberInput accepts numeric/string inputs and void callbacks';
    } else if (widget is coui.Card) {
      requireConcreteBoxSourceType(widget, coui.Card);
      slots = [
        ?widget.child,
        ?widget.media,
        ?widget.header,
        ?widget.body,
        ?widget.footer,
        ?widget.overlay,
      ];
      authority = 'Card.child/media/header/body/footer/overlay';
    } else if (widget is coui.Banner) {
      requireConcreteBoxSourceType(widget, coui.Banner);
      slots = [widget.message, ?widget.description, ?widget.action];
      authority = 'Banner.message/description/action';
    } else if (widget is coui.Alert) {
      requireConcreteBoxSourceType(widget, coui.Alert);
      slots = [?widget.leading, ?widget.action];
      authority = 'Alert.leading/action';
    } else if (widget is coui.Toast) {
      requireConcreteBoxSourceType(widget, coui.Toast);
      slots = [?widget.action];
      authority = 'Toast.action';
    } else if (widget is coui.AppBar) {
      requireConcreteBoxSourceType(widget, coui.AppBar);
      slots = [
        ?widget.title,
        ?widget.header,
        ?widget.subtitle,
        ?widget.child,
        ...widget.leading,
        ...widget.trailing,
      ];
      authority =
          'AppBar public title/content and leading/trailing Widget lists';
    } else if (widget is coui.Frame) {
      requireConcreteBoxSourceType(widget, coui.Frame);
      slots = [?widget.child, ...?widget.children];
      authority = 'Frame.child/children';
    } else if (widget is coui.Mask) {
      requireConcreteBoxSourceType(widget, coui.Mask);
      slots = [widget.child];
      authority = 'Mask.child';
    } else if (widget is coui.EmptyState) {
      requireConcreteBoxSourceType(widget, coui.EmptyState);
      slots = [widget.title, ?widget.icon, ?widget.description, ?widget.action];
      authority = 'EmptyState.title/icon/description/action';
    } else if (widget is coui.Label) {
      requireConcreteBoxSourceType(widget, coui.Label);
      slots = [?widget.icon];
      authority = 'Label.icon';
    } else if (widget is coui.Kbd) {
      requireConcreteBoxSourceType(widget, coui.Kbd);
      slots = [?widget.keyContent];
      authority = 'Kbd.keyContent';
    } else if (widget is coui.Link) {
      requireConcreteBoxSourceType(widget, coui.Link);
      slots = [?widget.child, ?widget.leading, ?widget.trailing];
      authority = 'Link.child/leading/trailing';
    } else if (widget is coui.ChatBubble) {
      requireConcreteBoxSourceType(widget, coui.ChatBubble);
      slots = [widget.child];
      authority = 'ChatBubble.child; the bubble is a separate producer';
    } else if (widget is coui.Chip) {
      requireConcreteBoxSourceType(widget, coui.Chip);
      slots = [?widget.child, ?widget.leading, ?widget.trailing];
      authority = 'Chip.child/leading/trailing';
    } else if (widget is coui.Tag) {
      requireConcreteBoxSourceType(widget, coui.Tag);
      slots = [widget.child];
      authority = 'Tag.child';
    } else if (widget is coui.FormattedInput) {
      requireConcreteBoxSourceType(widget, coui.FormattedInput);
      slots = [?widget.leading, ?widget.trailing];
      authority = 'FormattedInput.leading/trailing';
    } else if (widget is coui.Menu) {
      requireConcreteBoxSourceType(widget, coui.Menu);
      slots = [..._menuSuppliedWidgets(widget.items)];
      authority = 'Menu.items recursive leading/trailing Widget slots';
    } else if (widget is coui.MenuItem) {
      requireConcreteBoxSourceType(widget, coui.MenuItem);
      slots = [
        widget.label,
        ?widget.description,
        ?widget.shortcut,
        ?widget.leading,
        ?widget.trailing,
        ?widget.mark,
      ];
      authority = 'MenuItem.label/description/shortcut/leading/trailing/mark';
    } else if (widget is coui.CarouselBanner) {
      requireConcreteBoxSourceType(widget, coui.CarouselBanner);
      slots = [?widget.thumbnail, ?widget.title, ?widget.description];
      authority = 'CarouselBanner.thumbnail/title/description';
    } else if (widget is coui.PanelHeader) {
      requireConcreteBoxSourceType(widget, coui.PanelHeader);
      slots = [widget.title, ?widget.action];
      authority = 'PanelHeader.title/action';
    } else if (widget is coui.Calendar) {
      requireConcreteBoxSourceType(widget, coui.Calendar);
      slots = const [];
      authority =
          'Calendar callbacks return date-state and marker data, not Widgets';
    } else if (widget is coui.DefinitionList) {
      requireConcreteBoxSourceType(widget, coui.DefinitionList);
      slots = [..._definitionListSuppliedWidgets(widget.items)];
      authority = 'DefinitionList.items exact rich description Widget slots';
    } else if (widget is coui.ToggleGroup<Object?>) {
      requireConcreteBoxSourceType(widget, coui.ToggleGroup<String>);
      final typed = widget as coui.ToggleGroup<String>;
      slots = _layoutSuppliedWidgetBag([
        ..._toggleParameterWidgetSlots(typed.items),
        ?typed.trailing,
      ]);
      authority = 'ToggleGroup<String> exact item.icon and trailing slots';
    } else if (widget is coui.FormField) {
      requireConcreteBoxSourceType(widget, coui.FormField);
      slots = _layoutSuppliedWidgetBag([
        ?widget.labelWidget,
        ?widget.labelAction,
        ?widget.child,
      ]);
      authority = 'FormField.labelWidget/labelAction/child, including omission';
    } else if (widget is coui.FormLabel) {
      requireConcreteBoxSourceType(widget, coui.FormLabel);
      slots = _layoutSuppliedWidgetBag([
        ?widget.label,
        ?widget.requiredIndicator,
      ]);
      authority = 'FormLabel.label/requiredIndicator, including omitted marker';
    } else if (widget is coui.Listing) {
      requireConcreteBoxSourceType(widget, coui.Listing);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'Listing.children; whole supplied rows remain foreign';
    } else if (widget is coui.OptionList) {
      requireConcreteBoxSourceType(widget, coui.OptionList);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'OptionList.children; whole supplied items remain foreign';
    } else if (widget is coui.Disclosure) {
      requireConcreteBoxSourceType(widget, coui.Disclosure);
      slots = _layoutSuppliedWidgetBag([?widget.trigger, widget.content]);
      // widget.open is initial state, not authority for current omission.
      // Unmounted current content remains unresolved until a frame witness
      // authenticates its actual current operation; no private State is read.
      authority =
          'Disclosure.trigger/content raw slots; no open-state inference';
    } else if (widget is coui.DisclosureGroup) {
      requireConcreteBoxSourceType(widget, coui.DisclosureGroup);
      slots = _layoutSuppliedWidgetBag(widget.items);
      authority = 'DisclosureGroup.items; whole supplied sections stay foreign';
    } else if (widget is coui.Collapsible) {
      requireConcreteBoxSourceType(widget, coui.Collapsible);
      slots = _layoutSuppliedWidgetBag([widget.trigger, widget.content]);
      authority = 'Collapsible.trigger/content; animated inputs stay foreign';
    } else if (widget is coui.Resizable) {
      requireConcreteBoxSourceType(widget, coui.Resizable);
      slots = _layoutSuppliedWidgetBag(
        _resizableParameterWidgetSlots(widget.panes),
      );
      authority = 'Resizable exact CoreResizablePaneData<Widget>.content slots';
    } else if (widget is coui.Breadcrumb) {
      requireConcreteBoxSourceType(widget, coui.Breadcrumb);
      for (final item in widget.items) {
        if (item.runtimeType != coui.CoreBreadcrumbItem) {
          throw const BoxObservationError(
            'UNREGISTERED_CONCRETE_SOURCE_RECORD',
            'Breadcrumb requires exact scalar CoreBreadcrumbItem records.',
          );
        }
      }
      slots = const [];
      authority = 'Breadcrumb exact scalar item records and void callback';
    } else if (widget is coui.ResponsiveRowColumn) {
      requireConcreteBoxSourceType(widget, coui.ResponsiveRowColumn);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'ResponsiveRowColumn.children';
    } else if (widget is coui.ResponsiveGrid) {
      requireConcreteBoxSourceType(widget, coui.ResponsiveGrid);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'ResponsiveGrid.children; whole GridItem inputs stay foreign';
    } else if (widget is coui.ResponsiveContainer) {
      requireConcreteBoxSourceType(widget, coui.ResponsiveContainer);
      slots = _layoutSuppliedWidgetBag([widget.child]);
      authority = 'ResponsiveContainer.child';
    } else if (widget is coui.Stacks) {
      requireConcreteBoxSourceType(widget, coui.Stacks);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'Stacks.children; whole Position inputs stay foreign';
    } else if (widget is coui.IndexedSwitcher) {
      requireConcreteBoxSourceType(widget, coui.IndexedSwitcher);
      slots = _layoutSuppliedWidgetBag(widget.children);
      authority = 'IndexedSwitcher.children, including maintained hidden slots';
    } else if (widget is coui.Swap) {
      requireConcreteBoxSourceType(widget, coui.Swap);
      // Validate the full raw pair before any branch/omission decision.
      slots = _layoutSuppliedWidgetBag([widget.offContent, widget.onContent]);
      if ((widget.animation != .none && widget.animation != .rotate) ||
          widget.onToggle == null) {
        throw const BoxObservationError(
          'UNSUPPORTED_LAYOUT_SLOT_SOURCE_BRANCH',
          'Only interactive non-flip Swap slots have an adopted declaration.',
        );
      }
      authority = 'Swap.offContent/onContent; mounted non-flip foreign inputs';
    } else if (widget is coui.Divider) {
      requireConcreteBoxSourceType(widget, coui.Divider);
      if (widget.child == null ||
          widget.orientation != .horizontal ||
          widget.semantic) {
        throw const BoxObservationError(
          'UNSUPPORTED_LAYOUT_SLOT_SOURCE_BRANCH',
          'Only the labelled horizontal nonsemantic Divider is declared.',
        );
      }
      slots = _layoutSuppliedWidgetBag([widget.child!]);
      authority = 'Divider.child; label wrapper and line insets stay separate';
    } else if (widget is coui.DropdownMenu) {
      requireConcreteBoxSourceType(widget, coui.DropdownMenu);
      slots = [widget.trigger, ..._menuSuppliedWidgets(widget.items)];
      authority = 'DropdownMenu.trigger and recursive item Widget slots';
    } else if (widget is coui.Status) {
      requireConcreteBoxSourceType(widget, coui.Status);
      slots = [?widget.label];
      authority = 'Status.label';
    } else if (widget is coui.ValidationBadge) {
      requireConcreteBoxSourceType(widget, coui.ValidationBadge);
      slots = const [];
      authority = 'ValidationBadge accepts label strings and IconName data';
    } else if (widget is coui.Loading) {
      requireConcreteBoxSourceType(widget, coui.Loading);
      slots = const [];
      authority = 'Loading accepts semantic enums and style data, not Widgets';
    } else if (widget is coui.Skeleton) {
      requireConcreteBoxSourceType(widget, coui.Skeleton);
      slots = const [];
      authority =
          'Skeleton accepts sizing, variant and style data, not Widgets';
    } else if (widget is coui.Checkbox) {
      requireConcreteBoxSourceType(widget, coui.Checkbox);
      slots = [?widget.prefix, ?widget.suffix, ?widget.trailing];
      authority = 'Checkbox.prefix/suffix/trailing';
    } else if (widget is coui.Menubar) {
      requireConcreteBoxSourceType(widget, coui.Menubar);
      slots = const [];
      authority = 'Menubar accepts Core menu data, not supplied Widgets';
    } else if (widget is Container) {
      requireConcreteBoxSourceType(widget, Container);
      slots = [?widget.child];
      authority = 'framework Container.child';
    } else if (widget is DocsStage ||
        widget is FlutterDocsSizeSpec ||
        widget is FlutterDocsCardView) {
      if (!const {
        DocsStage,
        FlutterDocsSizeSpec,
        FlutterDocsCardView,
      }.contains(widget.runtimeType)) {
        throw const BoxObservationError(
          'UNREGISTERED_CONCRETE_SOURCE_PRODUCER',
          'The docs source requires its audited concrete constructor.',
        );
      }
      slots = const [];
      authority =
          'typed docs scene constructor accepts model data, not Widgets';
    } else if (sourceContract == 'docs-playground-frame-padding-v1' &&
        identical(widget, docsSceneConstructorResult)) {
      // This descriptor is emitted for renderFlutterScene's Playground
      // constructor, whose input is DocsScene data. Its returned Widget
      // identity must also match the actual registry construction result.
      slots = const [];
      authority =
          'renderFlutterScene returned Widget identity; '
          'DocsScene has no Widget slots';
    } else {
      additional = describeAdditionalBoxProducerSource(producer);
      if (additional == null) {
        throw const BoxObservationError(
          'UNREGISTERED_DECLARING_PRODUCER',
          'No source declaration describes this producer public Widget slots.',
        );
      }
      if (additional.authority.isEmpty ||
          additional.sourceOmitted.any(
            (omitted) =>
                omitted.authority.isEmpty ||
                !additional!.supplied.any(
                  (slot) => identical(slot, omitted.widget),
                ),
          )) {
        throw const BoxObservationError(
          'INVALID_ADDITIONAL_SLOT_AUTHORITY',
          'Every source omission must identify an actual supplied Widget.',
        );
      }
      slots = additional.supplied;
      authority = additional.authority;
    }
    final subtree = boxElements(producer);
    final rendered = <Widget>[];
    final absent = <Widget>[];
    for (final slot in slots) {
      if (subtree.any((element) => identical(element.widget, slot))) {
        if (additional?.sourceOmitted.any(
              (omitted) => identical(omitted.widget, slot),
            ) ??
            false) {
          throw const BoxObservationError(
            'SOURCE_OMISSION_IS_RENDERED',
            'A declared omitted slot is actually mounted.',
          );
        }
        rendered.add(slot);
      } else {
        absent.add(slot);
      }
    }
    final baseScope = BoxProducerScope(
      producer: producer,
      suppliedSlots: rendered,
    );
    final derived = <Element>[];
    final derivations = <Map<String, Object?>>[];
    for (final slot in absent) {
      if (widget is coui.Banner &&
          identical(slot, widget.action) &&
          slot is coui.Button) {
        final candidates = <Element>[];
        for (final element in subtree) {
          final current = element.widget;
          if (current is! coui.Button ||
              !identical(current.child, slot.child) ||
              !identical(current.leading, slot.leading) ||
              !identical(current.trailing, slot.trailing) ||
              !identical(current.onPressed, slot.onPressed)) {
            continue;
          }
          try {
            baseScope.requireOwned(element);
            candidates.add(element);
          } on BoxObservationError catch (error) {
            if (error.code != 'FOREIGN_SUPPLIED_CONTENT') {
              rethrow;
            }
          }
        }
        final copy = requireOneBoxOwner(
          candidates,
          'Banner action copyWith source',
        );
        derived.add(copy);
        derivations.add({
          'kind': 'source-generated-copy',
          'source':
              'Banner.build action Button.copyWith preserves '
              'content and callback identities',
          'providedWidget': identityHashCode(slot),
          'renderedElement': identityHashCode(copy),
          'renderedWidget': identityHashCode(copy.widget),
        });
      } else if (additional?.sourceOmitted.any(
            (omitted) => identical(omitted.widget, slot),
          ) ??
          false) {
        final omitted = additional!.sourceOmitted
            .where((omitted) => identical(omitted.widget, slot))
            .toList();
        if (omitted.length != 1) {
          throw const BoxObservationError(
            'AMBIGUOUS_SOURCE_OMISSION',
            'A supplied Widget has multiple omission authorities.',
          );
        }
        derivations.add({
          'kind': 'source-declared-unrendered-branch',
          'authority': omitted.single.authority,
          'providedWidget': identityHashCode(slot),
        });
      } else if (_isDeclaredUnrenderedSlot(widget, slot)) {
        derivations.add({
          'kind': 'source-declared-unrendered-branch',
          'providedWidget': identityHashCode(slot),
        });
      } else {
        throw const BoxObservationError(
          'UNRESOLVED_SUPPLIED_SLOT_SOURCE',
          'A supplied Widget has no rendered identity and no '
              'declared omission or copy source.',
        );
      }
    }
    return DeclaredBoxProducer._(
      element: producer,
      scope: BoxProducerScope(
        producer: producer,
        suppliedSlots: rendered,
        derivedSuppliedElements: derived,
      ),
      unrenderedSuppliedSlots: absent,
      authority: authority,
      suppliedSlotDerivations: derivations,
      isAdditionalSource: additional != null,
      additionalOutlinedFrame: additional?.outlinedFrame,
    );
  }
  final Element element;
  final BoxProducerScope scope;
  final List<Widget> unrenderedSuppliedSlots;
  final String authority;
  final List<Map<String, Object?>> suppliedSlotDerivations;
  final bool isAdditionalSource;
  final SourceOwnedOutlinedFrame? additionalOutlinedFrame;
}

/// Resolves an already declared semantic producer.
/// No style-owner inference is performed.
Element resolveDeclaringBoxProducer(Element captureRoot, String finder) {
  const byType = 'byType:';
  if (!finder.startsWith(byType)) {
    throw const BoxObservationError(
      'UNSUPPORTED_DECLARING_FINDER',
      'A source declaration is needed for this non-type semantic unit.',
    );
  }
  final declaredType = finder.substring(byType.length);
  return requireOneBoxOwner(
    boxElements(captureRoot).where(
      (element) => element.widget.runtimeType.toString() == declaredType,
    ),
    'the producer named by the existing ProbeSpec finder',
  );
}

/// A finite source binding result for additive observation, never a fallback.
Map<String, Object?> observeDeclaredRootPadding({
  required Element captureRoot,
  required String declaringFinder,
  required String? sourceContract,
  required RenderBox? canonicalFrame,
  Widget? docsSceneConstructorResult,
}) {
  if (sourceContract == null) {
    throw const BoxObservationError(
      'MISSING_BOX_SOURCE_DECLARATION',
      'Regenerate a source-declared manifest before padding observation.',
    );
  }
  final producer = resolveDeclaringBoxProducer(captureRoot, declaringFinder);
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: sourceContract,
    docsSceneConstructorResult: docsSceneConstructorResult,
  );
  final scope = declaration.scope;
  BoxPaddingObservation observation;
  if (declaration.isAdditionalSource) {
    final frame = declaration.additionalOutlinedFrame;
    if (frame == null || frame.authority.isEmpty) {
      throw const BoxObservationError(
        'UNRESOLVED_ADDITIONAL_OWN_FRAME_ROUTE',
        'A slot declaration alone cannot select an existing frame ancestor.',
      );
    }
    scope.requireOwned(frame.primitive);
    observation = observeOutlinedContainerContentPadding(
      primitive: frame.primitive,
      declaringScope: scope,
    );
  } else if (producer.widget is coui.OutlinedContainer) {
    observation = observeOutlinedContainerContentPadding(
      primitive: producer,
      declaringScope: scope,
    );
  } else if (producer.widget is Container) {
    observation = observeCurrentContainerPadding(owner: producer, scope: scope);
  } else {
    if (canonicalFrame == null) {
      throw const BoxObservationError(
        'UNRESOLVED_DECLARED_LAYOUT_OWNER',
        'This producer requires an independent layout-source adapter.',
      );
    }
    final frameElement = requireOneBoxOwner(
      boxElements(captureRoot).where(
        (element) =>
            element is RenderObjectElement &&
            identical(element.renderObject, canonicalFrame),
      ),
      'the exact existing frame primitive',
    );
    scope.requireOwned(frameElement);
    final surfaces = <Element>[];
    frameElement.visitAncestorElements((element) {
      if (element.widget is coui.OutlinedContainer) {
        final surface = element.widget as coui.OutlinedContainer;
        final surfaceScope = BoxProducerScope(
          producer: element,
          suppliedSlots: [?surface.child],
        );
        try {
          surfaceScope.requireOwned(frameElement);
          scope.requireOwned(element);
          surfaces.add(element);
        } on BoxObservationError catch (error) {
          if (error.code != 'FOREIGN_SUPPLIED_CONTENT' &&
              error.code != 'OUTSIDE_DECLARING_PRODUCER') {
            rethrow;
          }
        }
      }
      return !identical(element, producer);
    });
    if (surfaces.isNotEmpty) {
      observation = observeOutlinedContainerContentPadding(
        primitive: requireOneBoxOwner(surfaces, 'the owned shared surface'),
        declaringScope: scope,
      );
    } else if (producer.widget is coui.TextField ||
        producer.widget is coui.TextArea ||
        producer.widget is coui.BottomActionBar ||
        producer.widget is coui.NumberInput ||
        producer.widget is coui.FormattedInput) {
      final frame = containerOwningFrame(
        captureRoot: captureRoot,
        frame: canonicalFrame,
        scope: scope,
      );
      final child = (frame.widget as Container).child;
      late final Element padding;
      if (child is Align && child.child is Padding) {
        final alignment = elementOfDeclaredChild(frame, child);
        padding = elementOfDeclaredChild(alignment, child.child!);
      } else if (child is SafeArea && child.child is Padding) {
        final safeArea = elementOfDeclaredChild(frame, child);
        padding = elementOfDeclaredChild(safeArea, child.child);
      } else {
        throw const BoxObservationError(
          'DECLARED_CONTENT_PADDING_SHAPE_CHANGED',
          'The source-owned content Padding is not at its declared slot.',
        );
      }
      scope.requireOwned(padding);
      observation = _observeContentPadding(padding, scope);
    } else if (producer.widget is coui.Frame) {
      observation = _observeFrameGeneratedPadding(
        frameElement,
        canonicalFrame,
        scope,
      );
    } else if (producer.widget is coui.AppBar) {
      observation = _observeAppBarPadding(frameElement, scope);
    } else if (producer.widget is FlutterDocsSizeSpec) {
      observation = _observeSizeSpecPadding(frameElement, scope);
    } else if (sourceContract == 'docs-playground-frame-padding-v1') {
      observation = _observeDeclaredPlayground(frameElement, scope);
    } else if (producer.widget is coui.Menubar) {
      observation = _observeDeclaredWithinBorder(frameElement, scope);
    } else if (producer.widget is coui.Banner ||
        producer.widget is coui.ValidationBadge ||
        producer.widget is coui.Status ||
        producer.widget is coui.Button ||
        producer.widget is coui.Progress ||
        producer.widget is DocsStage ||
        producer.widget is FlutterDocsCardView) {
      final frame = containerOwningFrame(
        captureRoot: captureRoot,
        frame: canonicalFrame,
        scope: scope,
      );
      observation = observeCurrentContainerPadding(owner: frame, scope: scope);
    } else {
      throw const BoxObservationError(
        'UNSUPPORTED_PADDING_SOURCE',
        'A semantic source adapter is required; no geometric fallback exists.',
      );
    }
  }
  return {
    ...observation.toJson(),
    'sourceContract': sourceContract,
    'declaringFinder': declaringFinder,
    'scopeAuthority': declaration.authority,
    'suppliedSlotDerivations': declaration.suppliedSlotDerivations,
    'suppliedForeignBoundaries': [
      for (final boundary in scope.foreignBoundaries)
        identityHashCode(boundary),
    ],
    'unrenderedSuppliedWidgetReferences': [
      for (final slot in declaration.unrenderedSuppliedSlots)
        identityHashCode(slot),
    ],
  };
}

BoxPaddingObservation _observeContentPadding(
  Element owner,
  BoxProducerScope scope,
) => observeSourceOwnedRenderPadding(owner: owner, scope: scope);

BoxPaddingObservation _observeDeclaredPlayground(
  Element owner,
  BoxProducerScope scope,
) {
  if (owner.widget is! DecoratedBox) {
    throw const BoxObservationError(
      'PLAYGROUND_SOURCE_CHANGED',
      'The declared stage is not the source DecoratedBox.',
    );
  }
  final child = (owner.widget as DecoratedBox).child;
  if (child is! Center) {
    throw const BoxObservationError(
      'PLAYGROUND_BOUNDARY_CHANGED',
      'Own layout ends at the exact source-declared Center boundary.',
    );
  }
  return BoxPaddingObservation(
    value: EdgeInsets.zero,
    quantity: .declaredNoOwnPadding,
    owner: owner,
    producer: scope.producer,
    contentBoundary: elementOfDeclaredChild(owner, child),
    paddingElement: null,
    currentRenderPadding: EdgeInsets.zero,
    allocatedDecorationInsets: EdgeInsets.zero,
    excludedMargin: EdgeInsets.zero,
    generatedSlots: const [],
  );
}

/// Reads explicit source absence after operation/source-path validation.
/// This is not a fallback for a missing padding owner or alignment geometry.
BoxPaddingObservation observePlaygroundDeclaredNoPadding({
  required Element owner,
  required BoxProducerScope scope,
}) {
  scope.requireOwned(owner);
  final widget = owner.widget;
  if (widget.runtimeType != DecoratedBox ||
      owner.renderObject is! RenderDecoratedBox) {
    throw const BoxObservationError(
      'PLAYGROUND_SOURCE_CHANGED',
      'The source absence needs its exact current decorated frame.',
    );
  }
  final decoration = (owner.renderObject! as RenderDecoratedBox).decoration;
  if (decoration is! BoxDecoration || decoration.border != null) {
    throw const BoxObservationError(
      'PLAYGROUND_ALLOCATION_CHANGED',
      'No border allocation is authorized by this closed source route.',
    );
  }
  final center = (widget as DecoratedBox).child;
  if (center is! Center ||
      center.runtimeType != Center ||
      center.child == null) {
    throw const BoxObservationError(
      'PLAYGROUND_BOUNDARY_CHANGED',
      'The source-owned path must end directly at its supplied child Center.',
    );
  }
  final centerElement = elementOfDeclaredChild(owner, center);
  final child = elementOfDeclaredChild(centerElement, center.child!);
  if (!scope.foreignBoundaries.any((boundary) => identical(boundary, child))) {
    throw const BoxObservationError(
      'PLAYGROUND_BOUNDARY_CHANGED',
      'The actual helper-supplied child must remain outside the own frame.',
    );
  }
  return BoxPaddingObservation(
    value: EdgeInsets.zero,
    quantity: .declaredNoOwnPadding,
    owner: owner,
    producer: scope.producer,
    contentBoundary: child,
    paddingElement: null,
    currentRenderPadding: EdgeInsets.zero,
    allocatedDecorationInsets: EdgeInsets.zero,
    excludedMargin: EdgeInsets.zero,
    generatedSlots: const [],
    frameOwner: owner,
  );
}

BoxPaddingObservation _observeDeclaredWithinBorder(
  Element owner,
  BoxProducerScope scope,
) {
  if (owner.widget is! DecoratedBox ||
      owner.renderObject is! RenderDecoratedBox) {
    throw const BoxObservationError(
      'OUTER_EDGE_SOURCE_CHANGED',
      'The explicit source contract requires its exact decorated frame.',
    );
  }
  final child = (owner.widget as DecoratedBox).child;
  final decoration = (owner.renderObject! as RenderDecoratedBox).decoration;
  if (child is! Padding || decoration is! BoxDecoration) {
    throw const BoxObservationError(
      'OUTER_EDGE_PADDING_SOURCE_CHANGED',
      'The source-owned outer-edge Padding is not a direct frame child.',
    );
  }
  final element = elementOfDeclaredChild(owner, child);
  scope.requireOwned(element);
  final render = element.renderObject! as RenderPadding;
  final actual = render.padding.resolve(render.textDirection);
  final border = decoration.border;
  if (border != null && !border.isUniform) {
    throw const BoxObservationError(
      'UNPROVED_DIRECT_BORDER_ALLOCATION',
      'Nonuniform direct-box allocation requires its own source proof.',
    );
  }
  final allocation =
      border?.dimensions.resolve(render.textDirection) ?? EdgeInsets.zero;
  final value = EdgeInsets.fromLTRB(
    actual.left - allocation.left,
    actual.top - allocation.top,
    actual.right - allocation.right,
    actual.bottom - allocation.bottom,
  );
  if ([
    value.left,
    value.top,
    value.right,
    value.bottom,
  ].any((side) => side < 0)) {
    throw const BoxObservationError(
      'UNPROVED_CLAMPED_OUTER_EDGE_ALLOCATION',
      'No clamp or zero substitution is applied to an unsupported source.',
    );
  }
  return BoxPaddingObservation(
    value: value,
    quantity: .declaredOuterEdgeInsetWithinBorder,
    owner: owner,
    producer: scope.producer,
    contentBoundary: child.child == null
        ? null
        : elementOfDeclaredChild(element, child.child!),
    paddingElement: element,
    currentRenderPadding: actual,
    allocatedDecorationInsets: allocation,
    excludedMargin: EdgeInsets.zero,
    generatedSlots: const [],
  );
}

// These functions enumerate public inputs only. They do not grant a current
// frame, absence, observation, or authority across a producer Widget update.
Iterable<Widget> _toggleParameterWidgetSlots(
  Iterable<coui.CoreToggleGroupItem<String, Widget>> items,
) sync* {
  for (final item in items) {
    if (item.runtimeType != coui.CoreToggleGroupItem<String, Widget>) {
      throw const BoxObservationError(
        'UNREGISTERED_CONCRETE_SOURCE_RECORD',
        'ToggleGroup requires exact String/Widget item records.',
      );
    }
    if (item.icon case final icon?) yield icon;
  }
}

Iterable<Widget> _resizableParameterWidgetSlots(
  Iterable<coui.CoreResizablePaneData<Widget>> panes,
) sync* {
  for (final pane in panes) {
    if (pane.runtimeType != coui.CoreResizablePaneData<Widget>) {
      throw const BoxObservationError(
        'UNREGISTERED_CONCRETE_SOURCE_RECORD',
        'Resizable requires exact Widget pane records.',
      );
    }
    yield pane.content;
  }
}

/// Preserves the complete ordered public bag, never a deduplicated view.
/// These exact producers expose Widget refs, not Widget-returning callbacks.
List<Widget> _layoutSuppliedWidgetBag(Iterable<Widget> raw) {
  final slots = <Widget>[];
  final seen = Set<Widget>.identity();
  for (final slot in raw) {
    if (!seen.add(slot)) {
      throw const BoxObservationError(
        'DUPLICATE_SUPPLIED_SLOT_SOURCE',
        'Repeated raw layout Widget identities are ambiguous source inputs.',
      );
    }
    slots.add(slot);
  }
  return slots;
}

Iterable<Widget> _definitionListSuppliedWidgets(
  Iterable<coui.CoreDefinitionEntry<Widget>> items,
) sync* {
  final supplied = Set<Widget>.identity();
  for (final entry in items) {
    if (entry.runtimeType != coui.CoreDefinitionEntry<Widget>) {
      throw const BoxObservationError(
        'UNREGISTERED_CONCRETE_SOURCE_RECORD',
        'DefinitionList requires its audited concrete Widget entry record.',
      );
    }
    if ((entry.descriptionText == null) == (entry.description == null)) {
      throw const BoxObservationError(
        'INVALID_DEFINITION_ENTRY_SOURCE',
        'Exactly one plain or rich description must be declared.',
      );
    }
    if (entry.description case final description?) {
      if (!supplied.add(description)) {
        throw const BoxObservationError(
          'DUPLICATE_SUPPLIED_SLOT_SOURCE',
          'Rich descriptions must retain distinct supplied Widget identities.',
        );
      }
      yield description;
    }
  }
}

Iterable<Widget> _menuSuppliedWidgets(
  Iterable<coui.CoreMenuItem<Widget>> items,
) sync* {
  for (final item in items) {
    if (item.leading case final leading?) yield leading;
    if (item.trailing case final trailing?) yield trailing;
    if (item.submenu case final submenu?) yield* _menuSuppliedWidgets(submenu);
  }
}

BoxPaddingObservation _observeSizeSpecPadding(
  Element frame,
  BoxProducerScope scope,
) {
  // FlutterDocsSizeSpec.build declares Column.children[0] as this frame.
  // The direct Padding belongs to that frame; later table cell Padding is
  // outside this exact source slot and cannot supply the field.
  final producerChild = <Element>[];
  scope.producer.visitChildren(producerChild.add);
  final columnElement = requireOneBoxOwner(
    producerChild,
    'SizeSpec root Column',
  );
  final column = columnElement.widget;
  if (column is! Column ||
      column.children.isEmpty ||
      column.children[0] is! DecoratedBox) {
    throw const BoxObservationError(
      'SIZE_SPEC_SOURCE_CHANGED',
      'The declared source frame is no longer Column.children[0].',
    );
  }
  final renderedSlots = <Element>[];
  columnElement.visitChildren(renderedSlots.add);
  final declaredFrame = requireOneBoxOwner(
    renderedSlots.where(
      (element) => identical(element.widget, column.children[0]),
    ),
    'the actual SizeSpec Column.children[0] Element',
  );
  if (!identical(frame, declaredFrame) || frame.widget is! DecoratedBox) {
    throw const BoxObservationError(
      'SIZE_SPEC_FRAME_CHANGED',
      'The existing frame is not the source-declared SizeSpec frame.',
    );
  }
  final child = (frame.widget as DecoratedBox).child;
  if (child is! Padding) {
    throw const BoxObservationError(
      'SIZE_SPEC_PADDING_CHANGED',
      'The frame no longer directly owns its content Padding.',
    );
  }
  final padding = elementOfDeclaredChild(frame, child);
  scope.requireOwned(padding);
  return _observeContentPadding(padding, scope);
}

void _requireSourceContract({
  required Element producer,
  required String sourceContract,
  required Widget? docsSceneConstructorResult,
}) {
  final widget = producer.widget;
  final typedDocsModel = const {
    DocsStage,
    FlutterDocsSizeSpec,
    FlutterDocsCardView,
  }.contains(widget.runtimeType);
  switch (sourceContract) {
    case 'renderer-frame-padding-v1':
      if (typedDocsModel || docsSceneConstructorResult != null) {
        throw const BoxObservationError(
          'SOURCE_CONTRACT_PRODUCER_MISMATCH',
          'A docs scene requires its own source-construction contract.',
        );
      }
    case 'docs-model-frame-padding-v1':
      if (!typedDocsModel) {
        throw const BoxObservationError(
          'SOURCE_CONTRACT_PRODUCER_MISMATCH',
          'The declared docs-model source is not a typed docs constructor.',
        );
      }
    case 'docs-playground-frame-padding-v1':
      if (typedDocsModel ||
          docsSceneConstructorResult == null ||
          !identical(widget, docsSceneConstructorResult)) {
        throw const BoxObservationError(
          'SOURCE_CONTRACT_PRODUCER_MISMATCH',
          'The declared Playground must be the actual '
              'registry-returned scene Widget.',
        );
      }
    default:
      throw const BoxObservationError(
        'UNSUPPORTED_BOX_SOURCE_VERSION',
        'No observer implements this source declaration version.',
      );
  }
}

BoxPaddingObservation _observeFrameGeneratedPadding(
  Element frame,
  RenderBox frameRender,
  BoxProducerScope scope,
) {
  final owner = containerOwningFrame(
    captureRoot: scope.producer,
    frame: frameRender,
    scope: scope,
  );
  final container = owner.widget as Container;
  final producer = scope.producer.widget as coui.Frame;
  if (container.padding != null) {
    throw const BoxObservationError(
      'FRAME_CONTAINER_SOURCE_CHANGED',
      'Frame allocated its explicit padding in the content slot, '
          'not the chrome Container parameter.',
    );
  }
  final child = container.child;
  if (_isFrameContent(child, producer)) {
    return observeCurrentContainerPadding(owner: owner, scope: scope);
  }
  if (child is! Padding || !_isFrameContent(child.child, producer)) {
    throw const BoxObservationError(
      'FRAME_CONTENT_SOURCE_CHANGED',
      'The exact current content boundary is neither direct '
          'nor behind its declared own Padding.',
    );
  }
  final padding = elementOfDeclaredChild(owner, child);
  scope.requireOwned(padding);
  return _observeContentPadding(padding, scope);
}

bool _isFrameContent(Widget? current, coui.Frame source) {
  final children = source.children ?? [?source.child];
  if (source.direction == null && children.length <= 1) {
    return children.isEmpty
        ? current is SizedBox && current.child == null
        : identical(current, children.single);
  }
  final List<Widget> actual;
  if (current is Row) {
    if (source.direction != .row && source.direction != .rowReverse) {
      return false;
    }
    actual = current.children;
  } else if (current is Column) {
    if (source.direction != null &&
        source.direction != .column &&
        source.direction != .columnReverse) {
      return false;
    }
    actual = current.children;
  } else if (current is Wrap) {
    if (source.direction != .wrap) return false;
    actual = current.children;
  } else {
    return false;
  }
  return actual.length == children.length &&
      List.generate(
        actual.length,
        (i) => identical(actual[i], children[i]),
      ).every((same) => same);
}

BoxPaddingObservation _observeAppBarPadding(
  Element frame,
  BoxProducerScope scope,
) {
  if (frame.widget is! DecoratedBox) {
    throw const BoxObservationError(
      'APP_BAR_FRAME_SOURCE_CHANGED',
      'The solid bar source is a direct decorated frame.',
    );
  }
  final sized = (frame.widget as DecoratedBox).child;
  if (sized is! SizedBox || sized.child == null) {
    throw const BoxObservationError(
      'UNSUPPORTED_APP_BAR_CAST_SOURCE',
      'The separate glass cast layout requires an explicit box-source binding.',
    );
  }
  final sizedElement = elementOfDeclaredChild(frame, sized);
  final content = sized.child!;
  final contentElement = elementOfDeclaredChild(sizedElement, content);
  scope.requireOwned(contentElement);
  if (content is Padding) return _observeContentPadding(contentElement, scope);
  final source = scope.producer.widget as coui.AppBar;
  if (source.variant != .medium || content is! Column) {
    throw const BoxObservationError(
      'APP_BAR_CONTENT_SOURCE_CHANGED',
      'The source branch has no declared root content-padding slot.',
    );
  }
  // Medium places padding on its top-row subrole. Its root Column has no
  // own content inset; that different subrole cannot supply root padding.
  return BoxPaddingObservation(
    value: EdgeInsets.zero,
    quantity: .declaredNoOwnPadding,
    owner: frame,
    producer: scope.producer,
    contentBoundary: contentElement,
    paddingElement: null,
    currentRenderPadding: EdgeInsets.zero,
    allocatedDecorationInsets: EdgeInsets.zero,
    excludedMargin: EdgeInsets.zero,
    generatedSlots: const [],
  );
}

bool _isDeclaredUnrenderedSlot(Widget producer, Widget slot) {
  if (producer is coui.FormLabel &&
      !producer.isRequired &&
      identical(slot, producer.requiredIndicator)) {
    return true;
  }
  if (producer is coui.FormField &&
      producer.label == null &&
      producer.labelWidget == null &&
      identical(slot, producer.labelAction)) {
    return true;
  }
  if (producer is coui.BottomActionBar) {
    final summaryMode =
        producer.layout == .summary || producer.layout == .summaryCompact;
    if (identical(slot, producer.secondaryAction) && summaryMode) {
      return true;
    }
    if ((identical(slot, producer.summaryLabel) ||
            identical(slot, producer.summaryValue)) &&
        !summaryMode) {
      return true;
    }
  }
  if (producer is coui.Card &&
      producer.child != null &&
      !identical(slot, producer.child)) {
    return true;
  }
  if (producer is coui.AppBar &&
      producer.child != null &&
      (identical(slot, producer.header) ||
          identical(slot, producer.subtitle))) {
    return true;
  }
  return false;
}
