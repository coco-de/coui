import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:jaspr/jaspr.dart' show Component;

import '../model/box_observation_source_spec.dart';

typedef _Inputs = ({List<Component?> slots, Map<String, Object?> contract});

/// The original concrete public producer inputs, before constructor omissions.
/// No builder, formatter, resolver or private State is invoked by this reader.
class VisualValueWebRawSource {
  VisualValueWebRawSource._(this.producer, this.source, this._inputs);

  final Component producer;
  final BoxObservationSourceSpec source;
  final _Inputs _inputs;

  List<Component?> get rawSlots => List.unmodifiable(_inputs.slots);

  void validateExistingCurrentBinding() {
    final now = _readInputs(producer, source);
    if (now.slots.length != _inputs.slots.length ||
        List.generate(
          now.slots.length,
          (i) => identical(now.slots[i], _inputs.slots[i]),
        ).any((same) => !same) ||
        jsonEncode(now.contract) != jsonEncode(_inputs.contract)) {
      throw StateError('VISUAL_VALUE_CURRENT_INPUTS_CHANGED');
    }
  }

  Map<String, Object?> get currentDomContract {
    validateExistingCurrentBinding();
    return Map.unmodifiable(_inputs.contract);
  }
}

VisualValueWebRawSource bindVisualValueWebRawSource({
  required Component producer,
  required BoxObservationSourceSpec source,
}) =>
    VisualValueWebRawSource._(producer, source, _readInputs(producer, source));

_Inputs _readInputs(Component producer, BoxObservationSourceSpec source) {
  if (!BoxObservationSourceSpec.visualValueFrames.contains(source)) {
    throw StateError('VISUAL_VALUE_CLOSED_RAW_SOURCE_CHANGED');
  }
  final slots = <Component?>[];
  final operation = <String, Object?>{};
  if (source == BoxObservationSourceSpec.iconVisualFrame) {
    if (producer.runtimeType != coui.Icon) {
      throw StateError('VISUAL_VALUE_CONCRETE_ICON_REQUIRED');
    }
    final icon = (producer as coui.Icon).icon;
    if (icon.runtimeType != coui.IconName &&
        icon.runtimeType != coui.StyledIconName) {
      throw StateError('VISUAL_VALUE_UNKNOWN_ICON_DATA');
    }
  } else if (source == BoxObservationSourceSpec.numberTickerTextLayoutHost) {
    if (producer.runtimeType != coui.NumberTicker) {
      throw StateError('VISUAL_VALUE_CONCRETE_TICKER_REQUIRED');
    }
    final input = producer as coui.NumberTicker;
    // Retain the nullable raw child before deciding whether this mode has
    // source authority. Custom builder/formatter modes remain unsupported.
    slots.add(input.child);
    final unique = Set<Component>.identity();
    for (final slot in slots) {
      if (slot != null && !unique.add(slot)) {
        throw StateError('VISUAL_VALUE_DUPLICATE_RAW_BEFORE_OMISSION');
      }
    }
    if (input.builder != null ||
        input.formatter != null ||
        input.child != null) {
      throw StateError('VISUAL_VALUE_TICKER_PLAIN_MODE_REQUIRED');
    }
    operation['plainMode'] = true;
  } else if (source == BoxObservationSourceSpec.skeletonTextLinesLayoutHost) {
    if (producer.runtimeType != coui.Skeleton ||
        (producer as coui.Skeleton).variant != coui.CoreSkeletonVariant.text) {
      throw StateError('VISUAL_VALUE_CONCRETE_TEXT_SKELETON_REQUIRED');
    }
  } else if (source == BoxObservationSourceSpec.countdownValueLayoutHost) {
    if (producer.runtimeType != coui.Countdown) {
      throw StateError('VISUAL_VALUE_CONCRETE_COUNTDOWN_REQUIRED');
    }
  } else {
    throw StateError('VISUAL_VALUE_UNSUPPORTED_RAW_SOURCE');
  }
  return (
    slots: List.unmodifiable(slots),
    contract: Map.unmodifiable({
      'kind': 'current-visual-value-raw-v1',
      'logicalUnitId': source.logicalUnitId,
      'rawSlotCount': slots.length,
      'slotPresence': List<bool>.unmodifiable(
        slots.map((slot) => slot != null),
      ),
      ...operation,
    }),
  );
}
