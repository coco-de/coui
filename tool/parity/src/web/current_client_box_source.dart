import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart' show div;

/// The existing passive client harness lifecycle; no product callbacks.
abstract interface class CurrentClientBoxSource {
  void recordBuild(Component registryResult, div capture);
  void arm(Element root, {required bool Function() isMounted});
  void dispose();
}
