import 'package:coui_web/coui_web.dart';

class PaginationDefaultExample extends StatefulComponent {
  const PaginationDefaultExample({super.key});

  @override
  State<PaginationDefaultExample> createState() => _PaginationDefaultExampleState();
}

class _PaginationDefaultExampleState extends State<PaginationDefaultExample> {
  int _page = 3;

  @override
  Component build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (value) => setState(() => _page = value),
    );
  }
}
