import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// {@template menu_theme}
/// Styling options for menu widgets such as [MenuGroup] and [MenuButton].
/// {@endtemplate}
class MenuTheme {
  /// {@macro menu_theme}
  const MenuTheme({this.itemPadding, this.subMenuOffset});

  /// Default padding applied to each menu item.
  final EdgeInsets? itemPadding;

  /// Offset applied when showing a submenu.
  final Offset? subMenuOffset;

  /// Creates a copy of this theme but with the given fields replaced.
  MenuTheme copyWith({
    ValueGetter<EdgeInsets?>? itemPadding,
    ValueGetter<Offset?>? subMenuOffset,
  }) {
    return MenuTheme(
      itemPadding: itemPadding == null ? this.itemPadding : itemPadding(),
      subMenuOffset: subMenuOffset == null
          ? this.subMenuOffset
          : subMenuOffset(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MenuTheme &&
        other.itemPadding == itemPadding &&
        other.subMenuOffset == subMenuOffset;
  }

  @override
  String toString() {
    return 'MenuTheme(itemPadding: $itemPadding, subMenuOffset: $subMenuOffset)';
  }

  @override
  int get hashCode => Object.hash(itemPadding, subMenuOffset);
}

class MenuShortcut extends StatelessWidget {
  const MenuShortcut({required this.activator, this.combiner, super.key});

  final ShortcutActivator activator;

  final Widget? combiner;

  @override
  Widget build(BuildContext context) {
    final activator = this.activator;
    final combiner = this.combiner ?? const Text(' + ');
    final displayMapper = Data.maybeOf<KeyboardShortcutDisplayHandle>(context);
    assert(displayMapper != null, 'Cannot find KeyboardShortcutDisplayMapper');
    final keys = shortcutActivatorToKeySet(activator);
    final children = <Widget>[];
    for (int i = 0; i < keys.length; i += 1) {
      if (i > 0) {
        children.add(combiner);
      }
      children.add(displayMapper!.buildKeyboardDisplay(context, keys[i]));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    ).xSmall().muted();
  }
}

abstract class MenuItem extends Widget {
  const MenuItem({super.key});

  bool get hasLeading;
  PopoverController? get popoverController;
}

class MenuRadioGroup<T> extends StatelessWidget implements MenuItem {
  const MenuRadioGroup({
    required this.children,
    super.key,
    required this.onChanged,
    required this.value,
  });

  final T? value;
  final ContextedValueChanged<T>? onChanged;

  final List<Widget> children;

  @override
  bool get hasLeading => children.isNotEmpty;

  @override
  PopoverController? get popoverController => null;

  @override
  Widget build(BuildContext context) {
    final menuGroupData = Data.maybeOf<MenuGroupData>(context);
    assert(
      menuGroupData != null,
      'MenuRadioGroup must be a child of MenuGroup',
    );

    return Data<MenuRadioGroup<T>>.inherit(
      data: this,
      child: Flex(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        direction: menuGroupData!.direction,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class MenuRadio<T> extends StatelessWidget {
  const MenuRadio({
    this.autoClose = true,
    required this.child,
    this.enabled = true,
    this.focusNode,
    super.key,
    this.trailing,
    required this.value,
  });

  final T value;
  final Widget child;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool enabled;

  final bool autoClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final radioGroup = Data.maybeOf<MenuRadioGroup<T>>(context);
    assert(radioGroup != null, 'MenuRadio must be a child of MenuRadioGroup');

    return Data<MenuRadioGroup<T>>.boundary(
      child: MenuButton(
        onPressed: (context) {
          radioGroup.onChanged?.call(context, value);
        },
        autoClose: autoClose,
        enabled: enabled,
        focusNode: focusNode,
        leading: radioGroup!.value == value
            ? SizedBox.square(
                dimension: scaling * 16,
                child: const Icon(RadixIcons.dotFilled).iconSmall(),
              )
            : SizedBox(width: scaling * 16),
        trailing: trailing,
        child: child,
      ),
    );
  }
}

class MenuDivider extends StatelessWidget implements MenuItem {
  const MenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final menuGroupData = Data.maybeOf<MenuGroupData>(context);
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return AnimatedPadding(
      duration: kDefaultDuration,
      padding:
          (menuGroupData == null || menuGroupData.direction == Axis.vertical
              ? const EdgeInsets.symmetric(vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 4)) *
          scaling,
      child: menuGroupData == null || menuGroupData.direction == Axis.vertical
          ? Divider(
              color: theme.colorScheme.border,
              endIndent: -4 * scaling,
              height: scaling * 1,
              indent: -4 * scaling,
              thickness: scaling * 1,
            )
          : VerticalDivider(
              color: theme.colorScheme.border,
              endIndent: -4 * scaling,
              indent: -4 * scaling,
              thickness: scaling * 1,
              width: scaling * 1,
            ),
    );
  }

  @override
  bool get hasLeading => false;

  @override
  PopoverController? get popoverController => null;
}

class MenuGap extends StatelessWidget implements MenuItem {
  const MenuGap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Gap(size);
  }

  @override
  bool get hasLeading => false;

  @override
  PopoverController? get popoverController => null;
}

class MenuButton extends StatefulWidget implements MenuItem {
  const MenuButton({
    this.autoClose = true,
    required this.child,
    this.enabled = true,
    this.focusNode,
    super.key,
    this.leading,
    this.onPressed,
    this.popoverController,
    this.subMenu,
    this.trailing,
  });

  final Widget child;
  final List<MenuItem>? subMenu;
  final ContextedCallback? onPressed;
  final Widget? trailing;
  final Widget? leading;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autoClose;
  @override
  final PopoverController? popoverController;

  @override
  State<MenuButton> createState() => _MenuButtonState();

  @override
  bool get hasLeading => leading != null;
}

class MenuLabel extends StatelessWidget implements MenuItem {
  const MenuLabel({
    required this.child,
    super.key,
    this.leading,
    this.trailing,
  });

  final Widget child;
  final Widget? trailing;

  final Widget? leading;

  @override
  bool get hasLeading => leading != null;

  @override
  PopoverController? get popoverController => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final menuGroupData = Data.maybeOf<MenuGroupData>(context);
    assert(menuGroupData != null, 'MenuLabel must be a child of MenuGroup');

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 6, left: 8, right: 6, top: 6) *
              scaling +
          menuGroupData!.itemPadding,
      child: Basic(
        content: child.semiBold(),
        contentAlignment: menuGroupData.direction == Axis.vertical
            ? AlignmentDirectional.centerStart
            : Alignment.center,
        contentSpacing: scaling * 8,
        leading: leading == null && menuGroupData.hasLeading
            ? SizedBox(width: scaling * 16)
            : leading == null
            ? null
            : SizedBox.square(
                dimension: scaling * 16,
                child: leading!.iconSmall(),
              ),
        leadingAlignment: Alignment.center,
        trailing: trailing,
        trailingAlignment: Alignment.center,
      ),
    );
  }
}

class MenuCheckbox extends StatelessWidget implements MenuItem {
  const MenuCheckbox({
    this.autoClose = true,
    required this.child,
    this.enabled = true,
    super.key,
    this.onChanged,
    this.trailing,
    this.value = false,
  });

  final bool value;
  final ContextedValueChanged<bool>? onChanged;
  final Widget child;
  final Widget? trailing;
  final bool enabled;

  final bool autoClose;

  @override
  bool get hasLeading => true;
  @override
  PopoverController? get popoverController => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return MenuButton(
      onPressed: (context) {
        onChanged?.call(context, !value);
      },
      autoClose: autoClose,
      enabled: enabled,
      leading: value
          ? SizedBox.square(
              dimension: scaling * 16,
              child: const Icon(RadixIcons.check).iconSmall(),
            )
          : SizedBox(width: scaling * 16),
      trailing: trailing,
      child: child,
    );
  }
}

class _MenuButtonState extends State<MenuButton> {
  final _children = ValueNotifier<List<MenuItem>>([]);

  @override
  void initState() {
    super.initState();
    _children.value = widget.subMenu ?? [];
  }

  @override
  void didUpdateWidget(covariant MenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.subMenu, oldWidget.subMenu)) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          _children.value = widget.subMenu ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuBarData = Data.maybeOf<MenubarState>(context);
    final menuData = Data.maybeOf<MenuData>(context);
    final menuGroupData = Data.maybeOf<MenuGroupData>(context);
    assert(menuGroupData != null, 'MenuButton must be a child of MenuGroup');
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<MenuTheme>(context);
    final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
    final isDialogOverlay = DialogOverlayHandler.isDialogOverlay(context);
    final isIndependentOverlay = isSheetOverlay || isDialogOverlay;
    void openSubMenu(bool autofocus, BuildContext context) {
      menuGroupData!.closeOthers();
      final overlayManager = OverlayManager.of(context);
      menuData!.popoverController.show(
        alignment: Alignment.topLeft,
        anchorAlignment: menuBarData == null
            ? Alignment.topRight
            : Alignment.bottomLeft,
        builder: (context) {
          final theme = Theme.of(context);
          final scaling = theme.scaling;
          EdgeInsets itemPadding = menuGroupData.itemPadding;
          final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
          if (isSheetOverlay) {
            itemPadding = const EdgeInsets.symmetric(horizontal: 8) * scaling;
          }

          return ConstrainedBox(
            constraints:
                const BoxConstraints(
                  minWidth: 192, // 12rem
                ) *
                scaling,
            child: AnimatedBuilder(
              animation: _children,
              builder: (context, child) {
                return MenuGroup(
                  autofocus: autofocus,
                  builder: (context, children) {
                    return MenuPopup(children: children);
                  },
                  direction: menuGroupData.direction,
                  itemPadding: itemPadding,
                  onDismissed: menuGroupData.onDismissed,
                  parent: menuGroupData,
                  regionGroupId: menuGroupData.regionGroupId,
                  subMenuOffset:
                      compTheme?.subMenuOffset ??
                      const Offset(8, -4 + -1) * scaling,
                  children: _children.value,
                );
              },
            ),
          );
        },
        consumeOutsideTaps: false,
        context: context,
        dismissBackdropFocus: false,
        handler: MenuOverlayHandler(overlayManager),
        offset: menuGroupData.subMenuOffset ?? compTheme?.subMenuOffset,
        overlayBarrier: OverlayBarrier(
          borderRadius: BorderRadius.circular(theme.radiusMd),
        ),
        regionGroupId: menuGroupData.regionGroupId,
      );
    }

    return Actions(
      actions: {
        OpenSubMenuIntent: ContextCallbackAction<OpenSubMenuIntent>(
          onInvoke: (intent, [context]) {
            if (widget.subMenu?.isNotEmpty ?? false) {
              openSubMenu(this.context, true);

              return true;
            }

            return false;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed?.call(context);
            if (widget.subMenu?.isNotEmpty ?? false) {
              openSubMenu(context, true);
            }
            if (widget.autoClose) {
              menuGroupData!.closeAll();
            }

            return null;
          },
        ),
      },
      child: SubFocus(
        builder: (context, subFocusState) {
          final hasFocus = subFocusState.isFocused && menuBarData == null;

          return Data<MenuData>.boundary(
            child: Data<MenubarState>.boundary(
              child: TapRegion(
                groupId: menuGroupData!.root,
                child: AnimatedBuilder(
                  animation: menuData!.popoverController,
                  builder: (context, child) {
                    return Button(
                      onPressed: () {
                        widget.onPressed?.call(context);
                        if (widget.subMenu != null &&
                            widget.subMenu!.isNotEmpty) {
                          if (!menuData.popoverController.hasOpenPopover) {
                            openSubMenu(context, false);
                          }
                        } else {
                          if (widget.autoClose) {
                            menuGroupData.closeAll();
                          }
                        }
                      },
                      alignment: menuGroupData.direction == Axis.vertical
                          ? AlignmentDirectional.centerStart
                          : Alignment.center,
                      disableFocusOutline: true,
                      disableTransition: true,
                      enabled: widget.enabled,
                      focusNode: widget.focusNode,
                      leading:
                          widget.leading == null &&
                              menuGroupData.hasLeading &&
                              menuBarData == null
                          ? SizedBox(width: scaling * 16)
                          : widget.leading == null
                          ? null
                          : SizedBox.square(
                              dimension: scaling * 16,
                              child: widget.leading!.iconSmall(),
                            ),
                      onHover: (value) {
                        if (value) {
                          subFocusState.requestFocus();
                          if ((menuBarData == null ||
                                  menuGroupData.hasOpenPopovers) &&
                              widget.subMenu != null &&
                              widget.subMenu!.isNotEmpty) {
                            if (!menuData.popoverController.hasOpenPopover &&
                                !isIndependentOverlay) {
                              openSubMenu(context, false);
                            }
                          } else {
                            menuGroupData.closeOthers();
                          }
                        } else {
                          subFocusState.unfocus();
                        }
                      },
                      style:
                          (menuBarData == null
                                  ? ButtonVariance.menu
                                  : ButtonVariance.menubar)
                              .copyWith(
                                decoration: (context, states, value) {
                                  final theme = Theme.of(context);

                                  return (value as BoxDecoration).copyWith(
                                    borderRadius: BorderRadius.circular(
                                      theme.radiusMd,
                                    ),
                                    color:
                                        menuData
                                                .popoverController
                                                .hasOpenPopover ||
                                            hasFocus
                                        ? theme.colorScheme.accent
                                        : null,
                                  );
                                },
                                padding: (context, states, value) {
                                  return value.optionallyResolve(context) +
                                      menuGroupData.itemPadding;
                                },
                              ),
                      trailing: menuBarData == null
                          ? widget.trailing != null ||
                                    (widget.subMenu != null &&
                                        menuBarData == null)
                                ? Row(
                                    children: [
                                      if (widget.trailing != null)
                                        widget.trailing!,
                                      if (widget.subMenu != null &&
                                          menuBarData == null)
                                        const Icon(
                                          RadixIcons.chevronRight,
                                        ).iconSmall(),
                                    ],
                                  ).gap(scaling * 8)
                                : null
                          : widget.trailing,
                      child: widget.child,
                    );
                  },
                ),
              ),
            ),
          );
        },
        enabled: widget.enabled,
      ),
    );
  }
}

class MenuGroupData {
  const MenuGroupData(
    this.children,
    this.direction,
    this.focusScope,
    this.hasLeading,
    this.itemPadding,
    this.onDismissed,
    this.parent,
    this.regionGroupId,
    this.subMenuOffset,
  );

  final MenuGroupData? parent;
  final List<MenuData> children;
  final bool hasLeading;
  final Offset? subMenuOffset;
  final VoidCallback? onDismissed;
  final Object? regionGroupId;
  final Axis direction;
  final EdgeInsets itemPadding;

  final SubFocusScopeState focusScope;

  bool get hasOpenPopovers {
    for (final child in children) {
      if (child.popoverController.hasOpenPopover) {
        return true;
      }
    }

    return false;
  }

  void closeOthers() {
    for (final child in children) {
      child.popoverController.close();
    }
  }

  void closeAll() {
    final menuGroupData = parent;
    if (menuGroupData == null) {
      onDismissed?.call();

      return;
    }
    menuGroupData.closeOthers();
    menuGroupData.closeAll();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MenuGroupData
        ? listEquals(children, other.children) &&
              parent == other.parent &&
              hasLeading == other.hasLeading &&
              subMenuOffset == other.subMenuOffset &&
              onDismissed == other.onDismissed
        : (other is MenuGroupData) &&
              (listEquals(children, other.children) &&
                  parent == other.parent &&
                  hasLeading == other.hasLeading &&
                  subMenuOffset == other.subMenuOffset &&
                  onDismissed == other.onDismissed);
  }

  @override
  String toString() {
    return 'MenuGroupData{parent: $parent, children: $children, hasLeading: $hasLeading, subMenuOffset: $subMenuOffset, onDismissed: ${onDismissed()}, regionGroupId: $regionGroupId, direction: $direction}';
  }

  MenuGroupData get root {
    final menuGroupData = parent;

    return menuGroupData == null ? this : menuGroupData.root;
  }

  @override
  int get hashCode => Object.hash(
    children,
    parent,
    hasLeading,
    subMenuOffset,
    onDismissed,
  );
}

class MenuData {
  MenuData({PopoverController? popoverController})
    : popoverController = popoverController ?? PopoverController();
  final PopoverController popoverController;
}

class MenuGroup extends StatefulWidget {
  const MenuGroup({
    this.actions = const {},
    this.autofocus = true,
    required this.builder,
    required this.children,
    required this.direction,
    this.focusNode,
    this.itemPadding,
    super.key,
    this.onDismissed,
    this.parent,
    this.regionGroupId,
    this.subMenuOffset,
  });

  final List<MenuItem> children;
  final Widget Function(List<Widget> children, BuildContext context) builder;
  final MenuGroupData? parent;
  final Offset? subMenuOffset;
  final VoidCallback? onDismissed;
  final Object? regionGroupId;
  final Axis direction;
  final Map<Type, Action> actions;
  final EdgeInsets? itemPadding;
  final bool autofocus;

  final FocusNode? focusNode;

  @override
  State<MenuGroup> createState() => _MenuGroupState();
}

class _MenuGroupState extends State<MenuGroup> {
  List<MenuData> _data;

  @override
  void initState() {
    super.initState();
    _data = List.generate(widget.children.length, (i) {
      return MenuData();
    });
  }

  @override
  void didUpdateWidget(covariant MenuGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.children, widget.children)) {
      final oldKeyedData = <Key, MenuData>{};
      for (int i = 0; i < oldWidget.children.length; i += 1) {
        oldKeyedData[oldWidget.children[i].key ?? ValueKey(i)] = _data[i];
      }
      _data = List.generate(widget.children.length, (i) {
        final child = widget.children[i];
        final key = child.key ?? ValueKey(i);
        MenuData? oldData = oldKeyedData[key];
        if (oldData == null) {
          oldData = MenuData(popoverController: child.popoverController);
        } else {
          if (child.popoverController != null &&
              oldData.popoverController != child.popoverController) {
            oldData.popoverController.dispose();
            oldData = MenuData(popoverController: child.popoverController);
          }
        }

        return oldData;
      });

      /// Dispose unused data.
      for (final data in oldKeyedData.values) {
        if (!_data.contains(data)) {
          data.popoverController.dispose();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final data in _data) {
      data.popoverController.dispose();
    }
    super.dispose();
  }

  void closeAll() {
    final data = widget.parent;
    if (data == null) {
      widget.onDismissed?.call();

      return;
    }
    data.closeOthers();
    data.closeAll();
  }

  @override
  Widget build(BuildContext context) {
    final parentGroupData = Data.maybeOf<MenuGroupData>(context);
    final menubarData = Data.maybeOf<MenubarState>(context);
    final compTheme = ComponentTheme.maybeOf<MenuTheme>(context);
    final itemPadding =
        widget.itemPadding ?? compTheme?.itemPadding ?? EdgeInsets.zero;
    final subMenuOffset = widget.subMenuOffset ?? compTheme?.subMenuOffset;
    final children = <Widget>[];
    bool hasLeading = false;
    for (int i = 0; i < widget.children.length; i += 1) {
      final child = widget.children[i];
      final data = _data[i];
      if (child.hasLeading) {
        hasLeading = true;
      }
      children.add(
        Data<MenuData>.inherit(data: data, child: child),
      );
    }
    final direction = Directionality.of(context);

    return SubFocusScope(
      autofocus: widget.autofocus,
      builder: (context, scope) {
        return Actions(
          actions: {
            NextMenuFocusIntent: CallbackAction<NextMenuFocusIntent>(
              onInvoke: (intent) {
                scope.nextFocus(
                  intent.forward
                      ? widget.direction == Axis.horizontal
                            ? TraversalDirection.left
                            : TraversalDirection.up
                      : widget.direction == Axis.horizontal
                      ? TraversalDirection.right
                      : TraversalDirection.down,
                );

                return null;
              },
            ),
            DirectionalMenuFocusIntent:
                CallbackAction<DirectionalMenuFocusIntent>(
                  onInvoke: (intent) {
                    if (widget.direction == Axis.vertical) {
                      if (intent.direction == TraversalDirection.left) {
                        if (direction == TextDirection.ltr) {
                          for (final menu in parentGroupData?.children ?? []) {
                            menu.popoverController.close();
                          }

                          return;
                        }
                      } else if (intent.direction == TraversalDirection.right) {
                        if (direction == TextDirection.ltr) {
                          final result =
                              scope.invokeActionOnFocused(
                                    const OpenSubMenuIntent(),
                                  )
                                  as bool?;
                          if (result != true) {
                            parentGroupData?.root.focusScope.nextFocus(
                              TraversalDirection.right,
                            );
                          }

                          return;
                        }
                      }
                    }
                    if (!scope.nextFocus(intent.direction)) {
                      for (final menu in parentGroupData?.children ?? []) {
                        menu.popoverController.close();
                      }
                      parentGroupData?.focusScope.nextFocus(intent.direction);
                    }

                    return null;
                  },
                ),
            CloseMenuIntent: CallbackAction<CloseMenuIntent>(
              onInvoke: (intent) {
                closeAll();

                return null;
              },
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                scope.invokeActionOnFocused(const ActivateIntent());

                return null;
              },
            ),
            ...widget.actions,
          },
          child: Shortcuts(
            shortcuts: {
              const SingleActivator(LogicalKeyboardKey.arrowUp):
                  const DirectionalMenuFocusIntent(TraversalDirection.up),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const DirectionalMenuFocusIntent(TraversalDirection.down),
              const SingleActivator(LogicalKeyboardKey.arrowLeft):
                  const DirectionalMenuFocusIntent(TraversalDirection.left),
              const SingleActivator(LogicalKeyboardKey.arrowRight):
                  const DirectionalMenuFocusIntent(TraversalDirection.right),
              const SingleActivator(
                LogicalKeyboardKey.tab,
              ): DirectionalMenuFocusIntent(
                widget.direction == Axis.vertical
                    ? TraversalDirection.down
                    : TraversalDirection.right,
              ),
              const SingleActivator(
                LogicalKeyboardKey.tab,
                shift: true,
              ): DirectionalMenuFocusIntent(
                widget.direction == Axis.vertical
                    ? TraversalDirection.up
                    : TraversalDirection.left,
              ),
              const SingleActivator(LogicalKeyboardKey.escape):
                  const CloseMenuIntent(),
              const SingleActivator(LogicalKeyboardKey.enter):
                  const ActivateIntent(),
              const SingleActivator(LogicalKeyboardKey.space):
                  const ActivateIntent(),
              const SingleActivator(LogicalKeyboardKey.backspace):
                  const CloseMenuIntent(),
              const SingleActivator(LogicalKeyboardKey.numpadEnter):
                  const ActivateIntent(),
            },
            child: Focus(
              autofocus: menubarData == null,
              focusNode: widget.focusNode,
              child: Data.inherit(
                data: MenuGroupData(
                  widget.parent,
                  _data,
                  hasLeading,
                  subMenuOffset,
                  widget.onDismissed,
                  widget.regionGroupId,
                  widget.direction,
                  itemPadding,
                  scope,
                ),
                child: Builder(
                  builder: (context) {
                    return widget.builder(context, children);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CloseMenuIntent extends Intent {
  const CloseMenuIntent();
}

class OpenSubMenuIntent extends Intent {
  const OpenSubMenuIntent();
}

class NextMenuFocusIntent extends Intent {
  const NextMenuFocusIntent(this.forward);
  final bool forward;
}

class MenuOverlayHandler extends OverlayHandler {
  const MenuOverlayHandler(this.manager);

  final OverlayManager manager;

  @override
  OverlayCompleter<T?> show<T>({
    required AlignmentGeometry alignment,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    AlignmentGeometry? anchorAlignment,
    bool barrierDismissable = true,
    required WidgetBuilder builder,
    Clip clipBehavior = Clip.none,
    bool consumeOutsideTaps = true,
    required BuildContext context,
    bool dismissBackdropFocus = true,
    Duration? dismissDuration,
    bool follow = true,
    PopoverConstraint heightConstraint = PopoverConstraint.flexible,
    Key? key,
    LayerLink? layerLink,
    EdgeInsetsGeometry? margin,
    bool modal = true,
    Offset? offset,
    ValueChanged<PopoverOverlayWidgetState>? onTickFollow,
    OverlayBarrier? overlayBarrier,
    Offset? position,
    Object? regionGroupId,
    bool rootOverlay = true,
    Duration? showDuration,
    AlignmentGeometry? transitionAlignment,
    PopoverConstraint widthConstraint = PopoverConstraint.flexible,
  }) {
    return manager.showMenu(
      key: key,
      alignment: alignment,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      anchorAlignment: anchorAlignment,
      barrierDismissable: barrierDismissable,
      builder: builder,
      clipBehavior: clipBehavior,
      consumeOutsideTaps: consumeOutsideTaps,
      context: context,
      dismissBackdropFocus: dismissBackdropFocus,
      dismissDuration: dismissDuration,
      follow: follow,
      heightConstraint: heightConstraint,
      layerLink: layerLink,
      margin: margin,
      modal: modal,
      offset: offset,
      onTickFollow: onTickFollow,
      overlayBarrier: overlayBarrier,
      position: position,
      regionGroupId: regionGroupId,
      rootOverlay: rootOverlay,
      showDuration: showDuration,
      transitionAlignment: transitionAlignment,
      widthConstraint: widthConstraint,
    );
  }
}

class DirectionalMenuFocusIntent extends Intent {
  const DirectionalMenuFocusIntent(this.direction);
  final TraversalDirection direction;
}
