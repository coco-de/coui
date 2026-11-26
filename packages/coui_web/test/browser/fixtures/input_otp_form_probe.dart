import 'package:coui_web/coui_web.dart';

class InputOtpDefaultExample extends StatefulComponent {
  const InputOtpDefaultExample({super.key});

  @override
  State<InputOtpDefaultExample> createState() => _ExampleState();
}

class _ExampleState extends State<InputOtpDefaultExample> {
  final _defaultController = FormController();
  final _editingController = FormController();
  static const _otp = FormKey<String>('otp');
  String _defaultSubmitted = 'not submitted';
  String _editingSubmitted = 'not submitted';

  @override
  Component build(BuildContext context) {
    return div([
      Form(
        id: 'default-otp-form',
        controller: _defaultController,
        onSubmit: () => setState(
          () => _defaultSubmitted = _defaultController.getValue(_otp) ?? 'null',
        ),
        children: [
          const FormField(
            formKey: _otp,
            child: InputOtp(initialValue: '123456', separatorInterval: 0),
          ),
          const Component.element(
            tag: 'button',
            attributes: {'type': 'submit'},
            children: [Text('Submit default')],
          ),
          div([Text(_defaultSubmitted)], id: 'default-submitted'),
        ],
      ),
      Form(
        id: 'editing-otp-form',
        controller: _editingController,
        onSubmit: () => setState(
          () => _editingSubmitted = _editingController.getValue(_otp) ?? 'null',
        ),
        children: [
          const FormField(
            formKey: _otp,
            child: InputOtp(
              initialValue: '123456',
              separatorInterval: 0,
              allowCellEditing: true,
            ),
          ),
          const Component.element(
            tag: 'button',
            attributes: {'type': 'submit'},
            children: [Text('Submit editing')],
          ),
          div([Text(_editingSubmitted)], id: 'editing-submitted'),
        ],
      ),
    ], classes: 'flex flex-col items-start');
  }
}
