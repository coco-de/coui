/// No compositor exists during server rendering.
class ToggleLensRuntime {
  ToggleLensRuntime({required this.thumbId, required this.lensId});
  final String thumbId;
  final String lensId;
  void follow() {}
  void dispose() {}
}
