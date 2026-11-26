// Pins `TextField.obscureText` as a mount-time seed — the Web half of the
// Flutter test with the same name.
//
// The field reads the flag once, into its own obscured state, and a
// `passwordToggle` is the only thing that flips it afterwards. A caller
// flipping `obscureText: !visible` from outside used to get nothing: no
// mask change, no message. These cases hold the seed semantics and make
// the misuse loud in debug builds.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/debug_warn.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

String? get _inputType =>
    (find.tag('input').evaluate().single.component as DomComponent)
        .attributes?['type'];

void main() {
  group('TextField obscureText seed', () {
    late List<String> warnings;
    late void Function(String) previousSink;

    setUp(() {
      warnings = [];
      previousSink = debugWarn;
      debugWarn = warnings.add;
    });

    tearDown(() => debugWarn = previousSink);

    testComponents('a later change does not re-mask and warns in debug', (
      tester,
    ) async {
      late _SeedHostState host;
      pumpWithTheme(
        tester,
        _SeedHost(
          onState: (state) => host = state,
          builder: ({required obscure}) => TextField(obscureText: obscure),
        ),
      );
      expect(_inputType, equals('password'));

      host.setObscure(obscure: false);
      await tester.pump();

      expect(_inputType, equals('password'));
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('passwordToggle'));
    });

    testComponents('does not warn when a passwordToggle owns the state', (
      tester,
    ) async {
      late _SeedHostState host;
      pumpWithTheme(
        tester,
        _SeedHost(
          onState: (state) => host = state,
          builder: ({required obscure}) => TextField(
            obscureText: obscure,
            features: const [CoreInputFeature.passwordToggle()],
          ),
        ),
      );

      host.setObscure(obscure: false);
      await tester.pump();

      expect(warnings, isEmpty);
      expect(_inputType, equals('password'));
    });
  });
}

/// Rebuilds its child in place so the child reaches `didUpdateComponent`
/// — a second `pumpComponent` would mount a fresh root and reseed.
class _SeedHost extends StatefulComponent {
  const _SeedHost({required this.builder, required this.onState});

  final Component Function({required bool obscure}) builder;

  /// Hands the live state back, since `setState` is `@protected`.
  final void Function(_SeedHostState state) onState;

  @override
  State<_SeedHost> createState() => _SeedHostState();
}

class _SeedHostState extends State<_SeedHost> {
  bool obscure = true;

  void setObscure({required bool obscure}) =>
      setState(() => this.obscure = obscure);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(obscure: obscure);
  }
}
