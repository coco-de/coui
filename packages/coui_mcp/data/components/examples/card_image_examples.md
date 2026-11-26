# Card Image Examples

This document contains example code for the card_image component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class CardImageExample1 extends StatelessWidget {
  const CardImageExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < 10; i++)
                CardImage(
                  image: Image.network('https://picsum.photos/200/300'),
                  onPressed: () {
                    showDialog(
                      builder: (context) {
                        return AlertDialog(
                          actions: [
                            PrimaryButton(
                              child: Text(t.docs.components.button.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                          content: Text(
                            t.docs.components.card_image.card_clicked,
                          ),
                          title: Text(
                            t.docs.components.card_image.card_image_title,
                          ),
                        );
                      },
                      context: context,
                    );
                  },
                  subtitle: Text(t.docs.components.card_image.lorem_ipsum),
                  title: Text(
                    t.docs.components.card_image.card_number(n: i + 1),
                  ),
                ),
            ],
          ).gap(8),
        ),
      ),
    );
  }
}

```

