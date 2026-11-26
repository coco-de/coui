# Empty State Examples

This document contains example code for the empty_state component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class EmptyStateExample1 extends StatelessWidget {
  const EmptyStateExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: const Icon(Icons.inbox_outlined),
      title: Text(t.docs.components.empty_state.no_data),
      description: Text(t.docs.components.empty_state.no_data_description),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class EmptyStateExample2 extends StatelessWidget {
  const EmptyStateExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState.compact(
      icon: const Icon(Icons.search_off),
      title: Text(t.docs.components.empty_state.no_results),
      description: Text(t.docs.components.empty_state.no_results_description),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class EmptyStateExample3 extends StatelessWidget {
  const EmptyStateExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: const Icon(Icons.cloud_upload_outlined),
      title: Text(t.docs.components.empty_state.no_files),
      description: Text(t.docs.components.empty_state.no_files_description),
      action: PrimaryButton(
        onPressed: () {},
        child: Text(t.docs.components.empty_state.upload_files),
      ),
    );
  }
}

```

