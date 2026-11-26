/// Unified image-editing state for the Web platform.
///
/// `ImageProperties` and `CoreImageType` are platform-neutral data
/// models defined in `coui_core` — shared verbatim by Flutter and Web.
/// This file re-exports them so Web call sites can import the unified
/// types through the standard `coui_web` barrel without reaching into
/// `coui_core` directly.
library;

export 'package:coui_core/coui_core.dart' show ImageProperties, CoreImageType;
