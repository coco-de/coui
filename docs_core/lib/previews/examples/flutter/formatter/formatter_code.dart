String formatterCode(String? variant) {
  return '''
class FormatterDefaultExample extends StatelessWidget {
  const FormatterDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        placeholder: const Text('숫자만 입력 (0–100)'),
        inputFormatters: [TextInputFormatters.integerOnly(min: 0, max: 100)],
      ),
    );
  }
}''';
}
