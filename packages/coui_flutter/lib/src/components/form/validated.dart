import 'package:coui_flutter/coui_flutter.dart';

typedef ValidatedBuilder = Widget Function(
  BuildContext context,
  ValidationResult? error,
  Widget? child,
);

class Validated<T> extends StatefulWidget {
  const Validated({
    required this.builder,
    this.child,
    super.key,
    required this.validator,
  });

  final ValidatedBuilder builder;
  final Validator<T> validator;

  final Widget? child;

  @override
  State<Validated<dynamic>> createState() => _ValidatedState();
}

class _ValidatedState extends State<Validated<dynamic>> {
  final formKey = const FormKey<dynamic>(#validated);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: FormEntry(
        key: formKey,
        validator: widget.validator,
        child: FormEntryErrorBuilder(
          builder: (context, error, child) {
            return widget.builder(context, error, child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
