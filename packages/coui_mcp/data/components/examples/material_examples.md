# Material Examples

This document contains example code for the material component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:flutter/cupertino.dart';
import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:i10n/i10n.dart';

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
      navigationBar: CupertinoNavigationBar(
        middle: Text(t.docs.components.material.my_cupertino_app),
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
            const coui.Gap(size: 16),
            CupertinoButton.filled(
              child: const Icon(CupertinoIcons.add),
              onPressed: () => setState(() => _counter++),
            ),
            const coui.Gap(size: 64),
            coui.CoUIUI(
              child: coui.Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You can also use coui_flutter widgets inside Material widgets',
                    ),
                    const coui.Gap(size: 16),
                    coui.PrimaryButton(
                      child: Text(
                        t.docs.components.material.open_cupertino_dialog,
                      ),
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: Text(t.docs.components.dialog.hello),
                              content: Text(
                                t.docs.components.dialog
                                    .cupertino_dialog_content,
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(t.docs.components.button.close),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const coui.Gap(size: 8),
                    coui.SecondaryButton(
                      child: Text(t.docs.components.material.open_coui_dialog),
                      onPressed: () {
                        coui.showDialog(
                          builder: (context) {
                            return coui.AlertDialog(
                              actions: [
                                coui.PrimaryButton(
                                  child: Text(t.docs.components.button.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                              content: const Text(
                                'This is coui_flutter dialog',
                              ),
                              title: Text(t.docs.components.dialog.hello),
                            );
                          },
                          context: context,
                        );
                      },
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

```

## Example 1

**Basic Example**

```dart
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:i10n/i10n.dart';

class MaterialExample1 extends StatefulWidget {
  const MaterialExample1({super.key});

  @override
  State<MaterialExample1> createState() => _MaterialExample1State();
}

class _MaterialExample1State extends State<MaterialExample1> {
  int _counter = 0;

  void _incrementCounter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.docs.components.material.you_pushed_button(count: _counter),
        ),
      ),
    );
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.docs.components.material.my_material_app),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const coui.Gap(size: 64),
            coui.CoUIUI(
              child: coui.Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You can also use coui_flutter widgets inside Material widgets',
                    ),
                    const coui.Gap(size: 16),
                    coui.PrimaryButton(
                      child: Text(
                        t.docs.components.material.open_material_dialog,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(t.docs.components.dialog.hello),
                              content: Text(
                                t.docs.components.dialog
                                    .material_dialog_content,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(t.docs.common.close),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const coui.Gap(size: 8),
                    coui.SecondaryButton(
                      child: Text(t.docs.components.material.open_coui_dialog),
                      onPressed: () {
                        coui.showDialog(
                          builder: (context) {
                            return coui.AlertDialog(
                              actions: [
                                coui.PrimaryButton(
                                  child: Text(t.docs.common.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                              content: const Text(
                                'This is coui_flutter dialog',
                              ),
                              title: Text(t.docs.components.dialog.hello),
                            );
                          },
                          context: context,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Increment',
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}

```

