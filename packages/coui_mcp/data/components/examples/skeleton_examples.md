# Skeleton Examples

This document contains example code for the skeleton component.

A skeleton stands in for a value that has not arrived yet. The caller knows
the shape of what is loading, so it draws that shape with `Skeleton` — in
each slot the value will fill — and wraps the loading area in one
`LoadingRegion`, which announces the load once however many skeletons it
holds. `Skeleton` has no on/off switch: render it on the caller's own
loading condition. The Flutter `asSkeleton()` extension (skeletonizer) is
deprecated — do not use it in new code.

## Table of Contents

- [Example 1: Loading List Item](#example-1)
- [Example 2: Loading List](#example-2)

## Example 1

**Loading List Item**

```dart
import 'package:coui_flutter/coui_flutter.dart';

/// The width of one list row — the same in both states.
const _kRowWidth = 360.0;

class SkeletonExample1 extends StatelessWidget {
  const SkeletonExample1({super.key, this.loading = true});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    // `Basic` hugs its content, so both states take the row's width:
    // nothing moves when the value arrives.
    return SizedBox(
      width: _kRowWidth,
      child: loading
          // The caller knows what is loading, so it puts a skeleton in each
          // slot the value will fill, sized to that value's box: Avatar md
          // is 40, the title line is 26 tall (16 × 1.6), and two content
          // lines are 44 (two 16-px bars, 12 apart). The trailing chevron is
          // the row's own chrome and stays. One LoadingRegion announces the
          // load once for the whole area.
          ? const LoadingRegion(
              child: Basic(
                leading: Skeleton.circle(size: 40),
                title: Skeleton(width: 120, height: 26),
                content: Skeleton.text(
                  skeletonStyle: CoreSkeletonStyle(lines: 2, lineHeight: 16),
                ),
                trailing: Icon(LucideIcons.chevronRight),
              ),
            )
          : const Basic(
              leading: Avatar(initials: 'AL'),
              title: Text('Alice Lee'),
              content: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              ),
              trailing: Icon(LucideIcons.chevronRight),
            ),
    );
  }
}

```

## Example 2

**Loading List**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SkeletonExample2 extends StatelessWidget {
  const SkeletonExample2({super.key, this.orders});

  /// `null` while the orders are still loading.
  final List<String>? orders;

  @override
  Widget build(BuildContext context) {
    final orders = this.orders;
    if (orders == null) {
      // Five skeleton rows, one announcement: the region speaks for the
      // whole list, so a screen reader hears "Loading orders" once.
      return LoadingRegion(
        semanticLabel: 'Loading orders',
        child: Column(
          crossAxisAlignment: .start,
          spacing: CoreSpace.space8,
          children: [
            for (var i = 0; i < 5; i++) const Skeleton(width: 240, height: 20),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: .start,
      spacing: CoreSpace.space8,
      children: [for (final order in orders) Text(order).bodyMedium],
    );
  }
}

```
