import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/banner/banner_default_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_destructive_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_info_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_narrow_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_solid_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_success_example.dart';
import 'package:docs_core/previews/examples/flutter/banner/banner_warning_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_default_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_filled_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_ghost_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_placeholder_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_space_between_example.dart';
import 'package:docs_core/previews/examples/flutter/description_card/description_card_vertical_example.dart';
import 'package:docs_core/previews/examples/flutter/formatted_input/formatted_input_credit_card_example.dart';
import 'package:docs_core/previews/examples/flutter/formatted_input/formatted_input_date_example.dart';
import 'package:docs_core/previews/examples/flutter/formatted_input/formatted_input_default_example.dart';
import 'package:docs_core/previews/examples/flutter/formatted_input/formatted_input_korean_phone_example.dart';
import 'package:docs_core/previews/examples/flutter/formatted_input/formatted_input_verify_example.dart';
import 'package:docs_core/previews/examples/flutter/frame/frame_column_example.dart';
import 'package:docs_core/previews/examples/flutter/frame/frame_dashed_example.dart';
import 'package:docs_core/previews/examples/flutter/frame/frame_default_example.dart';
import 'package:docs_core/previews/examples/flutter/frame/frame_elevated_example.dart';
import 'package:flutter/widgets.dart'
    show
        Align,
        AnimatedContainer,
        ConstrainedBox,
        Container,
        CustomPaint,
        DecoratedBox,
        Element,
        Flexible,
        Focus,
        GestureDetector,
        ImageFiltered,
        KeyedSubtree,
        MouseRegion,
        Opacity,
        Padding,
        Semantics,
        SizedBox,
        Transform,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

/// The same seven named source-reference fields consumed by the coordinator.
typedef ExtendedComponentBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Binds an actual mounted producer or its exact audited registry example.
/// No factory/build/callback, expected style or measured value is consulted.
ExtendedComponentBoxSourceBinding? bindExtendedComponentBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.schemaVersion != 1) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_SOURCE_VERSION',
      'This extended construction source version is not implemented.',
    );
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_QUANTITY',
      'This source requires the existing own-content inset quantity.',
    );
  }
  final adapter = switch (source.logicalUnitId) {
    'banner-generated-frame' => 'banner-generated-frame-v1',
    'description-card-generated-frame' => 'description-card-generated-frame-v1',
    'formatted-input-generated-frame' => 'formatted-input-generated-frame-v1',
    'frame-generated-content-inset' => 'frame-generated-content-inset-v1',
    _ => null,
  };
  if (adapter == null) return null;
  if (source.nativeAdapterId != adapter || source.webAdapterId != adapter) {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The logical unit and both adapters must form one closed source tuple.',
    );
  }
  final root = captureRoot.widget;
  if (!identical(root, registryResult) &&
      !(root is KeyedSubtree && identical(root.child, registryResult))) {
    throw const BoxObservationError(
      'MISMATCHED_CONSTRUCTION_RESULT',
      'The declared registry result is not the actual capture child.',
    );
  }
  final result = requireOneBoxOwner(
    boxElements(captureRoot).where(
      (element) => identical(element.widget, registryResult),
    ),
    'the actual extended component construction result',
  );
  final example = registryResult.runtimeType;
  final Type producerType;
  final bool auditedExample;
  switch (adapter) {
    case 'banner-generated-frame-v1':
      producerType = coui.Banner;
      auditedExample = [
        BannerDefaultExample,
        BannerInfoExample,
        BannerWarningExample,
        BannerDestructiveExample,
        BannerSuccessExample,
        BannerSolidExample,
        BannerNarrowExample,
      ].contains(example);
    case 'description-card-generated-frame-v1':
      producerType = coui.DescriptionCard;
      auditedExample = [
        DescriptionCardDefaultExample,
        DescriptionCardFilledExample,
        DescriptionCardGhostExample,
        DescriptionCardVerticalExample,
        DescriptionCardSpaceBetweenExample,
        DescriptionCardPlaceholderExample,
      ].contains(example);
    case 'formatted-input-generated-frame-v1':
      producerType = coui.FormattedInput;
      auditedExample = [
        FormattedInputDefaultExample,
        FormattedInputKoreanPhoneExample,
        FormattedInputCreditCardExample,
        FormattedInputDateExample,
        FormattedInputVerifyExample,
      ].contains(example);
    case 'frame-generated-content-inset-v1':
      producerType = coui.Frame;
      auditedExample = [
        FrameDefaultExample,
        FrameColumnExample,
        FrameDashedExample,
        FrameElevatedExample,
      ].contains(example);
    default:
      throw const BoxObservationError(
        'UNSUPPORTED_EXTENDED_COMPONENT_ADAPTER',
        'No source route implements this construction adapter.',
      );
  }
  final direct = example == producerType;
  if (!direct && !auditedExample) {
    throw const BoxObservationError(
      'UNREGISTERED_COMPONENT_CONSTRUCTION',
      'Only an exact audited example or concrete producer is supported.',
    );
  }
  var producer = direct ? result : _generatedChild(result);
  if (example == BannerNarrowExample) {
    final widget = producer.widget;
    if (widget is! SizedBox || widget.runtimeType != SizedBox) {
      throw _changed('BannerNarrowExample generated SizedBox');
    }
    producer = _declaredChild(producer, widget.child);
  }
  if (producer.widget.runtimeType != producerType) {
    throw _changed('the exact generated concrete component');
  }
  final producerWidget = producer.widget;
  if (producerWidget is coui.Banner &&
      producerWidget.action is coui.Button &&
      producerWidget.action.runtimeType != coui.Button) {
    throw const BoxObservationError(
      'UNSUPPORTED_BANNER_ACTION_COPY_SOURCE',
      'An unknown Button subclass can override the source copy contract.',
    );
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  // Preserve the factory's actual foreign Element boundaries, including its
  // proven Banner action copyWith derivations. An absent original object is
  // never accepted as omission proof by this module.
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final Element padding;
  final Element frame;
  final String reader;
  switch (adapter) {
    case 'banner-generated-frame-v1':
      final semantics = _generatedChild(producer);
      if (semantics.widget is! Semantics) throw _changed('Banner Semantics');
      final cast = _declaredChild(
        semantics,
        (semantics.widget as Semantics).child,
      );
      if (cast.widget.runtimeType != coui.InjectedCast) {
        throw _changed('Banner Semantics.child InjectedCast');
      }
      final blur = _declaredChild(
        cast,
        (cast.widget as coui.InjectedCast).child,
      );
      if (blur.widget.runtimeType != coui.SurfaceBlur) {
        throw _changed('Banner InjectedCast.child SurfaceBlur');
      }
      padding = _declaredChild(
        blur,
        (blur.widget as coui.SurfaceBlur).child,
      );
      if (padding.widget.runtimeType != Container) {
        throw _changed('Banner SurfaceBlur.child Container');
      }
      frame = padding;
      reader = 'current-container-v1';
    case 'description-card-generated-frame-v1':
      var primitive = _generatedChild(producer);
      if (primitive.widget is DecoratedBox) {
        primitive = _declaredChild(
          primitive,
          (primitive.widget as DecoratedBox).child,
        );
      }
      // The 6 audited recipes are non-interactive. A new Clickable branch
      // needs its own construction proof, never a descendant search.
      if (primitive.widget.runtimeType != coui.OutlinedContainer) {
        throw _changed('DescriptionCard own Outlined frame');
      }
      padding = primitive;
      frame = primitive;
      reader = 'outlined-content-v1';
    case 'formatted-input-generated-frame-v1':
      final mouse = _generatedChild(producer);
      if (mouse.widget is! MouseRegion) {
        throw _changed('FormattedInput MouseRegion');
      }
      padding = _declaredChild(mouse, (mouse.widget as MouseRegion).child);
      if (padding.widget.runtimeType != coui.OutlinedContainer) {
        throw _changed('FormattedInput MouseRegion.child Outlined');
      }
      frame = padding;
      reader = 'outlined-content-v1';
    case 'frame-generated-content-inset-v1':
      final source = _frameInset(producer, scope);
      padding = source.padding;
      frame = source.frame;
      reader = 'current-render-padding-v1';
    default:
      throw _changed('closed extended component route');
  }
  scope
    ..requireOwned(padding)
    ..requireOwned(frame);
  return (
    authority:
        'Exact mounted construction and source child references; '
        '${declaration.authority}; $adapter',
    registryResultElement: result,
    fieldUnitElement: producer,
    paddingSource: padding,
    frameSource: frame,
    scope: scope,
    readerId: reader,
  );
}

({Element padding, Element frame}) _frameInset(
  Element producer,
  BoxProducerScope scope,
) {
  var current = _generatedChild(producer);
  var previous = -1;
  var painters = 0;
  // This is the reverse wrapper order in Frame.build, not a first-type
  // descendant/ancestor search. Unknown branches (including backdrop Stack)
  // and public content boundaries stop the route without a fallback value.
  const order = <Type>[
    Flexible,
    Semantics,
    coui.CoUISemantics,
    Focus,
    MouseRegion,
    GestureDetector,
    Transform,
    ImageFiltered,
    Opacity,
    Padding,
    Align,
    SizedBox,
    ConstrainedBox,
    CustomPaint,
  ];
  while (current.widget.runtimeType != AnimatedContainer) {
    scope.requireOwned(current);
    final widget = current.widget;
    final rank = order.indexOf(widget.runtimeType);
    final repeatedPainter = widget is CustomPaint && rank == previous;
    if (rank < 0 || rank < previous || (rank == previous && !repeatedPainter)) {
      throw const BoxObservationError(
        'UNSUPPORTED_FRAME_SOURCE_BRANCH',
        'The actual source left Frame.build ordered wrapper slots.',
      );
    }
    if (widget is CustomPaint && ++painters > 2) {
      throw _changed('Frame declared inner-shadow/dash wrappers');
    }
    previous = rank;
    final child = switch (widget) {
      Flexible() => widget.child,
      Semantics() => widget.child,
      coui.CoUISemantics() => widget.child,
      Focus() => widget.child,
      MouseRegion() => widget.child,
      GestureDetector() => widget.child,
      Transform() => widget.child,
      ImageFiltered() => widget.child,
      Opacity() => widget.child,
      Padding() => widget.child,
      Align() => widget.child,
      SizedBox() => widget.child,
      ConstrainedBox() => widget.child,
      CustomPaint() => widget.child,
      _ => null,
    };
    current = _declaredChild(current, child);
  }
  scope.requireOwned(current);
  final input = (current.widget as AnimatedContainer).child;
  if (input is! Padding || input.runtimeType != Padding) {
    throw const BoxObservationError(
      'FRAME_OWN_PADDING_BRANCH_UNSUPPORTED',
      'The chrome child is not the source-created own Padding branch.',
    );
  }
  final frame = evaluatedAnimatedContainer(current);
  scope.requireOwned(frame);
  final padding = _declaredChild(frame, input);
  scope.requireOwned(padding);
  // This explicit Padding was created before Frame's chrome Container.
  // Its own parameter excludes the Container's separate implicit border
  // allocation. No border subtraction or expected Core inset is used here.
  return (padding: padding, frame: frame);
}

Element _generatedChild(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the declared generated build result');
}

Element _declaredChild(Element parent, Widget? child) {
  if (child == null) throw _changed('a non-null source child reference');
  return requireOneBoxOwner(
    boxElements(parent).where((element) => identical(element.widget, child)),
    'the exact Widget object in the declared child slot',
  );
}

BoxObservationError _changed(String slot) => BoxObservationError(
  'EXTENDED_COMPONENT_SOURCE_CHANGED',
  'The actual generated source no longer matches $slot.',
);
