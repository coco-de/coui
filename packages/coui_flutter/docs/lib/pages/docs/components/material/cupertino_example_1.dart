import 'package:flutter/cupertino.dart';
import 'package:coui_flutter/coui_flutter.dart' as coui;

class CupertinoExample1 extends StatefulWidget {
  const CupertinoExample1({super.key});

  @override
  State<CupertinoExample1> createState() => _CupertinoExample1State();
}

class _CupertinoExample1State extends State<CupertinoExample1> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Cupertino App'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
            Text(
              '$_counter',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const coui.Gap(16),
            CupertinoButton.filled(
              onPressed: () => setState(() => _counter++),
              child: const Icon(CupertinoIcons.add),
            ),
            const coui.Gap(64),
            coui.CoUIUI(
              child: coui.Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You can also use coui_flutter widgets inside Material widgets',
                    ),
                    const coui.Gap(16),
                    coui.PrimaryButton(
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: const Text('Hello'),
                              content: const Text('This is Cupertino dialog'),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Open Cupertino Dialog'),
                    ),
                    const coui.Gap(8),
                    coui.SecondaryButton(
                      onPressed: () {
                        coui.showDialog(
                          context: context,
                          builder: (context) {
                            return coui.AlertDialog(
                              title: const Text('Hello'),
                              content: const Text(
                                'This is coui_flutter dialog',
                              ),
                              actions: [
                                coui.PrimaryButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Open coui_flutter Dialog'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
