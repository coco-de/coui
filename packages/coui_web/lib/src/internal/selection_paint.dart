import 'package:meta/meta.dart';

/// Registers the real per-root selection-color paint utility.
@internal
const kSelectableSelectionUtility = 'co-selectable-selection';

/// Selects only this root; the built-in selection variant includes descendants.
@internal
const kSelectableRootSelectionVariant = 'co-root-selection';

/// Pairs the semantic variant and fixed paint utility on its owner.
@internal
const kSelectableSelectionMarker =
    '$kSelectableRootSelectionVariant:$kSelectableSelectionUtility';

/// Carries that root's selection tint without encoding a value in a class.
@internal
const kSelectableSelectionColorVar = '--co-selectable-selection-color';
