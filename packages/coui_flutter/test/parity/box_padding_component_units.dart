import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/code_diff/code_diff_default_example.dart';
import 'package:docs_core/previews/examples/flutter/command/command_default_example.dart';
import 'package:docs_core/previews/examples/flutter/command/command_empty_example.dart';
import 'package:docs_core/previews/examples/flutter/command/command_scrollable_example.dart';
import 'package:docs_core/previews/examples/flutter/fieldset/fieldset_default_example.dart';
import 'package:docs_core/previews/examples/flutter/fieldset/fieldset_outlined_example.dart';
import 'package:docs_core/previews/examples/flutter/fieldset/fieldset_plain_example.dart';
import 'package:docs_core/previews/examples/flutter/item_picker/item_picker_default_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_browser_example.dart';
import 'package:docs_core/previews/examples/flutter/object_input/object_input_default_example.dart';
import 'package:flutter/widgets.dart'
    show Element, KeyedSubtree, SizedBox, Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_scope_extensions.dart';

/// Source references only; the coordinator's shared reader observes values.
typedef ComponentBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Binds audited, single-producer examples to their actual generated frame.
///
/// Exact example types describe key-only constructors, not arbitrary caller
/// wrappers. No registry, builder, callback or factory is invoked here. The
/// existing A declaration checks each producer's scalar/list/nested slots.
ComponentBoxSourceBinding? bindComponentBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.schemaVersion != 1) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_SOURCE_VERSION',
      'The component construction source version is not implemented.',
    );
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_QUANTITY',
      'The source must declare the existing own-content inset quantity.',
    );
  }
  final adapter = switch (source.logicalUnitId) {
    'code-diff-generated-frame' => 'code-diff-generated-frame-v1',
    'command-panel-generated-frame' => 'command-panel-generated-frame-v1',
    'fieldset-generated-frame' => 'fieldset-generated-frame-v1',
    'item-picker-generated-frame' => 'item-picker-generated-frame-v1',
    'mockup-browser-generated-frame' => 'mockup-browser-generated-frame-v1',
    'object-input-generated-frame' => 'object-input-generated-frame-v1',
    _ => null,
  };
  if (adapter == null) return null;
  if (source.nativeAdapterId != adapter || source.webAdapterId != adapter) {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The logical unit and both source adapters must match exactly.',
    );
  }
  final captured = captureRoot.widget;
  if (!identical(captured, registryResult) &&
      !(captured is KeyedSubtree &&
          identical(captured.child, registryResult))) {
    throw const BoxObservationError(
      'MISMATCHED_CONSTRUCTION_RESULT',
      'The registry result is not the actual keyed capture child.',
    );
  }
  final result = requireOneBoxOwner(
    boxElements(captureRoot).where(
      (element) => identical(element.widget, registryResult),
    ),
    'the actual mounted component registry result',
  );
  final Type expectedProducer;
  final bool sizedExample;
  final exampleType = registryResult.runtimeType;
  switch (adapter) {
    case 'code-diff-generated-frame-v1':
      _requireExample(exampleType == CodeDiffDefaultExample);
      expectedProducer = coui.CodeDiff;
      sizedExample = false;
    case 'command-panel-generated-frame-v1':
      _requireExample(
        exampleType == CommandDefaultExample ||
            exampleType == CommandScrollableExample ||
            exampleType == CommandEmptyExample,
      );
      expectedProducer = coui.Command;
      sizedExample = false;
    case 'fieldset-generated-frame-v1':
      _requireExample(
        exampleType == FieldsetDefaultExample ||
            exampleType == FieldsetOutlinedExample ||
            exampleType == FieldsetPlainExample,
      );
      expectedProducer = coui.Fieldset;
      sizedExample = true;
    case 'item-picker-generated-frame-v1':
      _requireExample(exampleType == ItemPickerDefaultExample);
      expectedProducer = coui.ItemPicker;
      sizedExample = false;
    case 'mockup-browser-generated-frame-v1':
      _requireExample(exampleType == MockupBrowserExample);
      expectedProducer = coui.MockupBrowser;
      sizedExample = true;
    case 'object-input-generated-frame-v1':
      _requireExample(exampleType == ObjectInputDefaultExample);
      expectedProducer = coui.ObjectInput;
      sizedExample = false;
    default:
      throw const BoxObservationError(
        'UNSUPPORTED_COMPONENT_BOX_ADAPTER',
        'No audited component construction route implements this adapter.',
      );
  }
  var producer = _generatedChild(result);
  if (sizedExample) {
    final sized = producer.widget;
    if (sized is! SizedBox ||
        sized.runtimeType != SizedBox ||
        sized.child == null) {
      throw const BoxObservationError(
        'COMPONENT_EXAMPLE_SOURCE_CHANGED',
        'The example must return its declared SizedBox with an actual child.',
      );
    }
    producer = requireOneBoxOwner(
      boxElements(producer).where(
        (element) => identical(element.widget, sized.child),
      ),
      'the example SizedBox.child Widget object',
    );
  }
  if (producer.widget.runtimeType != expectedProducer) {
    throw const BoxObservationError(
      'COMPONENT_EXAMPLE_SOURCE_CHANGED',
      'The actual generated child is not the audited concrete producer.',
    );
  }
  final declaration = describeAdditionalBoxProducerSource(producer);
  final frame = declaration?.outlinedFrame;
  if (declaration == null || frame == null) {
    throw const BoxObservationError(
      'MISSING_COMPONENT_FRAME_SOURCE',
      'The actual producer has no adopted source-owned frame route.',
    );
  }
  // All audited examples accept no Widget-valued constructor inputs. Their
  // internally built producer is owned, while the producer's public content
  // slots remain foreign even when they contain another outlined primitive.
  final scope =
      BoxProducerScope(
          producer: result,
          suppliedSlots: declaration.supplied.where(
            (slot) => !declaration.sourceOmitted.any(
              (omission) => identical(omission.widget, slot),
            ),
          ),
        )
        ..requireOwned(producer)
        ..requireOwned(frame.primitive);
  return (
    authority:
        'Audited key-only example actual generated child; '
        '${declaration.authority}; ${frame.authority}',
    registryResultElement: result,
    fieldUnitElement: producer,
    paddingSource: frame.primitive,
    frameSource: frame.primitive,
    scope: scope,
    readerId: 'outlined-content-v1',
  );
}

void _requireExample(bool matches) {
  if (matches) return;
  throw const BoxObservationError(
    'UNREGISTERED_COMPONENT_CONSTRUCTION',
    'Only an exact audited example class supplies this construction unit.',
  );
}

Element _generatedChild(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the actual generated example child');
}
