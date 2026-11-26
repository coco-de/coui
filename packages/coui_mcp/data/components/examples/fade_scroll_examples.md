# Fade Scroll Examples

This document contains example code for the fade_scroll component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

const _kItemCount = 20;
const _kContainerHeight = 200.0;

class FadeScrollExample1 extends StatefulWidget {
  const FadeScrollExample1({super.key});

  @override
  State<FadeScrollExample1> createState() => _FadeScrollExample1State();
}

class _FadeScrollExample1State extends State<FadeScrollExample1> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kContainerHeight,
      child: FadeScroll(
        controller: _controller,
        child: ListView.builder(
          controller: _controller,
          itemCount: _kItemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text('Item ${index + 1}'),
            );
          },
        ),
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

const _kItemCount = 15;
const _kContainerHeight = 60.0;
const _kItemWidth = 80.0;
const _kFadeOffset = 40.0;

class FadeScrollExample2 extends StatefulWidget {
  const FadeScrollExample2({super.key});

  @override
  State<FadeScrollExample2> createState() => _FadeScrollExample2State();
}

class _FadeScrollExample2State extends State<FadeScrollExample2> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kContainerHeight,
      child: FadeScroll(
        controller: _controller,
        startOffset: _kFadeOffset,
        endOffset: _kFadeOffset,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: _kItemCount,
          itemBuilder: (context, index) {
            return SizedBox(
              width: _kItemWidth,
              child: Card(child: Center(child: Text('${index + 1}'))),
            );
          },
        ),
      ),
    );
  }
}

```

