import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/prefer_handle_prefixed_callback_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferHandlePrefixedCallbackRuleTest);
  });
}

const _host = r'''
class Button {
  const Button({this.onTap, this.onChanged, this.builder});
  final void Function()? onTap;
  final void Function(bool)? onChanged;
  final Object Function()? builder;
}
''';

@reflectiveTest
class PreferHandlePrefixedCallbackRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferHandlePrefixedCallbackRule();
    super.setUp();
  }

  Future<void> test_flags_method_torn_off_without_handle_stem() async {
    final content =
        '''
$_host
class Screen {
  void _onTap() {}
  Button build() => Button(onTap: _onTap);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('_onTap)'), '_onTap'.length),
    ]);
  }

  Future<void> test_allows_private_and_public_handle_stem() async {
    await assertNoDiagnostics('''
$_host
class Screen {
  void _handleTap() {}
  void handleChanged(bool value) {}
  Button build() => Button(onTap: _handleTap, onChanged: handleChanged);
}
''');
  }

  Future<void> test_flags_top_level_function_tear_off() async {
    final content =
        '''
$_host
void toggle(bool value) {}
Button build() => Button(onChanged: toggle);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('toggle);'), 'toggle'.length),
    ]);
  }

  Future<void> test_ignores_closure() async {
    await assertNoDiagnostics('''
$_host
Button build() => Button(onTap: () {});
''');
  }

  Future<void> test_ignores_forwarded_callback_parameter() async {
    await assertNoDiagnostics('''
$_host
Button build(void Function()? onTap) => Button(onTap: onTap);
''');
  }

  Future<void> test_ignores_forwarded_callback_field() async {
    await assertNoDiagnostics('''
$_host
class Wrapper {
  Wrapper(this.onTap);
  final void Function()? onTap;
  Button build() => Button(onTap: onTap);
}
''');
  }

  Future<void> test_ignores_parameter_not_named_on() async {
    await assertNoDiagnostics('''
$_host
class Screen {
  Object _build() => 0;
  Button build() => Button(builder: _build);
}
''');
  }

  Future<void> test_suggestion_keeps_the_methods_own_meaning() async {
    // Two different methods fed to `onTap` must not be told to take the
    // same name, and an `on`-prefixed method keeps its stem.
    final content =
        '''
$_host
class Pager {
  void _goToPrev() {}
  void _goToNext() {}
  void _onTick() {}
  List<Button> build() => [
    Button(onTap: _goToPrev),
    Button(onTap: _goToNext),
    Button(onTap: _onTick),
  ];
}
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf('_goToPrev)'),
        '_goToPrev'.length,
        messageContainsAll: ['_handleGoToPrev'],
      ),
      lint(
        content.indexOf('_goToNext)'),
        '_goToNext'.length,
        messageContainsAll: ['_handleGoToNext'],
      ),
      lint(
        content.indexOf('_onTick)'),
        '_onTick'.length,
        messageContainsAll: ['_handleTick'],
      ),
    ]);
  }
}
