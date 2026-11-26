import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Test-only harness that owns a `bool open` field and re-renders a
/// `Dialog` from it on every rebuild — lets a test drive the *same*
/// `Dialog` instance through an open→close transition (via
/// [_DialogHostState.setOpen]) rather than re-attaching a fresh root
/// component (which would tear down `_DialogState` instead of calling
/// `didUpdateComponent` — `ComponentTester.pumpComponent` always mounts
/// a brand-new element tree, so this must be a *child* rebuild).
class _DialogHost extends StatefulComponent {
  const _DialogHost({required this.onState});

  final void Function(_DialogHostState state) onState;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  bool open = true;

  /// Public setter wrapping [setState] — `setState` itself is
  /// `@protected` (framework-internal API), so an external test driving
  /// this harness calls this instead of reaching into the state directly.
  void setOpen(bool value) => setState(() => open = value);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return Dialog(open: open, content: Component.text('Body'));
  }
}

void main() {
  group('Dialog', () {
    testComponents('renders title and content when open', (tester) async {
      pumpWithTheme(
        tester,
        Dialog(title: Component.text('Title'), content: Component.text('Body')),
      );

      expect(find.text('Title'), findsOneComponent);
      expect(find.text('Body'), findsOneComponent);
    });

    testComponents('renders nothing when open is false', (tester) async {
      pumpWithTheme(
        tester,
        Dialog(
          open: false,
          title: Component.text('Title'),
          content: Component.text('Body'),
        ),
      );

      expect(find.text('Title'), findsNothing);
      expect(find.text('Body'), findsNothing);
    });

    testComponents('renders leading, trailing, and actions slots', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Dialog(
          leading: Component.text('Icon'),
          trailing: Component.text('Close'),
          content: Component.text('Body'),
          actions: [Component.text('OK')],
        ),
      );

      expect(find.text('Icon'), findsOneComponent);
      expect(find.text('Close'), findsOneComponent);
      expect(find.text('OK'), findsOneComponent);
    });

    test('accepts custom id', () {
      final dialog = Dialog(content: Component.text('Body'), id: 'dialog-1');
      expect(dialog.id, equals('dialog-1'));
    });

    test('defaults to open', () {
      final dialog = Dialog(content: Component.text('Body'));
      expect(dialog.open, isTrue);
    });

    test('copyWith preserves properties', () {
      final original = Dialog(
        content: Component.text('Body'),
        open: false,
        id: 'dialog-orig',
      );

      final copy = original.copyWith(id: 'dialog-new');

      expect(copy.id, equals('dialog-new'));
      expect(copy.open, isFalse);
    });

    // Regression — #3621: Web `Dialog` used to unmount the instant `open`
    // flipped to `false` (`_buildOverlayTree` returned `null` synchronously),
    // with no exit transition. The panel must now stay mounted through the
    // `CoreDialogStyle.transitionDuration` exit window before disappearing.
    testComponents(
      'stays mounted through the exit window instead of vanishing instantly',
      (tester) async {
        late _DialogHostState host;
        pumpWithTheme(tester, _DialogHost(onState: (state) => host = state));
        await tester.pump();
        expect(find.text('Body'), findsOneComponent);

        host.setOpen(false);
        await tester.pump();

        // The exact bug: previously this assertion failed because the
        // panel unmounted synchronously with no exit window at all.
        expect(
          find.text('Body'),
          findsOneComponent,
          reason:
              'panel should still be in the DOM immediately after close — '
              'it has an exit transition to play',
        );

        // Past the transition window, the panel is finally gone.
        await Future<void>.delayed(
          CoreDialogStyle.defaultTransitionDuration +
              const Duration(milliseconds: 50),
        );
        await tester.pump();
        expect(find.text('Body'), findsNothing);
      },
    );

    testComponents(
      'cancels the pending unmount when reopened mid-exit',
      (tester) async {
        late _DialogHostState host;
        pumpWithTheme(tester, _DialogHost(onState: (state) => host = state));
        await tester.pump();

        host.setOpen(false);
        await tester.pump();
        expect(find.text('Body'), findsOneComponent);

        // Reopen before the exit window elapses (rapid toggle).
        host.setOpen(true);
        await tester.pump();

        // Wait past what would have been the original exit deadline —
        // the panel must still be here because the unmount was cancelled,
        // not merely delayed.
        await Future<void>.delayed(
          CoreDialogStyle.defaultTransitionDuration +
              const Duration(milliseconds: 50),
        );
        await tester.pump();
        expect(find.text('Body'), findsOneComponent);
      },
    );
  });
}
