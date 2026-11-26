/// Moves the real pointer over a page — the input half the browser tools
/// had none of.
///
/// Every other browser tool here observes: it reads computed style, the SSR
/// DOM, a screenshot. None of them ever moved the pointer, so "what happens
/// while the pointer rests on a trigger" was not a question any of them
/// could answer — a menu that opened and closed several times a second
/// under a still pointer passed all of them.
///
/// The moves go through puppeteer's `page.mouse`, i.e. the DevTools input
/// domain: trusted events the browser routes through hit testing exactly
/// as it does a real mouse, so `mouseenter` / `mouseleave` / `:hover` fire
/// the way a user sees them. No event is synthesised in page script — an
/// `element.dispatchEvent(new MouseEvent(...))` would reach the listener
/// without the browser deciding what is under the pointer, which is the
/// part a hover defect lives in.
///
/// Thin on purpose: this file owns *where* the pointer goes, never what a
/// probe concludes from it. The browser itself is launched by
/// `tool/browser_launch.dart`, shared with every capture path.
library;

import 'dart:convert';
import 'dart:math';

import 'package:puppeteer/puppeteer.dart' as pptr;

/// Intermediate moves per pointer travel. More than one, so the browser
/// sees the pointer cross the element's edge (a single jump still enters,
/// but hides travel-order defects); few enough to stay fast.
const int kPointerTravelSteps = 8;

/// Where the pointer rests when it should be over nothing a probe cares
/// about — the page's top-left corner, outside every preview pane.
const kPointerParkPosition = Point<num>(1, 1);

/// The centre of the first element matching [selector], in viewport
/// coordinates, after scrolling it into view — or `null` when no element
/// matches or the match has no area (hidden, not laid out).
Future<Point<num>?> elementCenter(pptr.Page page, String selector) async {
  final json = await page.evaluate<String?>(
    '''
(selector) => {
  const el = document.querySelector(selector);
  if (!el) return null;
  el.scrollIntoView({block: 'center', inline: 'center'});
  const r = el.getBoundingClientRect();
  if (r.width <= 0 || r.height <= 0) return null;
  return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]);
}''',
    args: [selector],
  );
  if (json == null) return null;
  final xy = (jsonDecode(json) as List<Object?>).cast<num>();

  return Point(xy[0], xy[1]);
}

/// Moves the pointer onto the centre of the first element matching
/// [selector]. Returns `false` (and leaves the pointer where it was) when
/// there is no such element with an area to land on.
Future<bool> hoverElement(
  pptr.Page page,
  String selector, {
  int steps = kPointerTravelSteps,
}) async {
  final center = await elementCenter(page, selector);
  if (center == null) return false;
  await page.mouse.move(center, steps: steps);

  return true;
}

/// Moves the pointer to [kPointerParkPosition], off every pane.
Future<void> parkPointer(pptr.Page page, {int steps = kPointerTravelSteps}) =>
    page.mouse.move(kPointerParkPosition, steps: steps);
