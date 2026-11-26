String aspectRatioBoxCode(String? variant) {
  return '''
class AspectRatioBoxDefaultExample extends StatelessWidget {
  const AspectRatioBoxDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: AspectRatioBox(
        ratio: 16 / 9,
        child: Card(
          child: Center(child: Text('16 : 9').titleMedium),
        ),
      ),
    );
  }
}''';
}
