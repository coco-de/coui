import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/bottom_sheet/bottom_sheet_close_example.dart';
import 'package:docs_core/previews/examples/web/bottom_sheet/bottom_sheet_default_example.dart';
import 'package:docs_core/previews/examples/web/diff/diff_default_example.dart';
import 'package:docs_core/previews/examples/web/diff/diff_text_example.dart';
import 'package:docs_core/previews/examples/web/swiper/swiper_default_example.dart';
import 'package:docs_core/previews/examples/web/swiper/swiper_sheet_example.dart';
import 'package:docs_core/previews/examples/web/theme_controller/theme_controller_default_example.dart';
import 'package:docs_core/previews/examples/web/tracker/tracker_default_example.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

typedef _Inputs = ({
  List<Component?> slots,
  List<Object> data,
  Map<String, Object?> contract,
});

/// Original public inputs, read on the current concrete producer before any
/// omitted slot is removed. The caller supplies the actual mounted producer.
class DataOverlayWebRawSource {
  DataOverlayWebRawSource._(this.producer, this.source, this._inputs);

  final Component producer;
  final BoxObservationSourceSpec source;
  final _Inputs _inputs;

  List<Component?> get rawSlots => List.unmodifiable(_inputs.slots);

  void validateExistingCurrentBinding() {
    final now = _readInputs(producer, source);
    if (!_sameIdentity(now.slots, _inputs.slots) ||
        !_sameIdentity(now.data, _inputs.data) ||
        jsonEncode(now.contract) != jsonEncode(_inputs.contract)) {
      throw StateError('DATA_OVERLAY_CURRENT_PUBLIC_INPUTS_CHANGED');
    }
  }

  Map<String, Object?> get currentDomContract {
    validateExistingCurrentBinding();
    return Map.unmodifiable(_inputs.contract);
  }
}

DataOverlayWebRawSource bindDataOverlayWebRawSource({
  required Component producer,
  required BoxObservationSourceSpec source,
}) =>
    DataOverlayWebRawSource._(producer, source, _readInputs(producer, source));

bool _sameIdentity(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);

_Inputs _readInputs(Component producer, BoxObservationSourceSpec source) {
  if (!BoxObservationSourceSpec.dataOverlayLayoutFrames.contains(source)) {
    throw StateError('DATA_OVERLAY_CLOSED_RAW_SOURCE_CHANGED');
  }
  final slots = <Component?>[];
  final data = <Object>[];
  final operation = <String, Object?>{};
  if (source == BoxObservationSourceSpec.themeControllerOptionGridLayoutHost) {
    if (producer.runtimeType != coui.ThemeController) {
      throw StateError('DATA_OVERLAY_CONCRETE_THEME_PRODUCER_REQUIRED');
    }
    final input = producer as coui.ThemeController;
    if (input.themes.any(
      (value) => value.runtimeType != coui.CoreThemeOption,
    )) {
      throw StateError('DATA_OVERLAY_CONCRETE_THEME_DATA_REQUIRED');
    }
    data.addAll(input.themes);
    operation['optionCount'] = input.themes.length;
  } else if (source == BoxObservationSourceSpec.trackerSegmentRowLayoutHost) {
    if (producer.runtimeType != coui.Tracker) {
      throw StateError('DATA_OVERLAY_CONCRETE_TRACKER_PRODUCER_REQUIRED');
    }
    final input = producer as coui.Tracker;
    if (input.segments.any(
      (value) => value.runtimeType != coui.CoreTrackerSegment,
    )) {
      throw StateError('DATA_OVERLAY_CONCRETE_TRACKER_DATA_REQUIRED');
    }
    data.addAll(input.segments);
    operation['segmentCount'] = input.segments.length;
  } else if (source == BoxObservationSourceSpec.bottomSheetOuterLayoutHost) {
    if (producer.runtimeType != coui.BottomSheet) {
      throw StateError('DATA_OVERLAY_CONCRETE_SHEET_PRODUCER_REQUIRED');
    }
    final input = producer as coui.BottomSheet;
    slots.addAll([input.title, input.description, input.content, input.footer]);
    operation.addAll({
      'showHandle': input.showHandle,
      'showCloseButton': input.showCloseButton,
      'showDivider': input.showDivider,
    });
  } else if (source == BoxObservationSourceSpec.swiperTriggerLayoutHost) {
    if (producer.runtimeType != coui.Swiper) {
      throw StateError('DATA_OVERLAY_CONCRETE_SWIPER_PRODUCER_REQUIRED');
    }
    final input = producer as coui.Swiper;
    slots.addAll([input.child, input.overlayContent]);
    operation.addAll({
      'position': input.position.name,
      'variant': input.variant.name,
    });
    // input.open is not a current-state witness. The DOM preserves its
    // actual optional aria-expanded; overlayContent is outside the trigger
    // by source in every state, not inferred absent/closed.
  } else if (source == BoxObservationSourceSpec.diffViewerLayoutHost) {
    if (producer.runtimeType != coui.Diff) {
      throw StateError('DATA_OVERLAY_CONCRETE_DIFF_PRODUCER_REQUIRED');
    }
    final input = producer as coui.Diff;
    slots.addAll([
      input.before,
      input.after,
      input.beforeLabel,
      input.afterLabel,
    ]);
    operation['interactive'] = input.interactive;
  } else {
    throw StateError('DATA_OVERLAY_UNSUPPORTED_RAW_SOURCE');
  }
  final unique = Set<Component>.identity();
  for (final slot in slots) {
    if (slot != null && !unique.add(slot)) {
      throw StateError('DATA_OVERLAY_DUPLICATE_RAW_SLOT_BEFORE_OMISSION');
    }
  }
  return (
    slots: List.unmodifiable(slots),
    data: List.unmodifiable(data),
    contract: Map.unmodifiable({
      'kind': 'current-data-overlay-raw-v1',
      'logicalUnitId': source.logicalUnitId,
      'rawSlotCount': slots.length,
      'slotPresence': List<bool>.unmodifiable(
        slots.map((slot) => slot != null),
      ),
      ...operation,
    }),
  );
}

/// Uses the backend's one existing registry build and its actual public tree.
class DataOverlaySsrSource implements CurrentSsrBoxSource {
  DataOverlaySsrSource._(this.entry, this.source, this.exampleType);

  static DataOverlaySsrSource? forEntry(MatrixEntry entry) {
    final sources = entry.probes
        .map((probe) => probe.boxObservationSource)
        .whereType<BoxObservationSourceSpec>()
        .where(
          (source) => BoxObservationSourceSpec.dataOverlayLayoutFrames.any(
            (closed) => closed.logicalUnitId == source.logicalUnitId,
          ),
        )
        .toSet();
    if (sources.isEmpty) {
      return null;
    }
    if (sources.length != 1 ||
        !BoxObservationSourceSpec.dataOverlayLayoutFrames.contains(
          sources.single,
        )) {
      throw StateError('DATA_OVERLAY_CLOSED_SSR_SOURCE_CHANGED');
    }
    final source = sources.single;
    final (expectedSource, exampleType) = switch ((
      entry.component,
      entry.variant,
    )) {
      ('theme-controller', 'default') => (
        BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
        ThemeControllerDefaultExample,
      ),
      ('tracker', 'default') => (
        BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
        TrackerDefaultExample,
      ),
      ('bottom-sheet', 'default') => (
        BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
        BottomSheetDefaultExample,
      ),
      ('bottom-sheet', 'close') => (
        BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
        BottomSheetCloseExample,
      ),
      ('swiper', 'default') => (
        BoxObservationSourceSpec.swiperTriggerLayoutHost,
        SwiperDefaultExample,
      ),
      ('swiper', 'sheet') => (
        BoxObservationSourceSpec.swiperTriggerLayoutHost,
        SwiperSheetExample,
      ),
      ('diff', 'default') => (
        BoxObservationSourceSpec.diffViewerLayoutHost,
        DiffDefaultExample,
      ),
      ('diff', 'text') => (
        BoxObservationSourceSpec.diffViewerLayoutHost,
        DiffTextExample,
      ),
      _ => throw StateError('DATA_OVERLAY_SSR_RECIPE_CHANGED'),
    };
    if (source != expectedSource) {
      throw StateError('DATA_OVERLAY_SSR_RECIPE_SOURCE_CHANGED');
    }
    return DataOverlaySsrSource._(entry, source, exampleType);
  }

  final MatrixEntry entry;
  final BoxObservationSourceSpec source;
  final Type exampleType;
  Component? _registryResult;
  div? _capture;

  @override
  void recordBuild(Component result, div capture) {
    if (_registryResult != null || _capture != null) {
      throw StateError('DATA_OVERLAY_SSR_BUILD_REPEATED');
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
        capture.children.length != 1 ||
        !identical(capture.children.single, result) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('DATA_OVERLAY_CAPTURE_SOURCE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final registryElement = currentSsrIdentityElement(root, result);
    if (!identical(registryElement.parent, captureDom)) {
      throw StateError('DATA_OVERLAY_REGISTRY_EDGE_CHANGED');
    }
    var exampleElement = registryElement;
    if (source == BoxObservationSourceSpec.swiperTriggerLayoutHost) {
      if (result.runtimeType != div) {
        throw StateError('DATA_OVERLAY_SWIPER_REGISTRY_WRAPPER_CHANGED');
      }
      final wrapper = result as div;
      if (wrapper.children.length != 1 || wrapper.classes != 'w-full') {
        throw StateError('DATA_OVERLAY_SWIPER_DECLARED_WRAPPER_CHANGED');
      }
      final wrapperDom = currentSsrGeneratedDiv(registryElement, wrapper);
      exampleElement = soleCurrentSsrChild(wrapperDom);
      if (!identical(exampleElement.component, wrapper.children.single)) {
        throw StateError('DATA_OVERLAY_SWIPER_EXAMPLE_EDGE_CHANGED');
      }
    }
    if (exampleElement.component.runtimeType != exampleType) {
      throw StateError('DATA_OVERLAY_CANONICAL_EXAMPLE_CHANGED');
    }
    final producerElement = soleCurrentSsrChild(exampleElement);
    final producer = producerElement.component;
    final raw = bindDataOverlayWebRawSource(producer: producer, source: source);
    final before = raw.currentDomContract;
    // Complete original raw references were already checked for aliases.
    // Whole supplied subtrees stay foreign. Only Swiper's overlay reference
    // is outside the trigger by its unconditional public source route.
    for (var index = 0; index < raw.rawSlots.length; index++) {
      final slot = raw.rawSlots[index];
      if (slot == null) {
        continue;
      }
      if (source == BoxObservationSourceSpec.swiperTriggerLayoutHost &&
          index == 1) {
        if (_identityCount(producerElement, slot) != 0) {
          throw StateError('DATA_OVERLAY_OVERLAY_INSIDE_TRIGGER');
        }
      } else {
        currentSsrIdentityElement(producerElement, slot);
      }
    }
    raw.validateExistingCurrentBinding();
    final after = raw.currentDomContract;
    if (!identical(captureElement.component, _capture) ||
        !identical(registryElement.component, _registryResult) ||
        !identical(producerElement.component, raw.producer) ||
        jsonEncode(before) != jsonEncode(after)) {
      throw StateError('DATA_OVERLAY_CURRENT_SOURCE_CHANGED');
    }
    return {
      'kind': 'canonical-ssr-data-overlay-v1',
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': after,
      'completeRawSlotCount': raw.rawSlots.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }
}

int _identityCount(Element root, Component component) {
  var count = 0;
  void visit(Element element) {
    if (identical(element.component, component)) {
      count++;
    }
    element.visitChildren(visit);
  }

  visit(root);
  return count;
}
