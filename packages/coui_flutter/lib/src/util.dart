import 'dart:async';
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

const kDataWidgetLibrary = 'package:data_widget/data_widget.dart';
const kDataWidgetExtensionLibrary = 'package:data_widget/extension.dart';

typedef Predicate<T> = bool Function(T value);
typedef UnaryOperator<T> = T Function(T value);
typedef BinaryOperator<T> = T Function(T a, T b);

const kDefaultDuration = Duration(milliseconds: 500);

typedef ContextedCallback = void Function(BuildContext context);
typedef ContextedValueChanged<T> = void Function(BuildContext context, T value);

typedef SearchPredicate<T> = double Function(String query, T value);

double degToRad(double deg) => deg * (pi / 180);
double radToDeg(double rad) => rad * (180 / pi);

enum SortDirection {
  ascending,
  descending,
  none,
}

typedef OnContextInvokeCallback<T extends Intent> =
    Object? Function(T intent, [BuildContext? context]);

class CallbackContextAction<T extends Intent> extends ContextAction<T> {
  CallbackContextAction({required this.onInvoke});

  final OnContextInvokeCallback onInvoke;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    return onInvoke(intent, context);
  }
}

class SafeLerp<T> {
  const SafeLerp(this.nullableLerp);

  final T? Function(T? a, T? b, double t) nullableLerp;

  T lerp(T a, T b, double t) {
    final result = nullableLerp(a, b, t);
    assert(result != null, 'Unsafe lerp');

    return result!;
  }
}

extension SafeLerpExtension<T> on T? Function(T? a, T? b, double t) {
  T nonNull(T a, T b, double t) {
    final result = this(a, b, t);
    assert(result != null);

    return result!;
  }
}

extension ListExtension<T> on List<T> {
  int? indexOfOrNull(T obj, [int start = 0]) {
    final index = indexOf(obj, start);

    return index == -1 ? null : index;
  }

  int? lastIndexOfOrNull(T obj, [int? start]) {
    final index = lastIndexOf(obj, start);

    return index == -1 ? null : index;
  }

  int? indexWhereOrNull(Predicate<T> test, [int start = 0]) {
    final index = indexWhere(test, start);

    return index == -1 ? null : index;
  }

  int? lastIndexWhereOrNull(Predicate<T> test, [int? start]) {
    final index = lastIndexWhere(test, start);

    return index == -1 ? null : index;
  }

  bool swapItem(T element, int targetIndex) {
    final currentIndex = indexOf(element);
    if (currentIndex == -1) {
      insert(targetIndex, element);

      return true;
    }
    if (currentIndex == targetIndex) {
      return true;
    }
    if (targetIndex >= length) {
      remove(element);
      add(element);

      return true;
    }
    removeAt(currentIndex);
    if (currentIndex < targetIndex) {
      insert(targetIndex - 1, element);
    } else {
      insert(targetIndex, element);
    }

    return true;
  }

  bool swapItemWhere(int targetIndex, Predicate<T> test) {
    final currentIndex = indexWhere(test);
    if (currentIndex == -1) {
      return false;
    }
    final element = this[currentIndex];

    return swapItem(element, targetIndex);
  }

  T? optGet(int index) {
    return index < 0 || index >= length ? null : this[index];
  }
}

double unlerpDouble(double max, double min, double value) {
  return (value - min) / (max - min);
}

void swapItemInLists<T>(
  List<List<T>> lists,
  T element,
  List<T> targetList,
  int targetIndex,
) {
  for (final list in lists) {
    if (list != targetList) {
      list.remove(element);
    }
  }
  targetList.swapItem(element, targetIndex);
}

BorderRadius? optionallyResolveBorderRadius(
  BuildContext context,
  BorderRadiusGeometry? radius,
) {
  if (radius == null) {
    return null;
  }

  return radius is BorderRadius
      ? radius
      : radius.resolve(Directionality.of(context));
}

/// A style helper function that returns the value from the widget, theme, or default value.
T styleValue<T>({T? widgetValue, T? themeValue, required T defaultValue}) {
  return widgetValue ?? themeValue ?? defaultValue;
}

extension FutureOrExtension<T> on FutureOr<T> {
  FutureOr<R> map<R>(R Function(T value) transform) {
    return this is Future<T>
        ? (this as Future<T>).then(transform)
        : transform(this as T);
  }

  FutureOr<R> flatMap<R>(FutureOr<R> Function(T value) transform) {
    return this is Future<T>
        ? (this as Future<T>).then(transform)
        : transform(this as T);
  }

  FutureOr<R> then<R>(FutureOr<R> Function(T value) transform) {
    return this is Future<T>
        ? (this as Future<T>).then(transform)
        : transform(this as T);
  }
}

extension AlignmentExtension on AlignmentGeometry {
  Alignment optionallyResolve(BuildContext context) {
    // The code belows also ignores if the alignment is already resolved,
    // but the code below fetches the directionality of the context.
    return this is Alignment
        ? this as Alignment
        : resolve(Directionality.of(context));
  }
}

extension BorderRadiusExtension on BorderRadiusGeometry {
  BorderRadius optionallyResolve(BuildContext context) {
    return this is BorderRadius
        ? this as BorderRadius
        : resolve(Directionality.of(context));
  }
}

extension EdgeInsetsExtension on EdgeInsetsGeometry {
  EdgeInsets optionallyResolve(BuildContext context) {
    return this is EdgeInsets
        ? this as EdgeInsets
        : resolve(Directionality.of(context));
  }
}

BorderRadius subtractByBorder(double borderWidth, BorderRadius radius) {
  return BorderRadius.only(
    topLeft: _subtractSafe(radius.topLeft, Radius.circular(borderWidth)),
    topRight: _subtractSafe(radius.topRight, Radius.circular(borderWidth)),
    bottomLeft: _subtractSafe(radius.bottomLeft, Radius.circular(borderWidth)),
    bottomRight: _subtractSafe(
      radius.bottomRight,
      Radius.circular(borderWidth),
    ),
  );
}

Radius _subtractSafe(Radius a, Radius b) {
  return Radius.elliptical(max(0, a.x - b.x), max(0, a.y - b.y));
}

bool isMobile(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return true;

    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

class CapturedWrapper extends StatefulWidget {
  const CapturedWrapper({
    required this.child,
    this.data,
    super.key,
    this.themes,
  });

  final CapturedThemes? themes;
  final CapturedData? data;

  final Widget child;

  @override
  State<CapturedWrapper> createState() => _CapturedWrapperState();
}

class _CapturedWrapperState extends State<CapturedWrapper> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget child = KeyedSubtree(key: _key, child: widget.child);
    if (widget.themes != null) {
      child = widget.themes!.wrap(child);
    }
    if (widget.data != null) {
      child = widget.data!.wrap(child);
    }

    return child;
  }
}

T tweenValue<T>(T begin, T end, double t) {
  final dynamic beginValue = begin;
  final dynamic endValue = end;

  return (beginValue + (endValue - beginValue) * t) as T;
}

double wrapDouble(double max, double min, double value) {
  final range = max - min;

  return range == 0 ? min : (value - min) % range + min;
}

class WidgetTreeChangeDetector extends StatefulWidget {
  const WidgetTreeChangeDetector({
    required this.child,
    super.key,
    required this.onWidgetTreeChange,
  });

  final Widget child;

  final void Function() onWidgetTreeChange;

  @override
  _WidgetTreeChangeDetectorState createState() =>
      _WidgetTreeChangeDetectorState();
}

class _WidgetTreeChangeDetectorState extends State<WidgetTreeChangeDetector> {
  @override
  void initState() {
    super.initState();
    widget.onWidgetTreeChange();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Widget gap(double gap, {double? crossGap}) {
  return Gap(gap, crossAxisExtent: crossGap);
}

extension Joinable<T extends Widget> on List<T> {
  List<T> joinSeparator(T separator) {
    final result = <T>[];
    for (int i = 0; i < length; i += 1) {
      if (i > 0) {
        result.add(separator);
      }
      result.add(this[i]);
    }

    return result;
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> joinSeparator(T separator) {
    return map((e) => [separator, e]).expand((element) => element).skip(1);
  }

  Iterable<T> buildSeparator(ValueGetter<T> separator) {
    return map((e) => [separator(), e]).expand((element) => element).skip(1);
  }
}

typedef NeverWidgetBuilder =
    Widget Function([
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
      dynamic,
    ]);

extension WidgetExtension on Widget {
  NeverWidgetBuilder get asBuilder =>
      ([a, b, c, d, e, f, g, h, i, j]) => this;

  Widget sized({double? height, double? width}) {
    return this is SizedBox
        ? SizedBox(
            width: width ?? (this as SizedBox).width,
            height: height ?? (this as SizedBox).height,
            child: (this as SizedBox).child,
          )
        : SizedBox(width: width, height: height?.toDouble(), child: this);
  }

  Widget constrained({
    double? height,
    double? maxHeight,
    double? maxWidth,
    double? minHeight,
    double? minWidth,
    double? width,
  }) {
    return this is ConstrainedBox
        ? ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  width ??
                  minWidth ??
                  (this as ConstrainedBox).constraints.minWidth,
              maxWidth:
                  width ??
                  maxWidth ??
                  (this as ConstrainedBox).constraints.maxWidth,
              minHeight:
                  height ??
                  minHeight ??
                  (this as ConstrainedBox).constraints.minHeight,
              maxHeight:
                  height ??
                  maxHeight ??
                  (this as ConstrainedBox).constraints.maxHeight,
            ),
            child: (this as ConstrainedBox).child,
          )
        : ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: width ?? minWidth ?? 0,
              maxWidth: width ?? maxWidth ?? double.infinity,
              minHeight: height ?? minHeight ?? 0,
              maxHeight: height ?? maxHeight ?? double.infinity,
            ),
            child: this,
          );
  }

  Widget withPadding({
    double? all,
    double? bottom,
    double? horizontal,
    double? left,
    EdgeInsetsGeometry? padding,
    double? right,
    double? top,
    double? vertical,
  }) {
    assert(() {
      if (all != null) {
        if (top != null ||
            bottom != null ||
            left != null ||
            right != null ||
            horizontal != null ||
            vertical != null) {
          throw FlutterError(
            'All padding properties cannot be used with other padding properties.',
          );
        }
      } else if (horizontal != null) {
        if (left != null || right != null) {
          throw FlutterError(
            'Horizontal padding cannot be used with left or right padding.',
          );
        }
      } else if (vertical != null) {
        if (top != null || bottom != null) {
          throw FlutterError(
            'Vertical padding cannot be used with top or bottom padding.',
          );
        }
      }

      return true;
    }());
    final edgeInsets = EdgeInsets.only(
      left: left ?? horizontal ?? all ?? 0,
      top: top ?? vertical ?? all ?? 0,
      right: right ?? horizontal ?? all ?? 0,
      bottom: bottom ?? vertical ?? all ?? 0,
    );

    return Padding(padding: padding ?? edgeInsets, child: this);
  }

  Widget withMargin({
    double? all,
    double? bottom,
    double? horizontal,
    double? left,
    double? right,
    double? top,
    double? vertical,
  }) {
    assert(() {
      if (all != null) {
        if (top != null ||
            bottom != null ||
            left != null ||
            right != null ||
            horizontal != null ||
            vertical != null) {
          throw FlutterError(
            'All margin properties cannot be used with other margin properties.',
          );
        }
      } else if (horizontal != null) {
        if (left != null || right != null) {
          throw FlutterError(
            'Horizontal margin cannot be used with left or right margin.',
          );
        }
      } else if (vertical != null) {
        if (top != null || bottom != null) {
          throw FlutterError(
            'Vertical margin cannot be used with top or bottom margin.',
          );
        }
      }

      return true;
    }());

    return Padding(
      padding: EdgeInsets.only(
        left: left ?? horizontal ?? all ?? 0,
        top: top ?? vertical ?? all ?? 0,
        right: right ?? horizontal ?? all ?? 0,
        bottom: bottom ?? vertical ?? all ?? 0,
      ),
      child: this,
    );
  }

  Widget center({Key? key}) {
    return Center(key: key, child: this);
  }

  Widget withAlign(AlignmentGeometry alignment) {
    return Align(alignment: alignment, child: this);
  }

  Widget positioned({
    double? bottom,
    Key? key,
    double? left,
    double? right,
    double? top,
  }) {
    return Positioned(
      key: key,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: this,
    );
  }

  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  Widget withOpacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  Widget clip({Clip clipBehavior = Clip.hardEdge}) {
    return ClipRect(clipBehavior: clipBehavior, child: this);
  }

  Widget clipRRect({
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: this,
    );
  }

  Widget clipOval({Clip clipBehavior = Clip.antiAlias}) {
    return ClipOval(clipBehavior: clipBehavior, child: this);
  }

  Widget clipPath({
    Clip clipBehavior = Clip.antiAlias,
    required CustomClipper<Path> clipper,
  }) {
    return ClipPath(
      clipper: clipper,
      clipBehavior: clipBehavior,
      child: this,
    );
  }

  Widget transform({Key? key, required Matrix4 transform}) {
    return Transform(key: key, transform: transform, child: this);
  }

  Widget intrinsicWidth({double? stepHeight, double? stepWidth}) {
    return IntrinsicWidth(
      stepWidth: stepWidth,
      stepHeight: stepHeight,
      child: this,
    );
  }

  Widget intrinsicHeight() {
    return IntrinsicHeight(child: this);
  }

  Widget intrinsic({double? stepHeight, double? stepWidth}) {
    return IntrinsicWidth(
      stepWidth: stepWidth,
      stepHeight: stepHeight,
      child: IntrinsicHeight(child: this),
    );
  }
}

extension ColumnExtension on Column {
  Widget gap(double gap) {
    return separator(SizedBox(height: gap));
  }

  Widget separator(Widget separator) {
    return SeparatedFlex(
      key: key,
      clipBehavior: clipBehavior,
      crossAxisAlignment: crossAxisAlignment,
      direction: Axis.vertical,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      separator: separator,
      textBaseline: textBaseline,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      children: children,
    );
  }
}

extension RowExtension on Row {
  Widget gap(double gap) {
    return separator(SizedBox(width: gap));
  }

  Widget separator(Widget separator) {
    return SeparatedFlex(
      key: key,
      clipBehavior: clipBehavior,
      crossAxisAlignment: crossAxisAlignment,
      direction: Axis.horizontal,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      separator: separator,
      textBaseline: textBaseline,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      children: children,
    );
  }
}

class SeparatedFlex extends StatefulWidget {
  const SeparatedFlex({
    required this.children,
    this.clipBehavior = Clip.none,
    required this.crossAxisAlignment,
    required this.direction,
    super.key,
    required this.mainAxisAlignment,
    required this.mainAxisSize,
    required this.separator,
    this.textBaseline,
    this.textDirection,
    required this.verticalDirection,
  });

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Widget> children;
  final Axis direction;
  final Widget separator;

  final Clip clipBehavior;

  @override
  State<SeparatedFlex> createState() => _SeparatedFlexState();
}

class _SeparatedFlexState extends State<SeparatedFlex> {
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = join(widget.children, widget.separator).toList();
  }

  @override
  void didUpdateWidget(covariant SeparatedFlex oldWidget) {
    super.didUpdateWidget(oldWidget);
    mutateSeparated(_children, widget.separator, widget.children);
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      key: widget.key,
      direction: widget.direction,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      textBaseline: widget.textBaseline,
      clipBehavior: widget.clipBehavior,
      children: _children,
    );
  }
}

extension FlexExtension on Flex {
  Widget gap(double gap) {
    return separator(
      direction == Axis.vertical ? SizedBox(height: gap) : SizedBox(width: gap),
    );
  }

  Widget separator(Widget separator) {
    return SeparatedFlex(
      key: key,
      clipBehavior: clipBehavior,
      crossAxisAlignment: crossAxisAlignment,
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      separator: separator,
      textBaseline: textBaseline,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      children: children,
    );
  }
}

Iterable<Widget> join(Iterable<Widget> widgets, Widget separator) {
  return SeparatedIterable(widgets, separator);
}

extension DoubleExtension on double {
  double min(double other) => this < other ? this : other;

  double max(double other) => this > other ? this : other;
}

extension IntExtension on int {
  int min(int other) => this < other ? this : other;

  int max(int other) => this > other ? this : other;
}

class IconThemeDataTween extends Tween<IconThemeData> {
  IconThemeDataTween({super.begin, super.end});

  @override
  IconThemeData lerp(double t) => IconThemeData.lerp(begin, end, t);
}

extension ColorExtension on Color {
  Color scaleAlpha(double factor) {
    return withValues(alpha: a * factor);
  }

  Color getContrastColor([double luminanceContrast = 1]) {
    // luminance contrast is between 0..1
    assert(
      luminanceContrast >= 0 && luminanceContrast <= 1,
      'luminanceContrast should be between 0 and 1',
    );
    final hsl = HSLColor.fromColor(this);
    final currentLuminance = hsl.lightness;
    double targetLuminance;
    targetLuminance = currentLuminance >= 0.5
        ? currentLuminance - (currentLuminance * luminanceContrast)
        : currentLuminance + ((1 - currentLuminance) * luminanceContrast);

    return hsl.withLightness(targetLuminance).toColor();
  }

  Color withLuminance(double luminance) {
    final hsl = HSLColor.fromColor(this);

    return hsl.withLightness(luminance).toColor();
  }

  String toHex({bool includeAlpha = true, bool includeHashSign = false}) {
    String hex = toARGB32().toRadixString(16).padLeft(8, '0');
    if (!includeAlpha) {
      hex = hex.substring(2);
    }
    if (includeHashSign) {
      hex = '#$hex';
    }

    return hex;
  }

  HSLColor toHSL() {
    return HSLColor.fromColor(this);
  }

  HSVColor toHSV() {
    return HSVColor.fromColor(this);
  }
}

extension HSLColorExtension on HSLColor {
  HSVColor toHSV() {
    final l = lightness;
    final s = saturation;
    final h = hue;
    final a = alpha;
    final v = l + s * min(l, 1 - l);
    double newH;
    double newS;
    if (v == 0) {
      newH = 0;
      newS = 0;
    } else {
      newS = (1 - l / v) * 2;
      newH = h;
    }

    return HSVColor.fromAHSV(a, newH, newS, v);
  }
}

extension HSVColorExtension on HSVColor {
  HSLColor toHSL() {
    final v = value;
    final s = saturation;
    final h = hue;
    final a = alpha;
    final l = v * (1 - s / 2);
    double newH;
    double newS;
    if (l == 0 || l == 1) {
      newH = 0;
      newS = 0;
    } else {
      newS = (v - l) / min(l, 1 - l);
      newH = h;
    }

    return HSLColor.fromAHSL(a, newH, newS, l);
  }
}

class TimeOfDay {
  const TimeOfDay({
    required this.hour,
    required this.minute,
    this.second = 0,
  });

  const TimeOfDay.pm({
    required int hour,
    required this.minute,
    this.second = 0,
  }) : hour = hour + 12;

  const TimeOfDay.am({
    required this.hour,
    required this.minute,
    this.second = 0,
  });

  TimeOfDay.fromDateTime(DateTime dateTime)
    : hour = dateTime.hour,
      minute = dateTime.minute,
      second = dateTime.second;

  TimeOfDay.fromDuration(Duration duration)
    : hour = duration.inHours,
      minute = duration.inMinutes % 60,
      second = duration.inSeconds % 60;

  TimeOfDay.now() : this.fromDateTime(DateTime.now());

  final int hour;

  final int minute;

  final int second;

  TimeOfDay copyWith({
    ValueGetter<int>? hour,
    ValueGetter<int>? minute,
    ValueGetter<int>? second,
  }) {
    return TimeOfDay(
      hour: hour == null ? this.hour : hour(),
      minute: minute == null ? this.minute : minute(),
      second: second == null ? this.second : second(),
    );
  }

  /// For backward compatibility.
  TimeOfDay replacing({int? hour, int? minute, int? second}) {
    return TimeOfDay(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      second: second ?? this.second,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimeOfDay &&
        other.hour == hour &&
        other.minute == minute &&
        other.second == second;
  }

  @override
  String toString() {
    return 'TimeOfDay{hour: $hour, minute: $minute, second: $second}';
  }

  @override
  int get hashCode => Object.hash(hour, minute, second);
}

(bool, Object?) invokeActionOnFocusedWidget(Intent intent) {
  final context = primaryFocus?.context;
  if (context != null) {
    final action = Actions.maybeFind<Intent>(context, intent: intent);
    if (action != null) {
      final (bool enabled, Object? invokeResult) = Actions.of(
        context,
      ).invokeActionIfEnabled(action, intent);

      return (enabled, invokeResult);
    }
  }

  return (false, null);
}

extension TextEditingControllerExtension on TextEditingController {
  String? get currentWord {
    final value = this.value;
    final text = value.text;
    final selection = value.selection;
    if (text.isEmpty) {
      return null;
    }

    return selection.isCollapsed
        ? getWordAtCaret(selection.baseOffset, text).$2
        : null;
  }
}

typedef WordInfo = (int, String);
typedef ReplacementInfo = (int, String);

WordInfo getWordAtCaret(int caret, String text, [String separator = ' ']) {
  if (caret < 0 || caret > text.length) {
    throw RangeError('Caret position is out of bounds.');
  }

  int start = caret;
  while (start > 0 && !separator.contains(text[start - 1])) {
    start -= 1;
  }

  int end = caret;
  while (end < text.length && !separator.contains(text[end])) {
    end += 1;
  }

  // Return the start index and the word at the caret position
  final word = text.substring(start, end);

  return (start, word);
}

ReplacementInfo replaceWordAtCaret(
  int caret,
  String replacement,
  String text, [
  String separator = ' ',
]) {
  if (caret < 0 || caret > text.length) {
    throw RangeError('Caret position is out of bounds.');
  }

  int start = caret;
  while (start > 0 && !separator.contains(text[start - 1])) {
    start -= 1;
  }

  int end = caret;
  while (end < text.length && !separator.contains(text[end])) {
    end += 1;
  }

  // Replace the word with the replacement
  final newText = text.replaceRange(start, end, replacement);

  return (start, newText);
}

void clearActiveTextInput() {
  const intent = TextFieldClearIntent();
  invokeActionOnFocusedWidget(intent);
}

mixin CachedValue {
  bool shouldRebuild(covariant CachedValue oldValue);
}

class CachedValueWidget<T> extends StatefulWidget {
  const CachedValueWidget({
    required this.builder,
    super.key,
    required this.value,
  });

  final T value;

  final Widget Function(BuildContext context, T value) builder;

  @override
  State<StatefulWidget> createState() => _CachedValueWidgetState<T>();
}

class _CachedValueWidgetState<T> extends State<CachedValueWidget<T>> {
  Widget? _cachedWidget;

  @override
  void didUpdateWidget(covariant CachedValueWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (T is CachedValue) {
      if ((widget.value as CachedValue).shouldRebuild(
        oldWidget.value as CachedValue,
      )) {
        _cachedWidget = null;
      }
    } else {
      if (widget.value != oldWidget.value) {
        _cachedWidget = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _cachedWidget ??= widget.builder(context, widget.value);

    return _cachedWidget!;
  }
}

typedef Convert<F, T> = T Function(F value);

class BiDirectionalConvert<A, B> {
  const BiDirectionalConvert(this.aToB, this.bToA);

  final Convert<A, B> aToB;

  final Convert<B, A> bToA;

  B convertA(A value) => aToB(value);

  A convertB(B value) => bToA(value);

  @override
  String toString() {
    return 'BiDirectionalConvert($aToB, $bToA)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BiDirectionalConvert<A, B> &&
        other.aToB == aToB &&
        other.bToA == bToA;
  }
}

class ConvertedController<F, T> extends ChangeNotifier
    implements ComponentController<T> {
  ConvertedController(
    BiDirectionalConvert<F, T> convert,
    ValueNotifier<F> other,
  ) : _other = other,
      _convert = convert,
      _value = convert.convertA(other.value) {
    _other.addListener(_onOtherValueChanged);
  }
  final ValueNotifier<F> _other;

  final BiDirectionalConvert<F, T> _convert;
  T _value;

  bool _isUpdating = false;

  @override
  void dispose() {
    _other.removeListener(_onOtherValueChanged);
    super.dispose();
  }

  void _onOtherValueChanged() {
    if (_isUpdating) {
      return;
    }
    _isUpdating = true;
    try {
      _value = _convert.convertA(_other.value);
      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  void _onValueChanged() {
    if (_isUpdating) {
      return;
    }
    _isUpdating = true;
    try {
      _other.value = _convert.convertB(_value);
    } finally {
      _isUpdating = false;
    }
  }

  @override
  T get value => _value;

  @override
  set value(T newValue) {
    if (newValue == _value) {
      return;
    }
    _value = newValue;
    notifyListeners();
    _onValueChanged();
  }
}

extension TextEditingValueExtension on TextEditingValue {
  TextEditingValue replaceText(String newText) {
    TextSelection selection = this.selection;
    selection = selection.copyWith(
      baseOffset: selection.baseOffset.clamp(0, newText.length),
      extentOffset: selection.extentOffset.clamp(0, newText.length),
    );

    return TextEditingValue(text: newText, selection: selection);
  }
}

typedef OnContextedCallback<T extends Intent> =
    Object? Function(T intent, [BuildContext? context]);

class ContextCallbackAction<T extends Intent> extends ContextAction<T> {
  ContextCallbackAction({required this.onInvoke});

  final OnContextedCallback<T> onInvoke;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    return onInvoke(intent, context);
  }
}
