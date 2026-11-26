# Card Examples

This document contains example code for the card component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class CardExample1 extends StatelessWidget {
  const CardExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.docs.components.card.create_project).semiBold(),
          const SizedBox(height: 4),
          Text(t.docs.components.card.deploy_description).baseContent().sm(),
          const SizedBox(height: 24),
          Text(t.docs.components.card.name).semiBold().sm(),
          const SizedBox(height: 4),
          TextField(placeholder: Text(t.docs.components.card.name_placeholder)),
          const SizedBox(height: 16),
          Text(t.docs.components.card.description).semiBold().sm(),
          const SizedBox(height: 4),
          TextField(
            placeholder: Text(t.docs.components.card.description_placeholder),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlineButton(
                child: Text(t.docs.components.button.cancel),
                onPressed: () {},
              ),
              const Spacer(),
              PrimaryButton(
                child: Text(t.docs.components.card.deploy),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    ).intrinsic();
  }
}

```

