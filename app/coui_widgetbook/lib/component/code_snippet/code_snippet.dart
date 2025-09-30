import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A Dart [coui.CodeSnippet] use case.
@UseCase(
  name: 'dart',
  type: coui.CodeSnippet,
)
Widget buildCodeSnippetDartUseCase(BuildContext context) {
  final code = context.knobs.string(
    initialValue: '''void main() {
  print('Hello, World!');

  final name = 'Flutter';
  final greeting = 'Hello, \$name!';
  print(greeting);
}''',
    label: 'code',
  );

  return coui.CodeSnippet(
    code: code,
    mode: 'dart',
    constraints: BoxConstraints(
      maxHeight: context.knobs.double.slider(
        initialValue: 300,
        label: 'maxHeight',
        max: 600,
        min: 100,
      ),
    ),
  );
}

/// A JSON [coui.CodeSnippet] use case.
@UseCase(
  name: 'json',
  type: coui.CodeSnippet,
)
Widget buildCodeSnippetJsonUseCase(BuildContext context) {
  final code = context.knobs.string(
    initialValue: '''{
  "name": "John Doe",
  "age": 30,
  "email": "john@example.com",
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "country": "USA"
  },
  "hobbies": ["reading", "coding", "gaming"]
}''',
    label: 'code',
  );

  return coui.CodeSnippet(
    code: code,
    mode: 'json',
    constraints: BoxConstraints(
      maxHeight: context.knobs.double.slider(
        initialValue: 300,
        label: 'maxHeight',
        max: 600,
        min: 100,
      ),
    ),
  );
}

/// A SQL [coui.CodeSnippet] use case.
@UseCase(
  name: 'sql',
  type: coui.CodeSnippet,
)
Widget buildCodeSnippetSqlUseCase(BuildContext context) {
  final code = context.knobs.string(
    initialValue: '''SELECT
  u.id,
  u.name,
  u.email,
  COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id, u.name, u.email
ORDER BY order_count DESC
LIMIT 10;''',
    label: 'code',
  );

  return coui.CodeSnippet(
    code: code,
    mode: 'sql',
    constraints: BoxConstraints(
      maxHeight: context.knobs.double.slider(
        initialValue: 300,
        label: 'maxHeight',
        max: 600,
        min: 100,
      ),
    ),
  );
}