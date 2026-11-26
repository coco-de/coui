# Carousel Examples

This document contains example code for the carousel component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample1 extends StatefulWidget {
  const CarouselExample1({super.key});

  @override
  State<CarouselExample1> createState() => _CarouselExample1State();
}

class _CarouselExample1State extends State<CarouselExample1> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      child: Row(
        children: [
          OutlineButton(
            onPressed: () {
              controller.animatePrevious(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_back),
          ),
          const Gap(size: 24),
          Expanded(
            child: SizedBox(
              height: 200,
              child: Carousel(
                autoplaySpeed: const Duration(seconds: 2),
                controller: controller,
                duration: const Duration(seconds: 1),
                itemBuilder: (context, index) {
                  return NumberedContainer(index: index);
                },
                itemCount: 5,
                sizeConstraint: const CarouselFixedConstraint(200),
                // frameTransform: Carousel.fadingTransform,
                transition: const CarouselTransition.sliding(gap: 24),
              ),
            ),
          ),
          const Gap(size: 24),
          OutlineButton(
            onPressed: () {
              controller.animateNext(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample2 extends StatefulWidget {
  const CarouselExample2({super.key});

  @override
  State<CarouselExample2> createState() => _CarouselExample2State();
}

class _CarouselExample2State extends State<CarouselExample2> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlineButton(
            onPressed: () {
              controller.animatePrevious(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_upward),
          ),
          const Gap(size: 24),
          Expanded(
            child: SizedBox(
              width: 200,
              child: Carousel(
                alignment: CarouselAlignment.center,
                controller: controller,
                direction: Axis.vertical,
                itemBuilder: (context, index) {
                  return NumberedContainer(index: index);
                },
                sizeConstraint: const CarouselFixedConstraint(200),
                transition: const CarouselTransition.sliding(gap: 24),
              ),
            ),
          ),
          const Gap(size: 24),
          OutlineButton(
            onPressed: () {
              controller.animateNext(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample3 extends StatefulWidget {
  const CarouselExample3({super.key});

  @override
  State<CarouselExample3> createState() => _CarouselExample3State();
}

class _CarouselExample3State extends State<CarouselExample3> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Carousel(
              autoplaySpeed: const Duration(seconds: 1),
              controller: controller,
              draggable: false,
              duration: const Duration(seconds: 1),
              itemBuilder: (context, index) {
                return NumberedContainer(index: index);
              },
              itemCount: 5,
              transition: const CarouselTransition.fading(),
            ),
          ),
          const Gap(size: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarouselDotIndicator(controller: controller, itemCount: 5),
              const Spacer(),
              OutlineButton(
                onPressed: () {
                  controller.animatePrevious(const Duration(milliseconds: 500));
                },
                shape: ButtonShape.circle,
                child: const Icon(Icons.arrow_back),
              ),
              const Gap(size: 8),
              OutlineButton(
                onPressed: () {
                  controller.animateNext(const Duration(milliseconds: 500));
                },
                shape: ButtonShape.circle,
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample4 extends StatefulWidget {
  const CarouselExample4({super.key});

  @override
  State<CarouselExample4> createState() => _CarouselExample4State();
}

class _CarouselExample4State extends State<CarouselExample4> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 200,
      child: Carousel(
        autoplaySpeed: const Duration(seconds: 2),
        controller: controller,
        curve: Curves.linear,
        draggable: false,
        duration: Duration.zero,
        itemBuilder: (context, index) {
          return NumberedContainer(index: index);
        },
        itemCount: 5,
        sizeConstraint: const CarouselSizeConstraint.fixed(200),
        transition: const CarouselTransition.sliding(gap: 24),
      ),
    );
  }
}

```

