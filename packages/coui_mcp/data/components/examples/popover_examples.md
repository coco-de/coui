# Popover Examples

This document contains example code for the popover component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class PopoverExample1 extends StatelessWidget {
  const PopoverExample1({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PrimaryButton(
      child: Text(t.docs.components.popover.open_popover),
      onPressed: () {
        showPopover(
          alignment: Alignment.topCenter,
          builder: (context) {
            return ModalContainer(
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.docs.components.popover.dimensions).lg().md(),
                    Text(
                      t.docs.components.popover.set_dimensions,
                    ).baseContent(),
                    Form(
                      controller: FormController(),
                      child: FormTableLayout(
                        rows: [
                          FormField<double>(
                            key: const FormKey(#width),
                            label: Text(t.docs.components.popover.width),
                            child: const TextField(initialValue: '100%'),
                          ),
                          FormField<double>(
                            key: const FormKey(#maxWidth),
                            label: Text(t.docs.components.popover.max_width),
                            child: const TextField(initialValue: '300px'),
                          ),
                          FormField<double>(
                            key: const FormKey(#height),
                            label: Text(t.docs.components.popover.height),
                            child: const TextField(initialValue: '25px'),
                          ),
                          FormField<double>(
                            key: const FormKey(#maxHeight),
                            label: Text(t.docs.components.popover.max_height),
                            child: const TextField(initialValue: 'none'),
                          ),
                        ],
                        spacing: 8,
                      ),
                    ).withPadding(vertical: 16),
                    PrimaryButton(
                      child: Text(t.docs.components.popover.submit),
                      onPressed: () {
                        closeOverlay(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          context: context,
          offset: const Offset(0, 8),
          // Unless you have full opacity surface,
          // you should explicitly set the overlay barrier.
          overlayBarrier: OverlayBarrier(borderRadius: theme.borderRadiusBox),
        );
      },
    );
  }
}

```

