@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/code_tag_block_syntax.dart';
import 'package:docs_core/markdown/heading_slug.dart';
import 'package:docs_site/components/docs_tabs.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:markdown/markdown.dart' as md;

/// Exercise the docs site's actual markdown parser and tabs component
/// together, on real pages: both platform examples render, each under its own
/// tab, and the group carries the name its `groupId` gives it.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  for (final slug in ['sidebar', 'number-input']) {
    testServer('$slug renders both platform examples', (tester) async {
      final source = File('../docs_core/content/components/$slug.md').readAsStringSync();
      final body = source.replaceFirst(RegExp(r'^---.*?---\n', dotAll: true), '');
      final markdown = md.Document(
        blockSyntaxes: kDocsBlockSyntaxes,
        extensionSet: docsHeadingAwareExtensionSet,
      );
      final nodes = MarkdownParser.buildNodes(markdown.parse(body));
      tester.pumpComponent(NodesBuilder([DocsTabs()]).build(nodes));
      final response = await tester.request('/');
      expect(response.statusCode, 200);
      final doc = response.document!;
      final group = doc.querySelector('[$kDocsTabsAttribute]')!;
      final tabs = group.querySelectorAll('[role="tab"]');
      final panels = group.querySelectorAll('[role="tabpanel"]');
      expect(tabs.map((e) => e.attributes[kDocsTabValueAttribute]), ['flutter', 'web']);
      expect(panels.map((e) => e.attributes[kDocsTabValueAttribute]), ['flutter', 'web']);
      expect(panels[0].text, contains(slug == 'sidebar' ? 'Sidebar(' : 'NumberInput('));
      expect(panels[1].text, contains(slug == 'sidebar' ? 'Sidebar(' : 'NumberInput('));
      // The content writes `groupId`; the parser hands it over as `groupid`.
      expect(source, contains('<Tabs groupId="platform">'));
      expect(group.attributes[kDocsTabsGroupAttribute], 'platform');
    });
  }
}
