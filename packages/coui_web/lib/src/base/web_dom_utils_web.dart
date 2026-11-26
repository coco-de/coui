// This file provides small JS DOM interop utilities for web-only builds.
// We intentionally keep scope limited and typed to preserve SSR safety via
// conditional export in `web_dom_utils.dart`.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coui_web/src/base/glass_chrome_dom_web.dart';
import 'package:web/web.dart' as web;

/// Structural material changes only; observes one attribute, never frames.
void Function()? listenForSurfaceStyleChange(void Function() onChange) {
  final root = web.document.documentElement;
  if (root == null) return null;
  final observer = web.MutationObserver(
    (JSArray<web.MutationRecord> _, web.MutationObserver _) {
      onChange();
    }.toJS,
  );
  observer.observe(
    root,
    web.MutationObserverInit(
      attributes: true,
      attributeFilter: ['data-coui-style'.toJS].toJS,
    ),
  );
  // External JS members cannot be torn off by dart2js.
  return () => observer.disconnect();
}

/// Updates a soft edge without rebuilding optical surfaces on every scroll.
/// Capturing also handles a Scaffold body's independently scrolling viewport.
void Function()? listenForAppBarScrollEdges() => GlassChromeDom.retain();

/// Gets the checked state of an HTML input element.
///
/// Returns true if the element is checked, false otherwise.
bool getChecked(Object target) {
  // Cast to HTMLInputElement to access the checked property
  if (target is web.HTMLInputElement) {
    return target.checked;
  }

  // Fallback for non-input elements
  return false;
}

/// Extracts the horizontal ratio (0.0–1.0) of a mouse event relative to [target].
///
/// [travelInset] shrinks the span the pointer maps over by that many
/// pixels, centred — the shape a thumb-style control needs, where the
/// handle's own width is subtracted because its edges, not its centre,
/// stop at the ends. Left at 0 the ratio spans the full width, which is
/// what a control with no handle (a star rating strip) wants.
///
/// Returns null if the target element has zero width.
double? getMouseRatio(Object event, Object target, {double travelInset = 0}) {
  if (event is! web.MouseEvent || target is! web.Element) return null;
  // Re-read through [mouseClientX] — browsers deliver sub-pixel mouse
  // coordinates and the `int`-declared `clientX` getter throws a cast
  // error on them.
  final clientX = mouseClientX(event);
  if (clientX == null) return null;
  final rect = target.getBoundingClientRect();
  final trackWidth = rect.width;
  if (trackWidth <= 0) return null;
  final localX = clientX - rect.left;
  final travel = trackWidth - travelInset;
  // A track narrower than its own handle has nowhere to travel; every
  // pointer position means the same value.
  if (travel <= 0) return 0;
  return ((localX - travelInset / 2) / travel).clamp(0.0, 1.0);
}

/// Returns the parent element of [eventTarget] if it is a DOM element,
/// otherwise null. Used to climb from an event's `currentTarget` to its
/// containing element without exposing extension-type casts to callers.
Object? eventTargetParent(Object? eventTarget) {
  if (eventTarget is web.Element) return eventTarget.parentElement;
  return null;
}

/// Reads the bounding client rect of [element] if it is a DOM element.
/// Returns null otherwise. Sizes are CSS pixels.
({double left, double top, double width, double height})? elementRect(
  Object? element,
) {
  if (element is! web.Element) return null;
  final rect = element.getBoundingClientRect();
  return (
    left: rect.left.toDouble(),
    top: rect.top.toDouble(),
    width: rect.width.toDouble(),
    height: rect.height.toDouble(),
  );
}

/// Returns the element the handler of [event] is attached to
/// (`event.currentTarget`), or null when [event] is not a DOM event.
Object? eventCurrentTarget(Object event) {
  if (event is web.Event) return event.currentTarget;
  return null;
}

/// Whether [event] is the press of a primary pointer's main button — what
/// a drag starts from. A pointer event from a second finger or a
/// non-primary button is not; any other event is taken as a plain press.
bool isPrimaryPointerPress(Object event) {
  if (event is! web.PointerEvent) return true;
  return event.isPrimary && event.button == 0;
}

/// Reads the bounding client rect of the first descendant of [root] that
/// matches [selector]. Returns null when [root] is not a DOM element or
/// nothing matches. Sizes are CSS pixels.
({double left, double top, double width, double height})? descendantRect(
  Object? root,
  String selector,
) {
  if (root is! web.Element) return null;
  return elementRect(root.querySelector(selector));
}

/// Moves keyboard focus to [element] if it is a focusable DOM element.
void focusElement(Object? element) {
  if (element is web.HTMLElement) element.focus();
}

/// Returns `event.clientX` if [event] is a [web.MouseEvent], otherwise null.
///
/// Browsers may return non-integer pixel positions (CSS sub-pixel
/// reporting in zoomed viewports / high-DPR displays). The `web` package
/// declares `clientX` as `int` so we re-read the JS property as a
/// `JSNumber` and convert via `toDartDouble` to avoid the strict-cast
/// throw when the runtime value is fractional.
double? mouseClientX(Object event) {
  if (event is web.Touch) {
    return event.getProperty<JSNumber>('clientX'.toJS).toDartDouble;
  }
  if (event is! web.MouseEvent) return null;
  return event.getProperty<JSNumber>('clientX'.toJS).toDartDouble;
}

/// Returns `event.clientY` if [event] is a [web.MouseEvent], otherwise null.
double? mouseClientY(Object event) {
  if (event is web.Touch) {
    return event.getProperty<JSNumber>('clientY'.toJS).toDartDouble;
  }
  if (event is! web.MouseEvent) return null;
  return event.getProperty<JSNumber>('clientY'.toJS).toDartDouble;
}

/// Invokes `preventDefault` on [event] if it's a DOM [web.Event].
void preventDefault(Object event) {
  if (event is web.Event) event.preventDefault();
}

/// Reads `pointerId` from a pointer event, or null when the event is not
/// a `PointerEvent` (the property is absent on plain mouse events).
double? _pointerIdOf(Object event) {
  if (event is! web.Event) return null;
  final id = event.getProperty<JSNumber?>('pointerId'.toJS);
  return id?.toDartDouble;
}

/// Registers document-level pointermove/pointerup listeners for drag
/// tracking. Pointer events cover mouse, touch and pen input, so drag
/// interactions work on touch devices too (parity with Flutter's
/// `GestureDetector` pan, which is input-device agnostic).
///
/// [downEvent] is the `pointerdown` that initiated the drag — the drag
/// tracks **only that pointer**, so a second finger touching the screen
/// mid-drag neither feeds its moves into the drag nor ends it early
/// (Flutter parity: the gesture arena tracks a single pointer per pan).
/// Triggers must listen to `pointerdown` (not `mousedown`): on touch
/// devices the compatibility `mousedown` fires *after* the gesture's
/// `pointerup`, so listeners registered from it would never detach.
///
/// [onMove] is called on each pointermove with the event.
/// [onUp] is called once on pointerup, then all listeners are removed.
/// [onCancel] is called instead of [onUp] when the browser aborts the
/// interaction (`pointercancel` — e.g. a touch turned into a scroll or
/// the OS stole the pointer); defaults to [onUp] so existing drag flows
/// still terminate. Mirrors Flutter's `onPanCancel`.
void Function() registerDragListeners({
  required void Function(Object event) onMove,
  required void Function(Object event) onUp,
  void Function(Object event)? onCancel,
  Object? downEvent,
}) {
  final pointerId = downEvent == null ? null : _pointerIdOf(downEvent);
  bool matches(web.Event e) {
    if (pointerId == null) return true;
    final id = _pointerIdOf(e);
    return id == null || id == pointerId;
  }

  // Store .toJS references so add/remove use the same JS function.
  JSFunction? moveJs;
  JSFunction? upJs;
  JSFunction? cancelJs;
  void detach() {
    web.document.removeEventListener('pointermove', moveJs!);
    web.document.removeEventListener('pointerup', upJs!);
    web.document.removeEventListener('pointercancel', cancelJs!);
  }

  moveJs = ((web.Event e) {
    if (matches(e)) onMove(e);
  }).toJS;
  upJs = ((web.Event e) {
    if (!matches(e)) return;
    onUp(e);
    detach();
  }).toJS;
  cancelJs = ((web.Event e) {
    if (!matches(e)) return;
    (onCancel ?? onUp)(e);
    detach();
  }).toJS;
  web.document.addEventListener('pointermove', moveJs);
  web.document.addEventListener('pointerup', upJs);
  web.document.addEventListener('pointercancel', cancelJs);
  return detach;
}

/// Reads the current viewport size (`innerWidth` / `innerHeight`).
///
/// Used by `DraggablePanel` to clamp the handle inside the viewport and
/// snap it to the nearer screen edge on drag release.
({double width, double height}) viewportSize() => (
  width: web.window.innerWidth.toDouble(),
  height: web.window.innerHeight.toDouble(),
);

/// Reads `scrollLeft` / `scrollTop` / `clientWidth` / `clientHeight` of the
/// element with [elementId]. Returns null if the element is not attached or
/// not an [Element]. Used by `ScrollableClient` to mirror the browser's
/// native scroll state into Dart.
({double x, double y, double width, double height})? readScrollGeometry(
  String elementId,
) {
  final el = web.document.getElementById(elementId);
  if (el == null) return null;
  return (
    x: el.scrollLeft.toDouble(),
    y: el.scrollTop.toDouble(),
    width: el.clientWidth.toDouble(),
    height: el.clientHeight.toDouble(),
  );
}

/// Reads both axes' scroll geometry off [element] — the six properties a
/// scrollbar needs to say how far through its range each axis currently
/// is. Returns null if [element] is not a DOM element.
///
/// Separate from [readScrollGeometry] because that one omits
/// `scrollWidth` / `scrollHeight`: knowing where the box is scrolled to
/// is enough to mirror scroll state, but not to express it as a
/// fraction, which needs the range as well.
///
/// This is the only place these six property names are written down.
/// A scroll event hands over the element it fired on and a mount-time
/// read has to look one up, but both arrive here, so the two paths
/// cannot come to disagree about what they are reading.
({
  double scrollTop,
  double scrollHeight,
  double clientHeight,
  double scrollLeft,
  double scrollWidth,
  double clientWidth,
})?
readScrollbarViewportOf(Object? element) {
  if (element is! web.Element) return null;
  return (
    scrollTop: element.scrollTop.toDouble(),
    scrollHeight: element.scrollHeight.toDouble(),
    clientHeight: element.clientHeight.toDouble(),
    scrollLeft: element.scrollLeft.toDouble(),
    scrollWidth: element.scrollWidth.toDouble(),
    clientWidth: element.clientWidth.toDouble(),
  );
}

/// [readScrollbarViewportOf] for a node reached by id — the shape a
/// caller needs when it has no event to take the element from. Returns
/// null if the element is not attached.
({
  double scrollTop,
  double scrollHeight,
  double clientHeight,
  double scrollLeft,
  double scrollWidth,
  double clientWidth,
})?
readScrollbarViewport(String elementId) =>
    readScrollbarViewportOf(web.document.getElementById(elementId));

/// The range each axis of [elementId] can be scrolled through.
///
/// Separate from [readScrollGeometry] because only keyboard scrolling
/// needs it: knowing the bounds is what lets a key press decide whether
/// it moved anything, and therefore whether to consume the event or let
/// it chain to the enclosing scroller the way a browser does natively.
///
/// Bounds rather than a single extent because the horizontal range is
/// signed — see the `rtl` branch below.
({double minX, double maxX, double minY, double maxY})? readScrollBounds(
  String elementId,
) {
  final el = web.document.getElementById(elementId);
  if (el == null) return null;
  final extentX = (el.scrollWidth - el.clientWidth).toDouble();
  final extentY = (el.scrollHeight - el.clientHeight).toDouble();
  // In a right-to-left box `scrollLeft` is 0 at the inline-start (right)
  // edge and goes *negative* leftward — the range is [-extent, 0], not
  // [0, extent] (CSSOM-View; Firefox always, Blink since Chrome 85).
  // Clamping to [0, extent] there would collapse every valid position to
  // 0, so a keyboard press would snap the content back to the right edge
  // instead of moving it.
  final rtl = web.window.getComputedStyle(el).direction == 'rtl';

  return (
    minX: rtl ? -extentX : 0.0,
    maxX: rtl ? 0.0 : extentX,
    minY: 0.0,
    maxY: extentY,
  );
}

/// Whether [event] was targeted at the element with [elementId] itself,
/// rather than at something inside it.
///
/// A `keydown` listener on a container also receives every key pressed
/// while a descendant holds focus, because the event bubbles. A scroll
/// container that acts on those would take the arrows and Home/End away
/// from a focused `<input>` inside it — so it has to be able to tell
/// "the container is focused" from "something in the container is".
bool eventTargetHasId(Object event, String elementId) {
  if (event is! web.Event) return false;
  if (event.target case final web.Element target) {
    return target.id == elementId;
  }

  return false;
}

/// The DOM event behind a handler's raw [event] argument, or null.
///
/// Jaspr hands every listener an `Object`, so the narrowing to a JS interop
/// type has to happen on that value — `isA` needs a JS value to start from.
web.Event? _domEvent(Object event) {
  // ignore: invalid_runtime_check_with_js_interop_types, the raw argument is all there is
  if (event is web.Event) return event;
  return null;
}

/// What inside a framed field box answers a click for itself — the
/// `<input>`, a built-in or slotted button, a link.
const String _kFieldBoxClickOwners =
    'input, textarea, select, button, a[href], [role="button"], '
    '[contenteditable="true"]';

/// Whether [event] landed on the framed field box itself — its padding, or
/// a prefix / suffix that handles no click of its own — rather than on
/// something inside it that does.
///
/// The event must be handled on the box (`currentTarget` is the box). A
/// click-owner that sits *above* the box answers for its own surface, not
/// the box's, so it does not count; one inside it, or already detached from
/// it, does.
bool isFieldBoxInertTarget(Object event) {
  final domEvent = _domEvent(event);
  if (domEvent == null) return false;
  final target = domEvent.target;
  final box = domEvent.currentTarget;
  if (target == null || box == null) return false;
  // `isA` is the only narrowing `package:web` extension types admit.
  if (!target.isA<web.Element>() || !box.isA<web.Element>()) return false;
  final owner = (target as web.Element).closest(_kFieldBoxClickOwners);
  if (owner == null) return true;
  // Only an owner that holds the box answers for something other than it.
  // Asked of the owner rather than of the box: a control that left the DOM
  // while handling its own click (the clear button empties the text and is
  // removed with it) is no longer inside the box, yet it did own the click.
  return owner.contains(box as web.Element);
}

/// Focuses the first `<input>` inside the element [event] is handled on.
/// No-op when there is none.
void focusInputOfEventBox(Object event) {
  final box = _domEvent(event)?.currentTarget;
  if (box == null || !box.isA<web.Element>()) return;
  final input = (box as web.Element).querySelector('input');
  if (input == null || !input.isA<web.HTMLElement>()) return;
  (input as web.HTMLElement).focus();
}

/// Scrolls the element with [elementId] to the given offsets. Uses a
/// non-smooth jump (equivalent to Flutter's `ScrollController.jumpTo`).
/// Null values leave the corresponding axis alone.
void scrollElementTo(String elementId, {double? x, double? y}) {
  final el = web.document.getElementById(elementId);
  if (el == null) return;
  if (x != null) el.scrollLeft = x.toInt();
  if (y != null) el.scrollTop = y.toInt();
}

/// Calls `select()` on the given event target if it is an
/// `<input>` or `<textarea>` — selects the entire current value.
/// Mirrors the Flutter side's
/// `controller.selection = TextSelection(0, length)` so a single
/// `selectAllOnFocus: true` prop drives identical behaviour on both
/// platforms.
void selectInputText(Object? target) {
  if (target is web.HTMLInputElement) {
    target.select();
  } else if (target is web.HTMLTextAreaElement) {
    target.select();
  }
}

/// Moves keyboard focus to the first element matching [selector], if any.
///
/// Roving-focus collections (`roving_focus.dart`) find their items by a
/// host-scoped attribute rather than an id, so the query is a selector.
void focusElementBySelector(String selector) {
  final Object? element = web.document.querySelector(selector);
  if (element is web.HTMLElement) {
    element.focus();
  }
}

/// Walks up from [event]'s target and returns the [attribute] value of the
/// nearest ancestor-or-self whose value starts with [prefix], or `null`.
///
/// Stepping past non-matching carriers is what lets an outer collection
/// find its own item when focus sits in an inner collection nested inside
/// it — the inner item is the nearest carrier but not the outer's.
String? closestAttributeWithPrefix(
  Object event,
  String attribute,
  String prefix,
) {
  if (event is! web.Event) return null;
  Object? node = event.target;
  while (node is web.Element) {
    final Object? match = node.closest('[$attribute]');
    if (match is! web.Element) return null;
    final value = match.getAttribute(attribute);
    if (value != null && value.startsWith(prefix)) return value;
    node = match.parentElement;
  }
  return null;
}

/// Scrolls the element with [elementId] into view within its scroll
/// container, moving as little as possible — for a highlight that lives in
/// `aria-activedescendant` (DOM focus stays on an input), so the browser
/// does not scroll to it on its own.
void scrollElementIntoViewById(String elementId) {
  web.document
      .getElementById(elementId)
      ?.scrollIntoView(
        web.ScrollIntoViewOptions(block: 'nearest', inline: 'nearest'),
      );
}

/// Focuses the first `<input>` descendant of the element with [elementId].
/// No-op when the host or its input is absent. Used e.g. by `PhoneInput`
/// to move focus into a just-opened panel.
void focusInputWithin(String elementId) {
  final host = web.document.getElementById(elementId);
  // Typed as `Object?` so the `is` check runtime-promotes without an
  // explicit extension-type cast (mirrors `selectInputText`). `focus()`
  // lives on `HTMLElement`, which the queried `<input>` element is.
  final Object? input = host?.querySelector('input');
  if (input is web.HTMLElement) {
    input.focus();
  }
}

/// Focuses the first `<input>` descendant of the element with [elementId]
/// and selects `[start, end)` of its value — the Web half of a Flutter
/// `TextEditingValue(selection: TextSelection(start, end))` seed. No-op
/// when the host or its input is absent.
void focusInputRangeWithin(String elementId, int start, int end) {
  final host = web.document.getElementById(elementId);
  final input = host?.querySelector('input');
  // `isA` is the only narrowing `package:web` extension types admit.
  if (input == null || !input.isA<web.HTMLInputElement>()) return;
  (input as web.HTMLInputElement)
    ..focus()
    ..setSelectionRange(start, end);
}

/// Calls `blur()` on `document.activeElement` if one is currently focused.
/// Mirrors Flutter's `ScrollViewKeyboardDismissBehavior.onDrag` semantics
/// by releasing focus when a drag-initiated scroll fires.
void blurActiveElement() {
  final active = web.document.activeElement;
  if (active == null) return;
  // `activeElement` is typed as `Element`, but DOM focus always lands on an
  // `HTMLElement`. Cast and call `blur()` via the stronger interface.
  final html = active as web.HTMLElement;
  html.blur();
}

/// Reads `clientWidth` / `clientHeight` of the element with [elementId].
/// Returns null if the element is not attached. Used by `StageContainer`
/// to measure its own parent viewport from Dart.
({double width, double height})? readElementSize(String elementId) {
  final el = web.document.getElementById(elementId);
  if (el == null) return null;
  return (
    width: el.clientWidth.toDouble(),
    height: el.clientHeight.toDouble(),
  );
}

/// Subscribes to layout-size changes of the element with [elementId] via
/// the native `ResizeObserver` API. [onResize] is invoked with the element's
/// current content-box width / height (CSS pixels) whenever the browser
/// reports a size change.
///
/// Returns a disposer that must be called to detach the observer (e.g. from
/// `State.dispose`). Returns null if the element isn't attached yet.
void Function()? observeElementResize(
  String elementId,
  void Function(double width, double height) onResize,
) {
  final el = web.document.getElementById(elementId);
  if (el == null) return null;
  final observer = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver _) {
      for (var i = 0; i < entries.length; i++) {
        final entry = entries.toDart[i];
        final rect = entry.contentRect;
        onResize(rect.width.toDouble(), rect.height.toDouble());
      }
    }).toJS,
  )..observe(el);
  // Tear-offs of `package:web` extension members aren't supported by DDC —
  // wrap in an explicit closure so the disposer call site is compiled as a
  // normal method invocation.
  return () => observer.disconnect();
}

/// Subscribes to size changes of a scroll container's *contents*: the
/// element with [rootId] and each of its element children, via
/// `ResizeObserver`. [onChange] is invoked whenever the browser reports one.
///
/// Observing the container alone is not enough: a box capped by
/// `max-height` keeps its own size while the content inside it grows, and
/// it is the content that decides how long a scrollbar thumb is. A
/// `MutationObserver` on the container's child list keeps the observed set
/// in step as children come and go.
///
/// Returns a disposer that detaches both observers (call it from
/// `State.dispose`), or null if the element is not attached yet.
void Function()? observeScrollContentResize(
  String rootId,
  void Function() onChange,
) {
  final root = web.document.getElementById(rootId);
  if (root == null) return null;

  final resizeObserver = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver _) {
      onChange();
    }).toJS,
  );

  void observeChildren() {
    resizeObserver.observe(root);
    final children = root.children;
    for (var i = 0; i < children.length; i++) {
      final child = children.item(i);
      if (child != null) resizeObserver.observe(child);
    }
  }

  observeChildren();

  final mutationObserver = web.MutationObserver(
    ((JSArray<web.MutationRecord> _, web.MutationObserver _) {
      // `observe` is idempotent per element, so the whole set is simply
      // asked for again.
      observeChildren();
      onChange();
    }).toJS,
  )..observe(root, web.MutationObserverInit(childList: true));

  // Tear-offs of `package:web` extension members aren't supported by DDC —
  // wrap in an explicit closure so the disposer call site is compiled as a
  // normal method invocation.
  return () {
    resizeObserver.disconnect();
    mutationObserver.disconnect();
  };
}

/// Returns `event.pointerType` (`mouse` / `touch` / `pen`) when [event] is a
/// pointer event, otherwise null.
///
/// Read through `getProperty` rather than a `PointerEvent` cast: the property
/// is simply absent on a plain mouse event.
String? pointerTypeOf(Object event) {
  if (event is! web.Event) return null;
  final type = event.getProperty<JSString?>('pointerType'.toJS);

  return type?.toDart;
}

/// Whether [element] lays out right to left (its computed `direction`).
///
/// A horizontally scrolled box reports `scrollLeft` as a negative number
/// there, and a vertical scrollbar sits on the left; both depend on it.
bool isElementRtl(Object? element) {
  if (element is! web.Element) return false;

  return web.window.getComputedStyle(element).direction == 'rtl';
}

/// Scrolls the nearest scrollable ancestor of the element with
/// [elementId] by ([deltaX], [deltaY]) CSS pixels.
///
/// Climbs the DOM from the element until it finds an ancestor whose
/// content overflows along the requested axis, then applies a
/// non-smooth `scrollBy`. Used by `ScrollViewInterceptor` to
/// translate middle-mouse hold-scroll velocity into actual scrolling
/// — the Web equivalent of Flutter's synthetic `PointerScrollEvent`
/// dispatch.
void scrollNearestAncestorBy(
  String elementId, {
  required double deltaX,
  required double deltaY,
}) {
  final origin = web.document.getElementById(elementId);
  if (origin == null) return;
  web.Element? node = origin;
  while (node != null) {
    final overflowsY = node.scrollHeight > node.clientHeight;
    final overflowsX = node.scrollWidth > node.clientWidth;
    if (overflowsY || overflowsX) {
      if (overflowsX) {
        node.scrollLeft = (node.scrollLeft + deltaX).round();
      }
      if (overflowsY) {
        node.scrollTop = (node.scrollTop + deltaY).round();
      }
      return;
    }
    node = node.parentElement;
  }
}

/// Writes [text] to the system clipboard via the async Clipboard API.
///
/// Fire-and-forget — the copy button does not await the promise (parity
/// with the Flutter `Clipboard.setData` call, whose result is likewise
/// not surfaced synchronously).
void writeTextToClipboard(String text) {
  final _ = web.window.navigator.clipboard.writeText(text);
}

/// Sets the `value` property of the `<input>` with [elementId] to
/// [value] — used to write a programmatically-obtained value (e.g.
/// WebOTP autofill) into the real DOM node so a subsequent manual edit
/// continues from it instead of stale DOM state. No-op when the element
/// is absent or not an `<input>`.
void setInputValue(String elementId, String value) {
  // `is` cannot meaningfully narrow between `package:web` extension
  // types (all `extension type X._(JSObject _)` — no distinct runtime
  // representation), so this reads as an explicit nullable cast rather
  // than a checked assertion. Null-safe either way: an absent element
  // (or a same-id element that isn't an `<input>`) just no-ops.
  // DOM lookups cannot be instantiated and extension types offer no
  // runtime narrowing, so the checked cast is the only expression.
  final el = web.document.getElementById(elementId) as web.HTMLInputElement?;
  el?.value = value;
}

/// Whether the browser implements the WebOTP API (`OTPCredential`) —
/// currently Chrome on Android is the only implementer. Feature-detected
/// so [requestWebOtp] degrades to a complete no-op everywhere else.
bool get supportsWebOtp => globalContext.has('OTPCredential');

/// Requests an SMS-delivered one-time code via the WebOTP API
/// (`navigator.credentials.get({otp: {transport: ['sms']}})`) and invokes
/// [onCode] with the extracted digits once the browser retrieves a
/// matching SMS. A pure progressive enhancement — `InputOtp` fills the
/// hidden buffer identically whether the code arrives this way or the
/// user types / pastes it, so a browser without WebOTP support (or a
/// user who declines the permission prompt) just falls back to manual
/// entry.
///
/// `package:web` does not bind the returned `OTPCredential`'s `code`
/// field (only `OTPCredentialRequestOptions`, the request-side shape),
/// so it is read dynamically via [JSObjectUnsafeUtilExtension.getProperty]
/// — `Credential` is a `JSObject` either way.
///
/// Returns a disposer that aborts the pending request via
/// [web.AbortController.abort] — call it once the code is filled
/// (manually or otherwise) or from `State.dispose`, so an unmounted /
/// already-complete widget never applies a stale callback.
void Function() requestWebOtp(void Function(String code) onCode) {
  if (!supportsWebOtp) return () {};

  final abortController = web.AbortController();
  unawaited(
    web.window.navigator.credentials
        .get(
          web.CredentialRequestOptions(
            signal: abortController.signal,
            otp: web.OTPCredentialRequestOptions(
              transport: ['sms'.toJS].toJS,
            ),
          ),
        )
        .toDart
        .then((credential) {
          if (credential == null) return;
          final code = credential.getProperty<JSString?>('code'.toJS);
          if (code != null) onCode(code.toDart);
        })
        .catchError((_) {
          // Ignored — the user dismissed the SMS permission prompt, the
          // request timed out, or the platform lacks SMS Retriever
          // support. Manual entry / paste remain available either way.
        }),
  );

  return () => abortController.abort();
}

/// Subscribes [onResize] to browser window `resize` events and returns
/// the unsubscribe callback. Viewport-reactive components (e.g.
/// `ResponsiveRowColumn`) re-render through it so a [viewportSize]
/// read at build time stays live across window resizes.
void Function() listenForViewportResize(void Function() onResize) {
  final handler = ((web.Event _) => onResize()).toJS;
  web.window.addEventListener('resize', handler);
  return () => web.window.removeEventListener('resize', handler);
}

/// Reads [name] from the document element, or null when it is absent.
String? documentAttribute(String name) =>
    web.document.documentElement?.getAttribute(name);

/// Writes [name] on the document element so stylesheet rules can key on it.
void setDocumentAttribute(String name, String value) {
  web.document.documentElement?.setAttribute(name, value);
}

/// Removes [name] from the document element.
void removeDocumentAttribute(String name) {
  web.document.documentElement?.removeAttribute(name);
}

/// Writes [message] to the browser console as a warning.
void consoleWarn(String message) {
  web.console.warn(message.toJS);
}
