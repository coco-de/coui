import 'package:coui_flutter/coui_flutter.dart';

enum PromptMode {
  dialog,
  popover,
}

class ObjectFormField<T> extends StatefulWidget {
  const ObjectFormField({
    required this.builder,
    this.decorate = true,
    this.density,
    this.dialogActions,
    this.dialogTitle,
    required this.editorBuilder,
    this.enabled,
    super.key,
    this.leading,
    this.mode = PromptMode.dialog,
    this.onChanged,
    required this.placeholder,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverPadding,
    this.shape,
    this.size,
    this.trailing,
    required this.value,
  });

  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget placeholder;
  final Widget Function(BuildContext context, T value) builder;
  final Widget? leading;
  final Widget? trailing;
  final PromptMode mode;
  final Widget Function(BuildContext context, ObjectFormHandler<T> handler)
  editorBuilder;
  final AlignmentGeometry? popoverAlignment;
  final AlignmentGeometry? popoverAnchorAlignment;
  final EdgeInsetsGeometry? popoverPadding;
  final Widget? dialogTitle;
  final ButtonSize? size;
  final ButtonDensity? density;
  final ButtonShape? shape;
  final List<Widget> Function(
    BuildContext context,
    ObjectFormHandler<T> handler,
  )?
  dialogActions;
  final bool? enabled;

  final bool decorate;

  @override
  State<ObjectFormField<T>> createState() => ObjectFormFieldState<T>();
}

abstract class ObjectFormHandler<T> {
  T? get value;
  set value(T? value);

  void prompt([T? value]);

  Future<void> close();
}

class ObjectFormFieldState<T> extends State<ObjectFormField<T>>
    with FormValueSupplier<T, ObjectFormField<T>> {
  final _popoverController = PopoverController();

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  T? get value => formValue;

  set value(T? value) {
    widget.onChanged?.call(value);
    formValue = value;
  }

  void _showDialog([T? value]) {
    value ??= formValue;
    showDialog<ObjectFormFieldDialogResult<T>>(
      context: context,
      builder: (context) {
        return _ObjectFormFieldDialog<T>(
          decorate: widget.decorate,
          dialogActions: widget.dialogActions,
          dialogTitle: widget.dialogTitle,
          editorBuilder: widget.editorBuilder,
          prompt: prompt,
          value: value,
        );
      },
    ).then((value) {
      if (mounted && value is ObjectFormFieldDialogResult<T>) {
        this.value = value.value;
      }
    });
  }

  void _showPopover([T? value]) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    value ??= formValue;
    _popoverController.show<void>(
      alignment: widget.popoverAlignment ?? Alignment.topLeft,
      anchorAlignment: widget.popoverAnchorAlignment ?? Alignment.bottomLeft,
      context: context,
      offset: Offset(0, scaling * 8),
      overlayBarrier: OverlayBarrier(
        borderRadius: BorderRadius.circular(theme.radiusLg),
      ),
      builder: (context) {
        return _ObjectFormFieldPopup<T>(
          decorate: widget.decorate,
          editorBuilder: widget.editorBuilder,
          onChanged: (value) {
            if (mounted) {
              this.value = value;
            }
          },
          popoverPadding: widget.popoverPadding,
          prompt: prompt,
          value: value,
        );
      },
    );
  }

  @override
  void didReplaceFormValue(T value) {
    widget.onChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant ObjectFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      formValue = widget.value;
    }
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  bool get enabled => widget.enabled ?? widget.onChanged != null;

  void prompt([T? value]) {
    if (widget.mode == PromptMode.dialog) {
      _showDialog(value);
    } else {
      _showPopover(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? ButtonSize.normal;
    final density = widget.density ?? ButtonDensity.normal;
    final shape = widget.shape ?? ButtonShape.rectangle;

    return OutlineButton(
      onPressed: widget.onChanged == null ? null : prompt,
      enabled: enabled,
      leading: widget.leading?.iconMutedForeground().iconSmall(),
      trailing: widget.trailing?.iconMutedForeground().iconSmall(),
      size: size,
      density: density,
      shape: shape,
      child: value == null
          ? widget.placeholder.muted()
          : widget.builder(context, value as T),
    );
  }
}

class _ObjectFormFieldDialog<T> extends StatefulWidget {
  const _ObjectFormFieldDialog({
    this.decorate = true,
    this.dialogActions,
    this.dialogTitle,
    required this.editorBuilder,
    super.key,
    required this.prompt,
    required this.value,
  });

  final T? value;
  final Widget Function(BuildContext context, ObjectFormHandler<T> handler)
  editorBuilder;
  final Widget? dialogTitle;
  final List<Widget> Function(
    BuildContext context,
    ObjectFormHandler<T> handler,
  )?
  dialogActions;
  final ValueChanged<T?> prompt;

  final bool decorate;

  @override
  State<_ObjectFormFieldDialog<T>> createState() =>
      _ObjectFormFieldDialogState<T>();
}

class ObjectFormFieldDialogResult<T> {
  const ObjectFormFieldDialogResult(this.value);
  final T? value;
}

class _ObjectFormFieldDialogState<T> extends State<_ObjectFormFieldDialog<T>>
    implements ObjectFormHandler<T> {
  T? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  T? get value => _value;

  @override
  set value(T? value) {
    if (mounted) {
      setState(() {
        _value = value;
      });
    } else {
      _value = value;
    }
  }

  @override
  void prompt([T? value]) {
    widget.prompt(value);
  }

  @override
  Future<void> close() {
    final modalRoute = ModalRoute.of(context);
    Navigator.of(context).pop();

    return modalRoute?.completed ?? Future.value();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.decorate) {
      return widget.editorBuilder(context, this);
    }
    final localizations = CoUILocalizations.of(context);
    final theme = Theme.of(context);

    return Data<ObjectFormHandler<T>>.inherit(
      data: this,
      child: AlertDialog(
        actions: [
          if (widget.dialogActions != null)
            ...widget.dialogActions!(context, this),
          SecondaryButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(localizations.buttonCancel),
          ),
          PrimaryButton(
            onPressed: () {
              Navigator.of(context).pop(ObjectFormFieldDialogResult(_value));
            },
            child: Text(localizations.buttonSave),
          ),
        ],
        content: Padding(
          padding: EdgeInsets.only(top: theme.scaling * 8),
          child: widget.editorBuilder(context, this),
        ),
        title: widget.dialogTitle,
      ),
    );
  }
}

class _ObjectFormFieldPopup<T> extends StatefulWidget {
  const _ObjectFormFieldPopup({
    this.decorate = true,
    required this.editorBuilder,
    super.key,
    this.onChanged,
    this.popoverPadding,
    required this.prompt,
    required this.value,
  });

  final T? value;
  final Widget Function(BuildContext context, ObjectFormHandler<T> handler)
  editorBuilder;
  final EdgeInsetsGeometry? popoverPadding;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<T?> prompt;

  final bool decorate;

  @override
  State<_ObjectFormFieldPopup<T>> createState() =>
      _ObjectFormFieldPopupState<T>();
}

class _ObjectFormFieldPopupState<T> extends State<_ObjectFormFieldPopup<T>>
    implements ObjectFormHandler<T> {
  T? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  T? get value => _value;

  @override
  set value(T? value) {
    if (mounted) {
      setState(() {
        _value = value;
      });
    } else {
      _value = value;
    }
    widget.onChanged?.call(value);
  }

  @override
  void prompt([T? value]) {
    widget.prompt(value);
  }

  @override
  Future<void> close() {
    // ignore: avoid-inferrable-type-arguments
    return closeOverlay<void>(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.decorate) {
      return widget.editorBuilder(context, this);
    }
    final theme = Theme.of(context);

    return Data<ObjectFormHandler<T>>.inherit(
      data: this,
      child: SurfaceCard(
        padding:
            widget.popoverPadding ?? (const EdgeInsets.all(16) * theme.scaling),
        child: widget.editorBuilder(context, this),
      ),
    );
  }
}
