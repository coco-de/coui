import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/command_search/command_search_default_example.dart';
import 'package:docs_core/previews/examples/web/dock/dock_default_example.dart';
import 'package:docs_core/previews/examples/web/navigation_bar/navigation_bar_default_example.dart';
import 'package:docs_core/previews/examples/web/navigation_bar/navigation_bar_rail_example.dart';
import 'package:docs_core/previews/examples/web/navigation_bar/navigation_bar_sidebar_example.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'box_padding_navigation_trigger_units_probe.dart';
import 'ssr_source_identity.dart';

/// Reads the actual SSR producer, without constructing or rebuilding it.
///
/// The registry result and capture wrapper are retained in their original
/// build. Public element identities connect that exact result to its current
/// producer. Raw slot order comes from the producer's public lists.
class NavigationTriggerSsrSource implements CurrentSsrBoxSource {
  NavigationTriggerSsrSource._(this.entry, this.source, this.exampleType);

  static NavigationTriggerSsrSource? forEntry(MatrixEntry entry) {
    final sources = entry.probes
        .map((probe) => probe.boxObservationSource)
        .whereType<BoxObservationSourceSpec>()
        .where(
          BoxObservationSourceSpec.navigationTriggerParameterFrames.contains,
        )
        .toSet();
    if (sources.isEmpty) return null;
    if (sources.length != 1) {
      throw StateError('NAVIGATION_TRIGGER_MULTIPLE_SSR_SOURCES');
    }
    final source = sources.single;
    final Type exampleType;
    switch ((entry.component, entry.variant)) {
      case ('command-search', 'default'):
        if (source !=
            BoxObservationSourceSpec.commandSearchTriggerContentInset) {
          throw StateError('COMMAND_SEARCH_SSR_SOURCE_CHANGED');
        }
        exampleType = CommandSearchDefaultExample;
      case ('navigation-bar', final variant):
        if (source != BoxObservationSourceSpec.navigationBarItemsContentInset) {
          throw StateError('NAVIGATION_BAR_SSR_SOURCE_CHANGED');
        }
        exampleType = switch (variant) {
          'default' => NavigationBarDefaultExample,
          'rail' => NavigationBarRailExample,
          'sidebar' => NavigationBarSidebarExample,
          _ => throw StateError('NAVIGATION_BAR_SSR_RECIPE_CHANGED'),
        };
      case ('dock', 'default'):
        if (source != BoxObservationSourceSpec.dockBarContentInset) {
          throw StateError('DOCK_SSR_SOURCE_CHANGED');
        }
        exampleType = DockDefaultExample;
      default:
        throw StateError('NAVIGATION_TRIGGER_SSR_RECIPE_CHANGED');
    }
    return NavigationTriggerSsrSource._(entry, source, exampleType);
  }

  final MatrixEntry entry;
  final BoxObservationSourceSpec source;
  final Type exampleType;
  Component? _registryResult;
  div? _capture;

  /// Called only by the existing registry build, using its original objects.
  @override
  void recordBuild(Component result, div capture) {
    if (_registryResult != null || _capture != null) {
      throw StateError('NAVIGATION_TRIGGER_SSR_BUILD_REPEATED');
    }
    _registryResult = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final result = _registryResult;
    final capture = _capture;
    if (result == null ||
        capture == null ||
        result.runtimeType != exampleType) {
      throw StateError('NAVIGATION_TRIGGER_CANONICAL_REGISTRY_CHANGED');
    }
    if (capture.children.length != 1 ||
        !identical(capture.children.single, result) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('NAVIGATION_TRIGGER_CAPTURE_SOURCE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final registryElement = currentSsrIdentityElement(root, result);
    if (!identical(registryElement.parent, captureDom)) {
      throw StateError('NAVIGATION_TRIGGER_REGISTRY_EDGE_CHANGED');
    }
    var producerElement = soleCurrentSsrChild(registryElement);
    if (entry.component == 'command-search') {
      final wrapper = producerElement.component;
      if (wrapper is! div || wrapper.children.length != 1) {
        throw StateError('COMMAND_SEARCH_AUTHORED_WRAPPER_CHANGED');
      }
      final wrapperDom = currentSsrGeneratedDiv(producerElement, wrapper);
      final declared = wrapper.children.single;
      producerElement = soleCurrentSsrChild(wrapperDom);
      if (!identical(producerElement.component, declared)) {
        throw StateError('COMMAND_SEARCH_DECLARED_PRODUCER_CHANGED');
      }
    }
    final producer = producerElement.component;
    final expectedProducer = switch (entry.component) {
      'command-search' => coui.CommandSearch,
      'navigation-bar' => coui.NavigationBar,
      'dock' => coui.Dock,
      _ => throw StateError('NAVIGATION_TRIGGER_SSR_RECIPE_CHANGED'),
    };
    if (producer.runtimeType != expectedProducer) {
      throw StateError('NAVIGATION_TRIGGER_CURRENT_PRODUCER_CHANGED');
    }
    final raw = bindNavigationTriggerWebRawSource(
      producer: producer,
      source: source,
    );
    final before = raw.currentDomContract;
    raw.validateExistingCurrentBinding();
    final after = raw.currentDomContract;
    if (!identical(registryElement.component, _registryResult) ||
        !identical(captureElement.component, _capture) ||
        !identical(producerElement.component, raw.producer) ||
        jsonEncode(before) != jsonEncode(after)) {
      throw StateError('NAVIGATION_TRIGGER_CURRENT_SOURCE_CHANGED');
    }
    return {
      'kind': 'canonical-ssr-navigation-trigger-v1',
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': after,
      'completeRawSlotCount': raw.rawSlots.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }
}
