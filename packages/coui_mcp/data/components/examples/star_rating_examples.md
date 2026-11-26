# Star Rating Examples

This document contains example code for the star_rating component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class StarRatingExample1 extends StatefulWidget {
  const StarRatingExample1({super.key});

  @override
  State<StarRatingExample1> createState() => _StarRatingExample1State();
}

class _StarRatingExample1State extends State<StarRatingExample1> {
  double value = 1.5;
  @override
  Widget build(BuildContext context) {
    return StarRating(
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
      },
      starSize: 32,
      value: value,
    );
  }
}

```

