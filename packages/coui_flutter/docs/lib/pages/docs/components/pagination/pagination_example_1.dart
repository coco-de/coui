import 'package:coui_flutter/coui_flutter.dart';

class PaginationExample1 extends StatefulWidget {
  const PaginationExample1({super.key});

  @override
  State<PaginationExample1> createState() => _PaginationExample1State();
}

class _PaginationExample1State extends State<PaginationExample1> {
  int page = 1;
  @override
  Widget build(BuildContext context) {
    return Pagination(
      maxPages: 3,
      onPageChanged: (value) {
        setState(() {
          page = value;
        });
      },
      page: page,
      totalPages: 20,
    );
  }
}
