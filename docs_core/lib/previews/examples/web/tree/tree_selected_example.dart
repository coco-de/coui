import 'package:coui_web/coui_web.dart';

class TreeSelectedExample extends StatelessComponent {
  const TreeSelectedExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Tree(
      nodes: [
        CoreTreeNode(
          label: '문서',
          expanded: true,
          children: [
            CoreTreeNode(label: '이력서.pdf', selected: true),
            CoreTreeNode(label: '자기소개서.pdf'),
          ],
        ),
        CoreTreeNode(
          label: '이미지',
          children: [
            CoreTreeNode(label: '사진.png'),
          ],
        ),
      ],
    );
  }
}
