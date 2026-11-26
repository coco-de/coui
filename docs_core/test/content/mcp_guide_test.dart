@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// Holds the MCP guide to what the server actually registers.
///
/// The guide lists every tool and resource URI by name, and the server
/// registers them by name — two hand-kept copies of one list. A tool
/// renamed or added on the server side leaves the guide describing a
/// server that does not exist, and nothing on the page looks wrong: a
/// reader only finds out when the call fails. So the lists are read from
/// the server source rather than written here, and checked in both
/// directions.
///
/// Source text rather than a running server, like the sidebar tests: the
/// server is a stdio process, and starting one here would make this test
/// depend on a toolchain it does not need to see the names.
void main() {
  late String guide;
  late Set<String> tools;
  late Set<String> uris;

  setUpAll(() {
    guide = File('content/guides/mcp.md').readAsStringSync();
    final server = File(
      '../packages/coui_mcp/lib/src/server/coui_mcp_server.dart',
    ).readAsStringSync();
    tools = {
      for (final match in RegExp(
        r"registerTool\(\s*'([a-z_]+)'",
      ).allMatches(server))
        match.group(1)!,
    };
    uris = {
      for (final match in RegExp(r"'(coui://[^']+)'").allMatches(server)) match.group(1)!,
    };
  });

  test('the server source still yields something to compare against', () {
    // A pattern that stops matching — a registration helper renamed, the
    // file moved — reads as "the guide covers every tool" while reading
    // none of them.
    expect(tools, isNotEmpty);
    expect(uris, isNotEmpty);
  });

  test('every tool the server registers is in the guide', () {
    for (final tool in tools) {
      expect(
        guide,
        contains('`$tool`'),
        reason: 'the server registers $tool and the guide is silent',
      );
    }
  });

  test('and every tool the guide lists is one the server registers', () {
    // The direction that catches a rename: the old name stays in the guide,
    // still formatted as a tool, pointing at nothing.
    // The tool sits in its own cell — after the group column, which is
    // blank on every row but a group's first.
    final section = _section(guide, '## 툴', '## 리소스');
    final listed = {
      for (final match in RegExp(r'\| `([a-z_]+)` \|').allMatches(section)) match.group(1)!,
    };
    expect(listed, isNotEmpty);
    expect(listed.difference(tools), isEmpty);
  });

  test('the tool count the guide states is the count the server has', () {
    // The tools section opens with the count ("11개입니다.").
    final stated = RegExp(r'(\d+)개').firstMatch(_section(guide, '## 툴', '## 리소스'));
    expect(stated, isNotNull);
    expect(int.parse(stated!.group(1)!), tools.length);
  });

  test('every resource URI the server registers is in the guide', () {
    for (final uri in uris) {
      expect(
        guide,
        contains('`$uri`'),
        reason: 'the server registers $uri and the guide is silent',
      );
    }
  });

  test('and every URI the guide mentions resolves to a registration', () {
    // Concrete URIs in the measurement table (`…/button/overview`) have to
    // match a template, not appear verbatim.
    final patterns = [
      for (final uri in uris)
        RegExp(
          '^${RegExp.escape(uri).replaceAll(RegExp(r'\\\{[a-z]+\\\}'), '[^/]+')}\$',
        ),
    ];
    final mentioned = {
      for (final match in RegExp(r'`(coui://[^`]+)`').allMatches(guide)) match.group(1)!,
    };
    expect(mentioned, isNotEmpty);
    for (final uri in mentioned) {
      expect(
        patterns.any((pattern) => pattern.hasMatch(uri)),
        isTrue,
        reason: 'the guide mentions $uri and no registration serves it',
      );
    }
  });
}

String _section(String text, String from, String to) {
  final start = text.indexOf(from);
  final end = text.indexOf(to, start);
  if (start < 0 || end < 0) return '';
  return text.substring(start, end);
}
