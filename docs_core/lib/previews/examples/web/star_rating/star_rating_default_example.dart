import 'package:coui_web/coui_web.dart';

class StarRatingDefaultExample extends StatefulComponent {
  const StarRatingDefaultExample({super.key});

  @override
  State<StarRatingDefaultExample> createState() => _StarRatingDefaultExampleState();
}

class _StarRatingDefaultExampleState extends State<StarRatingDefaultExample> {
  double _value = 3;

  @override
  Component build(BuildContext context) {
    return StarRating(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
