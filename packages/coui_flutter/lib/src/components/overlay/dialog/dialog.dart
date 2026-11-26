import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:coui_flutter/src/components/overlay/dialog/dialog_actions_stretch_layout.dart';

// ---------------------------------------------------------------------------
// DialogRoute
// ---------------------------------------------------------------------------

/// Custom route implementation for CoUI dialogs.
///
/// Extends [RawDialogRoute] to provide consistent dialog behavior with
/// proper theme inheritance, data capture, and transition animations.
/// Supports an optional [barrierColorBuilder] callback for dynamic barrier
/// colours that depend on the navigator context.
class DialogRoute<T> extends RawDialogRoute<T> {
  /// Creates a [DialogRoute].
  DialogRoute({
    required WidgetBuilder builder,
    required super.transitionBuilder,
    super.anchorPoint,
    Color barrierColorFallback = const Color.fromRGBO(0, 0, 0, 0),
    this.barrierColorBuilder,
    super.barrierDismissible,
    String? barrierLabel,
    this.data,
    this.dialogStyle,
    this.fullScreen = false,
    super.settings,
    CapturedThemes? themes,
    super.transitionDuration = const Duration(
      milliseconds: CoreDuration.normal,
    ),
    super.traversalEdgeBehavior,
    bool useSafeArea = true,
  }) : _barrierColor = barrierColorFallback,
       _barrierLabel = barrierLabel,
       super(
         pageBuilder: (buildContext, animation, secondaryAnimation) {
           final pageChild = Builder(
             builder: (context) {
               if (fullScreen) return builder(context);
               // The room around the panel is the dialog's
               // `routePadding` — resolved like every other dialog
               // value, so a theme or the launching dialog's own
               // style reaches it and the theme density moves it.
               final routePadding = resolveDialog(
                 context,
                 dialogStyle: dialogStyle,
               ).routePadding;

               return Padding(
                 padding: EdgeInsets.all(routePadding),
                 child: builder(context),
               );
             },
           );
           var dialog = themes?.wrap(pageChild) ?? pageChild;
           if (data != null) {
             dialog = data.wrap(dialog);
           }
           if (useSafeArea) {
             dialog = SafeArea(child: dialog);
           }

           return dialog;
         },
         // Left null on purpose — a constructor initializer has no
         // BuildContext, so the localised name is resolved by the
         // [barrierLabel] getter below instead.
         barrierLabel: null,
       );

  /// Optional callback that resolves barrier colour from the navigator context.
  final Color? Function(BuildContext context)? barrierColorBuilder;

  /// Captured data from the launching context.
  final CapturedData? data;

  /// The launching dialog's own style, read for the room the route leaves
  /// around the panel ([CoreDialogStyle.routePadding]). `null` reads the
  /// theme's dialog style and the design-system default.
  final CoreDialogStyle? dialogStyle;

  /// Whether the dialog should display in full-screen mode.
  final bool fullScreen;

  /// Fallback barrier colour when [barrierColorBuilder] is null.
  final Color _barrierColor;

  /// Caller-supplied barrier label, if any.
  final String? _barrierLabel;

  // The super field is intentionally left null and shadowed: `ModalRoute`
  // takes its barrier label at construction, but a localised name needs a
  // BuildContext that does not exist until the route is installed. Resolving
  // in the getter is the only point where both are available.
  @override
  String get barrierLabel {
    final explicit = _barrierLabel;
    if (explicit != null) return explicit;
    final context = navigator?.context;
    if (context == null) return DefaultCoUILocalizations.instance.dismissLabel;

    return CoUILocalizations.of(context).dismissLabel;
  }

  @override
  Color get barrierColor {
    if (barrierColorBuilder != null && navigator != null) {
      final resolved = barrierColorBuilder!(navigator!.context);

      return resolved ?? _barrierColor;
    }

    return _barrierColor;
  }
}

// ---------------------------------------------------------------------------
// Transition builder
// ---------------------------------------------------------------------------

Widget _buildCoUIDialogTransitions(
  AlignmentGeometry alignment,
  Animation<double> animation,
  BorderRadiusGeometry borderRadius,
  Widget child,
  BuildContext context,
  bool fullScreen,
  Animation<double> secondaryAnimation,
) {
  final scaleTransition = _DialogOpenTransition(
    animation: animation,
    // A full-screen route has no one panel for a surface to be the root of:
    // its content is the caller's, and a glass surface somewhere in it that
    // took the fade over would leave the rest of the page unfaded.
    offersSurfaceFade: !fullScreen,
    child: child,
  );

  return FocusScope(
    child: fullScreen
        ? MultiModel(
            data: const [Model(ModalContainer.kFullScreenMode, true)],
            child: scaleTransition,
          )
        // The keyboard covers the bottom of the window, and the panel is
        // centred inside the window — so, unreduced, a field's dialog put its
        // actions under it. The room is cut by the inset before the panel is
        // aligned in it, which is what a Material dialog does too; the
        // platform animates the inset, so nothing here needs a motion value.
        // Below this the inset is spent: a descendant that reads it again
        // would reserve the keyboard's room twice.
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Align(alignment: alignment, child: scaleTransition),
            ),
          ),
  );
}

/// The panel's open/close zoom + fade.
///
/// The eased curve is owned here and disposed with the transition. It
/// cannot live in [_buildCoUIDialogTransitions] — that is a free function
/// called on every transition frame, so a `CurvedAnimation` built there was
/// allocated per frame with nothing to release it. A `CurveTween` would
/// avoid the ownership question but has no reverse direction, and the
/// close motion's `reverseCurve` is what Web's exit keyframe mirrors.
///
/// Order matters: the curve runs on the raw 0..1 route progress and the
/// scale range is applied after (curve-then-tween). Curving a parent that
/// had already been remapped to `scaleAnimationStart..scaleAnimationEnd`
/// evaluated the curve only on that narrow tail, where it is nearly flat —
/// so the zoom was imperceptible.
///
/// The fade is the panel's surface's to take over where it draws a backdrop
/// pass (`SurfaceFadeHost`): an opacity over a glass panel saves a layer the
/// panel's backdrop filter reads nothing from, so the blur would be gone for
/// the whole of the open and the close and pop back at the end. A panel whose
/// surface draws no pass is faded by the opacity, exactly as before.
class _DialogOpenTransition extends StatefulWidget {
  const _DialogOpenTransition({
    required this.animation,
    required this.offersSurfaceFade,
    required this.child,
  });

  final Animation<double> animation;

  /// Whether the panel's surface is asked to fade itself (see
  /// `SurfaceFadeHost`) rather than the panel being faded as a whole.
  final bool offersSurfaceFade;

  final Widget child;

  @override
  State<_DialogOpenTransition> createState() => _DialogOpenTransitionState();
}

class _DialogOpenTransitionState extends State<_DialogOpenTransition> {
  CurvedAnimation? _scaleCurve;

  // The fade has no reverse curve, so an `Animatable` chain is enough —
  // nothing to own or dispose.
  late Animation<double> _opacity;

  void _bind(Animation<double> animation) {
    _scaleCurve?.dispose();
    _scaleCurve = CurvedAnimation(
      parent: animation,
      curve: CoreEasing.enter.toValue(),
      reverseCurve: CoreEasing.exit.toValue(),
    );
    _opacity = animation.drive(CurveTween(curve: CoreEasing.enter.toValue()));
  }

  @override
  void initState() {
    super.initState();
    _bind(widget.animation);
  }

  @override
  void didUpdateWidget(covariant _DialogOpenTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _bind(widget.animation);
    }
  }

  @override
  void dispose() {
    _scaleCurve?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Open-animation scale range resolves through the single
    // [resolveDialog] entry point so a per-instance / theme
    // `scaleAnimationStart` / `scaleAnimationEnd` override drives the
    // panel zoom (mirrors Web's `--coui-dialog-scale-from/to`).
    final resolved = resolveDialog(context);

    return ScaleTransition(
      scale: _scaleCurve!.drive(
        Tween<double>(
          begin: resolved.scaleAnimationStart,
          end: resolved.scaleAnimationEnd,
        ),
      ),
      child: widget.offersSurfaceFade
          ? SurfaceFadeHost(animation: _opacity, child: widget.child)
          : FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// _DialogOverlayMarker (private InheritedWidget marker)
//
// `MultiModel` + `Model<T>` 패턴은 `MultiModelItem.normalized` 의 covariant
// return 시그니처 (`Model<Object?> get normalized`) 가 dart2js 환경에서 reified
// T 를 보존하지 않고 erase 하는 회귀가 있어, `InheritedModel.isSupportedAspect`
// 의 `model.dataType == aspect.dataType` 매칭이 실패함. `Model<bool>`/`<Object?>`
// 명시적 타입 인자도 효과 없음이 실측됨 (Web 에서만 발생, macOS native 정상).
//
// generic 추론에 의존하지 않는 단순 `InheritedWidget` marker 로 대체하여
// platform 일관성 확보. `_isHostedInDialogOverlay` 판정에는 불리언 값이 필요
// 없고 ancestor 존재 여부만 체크하면 충분.
// ---------------------------------------------------------------------------

class _DialogOverlayMarker extends InheritedWidget {
  const _DialogOverlayMarker({required super.child});

  @override
  bool updateShouldNotify(_DialogOverlayMarker oldWidget) => false;
}

// ---------------------------------------------------------------------------
// _DialogOverlayWrapper (private, used by showDialog / DialogOverlayHandler)
// ---------------------------------------------------------------------------

class _DialogOverlayWrapper<T> extends StatefulWidget {
  const _DialogOverlayWrapper({
    required this.child,
    required this.route,
    super.key,
  });

  final DialogRoute<T> route;

  final Widget child;

  @override
  State<_DialogOverlayWrapper<T>> createState() =>
      _DialogOverlayWrapperState<T>();
}

class _DialogOverlayWrapperState<T> extends State<_DialogOverlayWrapper<T>>
    with OverlayHandlerStateMixin {
  @override
  Future<void> close([bool immediate = false]) {
    final route = widget.route;
    final navigator = route.navigator;
    if (immediate || !route.isCurrent) {
      navigator?.removeRoute(route);
    } else {
      navigator?.pop();
    }

    return route.completed;
  }

  @override
  void closeLater() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final route = widget.route;
      final navigator = route.navigator;
      if (route.isCurrent) {
        navigator?.pop();
      } else {
        navigator?.removeRoute(route);
      }
    });
  }

  @override
  Future<void> closeWithResult<X>([X? value]) {
    final route = widget.route;
    final navigator = route.navigator;
    if (route.isCurrent) {
      navigator?.pop(value);
    } else {
      navigator?.removeRoute(route);
    }

    return route.completed;
  }

  @override
  Widget build(BuildContext context) {
    // `_DialogOverlayMarker` (InheritedWidget) 를 ancestor 로 제공하여
    // `DialogOverlayHandler.isDialogOverlay(context)` 가 true 를 반환하도록 함.
    //
    // 이 marker 가 없으면 outer `showDialog` 의 builder 안에 마운트된
    // [Dialog] 가 `_isHostedInDialogOverlay` 를 false 로 판정하여 자체적으로
    // 또 다른 `_showDialog()` 를 호출(double-push) → outer dialog 가 즉시
    // dismiss 되고 `Future` 가 null 로 resolve 되는 회귀가 발생한다.
    return Data<OverlayHandlerStateMixin>.inherit(
      data: this,
      child: _DialogOverlayMarker(
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// showDialog
// ---------------------------------------------------------------------------

/// Displays a dialog using the CoUI design system.
///
/// Shows a modal dialog with consistent styling and animation behaviour.
/// The dialog is displayed over the current route and blocks interaction
/// with the content below. Supports both centred and full-screen modes.
///
/// Use [barrierColorBuilder] to resolve the barrier colour from the navigator
/// context (e.g. to read the current theme).
///
/// [dialogStyle] is the style the route reads for itself — the room it
/// leaves around the panel (`routePadding`), the barrier and the timing. A
/// `Dialog` opened through its `open` flag passes its own; left `null`, the
/// route reads the theme's dialog style and the design-system defaults.
///
/// Example:
/// ```dart
/// final result = await showDialog<void>(
///   context: context,
///   builder: (context) => Dialog(
///     title: Text('Confirm'),
///     content: Text('Are you sure?'),
///     onClose: () => Navigator.pop(context),
///   ),
/// );
/// ```
Future<T?> showDialog<T>({
  required WidgetBuilder builder,
  required BuildContext context,
  AlignmentGeometry? alignment,
  Offset? anchorPoint,
  Color? barrierColor,
  Color? Function(BuildContext context)? barrierColorBuilder,
  bool barrierDismissible = true,
  String? barrierLabel,
  CoreDialogStyle? dialogStyle,
  bool fullScreen = false,
  RouteSettings? routeSettings,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool useRootNavigator = true,
  bool useSafeArea = true,
}) async {
  final navigatorState = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );

  return await navigatorState.push(
    _createDialogRoute<T>(
      alignment: alignment,
      anchorPoint: anchorPoint,
      barrierColor: barrierColor,
      barrierColorBuilder: barrierColorBuilder,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      context: context,
      dialogStyle: dialogStyle,
      fullScreen: fullScreen,
      navigatorState: navigatorState,
      routeSettings: routeSettings,
      traversalEdgeBehavior: traversalEdgeBehavior,
      useSafeArea: useSafeArea,
      builder: builder,
    ),
  );
}

/// Builds the route [showDialog] pushes onto [navigatorState], without
/// pushing it.
///
/// Split out so a caller that has to close *its own* route later — the
/// declarative [Dialog] — keeps the route itself. Closing a dialog through
/// the navigator's top route closes whatever is on top, which is a page or
/// another dialog whenever one was opened over this one.
DialogRoute<T> _createDialogRoute<T>({
  required WidgetBuilder builder,
  required BuildContext context,
  required NavigatorState navigatorState,
  AlignmentGeometry? alignment,
  Offset? anchorPoint,
  Color? barrierColor,
  Color? Function(BuildContext context)? barrierColorBuilder,
  bool barrierDismissible = true,
  String? barrierLabel,
  CoreDialogStyle? dialogStyle,
  bool fullScreen = false,
  RouteSettings? routeSettings,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool useSafeArea = true,
}) {
  final themes = InheritedTheme.capture(
    from: context,
    to: navigatorState.context,
  );
  final data = Data.capture(from: context, to: navigatorState.context);
  // Default barrier resolves to the same `scrim` token at the scrim
  // strength (`CoreOpacity.scrim`) the Web `Dialog` backdrop paints
  // (`rgb(var(--coui-scrim) / 30%)`). When `barrierColor` is explicitly
  // passed it wins, otherwise we delegate to the single
  // [resolveDialog] entry point so callers using `showDialog(...)`
  // directly (e.g. DatePicker dialog mode) get the same dim
  // treatment that the `Dialog` widget already paints when used
  // declaratively (theme override + barrier opacity baked in).
  // The launching theme can be below the root Navigator (embedded previews,
  // nested branded sections). Its navigator context does not inherit it.
  final resolved = resolveDialog(context, dialogStyle: dialogStyle);

  // Open/close transition duration resolves through the single
  // [resolveDialog] entry point (theme override + design-system
  // default), so `showDialog` callers inherit the dialog's resolved
  // motion timing instead of a hard-coded constant.
  final transitionDuration = resolved.transitionDuration;

  return DialogRoute<T>(
    anchorPoint: anchorPoint,
    barrierColorFallback: barrierColor ?? resolved.barrierColor,
    barrierColorBuilder: barrierColorBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    data: data,
    dialogStyle: dialogStyle,
    fullScreen: fullScreen,
    settings: routeSettings,
    themes: themes,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // RawDialogRoute builds transitions outside its pageBuilder. Capturing
      // the page alone leaves the transition's resolver without a CoUI Theme.
      return themes.wrap(
        Builder(
          builder: (themedContext) => _buildCoUIDialogTransitions(
            alignment ?? Alignment.center,
            animation,
            BorderRadius.zero,
            child,
            themedContext,
            fullScreen,
            secondaryAnimation,
          ),
        ),
      );
    },
    transitionDuration: transitionDuration,
    traversalEdgeBehavior: traversalEdgeBehavior ?? .closedLoop,
    useSafeArea: useSafeArea,
    builder: (context) {
      return _DialogOverlayWrapper(
        route: ModalRoute.of(context)! as DialogRoute<T>,
        child: Builder(
          builder: (context) {
            return builder(context);
          },
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// DialogOverlayHandler
// ---------------------------------------------------------------------------

/// Overlay handler that manages dialog display using the navigation stack.
///
/// Provides a standardised way to show dialogs through the overlay system
/// with proper theme inheritance, animation handling, and modal behaviour.
///
/// Example:
/// ```dart
/// const DialogOverlayHandler().show<void>(
///   context: context,
///   alignment: Alignment.center,
///   builder: (context) => Dialog(
///     title: Text('Confirm'),
///     onClose: () => Navigator.pop(context),
///   ),
/// );
/// ```
class DialogOverlayHandler {
  /// Creates a [DialogOverlayHandler].
  const DialogOverlayHandler();

  /// Checks if the current context is within a dialog overlay.
  ///
  /// `_DialogOverlayMarker` (InheritedWidget) 의 ancestor 존재 여부로 판정.
  /// Generic 추론/erasure 와 무관한 platform-독립적 패턴.
  static bool isDialogOverlay(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DialogOverlayMarker>() !=
        null;
  }
}

// ---------------------------------------------------------------------------
// Dialog — unified cross-platform dialog widget
// ---------------------------------------------------------------------------

/// Unified cross-platform dialog with token-based rendering.
///
/// When [open] transitions to `true`, the dialog is shown via the
/// CoUI [showDialog] route (barrier, animation, theme inheritance).
/// When [open] transitions to `false`, the dialog is dismissed.
///
/// Example:
/// ```dart
/// Dialog(
///   open: _isOpen,
///   onClose: () => setState(() => _isOpen = false),
///   title: Text('Confirm'),
///   content: Text('Are you sure?'),
///   actions: [
///     Button(
///       variant: CoreButtonVariant.outline,
///       onPressed: () => setState(() => _isOpen = false),
///       child: Text('Cancel'),
///     ),
///     Button(
///       onPressed: () => setState(() => _isOpen = false),
///       child: Text('Confirm'),
///     ),
///   ],
/// )
/// ```
///
/// surface:functional — a modal route mounts this panel over the page it
/// covers.
class Dialog extends StatefulWidget implements CoreDialogContract<Widget> {
  /// Creates a [Dialog].
  const Dialog({
    this.title,
    this.content,
    this.leading,
    this.trailing,
    this.actions,
    this.open = true,
    this.onClose,
    this.dialogStyle,
    super.key,
  });

  @override
  final Widget? title;

  @override
  final Widget? content;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final List<Widget>? actions;

  @override
  final bool open;

  @override
  final VoidCallback? onClose;

  @override
  final CoreDialogStyle? dialogStyle;

  /// Returns a copy of this [Dialog] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Dialog copyWith({
    Key? key,
    Widget? title,
    Widget? content,
    Widget? leading,
    Widget? trailing,
    List<Widget>? actions,
    bool? open,
    VoidCallback? onClose,
    CoreDialogStyle? dialogStyle,
  }) {
    return Dialog(
      key: key ?? this.key,
      title: title ?? this.title,
      content: content ?? this.content,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      actions: actions ?? this.actions,
      open: open ?? this.open,
      onClose: onClose ?? this.onClose,
      dialogStyle: dialogStyle ?? this.dialogStyle,
    );
  }

  @override
  State<Dialog> createState() => _DialogState();
}

class _DialogState extends State<Dialog> {
  bool _isDialogShowing = false;

  /// The route this dialog pushed, while it is on the navigator.
  ///
  /// Closing goes through it and never through the navigator's top route:
  /// the top route is a page or another dialog whenever one was opened over
  /// this one, and popping it closed that one and left this dialog standing
  /// with nothing left to close it.
  DialogRoute<void>? _route;

  // Each pushed route owns its notifier until that route finishes closing.
  // The route is in a separate overlay subtree, so rebuilding this widget
  // does not otherwise rebuild the slots already mounted in that route.
  ValueNotifier<Dialog>? _routeContent;
  bool _contentUpdateScheduled = false;

  /// Whether this Dialog is mounted *inside* an existing dialog overlay
  /// (e.g., used as the `builder` return value of `showDialog(...)`).
  ///
  /// When true, the widget skips its self-managed showDialog push and
  /// renders [_DialogContent] directly in [build]. This prevents the
  /// double-push stuck where the outer showDialog and Dialog's own
  /// initState both push a DialogRoute, leaving an orphaned ModalBarrier
  /// after a single pop.
  bool _isHostedInDialogOverlay = false;

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      // Schedule for after first frame so context has a Navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // If already inside a dialog overlay, the caller has already
        // pushed a DialogRoute; rendering content inline is enough.
        if (DialogOverlayHandler.isDialogOverlay(context)) {
          if (!_isHostedInDialogOverlay) {
            setState(() {
              _isHostedInDialogOverlay = true;
            });
          }
          return;
        }
        if (widget.open && !_isDialogShowing) {
          _showDialog();
        }
      });
    }
  }

  void _showDialog() {
    _isDialogShowing = true;
    final dialogStyle = widget.dialogStyle;
    final content = ValueNotifier<Dialog>(widget);
    _routeContent = content;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = _createDialogRoute<void>(
      barrierColor: resolveDialog(
        context,
        dialogStyle: dialogStyle,
      ).barrierColor,
      barrierDismissible: widget.onClose != null,
      context: context,
      dialogStyle: dialogStyle,
      navigatorState: navigator,
      builder: (_) => ValueListenableBuilder<Dialog>(
        valueListenable: content,
        builder: (_, current, _) => _DialogContent(
          title: current.title,
          content: current.content,
          leading: current.leading,
          trailing: current.trailing,
          actions: current.actions,
          dialogStyle: dialogStyle,
        ),
      ),
    );
    _route = route;
    unawaited(
      navigator.push(route).then((_) {
        if (identical(_routeContent, content)) _routeContent = null;
        content.dispose();
        if (identical(_route, route)) {
          _route = null;
          _isDialogShowing = false;
          // If user dismissed via barrier tap or back button, notify parent.
          if (mounted && widget.open) widget.onClose?.call();
        }
      }),
    );
  }

  void _dismissDialog() {
    if (!mounted) return;
    final route = _route;
    _route = null;
    _routeContent = null;
    if (route != null) _closeRoute(route);
    _isDialogShowing = false;
  }

  /// Closes [route], the one this dialog pushed: with its exit animation
  /// when it is the top route, taken out from under whatever sits over it
  /// otherwise — that page or dialog stays where it is. The same rule
  /// `_DialogOverlayWrapperState.closeLater` uses for the route it wraps.
  static void _closeRoute(DialogRoute<void> route) {
    if (!route.isActive) return;
    final navigator = route.navigator;
    if (navigator == null) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  void didUpdateWidget(covariant Dialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hosted in an outer dialog overlay — caller controls lifecycle, skip
    // self-managed showDialog/dismiss handling here.
    if (_isHostedInDialogOverlay) return;
    if (oldWidget.open && widget.open && _isDialogShowing) {
      // An owner can rebuild while the overlay is a sibling of its subtree.
      // Notify after the current frame instead of marking that sibling dirty
      // while Flutter is already building the owner.
      if (!_contentUpdateScheduled) {
        _contentUpdateScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _contentUpdateScheduled = false;
          if (!mounted || !widget.open || _route?.isActive != true) return;
          _routeContent?.value = widget;
        });
      }
    }
    if (!oldWidget.open && widget.open && !_isDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open && !_isDialogShowing) {
          _showDialog();
        }
      });
    } else if (oldWidget.open && !widget.open && _isDialogShowing) {
      _dismissDialog();
    }
  }

  @override
  void dispose() {
    final route = _route;
    _route = null;
    _routeContent = null;
    if (_isDialogShowing && route != null) {
      // After the frame: the navigator may be mid-update while this
      // subtree is torn down.
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeRoute(route));
    }
    _isDialogShowing = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When the widget is hosted inside an outer dialog overlay (e.g., used
    // as the `builder` return value of `showDialog(...)`), render the
    // dialog content inline instead of pushing a nested DialogRoute.
    //
    // build 시점에 직접 `isDialogOverlay(context)` 체크하여 첫 frame 부터 정확한
    // 분기를 결정한다. `_isHostedInDialogOverlay` state + `addPostFrameCallback`
    // setState 흐름만 사용하면 첫 frame 이 `SizedBox.shrink()` 로 그려진 후
    // 두 번째 frame 에서 `_DialogContent` 가 그려져 visual gap (테두리/배경이
    // 늦게 나타남) 이 발생함. `_DialogOverlayMarker` 는 `getInheritedWidgetOfExactType`
    // 으로 lookup 하므로 build 단계에서도 안전하게 호출 가능.
    final isHosted =
        _isHostedInDialogOverlay ||
        DialogOverlayHandler.isDialogOverlay(context);
    if (isHosted && widget.open) {
      return _DialogContent(
        title: widget.title,
        content: widget.content,
        leading: widget.leading,
        trailing: widget.trailing,
        actions: widget.actions,
        dialogStyle: widget.dialogStyle,
      );
    }
    // Declarative usage — the dialog is shown via the self-managed overlay.
    return const SizedBox.shrink();
  }
}

/// The actual dialog content rendered inside the overlay route.
class _DialogContent extends StatelessWidget {
  const _DialogContent({
    this.title,
    this.content,
    this.leading,
    this.trailing,
    this.actions,
    this.dialogStyle,
  });

  final Widget? title;
  final Widget? content;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final CoreDialogStyle? dialogStyle;

  @override
  Widget build(BuildContext context) {
    // Render-only: every chrome / dimensional / typography value is
    // pre-resolved (colours via `scheme.resolve`, scaling pre-applied,
    // title/content text styles composed) by `resolveDialog`. The
    // widget reads `resolved.X` and never touches the theme, the scheme,
    // or `theme.scaling` itself (Epic #1603 C11).
    final resolved = resolveDialog(context, dialogStyle: dialogStyle);

    final dialogBox = ConstrainedBox(
      // `ConstrainedBox` enforces its bounds inside the route's own, so a
      // route narrower than `panelMinWidth` narrows the panel to its room
      // rather than overflowing it — the Web twin's `min()` says the same.
      constraints: BoxConstraints(
        minWidth: resolved.panelMinWidth,
        maxWidth: resolved.panelMaxWidth,
      ),
      // `InsetShadow` carries the claymorphism rim (#3777) — parity with
      // `Popup`/`Drawer`, whose panels wrap the same way. The outer
      // `boxShadow` (elevation) and the rim are two different paint
      // layers, so they stay on separate widgets rather than both
      // routing through `BoxDecoration.boxShadow`.
      child: InsetShadow(
        shadows: resolved.panelInsetBoxShadow,
        radius: resolved.panelBorderRadius,
        child: Container(
          padding: resolved.panelPadding,
          decoration: BoxDecoration(
            color: resolved.panelBackgroundColor,
            border: Border.all(
              color: resolved.panelBorderColor,
              width: resolved.panelBorderWidth,
            ),
            borderRadius: resolved.panelBorderRadius,
            // Behind a translucent fill the cast is painted outside the box
            // instead (`drawBox` below).
            boxShadow: resolved.castOutsideBox ? null : resolved.panelBoxShadow,
          ),
          // The panel foreground is what everything the panel holds
          // inherits when it states no colour of its own — the leading /
          // trailing slots. The title and body set their own colours below.
          child: DefaultTextStyle.merge(
            style: TextStyle(color: resolved.panelForegroundColor),
            child: IconTheme.merge(
              data: IconThemeData(color: resolved.panelForegroundColor),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  // Header row: leading + title + trailing.
                  if (title != null || leading != null || trailing != null)
                    Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          Gap(gapStyle: resolved.sectionGapStyle),
                        ],
                        if (title != null)
                          Expanded(
                            // The title is the dialog's name: the route
                            // already scopes the screen-reader's context, and
                            // this is what it announces on arrival. No new
                            // string — the name is the title the caller
                            // wrote, as `aria-labelledby` does on the Web.
                            child: Semantics(
                              namesRoute: true,
                              container: true,
                              child: DefaultTextStyle.merge(
                                style: resolved.titleTextStyle,
                                child: title!,
                              ),
                            ),
                          ),
                        if (trailing != null) ...[
                          Gap(gapStyle: resolved.sectionGapStyle),
                          trailing!,
                        ],
                      ],
                    ),
                  // Content. A body taller than the room the route leaves
                  // scrolls on its own while the header and the actions
                  // stay put. Loose fit, so a body that fits keeps its own
                  // height — and outside a route, under unbounded height,
                  // the loose child is laid out like any other.
                  //
                  // The scroll view does not clip; the clip around it
                  // reaches `contentClipMargin` past the body on every side,
                  // whether it scrolls or not — the reach the Web twin gives
                  // its always-clipping scroll container, so a field flush
                  // with the body's edge keeps its whole focus ring on both.
                  if (content != null) ...[
                    Gap(gapStyle: resolved.sectionGapStyle),
                    Flexible(
                      child: ClipRect(
                        clipper: _ContentClipper(resolved.contentClipMargin),
                        child: SingleChildScrollView(
                          clipBehavior: .none,
                          child: DefaultTextStyle.merge(
                            style: resolved.contentTextStyle,
                            child: content!,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Actions.
                  if (actions != null && actions!.isNotEmpty) ...[
                    Gap(gapStyle: resolved.actionsGapStyle),
                    _buildActions(resolved, actions!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final effectiveBlur = resolved.surfaceBlur;
    // The active material's bend. Every surface that draws the material
    // draws all of it — the frost and the chroma without the bend is a
    // blurred panel, not glass, and the bend is the term the material
    // is named for.
    //
    // Falls back rather than being required: a style that states no
    // refraction leaves this null and the surface simply does not
    // bend, which is how every preset but glass renders.
    final refraction = Theme.of(context).surfaceRefraction;
    final drawsSurface =
        (effectiveBlur != null && effectiveBlur > 0) ||
        resolved.surfaceSheen != null;

    // The panel as it is drawn at [fadeProgress] of the way in view, or at rest
    // where it is null. A panel that is being faded by the opacity above it —
    // every panel whose surface draws no backdrop pass — is drawn at rest.
    Widget drawBox(double? fadeProgress) {
      final box = drawsSurface
          ? SurfaceBlur(
              borderRadius: resolved.panelBorderRadius,
              surfaceBlur: effectiveBlur,
              surfaceSaturation: resolved.surfaceSaturation,
              surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
              surfaceSheen: resolved.surfaceSheen,
              refraction: refraction,
              fadeProgress: fadeProgress,
              child: dialogBox,
            )
          : dialogBox;
      if (!resolved.castOutsideBox) return box;

      // The cast sits behind the panel, outside the opacity the fill and the
      // content fade under, so it fades by the progress itself here.
      return InjectedCast(
        shadows: fadeShadows(resolved.panelBoxShadow, fadeProgress),
        borderRadius: resolved.panelBorderRadius,
        child: box,
      );
    }

    // A route that fades the panel offers its surface the fade. A surface that
    // draws a backdrop pass takes it over — an opacity above a backdrop filter
    // would take the pass away — and one that does not leaves the panel to be
    // faded as a whole. With no host above (a dialog drawn outside a route, a
    // full-screen route) nothing is mounted and the panel is built without a
    // wrapper.
    final fadeScope = SurfaceFadeScope.maybeOf(context);
    final box = fadeScope == null
        ? drawBox(null)
        : SurfaceFadeAdopter(
            scope: fadeScope,
            drawsPass: surfaceDrawsBackdropPass(
              blur: effectiveBlur,
              refraction: refraction,
            ),
            builder: drawBox,
          );

    // The panel says what it is. A dialog is a modal context, not a stretch
    // of the page, and its controls stay separate focus targets inside it.
    return CoUISemantics(
      role: .dialog,
      container: true,
      explicitChildNodes: true,
      child: box,
    );
  }

  /// The actions row, spread the way [ResolvedDialog.actionsLayout] states.
  ///
  /// [CoreDialogActionsLayout.end]: at the panel's end, wrapping onto
  /// further rows when one line cannot hold them — the Web footer states the
  /// same rule with `flex-wrap`. Each row keeps the single line's alignment:
  /// at the end, centred across.
  ///
  /// [CoreDialogActionsLayout.stretch]: every action at an equal share of
  /// the row, every line filling its width — the Web footer's equal-basis
  /// flex cells, placed by the same Core rule.
  ///
  /// A list that asks for flex distribution (a [Flexible] / [Spacer]
  /// action) keeps the single line it asked for under either. The
  /// distribution is a [Row]'s, and neither a [Wrap] nor the stretched row
  /// can lay those children out at all.
  static Widget _buildActions(ResolvedDialog resolved, List<Widget> actions) {
    final actionStyle = resolved.actionButtonStyle;
    final styledActions = actionStyle == null
        ? actions
        : [
            for (final action in actions)
              if (action case final Button button)
                button.copyWith(
                  buttonStyle: actionStyle.merge(button.buttonStyle),
                )
              else
                action,
          ];
    final distributes = actions.any(
      (action) => action is Flexible || action is Spacer,
    );
    if (distributes) {
      return Row(
        mainAxisAlignment: .end,
        spacing: resolved.actionSpacing,
        children: styledActions,
      );
    }

    return switch (resolved.actionsLayout) {
      .end => Wrap(
        alignment: .end,
        spacing: resolved.actionSpacing,
        runSpacing: resolved.actionRunSpacing,
        crossAxisAlignment: .center,
        children: styledActions,
      ),
      .stretch => DialogActionsStretchLayout(
        spacing: resolved.actionSpacing,
        runSpacing: resolved.actionRunSpacing,
        children: styledActions,
      ),
    };
  }
}

/// Clips the dialog body [margin] past its own box on every side — the
/// reach [ResolvedDialog.contentClipMargin] states.
class _ContentClipper extends CustomClipper<Rect> {
  const _ContentClipper(this.margin);

  final double margin;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(margin);

  @override
  bool shouldReclip(_ContentClipper oldClipper) => oldClipper.margin != margin;
}

/// Chain sugar for merging a [CoreDialogStyle] patch into
/// [Dialog.dialogStyle] without hand-reconstructing every field. Mirrors
/// the Web `Dialog.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDialogStyle.merge` right-side-wins semantics).
extension DialogStyleChain on Dialog {
  /// Returns a copy of this [Dialog] with [patch] merged into
  /// [dialogStyle] (patch fields win on conflict).
  Dialog withStyle(CoreDialogStyle patch) => copyWith(
    dialogStyle: (dialogStyle ?? const CoreDialogStyle()).merge(patch),
  );
}
