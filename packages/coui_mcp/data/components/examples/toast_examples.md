# Toast Examples

This document contains example code for the toast component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ToastExample1 extends StatefulWidget {
  const ToastExample1({super.key});

  @override
  State<ToastExample1> createState() => _ToastExample1State();
}

class _ToastExample1State extends State<ToastExample1> {
  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        subtitle: Text(t.docs.components.toast.event_date),
        title: Text(t.docs.components.toast.event_created),
        trailing: PrimaryButton(
          onPressed: () {
            overlay.close();
          },
          size: ButtonSize.small,
          child: Text(t.docs.components.button.undo),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PrimaryButton(
          child: Text(t.docs.components.toast.show_bottom_left),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomLeft,
            );
          },
        ),
        PrimaryButton(
          child: Text(t.docs.components.toast.show_bottom_right),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomRight,
            );
          },
        ),
        PrimaryButton(
          child: Text(t.docs.components.toast.show_top_left),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topLeft,
            );
          },
        ),
        PrimaryButton(
          child: Text(t.docs.components.toast.show_top_right),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topRight,
            );
          },
        ),
        // bottom center
        PrimaryButton(
          child: Text(t.docs.components.toast.show_bottom_center),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomCenter,
            );
          },
        ),
        // top center
        PrimaryButton(
          child: Text(t.docs.components.toast.show_top_center),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topCenter,
            );
          },
        ),
      ],
    );
  }
}

```

