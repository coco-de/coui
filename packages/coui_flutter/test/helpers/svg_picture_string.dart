import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The SVG source an `Icon` handed to `flutter_svg` under [of].
///
/// `Icon` builds its SVG as a string and draws it with `SvgPicture.string`,
/// so the string is the one place its stroke can be read without rasterising.
/// [of] is the `Icon` (or any ancestor with exactly one `SvgPicture` below
/// it) — scoping the search keeps another glyph in the tree from satisfying
/// an assertion about this one.
String svgStringOf(WidgetTester tester, Finder of) {
  final picture = tester.widget<SvgPicture>(
    find.descendant(of: of, matching: find.byType(SvgPicture)),
  );
  final loader = picture.bytesLoader;
  if (loader is! SvgStringLoader) {
    throw StateError('Icon draws with SvgPicture.string, got $loader');
  }

  // The string a loader was built from is private; `provideSvg` hands it
  // back without the isolate round trip `flutter_svg` itself takes.
  return loader.provideSvg(null);
}

/// Every `stroke-width` attribute value in [svg], in document order.
List<String> strokeWidthsIn(String svg) => [
  for (final match in RegExp(
    '\\sstroke-width=["\']([^"\']*)["\']',
  ).allMatches(svg))
    match.group(1)!,
];
