import 'package:coui_flutter/coui_flutter.dart';

class StarRatingDefaultExample extends StatefulWidget {
  const StarRatingDefaultExample({super.key});

  @override
  State<StarRatingDefaultExample> createState() => _StarRatingDefaultExampleState();
}

class _StarRatingDefaultExampleState extends State<StarRatingDefaultExample> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return StarRating(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
