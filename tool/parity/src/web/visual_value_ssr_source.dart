import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/countdown/countdown_default_example.dart';
import 'package:docs_core/previews/examples/web/icon/icon_default_example.dart';
import 'package:docs_core/previews/examples/web/icon/icon_favorite_example.dart';
import 'package:docs_core/previews/examples/web/icon/icon_search_example.dart';
import 'package:docs_core/previews/examples/web/number_ticker/number_ticker_default_example.dart';
import 'package:docs_core/previews/examples/web/skeleton/skeleton_text_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div, span;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';
import 'visual_value_web_raw_source.dart';

export 'visual_value_web_raw_source.dart';

/// Passive source binding on the original registry build and mounted tree.
/// Generated child declarations and their already executed Elements establish
/// full order. The markup of that exact DOM owner supplies SVG RawText glyph
/// children and Skeleton's actual line count; no Core/Resolved count is read.
class VisualValueSsrSource implements CurrentSsrBoxSource {
  VisualValueSsrSource._(this.entry, this.source, this.exampleType);

  static VisualValueSsrSource? forEntry(MatrixEntry entry) {
    final sources = entry.probes
        .map((probe) => probe.boxObservationSource)
        .whereType<BoxObservationSourceSpec>()
        .where(
          (source) => BoxObservationSourceSpec.visualValueFrames.any(
            (closed) => closed.logicalUnitId == source.logicalUnitId,
          ),
        )
        .toSet();
    if (sources.isEmpty) return null;
    if (sources.length != 1 ||
        !BoxObservationSourceSpec.visualValueFrames.contains(sources.single)) {
      throw StateError('VISUAL_VALUE_CLOSED_SSR_SOURCE_CHANGED');
    }
    final source = sources.single;
    final (expected, exampleType) = switch ((entry.component, entry.variant)) {
      ('icon', 'default') => (
        BoxObservationSourceSpec.iconVisualFrame,
        IconDefaultExample,
      ),
      ('icon', 'search') => (
        BoxObservationSourceSpec.iconVisualFrame,
        IconSearchExample,
      ),
      ('icon', 'favorite') => (
        BoxObservationSourceSpec.iconVisualFrame,
        IconFavoriteExample,
      ),
      ('number-ticker', 'default') => (
        BoxObservationSourceSpec.numberTickerTextLayoutHost,
        NumberTickerDefaultExample,
      ),
      ('skeleton', 'text') => (
        BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
        SkeletonTextExample,
      ),
      ('countdown', 'default') => (
        BoxObservationSourceSpec.countdownValueLayoutHost,
        CountdownDefaultExample,
      ),
      _ => throw StateError('VISUAL_VALUE_SSR_RECIPE_CHANGED'),
    };
    if (source != expected) {
      throw StateError('VISUAL_VALUE_SSR_RECIPE_SOURCE_CHANGED');
    }
    return VisualValueSsrSource._(entry, source, exampleType);
  }

  final MatrixEntry entry;
  final BoxObservationSourceSpec source;
  final Type exampleType;
  Component? _registryResult;
  div? _capture;

  @override
  void recordBuild(Component result, div capture) {
    if (_registryResult != null || _capture != null) {
      throw StateError('VISUAL_VALUE_SSR_BUILD_REPEATED');
    }
    _registryResult = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final registry = _registryResult;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != exampleType ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('VISUAL_VALUE_CANONICAL_CAPTURE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final registryElement = currentSsrIdentityElement(root, registry);
    if (!identical(registryElement.parent, captureDom)) {
      throw StateError('VISUAL_VALUE_REGISTRY_EDGE_CHANGED');
    }
    // Each reviewed Example directly returns its actual public producer.
    // No new Example build and no private State lookup is performed.
    final producerElement = soleCurrentSsrChild(registryElement);
    final raw = bindVisualValueWebRawSource(
      producer: producerElement.component,
      source: source,
    );
    final built = soleCurrentSsrChild(producerElement);
    Element owner;
    if (source == BoxObservationSourceSpec.numberTickerTextLayoutHost ||
        source == BoxObservationSourceSpec.countdownValueLayoutHost) {
      if (built.component.runtimeType != span) {
        throw StateError('VISUAL_VALUE_GENERATED_SPAN_REQUIRED');
      }
      final declared = built.component as span;
      owner = soleCurrentSsrChild(built);
      _declaredDomChildren(owner, 'span', declared.children);
      if (declared.children.length != 1 ||
          declared.children.single.runtimeType != coui.Text) {
        throw StateError('VISUAL_VALUE_GENERATED_TEXT_REQUIRED');
      }
    } else {
      owner = built;
      final component = owner.component;
      if (component is! DomComponent) {
        throw StateError('VISUAL_VALUE_GENERATED_DOM_REQUIRED');
      }
      final declared = component.children ?? const <Component>[];
      _declaredDomChildren(owner, component.tag, declared);
      if (source == BoxObservationSourceSpec.skeletonTextLinesLayoutHost) {
        _validateSkeletonDeclarations(component.tag, declared);
      } else {
        _validateIconDeclarations(component.tag, declared);
      }
    }
    if (owner is! RenderObjectElement ||
        owner.renderObject is! MarkupRenderObject) {
      throw StateError('VISUAL_VALUE_ACTUAL_MARKUP_OWNER_REQUIRED');
    }
    final markup = owner.renderObject as MarkupRenderObject;
    final before = markup.renderToHtml();
    final parsed = html.parseFragment(before);
    final formattingWhitespace = RegExp(r'^[\t\n\f\r ]*$');
    if (parsed.children.length != 1 ||
        parsed.children.single.localName !=
            (owner.component as DomComponent).tag ||
        parsed.nodes.any(
          (node) =>
              !identical(node, parsed.children.single) &&
              !(node is dom.Text && formattingWhitespace.hasMatch(node.data)),
        )) {
      // Element.children alone would hide a malformed RawText SVG that
      // closes the root and emits a non-whitespace text sibling.
      throw StateError('VISUAL_VALUE_MARKUP_ROOT_CHANGED');
    }
    final generatedTree = _generatedTree(parsed.children.single);
    raw.validateExistingCurrentBinding();
    if (!identical(captureElement.component, _capture) ||
        !identical(registryElement.component, _registryResult) ||
        !identical(producerElement.component, raw.producer) ||
        markup.renderToHtml() != before) {
      throw StateError('VISUAL_VALUE_CURRENT_SOURCE_CHANGED');
    }
    return {
      'kind': 'canonical-ssr-visual-value-v1',
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': {...raw.currentDomContract, 'generatedTree': generatedTree},
      'completeRawSlotCount': raw.rawSlots.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }
}

void _declaredDomChildren(Element owner, String tag, List<Component> declared) {
  final component = owner.component;
  if (component is! DomComponent || component.tag != tag) {
    throw StateError('VISUAL_VALUE_DOM_DECLARATION_CHANGED');
  }
  final children = component.children ?? const <Component>[];
  final actual = <Element>[];
  owner.visitChildren(actual.add);
  final unique = Set<Component>.identity()..addAll(declared);
  if (children.length != declared.length ||
      actual.length != declared.length ||
      unique.length != declared.length) {
    throw StateError('VISUAL_VALUE_COMPLETE_GENERATED_CHILDREN_CHANGED');
  }
  for (var i = 0; i < declared.length; i++) {
    if (!identical(children[i], declared[i]) ||
        !identical(actual[i].component, declared[i]) ||
        !identical(actual[i].parent, owner)) {
      throw StateError('VISUAL_VALUE_GENERATED_ORDER_CHANGED');
    }
  }
}

void _validateSkeletonDeclarations(String tag, List<Component> children) {
  if (tag != 'div') throw StateError('VISUAL_VALUE_SKELETON_ROOT_CHANGED');
  var announcerSeen = false;
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    if (child is! DomComponent) {
      throw StateError('VISUAL_VALUE_SKELETON_GENERATED_CHILD_CHANGED');
    }
    if (child.tag == 'div' &&
        !announcerSeen &&
        (child.children == null || child.children!.isEmpty)) {
      continue;
    }
    if (child.tag != 'span' ||
        i != children.length - 1 ||
        announcerSeen ||
        child.children?.length != 1 ||
        child.children!.single.runtimeType != coui.Text) {
      throw StateError('VISUAL_VALUE_SKELETON_ANNOUNCER_CHANGED');
    }
    announcerSeen = true;
  }
}

void _validateIconDeclarations(String tag, List<Component> children) {
  if (tag == 'svg' && children.length == 1 && children.single is coui.RawText) {
    return;
  }
  if (tag == 'iconify-icon' && children.length == 1) {
    final child = children.single;
    if (child is DomComponent &&
        child.tag == 'coui-iconify-stroke' &&
        (child.children == null || child.children!.isEmpty)) {
      return;
    }
  }
  throw StateError('VISUAL_VALUE_ICON_GENERATED_CHILDREN_CHANGED');
}

Map<String, Object?> _generatedTree(dom.Element element) => {
  'namespaceURI': element.namespaceUri,
  'localName': element.localName,
  'children': element.children.map(_generatedTree).toList(growable: false),
};
