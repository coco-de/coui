/// Test helper that wraps a component with [Theme.defaults] before pumping.
///
/// Use [pumpWithTheme] whenever a component requires [Theme.of(context)]
/// (e.g. Button, Badge, Toggle, Checkbox, Loading, Input).
library;

import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// Pumps [component] wrapped inside [Theme.defaults] so that any descendant
/// that calls [Theme.of(context)] finds a valid [ThemeData].
void pumpWithTheme(ComponentTester tester, Component component) {
  tester.pumpComponent(Theme.defaults(child: component));
}
