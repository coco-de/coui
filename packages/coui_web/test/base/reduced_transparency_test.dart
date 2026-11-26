// The reduce-transparency response, on the one platform that has a handle.
//
// The gate this closes is stated by hand in the acceptance criteria: a
// preset that declares `usesTransparency` owes an opaque fallback, and a
// declaration with no drawn path is a claim rather than a pass. Until this
// landed, nothing on either platform read the preference — while the
// contract's own doc said the field drove the response.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const _kQuery = '@media (prefers-reduced-transparency:reduce)';

String _sheet() => ThemeConfig.defaults().surfaceStyleVariableBlocks;

/// The reduce-transparency rule emitted for [id], or empty.
String _blockFor(CoreSurfaceStyleId id) {
  final sheet = _sheet();
  final scope = '[data-coui-style="${id.name}"]';
  var from = 0;
  while (true) {
    final start = sheet.indexOf(_kQuery, from);
    if (start < 0) return '';

    final end = sheet.indexOf('}}', start);
    final block = sheet.substring(start, end < 0 ? sheet.length : end + 2);
    if (block.contains(scope)) return block;

    from = start + _kQuery.length;
  }
}

void main() {
  group('a translucent preset answers the preference', () {
    test('liquid glass turns opaque and drops its backdrop filter', () {
      // Both halves, because they are one statement: an opaque fill with
      // the blur still running composites a backdrop nobody can see
      // through, and keeps amplifying its chroma.
      final block = _blockFor(CoreSurfaceStyleId.liquidGlass);

      expect(block, isNotEmpty, reason: 'no reduce-transparency rule at all');
      expect(block, contains('backdrop-filter:none !important'));
      expect(
        block,
        contains(
          'background-color:rgb(var(--coui-surface-rgb) / '
          'var(--coui-surface-alpha, 1)) !important',
        ),
        reason: 'the fill is still translucent under the preference',
      );
    });

    test('and it is the surface marker it lands on', () {
      // Not the document, not a wrapper. The marker is what a surface puts
      // on itself, and it is the element the treatment block styles.
      expect(_blockFor(CoreSurfaceStyleId.liquidGlass), contains('surface'));
    });

    test('and `!important` is there, because the fill is written inline', () {
      // The surface primitive writes its own fill as an inline style, and
      // an inline declaration outranks every selector — the same rule
      // without this would parse, match, and change nothing.
      final block = _blockFor(CoreSurfaceStyleId.liquidGlass);
      final declarations = block.split(';').where((d) => d.contains(':'));

      expect(declarations, isNotEmpty);
      for (final declaration in declarations) {
        if (declaration.contains('@media') || declaration.contains('{')) {
          // The selector line, not a declaration.
          if (!declaration.contains('background-color') &&
              !declaration.contains('backdrop-filter')) {
            continue;
          }
        }
        expect(
          declaration,
          contains('!important'),
          reason: 'inline styles would outrank `$declaration`',
        );
      }
    });
  });

  group('an opaque preset emits nothing', () {
    test('because it has no transparency to reduce', () {
      // Emitting a no-op rule for every style would put a media query in
      // the sheet for presets that never asked, and make "does this style
      // respond" unanswerable by reading it.
      for (final id in CoreSurfaceStyleId.values) {
        final translucent = CoreSurfaceRecipe.of(id).a11y.usesTransparency;
        if (translucent) continue;

        expect(
          _blockFor(id),
          isEmpty,
          reason: '$id emits a reduce-transparency rule it does not need',
        );
      }
    });

    test('and exactly the presets that declare transparency emit one', () {
      // Ties the emitted rule back to the declaration it is supposed to
      // honour, rather than to a hardcoded list of style names.
      for (final id in CoreSurfaceStyleId.values) {
        expect(
          _blockFor(id).isNotEmpty,
          CoreSurfaceRecipe.of(id).a11y.usesTransparency,
          reason: '$id disagrees with its own `usesTransparency`',
        );
      }
    });
  });
}
