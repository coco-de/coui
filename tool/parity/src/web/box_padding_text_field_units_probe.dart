/// Reads the two complementary parameters declared by TextField's renderer.
///
/// The source resolver must first bind the actual framed wrapper, its input,
/// and the complete current affix/feature seats. This does not discover an
/// owner or infer an inset from content geometry.
String get textFieldComplementaryPaddingScript => r'''
(binding) => {
  const fail = error => ({error});
  const parts = binding?.complementaryPaddingSources;
  if (!parts || parts.kind !== 'text-field-wrapper-input-v1') return fail('MISSING_TEXT_FIELD_PADDING_PARTS');
  const {wrapper,input,leadingAffixed,trailingAffixed} = parts;
  if (!wrapper || !input || wrapper === input || !wrapper.isConnected || !input.isConnected || wrapper.tagName !== 'DIV' || input.tagName !== 'INPUT' || input.parentElement !== wrapper || binding.fieldUnitElement !== wrapper || binding.paddingSource !== wrapper || binding.frameSource !== wrapper) return fail('TEXT_FIELD_PADDING_PART_OWNER_CHANGED');
  const children = Array.from(wrapper.children);
  const inputs = children.filter(child=>child.tagName === 'INPUT');
  const index = children.indexOf(input);
  if (inputs.length !== 1 || inputs[0] !== input || typeof leadingAffixed !== 'boolean' || typeof trailingAffixed !== 'boolean' || leadingAffixed !== (index > 0) || trailingAffixed !== (index < children.length-1)) return fail('TEXT_FIELD_AFFIX_ALLOCATION_CHANGED');
  const read = node => {
    const css = getComputedStyle(node);
    if (css.display === 'none' || css.display === 'contents') return fail('NO_DECLARED_LAYOUT_BOX');
    const raw = [css.paddingTop,css.paddingRight,css.paddingBottom,css.paddingLeft];
    if (raw.some(text=>typeof text !== 'string' || !/^[+-]?(?:[0-9]+(?:[.][0-9]*)?|[.][0-9]+)(?:[eE][+-]?[0-9]+)?px$/.test(text))) return fail('UNRESOLVED_CSS_PADDING_UNIT');
    const value = raw.map(text=>Number.parseFloat(text));
    if (value.some(number=>!Number.isFinite(number) || number < 0)) return fail('UNRESOLVED_CSS_PADDING');
    return {raw,value};
  };
  const outer = read(wrapper);
  if (outer.error) return outer;
  const inner = read(input);
  if (inner.error) return inner;
  // text_field_style.dart allocates each side to exactly one source slot.
  // These zeros are literal allocation premises, not expected inset values.
  if (inner.value[0] !== 0 || inner.value[2] !== 0 || (leadingAffixed ? inner.value[3] : outer.value[3]) !== 0 || (trailingAffixed ? inner.value[1] : outer.value[1]) !== 0) return fail('TEXT_FIELD_COMPLEMENTARY_ALLOCATION_CHANGED');
  const value = outer.value.map((number,axis)=>number+inner.value[axis]);
  if (value.some(number=>!Number.isFinite(number))) return fail('UNRESOLVED_CSS_PADDING');
  return {
    value,
    quantityDerivation:'source-complementary-wrapper-input-v1',
    rawCssParts:[
      {slot:'framed-wrapper',ownerTag:wrapper.tagName,rawCss:outer.raw},
      {slot:'direct-input',ownerTag:input.tagName,rawCss:inner.raw}
    ],
    parameterAllocation:{leadingAffixed,trailingAffixed,inputOwnVerticalPaddingAbsent:true}
  };
}
''';
