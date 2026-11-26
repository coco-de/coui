# Refresh Trigger Examples

This document contains example code for the refresh_trigger component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class RefreshTriggerExample1 extends StatefulWidget {
  const RefreshTriggerExample1({super.key});

  @override
  State<RefreshTriggerExample1> createState() => _RefreshTriggerExample1State();
}

class _RefreshTriggerExample1State extends State<RefreshTriggerExample1> {
  final GlobalKey<RefreshTriggerState> _refreshTriggerKey =
      GlobalKey<RefreshTriggerState>();
  @override
  Widget build(BuildContext context) {
    return RefreshTrigger(
      key: _refreshTriggerKey,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
      },
      child: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 32),
          height: 800,
          child: Column(
            children: [
              Text(t.docs.components.refresh_trigger.pull_me),
              const Gap(size: 16),
              PrimaryButton(
                child: Text(t.docs.components.refresh_trigger.refresh),
                onPressed: () {
                  _refreshTriggerKey.currentState!.refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

