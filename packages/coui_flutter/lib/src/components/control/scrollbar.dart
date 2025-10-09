// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [Scrollbar].
class ScrollbarTheme {
  /// Creates a [ScrollbarTheme].
  const ScrollbarTheme({this.color, this.radius, this.thickness});

  /// Color of the scrollbar thumb.
  final Color? color;

  /// Thickness of the scrollbar thumb.
  final double? thickness;

  /// Radius of the scrollbar thumb.
  final Radius? radius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScrollbarTheme &&
        other.color == color &&
        other.thickness == thickness &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(color, thickness, radius);
}

const _kScrollbarMinLength = 48;
const _kScrollbarFadeDuration = Duration(milliseconds: 300);
const _kScrollbarTimeToFade = Duration(milliseconds: 600);

class Scrollbar extends StatelessWidget {
  const Scrollbar({
    required this.child,
    this.color,
    this.controller,
    this.interactive,
    super.key,
    this.notificationPredicate,
    this.radius,
    this.scrollbarOrientation,
    this.thickness,
    this.thumbVisibility,
    this.trackVisibility,
  });
  final Widget child;
  final ScrollController? controller;
  final bool? thumbVisibility;
  final bool? trackVisibility;

  final double? thickness;

  final Radius? radius;
  final Color? color;

  final bool? interactive;
  final ScrollNotificationPredicate? notificationPredicate;
  final ScrollbarOrientation? scrollbarOrientation;

  @override
  Widget build(BuildContext context) {
    return _CoUIScrollbar(
      color: color,
      controller: controller,
      interactive: interactive,
      notificationPredicate: notificationPredicate,
      radius: radius,
      scrollbarOrientation: scrollbarOrientation,
      thickness: thickness,
      thumbVisibility: thumbVisibility,
      trackVisibility: trackVisibility,
      child: child,
    );
  }
}

class _CoUIScrollbar extends RawScrollbar {
  const _CoUIScrollbar({
    required super.child,
    this.color,
    super.controller,
    super.interactive,
    ScrollNotificationPredicate? notificationPredicate,
    super.radius,
    super.scrollbarOrientation,
    super.thickness,
    super.thumbVisibility,
    super.trackVisibility,
  }) : super(
         fadeDuration: _kScrollbarFadeDuration,
         timeToFade: _kScrollbarTimeToFade,
         pressDuration: Duration.zero,
         notificationPredicate:
             notificationPredicate ?? defaultScrollNotificationPredicate,
       );

  final Color? color;

  @override
  _CoUIScrollbarState createState() => _CoUIScrollbarState();
}

class _CoUIScrollbarState extends RawScrollbarState<_CoUIScrollbar> {
  late AnimationController _hoverAnimationController;
  bool _hoverIsActive = false;
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimationController.addListener(updateScrollbarPainter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
  }

  @override
  void updateScrollbarPainter() {
    final compTheme = ComponentTheme.maybeOf<ScrollbarTheme>(context);
    scrollbarPainter
      ..color = styleValue(
        widgetValue: widget.color,
        themeValue: compTheme?.color,
        defaultValue: _theme.colorScheme.border,
      )
      ..textDirection = Directionality.of(context)
      // Should this be affected by density?
      ..thickness = styleValue(
        widgetValue: widget.thickness,
        themeValue: compTheme?.thickness,
        defaultValue: _theme.scaling * 7.0,
      )
      ..radius = styleValue(
        widgetValue: widget.radius,
        themeValue: compTheme?.radius,
        defaultValue: Radius.circular(_theme.radiusSm),
      )
      ..minLength = _kScrollbarMinLength.toDouble()
      ..padding = MediaQuery.paddingOf(context) + EdgeInsets.all(_theme.scaling)
      ..scrollbarOrientation = widget.scrollbarOrientation
      ..ignorePointer = !enableGestures;
  }

  @override
  void handleHover(PointerHoverEvent event) {
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbar(event.position, event.kind, forHover: true)) {
      // Pointer is hovering over the scrollbar
      setState(() {
        _hoverIsActive = true;
      });
      _hoverAnimationController.forward();
    } else if (_hoverIsActive) {
      // Pointer was, but is no longer over painted scrollbar.
      setState(() {
        _hoverIsActive = false;
      });
      _hoverAnimationController.reverse();
    }
    super.handleHover(event);
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    setState(() {
      _hoverIsActive = false;
    });
    _hoverAnimationController.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  bool get enableGestures => widget.interactive ?? true;
}
