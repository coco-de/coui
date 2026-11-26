/// Stub — no DOM on server.
void Function()? listenForSurfaceStyleChange(void Function() onChange) => null;

/// Stub — no DOM scroll edges during server rendering.
void Function()? listenForAppBarScrollEdges() => null;

/// Stub — no DOM on server.
bool getChecked(Object _) {
  // On non-web platforms there is no DOM; always return false.
  return false;
}

/// Stub — no DOM on server.
double? getMouseRatio(Object event, Object target, {double travelInset = 0}) =>
    null;

/// Stub — no DOM on server.
Object? eventTargetParent(Object? eventTarget) => null;

/// Stub — no DOM on server.
({double left, double top, double width, double height})? elementRect(
  Object? element,
) => null;

/// Stub — no DOM on server.
void Function() registerDragListeners({
  required void Function(Object event) onMove,
  required void Function(Object event) onUp,
  void Function(Object event)? onCancel,
  Object? downEvent,
}) => () {};

/// Stub — no DOM on server.
({double width, double height}) viewportSize() => (width: 0, height: 0);

/// Stub — no DOM on server (no resize events; nothing to dispose).
void Function()? listenForViewportResize(void Function() onResize) => null;

/// Stub — no DOM on server.
Object? eventCurrentTarget(Object event) => null;

/// Stub — no DOM on server.
bool isPrimaryPointerPress(Object event) => true;

/// Stub — no DOM on server.
({double left, double top, double width, double height})? descendantRect(
  Object? root,
  String selector,
) => null;

/// Stub — no DOM on server.
void focusElement(Object? element) {}

/// Stub — no DOM on server.
double? mouseClientX(Object event) => null;

/// Stub — no DOM on server.
double? mouseClientY(Object event) => null;

/// Stub — no DOM on server.
void preventDefault(Object event) {}

/// Stub — no DOM on server.
({double x, double y, double width, double height})? readScrollGeometry(
  String elementId,
) => null;

/// Stub — no DOM on server. Nothing has been scrolled during a server
/// render, so there is no position to report and the caller keeps the
/// start-of-range value it rendered with.
({
  double scrollTop,
  double scrollHeight,
  double clientHeight,
  double scrollLeft,
  double scrollWidth,
  double clientWidth,
})?
readScrollbarViewportOf(Object? element) => null;

/// Stub — no DOM on server.
({
  double scrollTop,
  double scrollHeight,
  double clientHeight,
  double scrollLeft,
  double scrollWidth,
  double clientWidth,
})?
readScrollbarViewport(String elementId) => null;

/// Stub — no DOM on server.
({double minX, double maxX, double minY, double maxY})? readScrollBounds(
  String elementId,
) => null;

/// Stub — no DOM on server.
bool eventTargetHasId(Object event, String elementId) => false;

/// Stub — no DOM on server, so nothing inside the box can own the click:
/// the box gets it.
bool isFieldBoxInertTarget(Object event) => true;

/// Stub — no DOM on server.
void focusInputOfEventBox(Object event) {}

/// Stub — no DOM on server.
void scrollElementTo(String elementId, {double? x, double? y}) {}

/// Stub — no DOM on server.
void focusInputWithin(String elementId) {}

/// Stub — no DOM on server.
void focusInputRangeWithin(String elementId, int start, int end) {}

/// Moves keyboard focus to the first element matching [selector]. No-op on
/// the server.
void focusElementBySelector(String selector) {}

/// Stub — no DOM on server.
void scrollElementIntoViewById(String elementId) {}

/// Stub — no DOM on server.
String? closestAttributeWithPrefix(
  Object event,
  String attribute,
  String prefix,
) => null;

/// Stub — no DOM on server.
void blurActiveElement() {}

/// Stub — no DOM on server.
void selectInputText(Object? target) {}

/// Stub — no DOM on server.
({double width, double height})? readElementSize(String elementId) => null;

/// Stub — no DOM on server.
void Function()? observeElementResize(
  String elementId,
  void Function(double width, double height) onResize,
) => null;

/// Stub — no DOM on server.
void Function()? observeScrollContentResize(
  String rootId,
  void Function() onChange,
) => null;

/// Stub — no DOM on server.
String? pointerTypeOf(Object event) => null;

/// Stub — no DOM on server.
bool isElementRtl(Object? element) => false;

/// Stub — no DOM on server.
void scrollNearestAncestorBy(
  String elementId, {
  required double deltaX,
  required double deltaY,
}) {}

/// Stub — no clipboard on server.
void writeTextToClipboard(String text) {}

/// Stub — no DOM on server.
void setInputValue(String elementId, String value) {}

/// Stub — no WebOTP on server.
bool get supportsWebOtp => false;

/// Stub — no WebOTP on server; never invokes [onCode].
void Function() requestWebOtp(void Function(String code) onCode) => () {};

/// Stub — no document on the server, so nothing carries an attribute.
///
/// Returning null rather than throwing is what lets a scope be read during
/// server rendering: the server states the style through the component tree
/// it builds, and the attribute only matters once a browser is switching.
String? documentAttribute(String name) => null;

/// Stub — no document on the server.
void setDocumentAttribute(String name, String value) {}

/// Stub — no document on the server.
void removeDocumentAttribute(String name) {}

/// Stub — no console on server; the warning has nowhere to go.
void consoleWarn(String _) {}
