import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

/// The screen each scenario opens its dialog on — a phone's width, tall
/// enough for a dialog with two stacked actions.
const _kScreenWidth = 360.0;
const _kScreenHeight = 340.0;

/// A screen too narrow for two short actions to share the row.
const _kNarrowScreenWidth = 240.0;

const CoreDialogStyle _kStretch = CoreDialogStyle(actionsLayout: .stretch);

Widget _button(String label, {CoreButtonVariant? variant}) => Button(
  variant: variant ?? CoreButtonVariant.primary,
  onPressed: () {},
  child: Text(label),
);

/// A [width]-wide screen of its own with a stretched dialog open on it.
///
/// The screen has its own navigator and the dialog is pushed onto it, not
/// onto the root one — the route then lays out inside the scenario's box,
/// at the screen's size, the way it would on a phone. The push waits for the
/// first frame, when the page has a navigator to push from.
class _OpenDialog extends StatelessWidget {
  const _OpenDialog({required this.actions, this.width = _kScreenWidth});

  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: _kScreenHeight,
    child: Navigator(
      onGenerateRoute: (settings) => material.PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, _, _) => _DialogOpener(actions: actions),
      ),
    ),
  );
}

class _DialogOpener extends StatefulWidget {
  const _DialogOpener({required this.actions});

  final List<Widget> actions;

  @override
  State<_DialogOpener> createState() => _DialogOpenerState();
}

class _DialogOpenerState extends State<_DialogOpener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          useRootNavigator: false,
          builder: (_) => Dialog(
            title: const Text('Delete draft?'),
            content: const Text('The draft goes from every device.'),
            actions: widget.actions,
            dialogStyle: _kStretch,
          ),
        ),
      );
    });
  }

  // The page under the dialog — the surface an app paints, which the
  // barrier then dims.
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).colorScheme.surface.toValue());
}

void main() {
  group('Dialog actions stretch Golden', () {
    goldenTest(
      'stretched actions row',
      fileName: 'dialog_actions_stretch',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'one action fills the row',
            child: buildGoldenTestApp(
              _OpenDialog(actions: [_button('Delete')]),
            ),
          ),
          GoldenTestScenario(
            name: 'two actions split the row',
            child: buildGoldenTestApp(
              _OpenDialog(
                actions: [
                  _button('Cancel', variant: CoreButtonVariant.outline),
                  _button('Delete'),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'a label too wide for its half stacks both',
            child: buildGoldenTestApp(
              _OpenDialog(
                actions: [
                  _button('Cancel', variant: CoreButtonVariant.outline),
                  _button('Delete forever'),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'a narrow screen stacks two short actions',
            child: buildGoldenTestApp(
              _OpenDialog(
                width: _kNarrowScreenWidth,
                actions: [
                  _button('Cancel', variant: CoreButtonVariant.outline),
                  _button('Delete'),
                ],
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
