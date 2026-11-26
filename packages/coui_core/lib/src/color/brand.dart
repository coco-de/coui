import 'package:coui_core/src/color/brand_palette.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/color/semantic_mapping_set.dart';
import 'package:meta/meta.dart';

/// A named, app-registered brand: a lookup key plus the colour source the
/// brand renders from.
///
/// A [CoreSchemeSource] can already be handed to any colour seat on its
/// own — this class only adds a name to that value, so a multi-tenant app
/// can look one up instead of threading the raw source through its own
/// bootstrap code by hand.
///
/// ```dart
/// const brand = CoreBrand(
///   id: 'acme',
///   displayName: 'Acme Corp',
///   palette: ..., // PrimitiveColors.generate(...)
/// );
/// ```
///
/// A brand with a generated [PrimitiveColors] palette states it (and,
/// optionally, its own [CoreSemanticMappingSet]); a brand whose colours are
/// already a [CoreSchemeSource] — CoUI's fixed palette is one — uses
/// [CoreBrand.from]. Either way [source] is what reaches the app.
/// [CoreBrand] carries no rendering behaviour of its own.
@immutable
class CoreBrand {
  /// Creates a [CoreBrand] from a generated [palette], read through
  /// [mapping] (the standard interpretation unless the brand states its
  /// own).
  const CoreBrand({
    required this.id,
    required this.displayName,
    required PrimitiveColors palette,
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) : _palette = palette,
       _mapping = mapping,
       _source = null,
       _color = null,
       _onLightFill = CoreBrandOnFill.measured;

  /// Creates a [CoreBrand] from one brand [color].
  ///
  /// The palette is generated on CoUI's step scale and read through CoUI's
  /// semantic mapping with the CTA rule for the primary family — see
  /// [CoreBrandPalette] and [CoreBrandSchemeSource]. This is the path a new
  /// brand takes: the brand states its colour and nothing else.
  ///
  /// ```dart
  /// const brand = CoreBrand.fromColor(
  ///   id: 'violet',
  ///   displayName: 'Violet',
  ///   color: CoreColor(0xFF7A3FD1),
  /// );
  /// ```
  ///
  /// [onLightFill] states the light-mode text on the primary fill when the
  /// designer has chosen it — see [CoreBrandOnFill].
  const CoreBrand.fromColor({
    required this.id,
    required this.displayName,
    required CoreColor color,
    CoreBrandOnFill onLightFill = CoreBrandOnFill.measured,
  }) : _color = color,
       _onLightFill = onLightFill,
       _palette = null,
       _mapping = null,
       _source = null;

  /// Creates a [CoreBrand] from a colour [source] that is not a generated
  /// palette — CoUI's own `CouiColorPresets.source`, for one.
  const CoreBrand.from({
    required this.id,
    required this.displayName,
    required CoreSchemeSource source,
  }) : _source = source,
       _palette = null,
       _mapping = null,
       _color = null,
       _onLightFill = CoreBrandOnFill.measured;

  /// The lookup key — unique within a [CoreBrandRegistry].
  final String id;

  /// Human-readable name, for a settings screen or a build log — never
  /// used as the lookup key so renaming a brand in the UI does not also
  /// require updating every call site that looks it up by [id].
  final String displayName;

  // A const constructor cannot build the source from its parameters, so a
  // palette brand keeps the pair and [source] wraps it on read.
  final PrimitiveColors? _palette;
  final CoreSemanticMappingSet? _mapping;
  final CoreSchemeSource? _source;
  final CoreColor? _color;
  final CoreBrandOnFill _onLightFill;

  /// The colours this brand renders from — what every colour seat takes.
  CoreSchemeSource get source {
    final color = _color;
    if (color != null) {
      return CoreBrandSchemeSource.fromColor(color, onLightFill: _onLightFill);
    }

    return _source ?? CorePrimitiveSchemeSource(_palette!, _mapping!);
  }

  /// The generated palette of a palette brand.
  ///
  /// Throws a [StateError] for a brand built with [CoreBrand.from] whose
  /// source is not a generated palette — there is no [PrimitiveColors] to
  /// return.
  @Deprecated('Read CoreBrand.source (since 0.154).')
  PrimitiveColors get palette => switch (source) {
    CorePrimitiveSchemeSource(:final palette) => palette,
    _ => throw StateError(
      'CoreBrand "$id" is built from a CoreSchemeSource with no '
      'PrimitiveColors palette — read CoreBrand.source instead.',
    ),
  };

  /// How a palette brand's semantic slots read its palette.
  ///
  /// Throws a [StateError] for a brand built with [CoreBrand.from] whose
  /// source is not a generated palette — see [palette].
  @Deprecated('Read CoreBrand.source (since 0.154).')
  CoreSemanticMappingSet get mapping => switch (source) {
    CorePrimitiveSchemeSource(:final mapping) => mapping,
    _ => throw StateError(
      'CoreBrand "$id" is built from a CoreSchemeSource with no '
      'CoreSemanticMappingSet — read CoreBrand.source instead.',
    ),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreBrand &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          source == other.source);

  @override
  int get hashCode => Object.hash(id, displayName, source);

  @override
  String toString() => 'CoreBrand($id, $displayName)';
}

/// An immutable, id-keyed lookup of [CoreBrand]s.
///
/// Built once from a fixed list at app bootstrap — a multi-tenant app
/// resolves which brand is active for a given app/tenant/build at that same
/// point (a build flavor, a config value, a request's subdomain — this
/// class does not care which) and looks it up by `id` exactly once, before
/// constructing the platform theme:
///
/// ```dart
/// final brands = CoreBrandRegistry([
///   CoreBrand.from(
///     id: 'coui',
///     displayName: 'CoUI Default',
///     source: CouiColorPresets.source,
///   ),
///   CoreBrand(
///     id: 'acme',
///     displayName: 'Acme Corp',
///     palette: PrimitiveColors.generate(...),
///   ),
/// ]);
/// final brand = brands[tenantId];
/// ```
///
/// There is deliberately no mutable `register()` / "current brand" global
/// on this class. Read `cross-platform/localization.md`'s "ambient scope,
/// not global mutable state" rule for why: a Jaspr Web app renders under
/// SSR, which serves requests concurrently, and a global mutable "which
/// brand is active" would let one request's brand leak into another's
/// response. Registration (which brands exist) is fixed, immutable data
/// built once here; *selection* (which one a given app/request renders)
/// stays the caller's own value — passed down its own tree/request context
/// like any other per-request value — never routed through this class.
@immutable
class CoreBrandRegistry {
  /// Creates a [CoreBrandRegistry] from a fixed list of brands.
  ///
  /// Throws an [ArgumentError] if two brands share an [CoreBrand.id] —
  /// silently keeping the last one would let a duplicate registration
  /// shadow an earlier brand without any signal that it happened.
  CoreBrandRegistry(List<CoreBrand> brands) : _byId = _index(brands);

  static Map<String, CoreBrand> _index(List<CoreBrand> brands) {
    final map = <String, CoreBrand>{};
    for (final brand in brands) {
      if (map.containsKey(brand.id)) {
        throw ArgumentError(
          'Duplicate CoreBrand id "${brand.id}" — brand ids must be '
          'unique within a CoreBrandRegistry.',
        );
      }
      map[brand.id] = brand;
    }
    return Map.unmodifiable(map);
  }

  final Map<String, CoreBrand> _byId;

  /// The brand registered under [id]. Throws an [ArgumentError] naming
  /// every registered id when [id] is not one of them — a typo'd tenant
  /// id fails loud here rather than silently falling back to whatever
  /// brand happens to be first.
  CoreBrand operator [](String id) {
    final brand = _byId[id];
    if (brand == null) {
      throw ArgumentError.value(
        id,
        'id',
        'No CoreBrand registered under this id. Registered ids: '
            '${_byId.keys.join(', ')}',
      );
    }
    return brand;
  }

  /// The brand registered under [id], or `null` when none is — for a
  /// caller that wants to fall back rather than fail (e.g. an unknown
  /// subdomain falling back to a default brand).
  CoreBrand? tryGet(String id) => _byId[id];

  /// Whether a brand is registered under [id].
  bool contains(String id) => _byId.containsKey(id);

  /// Every registered brand, in registration order.
  Iterable<CoreBrand> get all => _byId.values;
}
