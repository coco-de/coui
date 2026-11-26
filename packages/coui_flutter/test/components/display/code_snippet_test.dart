// The cap values under test are the fixture data — naming each one would hide
// the number the assertion is about.

/// Read-back tests for the `CodeSnippet` code-area size caps.
///
/// The four caps (`minWidth` / `maxWidth` / `minHeight` / `maxHeight`)
/// replaced a Flutter-only `constraints: BoxConstraints?` widget parameter.
/// A field that is declared, merged and compared but never read looks
/// finished from the authoring side and changes nothing on screen, so these
/// assert the constraints that get computed and painted rather than the
/// field's presence.
///
/// The value coverage sits at the resolver, and two widget tests carry the
/// paint hop. That split is deliberate: `CodeSnippet` caches its syntax
/// highlighter in static fields, so from the third pumped instance in one
/// file the `FutureBuilder` never leaves its loading branch — the branch
/// that holds the constrained box. Piling every case onto pumped widgets
/// would make the later ones pass or fail on cache order rather than on the
/// behaviour under test.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kCode = "void main() {\n  print('hi');\n}";

const _kAllCaps = CoreCodeSnippetStyle(
  minWidth: 160,
  maxWidth: 640,
  minHeight: 32,
  maxHeight: 320,
);

/// Resolves against a themed context, optionally with a project-level
/// `CoreCodeSnippetTheme` installed, so the merge chain is exercised the
/// same way the widget exercises it.
Future<ResolvedCodeSnippet> _resolve(
  WidgetTester tester, {
  CoreCodeSnippetStyle? style,
  CoreCodeSnippetStyle? themeStyle,
}) async {
  late ResolvedCodeSnippet resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          coreComponentTheme: themeStyle == null
              ? null
              : CoreComponentTheme(
                  codeSnippet: CoreCodeSnippetTheme(style: themeStyle),
                ),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveCodeSnippet(context, codeSnippetStyle: style);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

/// The constraints on the box that wraps the scrolling code area — the one
/// site the caps have to reach. Read off the render tree so an unread style
/// field cannot pass.
BoxConstraints? _paintedConstraints(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    if (container.constraints != null) return container.constraints;
  }
  return null;
}

Future<void> _pumpSnippet(
  WidgetTester tester,
  CoreCodeSnippetStyle? style,
) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: CodeSnippet(code: _kCode, mode: 'dart', codeSnippetStyle: style),
      ),
    ),
  );
  // The highlighter resolves asynchronously; the constrained box only exists
  // in the settled branch.
  final _ = await tester.pumpAndSettle();
}

void main() {
  group('CodeSnippet code-area caps — painted constraints', () {
    testWidgets('every cap reaches the painted code area', (tester) async {
      await _pumpSnippet(tester, _kAllCaps);
      final constraints = _paintedConstraints(tester);
      expect(constraints, isNotNull);
      expect(constraints!.minWidth, 160);
      expect(constraints.maxWidth, 640);
      expect(constraints.minHeight, 32);
      expect(constraints.maxHeight, 320);
    });

    testWidgets('no cap paints an unconstrained code area', (tester) async {
      await _pumpSnippet(tester, null);
      expect(_paintedConstraints(tester), isNull);
    });
  });

  group('CodeSnippet code-area caps — resolved values', () {
    testWidgets('unset stays null rather than collapsing to zero', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      expect(resolved.codeAreaConstraints, isNull);
    });

    testWidgets('one cap leaves the other edges unbounded', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(maxHeight: 300),
      );
      final constraints = resolved.codeAreaConstraints;
      expect(constraints, isNotNull);
      expect(constraints!.maxHeight, 300);
      expect(constraints.maxWidth, double.infinity);
      expect(constraints.minWidth, 0);
      expect(constraints.minHeight, 0);
    });

    testWidgets('a theme-level cap alone reaches the resolved constraints', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        themeStyle: const CoreCodeSnippetStyle(maxHeight: 160),
      );
      expect(resolved.codeAreaConstraints!.maxHeight, 160);
    });

    testWidgets('a per-instance cap wins over the theme-level one', (
      tester,
    ) async {
      // Proves the caps ride the same merge chain as the rest of the style
      // rather than being read straight off the widget.
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(maxHeight: 320),
        themeStyle: const CoreCodeSnippetStyle(maxHeight: 160),
      );
      expect(resolved.codeAreaConstraints!.maxHeight, 320);
    });

    testWidgets('caps scale with the theme scaling axis', (tester) async {
      // Sizes live on the scaling axis, so a cap has to follow it — an
      // unscaled cap would clip differently on mobile than the padding and
      // radius around it.
      late ResolvedCodeSnippet resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(scaling: 2),
            child: Builder(
              builder: (context) {
                resolved = resolveCodeSnippet(
                  context,
                  codeSnippetStyle: const CoreCodeSnippetStyle(maxHeight: 200),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved.codeAreaConstraints!.maxHeight, 400);
    });
  });
}
