// Test code reads JSON-decoded maps where dynamic chaining is conventional.
// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:coui_mcp/src/tools/component_generator.dart';
import 'package:coui_mcp/src/tools/pattern_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Jaspr target smoke tests', () {
    test('generate_component(button, target=jaspr) emits Button.primary', () {
      final result = ComponentGenerator.generateComponent({
        'component_name': 'button',
        'variant': 'primary',
        'target': 'jaspr',
        'properties': {'text': 'Click me'},
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['target'], 'jaspr');
      expect(body['code'], contains('Button.primary'));
      expect(body['code'], contains("text('Click me')"));
      expect(body['imports'], contains('coui_web'));
      expect(body['imports'], contains('jaspr'));
    });

    test('generate_component default (no target) is flutter', () {
      final result = ComponentGenerator.generateComponent({
        'component_name': 'button',
        'variant': 'primary',
        'properties': {'text': 'Click me'},
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['target'], 'flutter');
      expect(body['code'], contains('PrimaryButton'));
      expect(body['imports'], contains('coui_flutter'));
    });

    test('generate_component(card, target=jaspr) emits Card with header', () {
      final result = ComponentGenerator.generateComponent({
        'component_name': 'card',
        'target': 'jaspr',
        'properties': {
          'title': 'Hello',
          'description': 'World',
          'footer': true,
        },
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['code'], contains('Card('));
      expect(body['code'], contains("header: text('Hello')"));
      expect(body['code'], contains("body: text('World')"));
      expect(body['code'], contains('Button.primary'));
    });

    test('generate_screen(target=jaspr) emits StatelessComponent', () {
      final result = ComponentGenerator.generateScreen({
        'screen_type': 'list',
        'title': 'Users',
        'target': 'jaspr',
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['code'], contains('extends StatelessComponent'));
      expect(body['code'], contains('Iterable<Component> build'));
      expect(body['code'], contains("text('Users')"));
    });

    test('generate_form(target=jaspr) emits StatefulComponent + TextField', () {
      final result = ComponentGenerator.generateForm({
        'form_name': 'signup',
        'target': 'jaspr',
        'fields': [
          {'name': 'email', 'required': true},
          {'name': 'password', 'required': true},
        ],
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['code'], contains('extends StatefulComponent'));
      expect(body['code'], contains('TextField('));
      expect(body['code'], contains('Button.primary'));
      expect(body['code'], contains('Email *'));
    });

    test('generate_pattern(login, target=jaspr) emits coui_web import', () {
      final result = PatternGenerator.generatePattern({
        'pattern_name': 'login',
        'target': 'jaspr',
        'customization': {'social_login': true},
      });
      final body =
          json.decode(
                (result['content'] as List).first['text'] as String,
              )
              as Map<String, dynamic>;
      expect(body['target'], 'jaspr');
      expect(body['code'], contains('package:coui_web/coui_web.dart'));
      expect(body['code'], contains('Card('));
      expect(body['code'], contains('Button.primary'));
      expect(body['code'], contains('Continue with Google'));
    });

    test(
      'generate_pattern with unsupported jaspr pattern falls back + warns',
      () {
        final result = PatternGenerator.generatePattern({
          'pattern_name': 'crud',
          'target': 'jaspr',
        });
        final body =
            json.decode(
                  (result['content'] as List).first['text'] as String,
                )
                as Map<String, dynamic>;
        expect(body['target'], 'jaspr');
        expect(body['note'], contains('not yet ported to Jaspr'));
        // Falls back to Flutter code
        expect(body['code'], contains('coui_flutter'));
      },
    );
  });

  group('Component metadata platform info', () {
    late List<Map<String, dynamic>> components;

    setUpAll(() {
      final file = File('data/components/component_metadata.json');
      final content = file.readAsStringSync();
      components = (json.decode(content) as List).cast<Map<String, dynamic>>();
    });

    test('every component has both flutter and jaspr platform blocks', () {
      for (final c in components) {
        final platforms = c['platforms'] as Map<String, dynamic>?;
        expect(
          platforms,
          isNotNull,
          reason: 'platforms missing on ${c['name']}',
        );
        expect(platforms!['flutter'], isNotNull);
        expect(platforms['jaspr'], isNotNull);
      }
    });

    test('flutter platform info uses correct package and PascalCase class', () {
      final accordion = components.firstWhere((c) => c['name'] == 'accordion');
      final platforms = accordion['platforms'] as Map<String, dynamic>;
      final flutter = platforms['flutter'] as Map<String, dynamic>;
      expect(flutter['package'], 'package:coui_flutter/coui_flutter.dart');
      expect(flutter['className'], 'Accordion');
      expect(flutter['supported'], true);
    });

    test('alert_dialog flutter className is AlertDialog (no spaces)', () {
      final c = components.firstWhere((c) => c['name'] == 'alert_dialog');
      final platforms = c['platforms'] as Map<String, dynamic>;
      final flutter = platforms['flutter'] as Map<String, dynamic>;
      expect(flutter['className'], 'AlertDialog');
    });

    test('jaspr-supported component points at coui_web with Co-prefix', () {
      final card = components.firstWhere((c) => c['name'] == 'card');
      final platforms = card['platforms'] as Map<String, dynamic>;
      final jaspr = platforms['jaspr'] as Map<String, dynamic>;
      expect(jaspr['supported'], true);
      expect(jaspr['package'], 'package:coui_web/coui_web.dart');
      expect(jaspr['className'], anyOf('Card', 'Card'));
    });

    test(
      'jaspr-unsupported components have null className + supported=false',
      () {
        final unsupported = components.where((c) {
          final platforms = c['platforms'] as Map<String, dynamic>;
          final jaspr = platforms['jaspr'] as Map<String, dynamic>;
          return jaspr['supported'] == false;
        }).toList();
        expect(unsupported, isNotEmpty);
        for (final c in unsupported) {
          final platforms = c['platforms'] as Map<String, dynamic>;
          final jaspr = platforms['jaspr'] as Map<String, dynamic>;
          expect(jaspr['className'], isNull);
        }
      },
    );
  });
}
