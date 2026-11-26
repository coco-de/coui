import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source references and operation evidence only. The coordinator reads CSS.
String get validationViewportBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const tuples=${jsonEncode(BoxObservationSourceSpec.validationViewportFrames.map((s) => s.toJson()).toList())};
  const spec=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!spec || Object.keys(spec).some(k=>source[k]!==spec[k]))
    return fail('VALIDATION_VIEWPORT_TUPLE_CHANGED');
  const children=n=>{
    if(!n || !n.children)return null;
    const all=Array.from(n.children);
    return all.length===new Set(all).size && all.every(c=>c.parentElement===n)?all:null;
  };
  const div=n=>n && n.tagName==='DIV';
  const has=(n,...names)=>n && names.every(s=>n.classList.contains(s));
  const capture=layoutRoot && layoutRoot.parentElement;
  const top=children(capture),outer=children(layoutRoot);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top ||
      top.length!==1 || top[0]!==layoutRoot || !outer)
    return fail('VALIDATION_VIEWPORT_CAPTURE_CHANGED');
  let field=layoutRoot,complementaryPaddingSources=null;
  const foreignSeats=[];
  switch(source.logicalUnitId){
    case 'text-field-generated-content-inset': {
      // The exact Formatter example returns a width wrapper. TextField then
      // returns its own root, optional generated STYLEs, FocusOutline and box.
      if(!div(layoutRoot) || outer.length!==1 || !div(outer[0]))
        return fail('TEXT_FIELD_REGISTRY_CHANGED');
      const root=outer[0],all=children(root);
      if(!all || !has(root,'grid','w-full'))return fail('TEXT_FIELD_ROOT_CHANGED');
      let i=0;
      while(i<all.length && all[i].tagName==='STYLE'){
        if(children(all[i]).length!==0)return fail('TEXT_FIELD_STYLE_SEAT_CHANGED');
        i++;
      }
      if(i>2 || all.length!==i+1 || !div(all[i]))
        return fail('TEXT_FIELD_LABEL_OR_FEATURE_ROUTE_CHANGED');
      const focus=all[i],focusSeats=children(focus);
      if(!focusSeats || focusSeats.length!==1 || !div(focusSeats[0]))
        return fail('TEXT_FIELD_FOCUS_FRAME_CHANGED');
      field=focusSeats[0];
      if(!has(field,'flex'))return fail('TEXT_FIELD_BOX_CHANGED');
      const seats=children(field);
      if(!seats)return fail('TEXT_FIELD_SEAT_IDENTITY_CHANGED');
      const inputs=seats.filter(n=>n.tagName==='INPUT');
      if(inputs.length!==1)return fail('TEXT_FIELD_SINGLE_INPUT_CHANGED');
      const input=inputs[0],index=seats.indexOf(input);
      if(children(input).length!==0)return fail('TEXT_FIELD_INPUT_PART_CHANGED');
      const before=seats.slice(0,index),after=seats.slice(index+1);
      const affix=n=>n.tagName==='SPAN' && has(n,'flex','items-center') &&
        children(n)?.length===1;
      const feature=n=>n.tagName==='BUTTON' && n.getAttribute('type')==='button';
      // All slots are enumerated before deriving either allocation flag.
      if(before.some((n,j)=>!(j===0 && affix(n)) && !feature(n)) ||
          after.some((n,j)=>!(j===after.length-1 && affix(n)) && !feature(n)))
        return fail('TEXT_FIELD_AFFIX_FEATURE_SEATS_CHANGED');
      for(const n of [...before,...after])foreignSeats.push(n);
      complementaryPaddingSources={kind:'text-field-wrapper-input-v1',
        wrapper:field,input,leadingAffixed:before.length>0,trailingAffixed:after.length>0};
      break;
    }
    case 'validated-generated-layout-host': {
      if(!div(layoutRoot) || outer.length!==1 || !div(outer[0]))
        return fail('VALIDATED_REGISTRY_CHANGED');
      field=outer[0];
      const seats=children(field);
      // Closed actual default recipe: complete child, generated Gap, Hint.
      // A pending/missing message never falls back to a zero-valued node.
      if(!has(field,'flex','flex-col') || !seats || seats.length!==3 ||
          !div(seats[1]) || seats[2].tagName!=='P' || seats[2].getAttribute('role')!=='alert')
        return fail('VALIDATED_CURRENT_MESSAGE_CHANGED');
      const hint=children(seats[2]);
      if(!hint || hint.length!==2 || hint[0].tagName!=='SPAN' ||
          hint[0].getAttribute('aria-hidden')!=='true')
        return fail('VALIDATED_COMPOSED_HINT_CHANGED');
      foreignSeats.push(seats[0],hint[1]);
      break;
    }
    case 'validator-hint-generated-message-layout-host': {
      if(field.tagName!=='P' || !has(field,'inline-flex','flex-row','items-center') ||
          outer.length!==2 || outer[0].tagName!=='SPAN' ||
          outer[0].getAttribute('aria-hidden')!=='true')
        return fail('VALIDATOR_HINT_VISIBLE_MESSAGE_CHANGED');
      foreignSeats.push(outer[0],outer[1]);
      break;
    }
    case 'scroll-area-generated-viewport-layout-host': {
      if(!div(layoutRoot) || outer.length!==1 || !div(outer[0]))
        return fail('SCROLL_AREA_REGISTRY_CHANGED');
      field=outer[0];
      const seats=children(field);
      if(!has(field,'relative') || !seats || seats.length<3 ||
          seats[0].tagName!=='STYLE')return fail('SCROLL_AREA_VIEWPORT_CHANGED');
      let i=1;
      while(i<seats.length && seats[i].getAttribute('role')==='scrollbar'){
        if(!div(seats[i]) || children(seats[i]).length!==0 ||
            !['vertical','horizontal'].includes(seats[i].getAttribute('aria-orientation')) ||
            seats[i].getAttribute('aria-controls')!==field.getAttribute('id'))
          return fail('SCROLL_AREA_GENERATED_ROLE_CHANGED');
        i++;
      }
      if(i===1 || i>3)return fail('SCROLL_AREA_AXIS_SEATS_CHANGED');
      if(i<seats.length-1){
        const layer=seats[i++];
        if(!div(layer) || !has(layer,'co-scrollbar-layer') ||
            layer.getAttribute('aria-hidden')!=='true')return fail('SCROLL_AREA_LAYER_CHANGED');
      }
      if(seats.length!==i+1)return fail('SCROLL_AREA_WHOLE_CHILD_CHANGED');
      foreignSeats.push(seats[i]);
      break;
    }
    case 'fade-scroll-generated-viewport-layout-host': {
      let host=layoutRoot;
      if(!div(host))return fail('FADE_SCROLL_REGISTRY_CHANGED');
      // Vertical docs recipes own one height wrapper; horizontal returns host.
      if(!has(host,'relative','overflow-hidden')){
        if(!div(host) || outer.length!==1 || !div(outer[0]))
          return fail('FADE_SCROLL_REGISTRY_CHANGED');
        host=outer[0];
      }
      const seats=children(host);
      if(!has(host,'relative','overflow-hidden','w-full','h-full') || !seats)
        return fail('FADE_SCROLL_HOST_CHANGED');
      let i=0;
      if(seats[0]?.tagName==='STYLE')i++;
      if(seats.length!==i+1 || !div(seats[i]))return fail('FADE_SCROLL_VIEWPORT_SEAT_CHANGED');
      field=seats[i];
      if(!((has(field,'h-full','overflow-y-auto','overflow-x-hidden')) ||
          has(field,'w-full','overflow-x-auto','overflow-y-hidden')))
        return fail('FADE_SCROLL_VIEWPORT_OPERATION_CHANGED');
      const content=children(field);
      if(!content || content.length!==1)return fail('FADE_SCROLL_WHOLE_CHILD_CHANGED');
      foreignSeats.push(content[0]);
      break;
    }
    case 'overflow-marquee-generated-viewport-layout-host': {
      if(!div(layoutRoot) || outer.length!==1 || !div(outer[0]))
        return fail('MARQUEE_REGISTRY_CHANGED');
      field=outer[0];
      const seats=children(field);
      if(!has(field,'co-om') || !seats || seats.length!==2 ||
          seats[0].tagName!=='STYLE' || !div(seats[1]) || !has(seats[1],'co-om-track'))
        return fail('MARQUEE_VIEWPORT_TRACK_CHANGED');
      const content=children(seats[1]);
      if(!content || content.length!==1)return fail('MARQUEE_SINGLE_CHILD_MULTIPLICITY_CHANGED');
      foreignSeats.push(content[0]);
      break;
    }
    case 'kbd-generated-key-sequence-layout-host': {
      // The closed typed construction is the keys-list route, not keyContent.
      // Preserve its whole ordered sequence; no capture-key/preset selection.
      if(field.tagName!=='SPAN' || !has(field,'inline-flex','items-center') ||
          outer.length===0 || outer.some(n=>n.tagName!=='SPAN' ||
            !has(n,'inline-flex','shrink-0','items-center','justify-center') || children(n).length!==0))
        return fail('KBD_COMPLETE_KEY_SEQUENCE_CHANGED');
      if(field.getAttribute('aria-label')!==outer.map(n=>n.textContent).join(' '))
        return fail('KBD_CURRENT_ORDERED_KEYS_CHANGED');
      break;
    }
    default:return fail('UNSUPPORTED_VALIDATION_VIEWPORT_SOURCE');
  }
  if(!field || field.isConnected===false || new Set(foreignSeats).size!==foreignSeats.length ||
      foreignSeats.some(n=>n===field || n.contains?.(field)))
    return fail('VALIDATION_VIEWPORT_FOREIGN_FRAME');
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,registryIsLayoutRoot:true,
    complementaryPaddingSources,foreignSeats,
    authority:'Exact prevalidated validation/viewport recipe; canonical registry and current source edges; complete whole foreign seats and single-child marquee path; TextField complementary wrapper/input parameters are refs only; no CSS/geometry/Core/style values or callbacks read'};
}
''';
