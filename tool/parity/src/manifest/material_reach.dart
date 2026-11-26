// The material half of a surface preset — translucency, blur, refraction
// — lands only on an element that carries the Web surface marker
// (`kWebSurfaceMarker`), whether the component wrote the marker on its
// own root or composed a child that did. Which components that is cannot
// be read off any declaration: `gap`'s example is two `Button`s, and
// `Button` is a marker. So this file MEASURES it, by server-rendering
// every active example once and looking for the marker class in the
// output.
//
// Why measure rather than declare. The pruning rule used to hold two
// lists — components that mark their own root, and components known to
// compose one — and re-capture every pruned combination nightly to catch
// the lists being wrong. The nightly did its job: 44 of the catalog's
// unmarked components compose a marker somewhere in their example, the
// declared list named two of them, and every other one was a red morning.
// A list of what an example happens to compose rots the day an example
// changes. The render does not.
//
// Why it is cheap enough to sit in manifest derivation. The objection was
// cost — "SSR-rendering all ~139 examples just to grep for one class
// name". Measured: 284 (component, variant) renders in 1.3 s, on a laptop.
// A screenshot of one cell costs more than the whole measurement.
import 'package:coui_web/coui_web.dart'
    show CoreSurfaceStyleId, kWebSurfaceMarker;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';

import '../model/matrix_entry.dart';
import '../model/parity_theme.dart';
import '../model/parity_tier.dart';
import '../web/web_capture_backend.dart';
import 'active_catalog.dart';
import 'capture_probes.dart';
import 'component_class_name.dart';
import 'variant_registry.dart';

/// Default doc-content directory — the same one `ParityManifest` reads
/// variants from, so the examples rendered here are the cells captured.
const String kDefaultMaterialReachContentDir = 'docs_core/content/components';

final RegExp _kClassAttribute = RegExp('class="([^"]*)"');
final RegExp _kWhitespace = RegExp(r'\s+');

/// Whether [html] contains an element whose class list carries the
/// surface marker as a whole token.
///
/// A whole token, not a substring: the marker is `coui-surface`, and the
/// same rendered page also carries `coui-surface-content` role classes and
/// `--coui-surface-rim` inline variables. A `contains` would light up on
/// every one of those and report a marker on an element that has none.
bool htmlCarriesSurfaceMarker(String html) {
  for (final match in _kClassAttribute.allMatches(html)) {
    final tokens = match.group(1)!.split(_kWhitespace);
    if (tokens.contains(kWebSurfaceMarker)) return true;
  }
  return false;
}

/// The catalog slugs whose rendered Web example carries the surface
/// marker anywhere in it — on its own root or on a composed child.
///
/// Rendered at `defaultStyle`, light: the marker class is what the style
/// rules key off, so it is present in the markup under every style and
/// both themes, and one render per (component, variant) is the whole
/// measurement. A slug whose variants disagree is reached — one reached
/// variant is enough for a material to change a pixel the matrix must
/// see.
///
/// Every active component is rendered, not only the ones a filter later
/// keeps: the set is a fact about the catalog, and computing it once per
/// run is cheaper than making it depend on the filter.
Future<Set<String>> measureMaterialReachedSlugs({
  String contentDir = kDefaultMaterialReachContentDir,
}) async {
  final reached = <String>{};
  for (final (:component, group: _) in activeCatalogComponents()) {
    final slug = component.slug;
    final flutterClassName = pascalCaseComponentSlug(slug);
    for (final variant in variantsForSlug(slug, contentDir: contentDir)) {
      final scene = variant.startsWith(docsScenePrefix)
          ? resolveDocsScene(slug, variant, contentDir: contentDir)
          : null;
      final key = '$slug-$variant-light-defaultStyle';
      final html = await renderCaptureBodyHtml(
        MatrixEntry(
          component: slug,
          variant: variant,
          theme: ParityTheme.light,
          surfaceStyle: CoreSurfaceStyleId.defaultId,
          // The tier is not part of what is rendered — any value builds
          // the same markup. `resolvePrunedPairs` uses the real tier for
          // its entries; this one is discarded with the entry.
          tier: ParityTier.t2,
          probes: captureProbes(
            key: key,
            component: slug,
            variant: variant,
            flutterClassName: scene?.flutterOwnerType ?? flutterClassName,
            docsScene: scene,
          ),
        ),
      );
      if (htmlCarriesSurfaceMarker(html)) {
        reached.add(slug);
        break;
      }
    }
  }
  return reached;
}
