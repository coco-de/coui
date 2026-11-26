import 'dart:convert';
import 'package:coui_web/coui_web.dart' as coui;
import '../model/box_observation_source_spec.dart';

/// Internal pre-render witness. Root must wire this closed typed preflight
/// before granting source authority; DOM inspection cannot recreate raw bags.
class NavigationTriggerWebRawBinding {
  NavigationTriggerWebRawBinding._(
    this.producer,
    this.source,
    this.rawSlots,
    this._operation,
  );
  final coui.Component producer;
  final BoxObservationSourceSpec source;
  final List<coui.Component?> rawSlots;
  final List<Object?> _operation;
  Map<String, Object?> get currentDomContract {
    validateExistingCurrentBinding();
    final result = <String, Object?>{
      'schema': 'navigation-trigger-current-raw-v1',
      'source': source.toJson(),
    };
    switch (producer) {
      case final coui.CommandSearch w:
        result.addAll({
          'leadingSupplied': w.leading != null,
          'shortcutSupplied': w.shortcut != null,
        });
      case final coui.NavigationBar w:
        result.addAll({
          'headerSupplied': w.header != null,
          'vertical': w.mode.isVertical,
          'sidebar': w.mode.isSidebar,
          'footerSupplied': w.footer != null,
          'items': [
            for (final item in w.items)
              {
                'kind': switch (item.kind) {
                  .item => 'item',
                  .label => 'label',
                  .divider => 'divider',
                  .gap => 'gap',
                },
              },
          ],
        });
      case final coui.Dock w:
        result['items'] = [
          for (final item in w.items)
            {
              'interactive': item.onPressed != null,
              'labelSupplied': item.label != null,
              'active': item.isActive,
            },
        ];
      default:
        throw StateError('NAVIGATION_TRIGGER_PRODUCER_CHANGED');
    }
    return result;
  }

  void validateExistingCurrentBinding() {
    final now = bindNavigationTriggerWebRawSource(
      producer: producer,
      source: source,
    );
    if (now.rawSlots.length != rawSlots.length ||
        List.generate(
          rawSlots.length,
          (i) => identical(now.rawSlots[i], rawSlots[i]),
        ).any((same) => !same) ||
        now._operation.length != _operation.length ||
        List.generate(
          _operation.length,
          (i) => now._operation[i] == _operation[i],
        ).any((same) => !same)) {
      throw StateError('NAVIGATION_TRIGGER_RAW_CURRENT_CHANGED');
    }
  }
}

NavigationTriggerWebRawBinding bindNavigationTriggerWebRawSource({
  required coui.Component producer,
  required BoxObservationSourceSpec source,
}) {
  final raw = <coui.Component?>[];
  final operation = <Object?>[];
  if (source == BoxObservationSourceSpec.commandSearchTriggerContentInset) {
    if (producer.runtimeType != coui.CommandSearch) {
      throw StateError('COMMAND_SEARCH_CONCRETE_PRODUCER_REQUIRED');
    }
    final w = producer as coui.CommandSearch;
    raw.addAll([w.leading, w.shortcut]);
    operation.addAll([w.hint, w.enabled]);
  } else if (source ==
      BoxObservationSourceSpec.navigationBarItemsContentInset) {
    if (producer.runtimeType != coui.NavigationBar) {
      throw StateError('NAVIGATION_BAR_CONCRETE_PRODUCER_REQUIRED');
    }
    final w = producer as coui.NavigationBar;
    for (final item in w.items) {
      if (item.runtimeType != (coui.CoreNavigationBarItem<coui.Component>)) {
        throw StateError('NAVIGATION_BAR_CONCRETE_GENERIC_DATA_REQUIRED');
      }
      // Every kind, including a raw reference later suppressed by its kind.
      raw.addAll([item.icon, item.badge]);
      operation.add(item);
    }
    raw.addAll([w.header, w.footer]);
    operation.addAll([w.mode, w.selectedIndex]);
  } else if (source == BoxObservationSourceSpec.dockBarContentInset) {
    if (producer.runtimeType != coui.Dock) {
      throw StateError('DOCK_CONCRETE_PRODUCER_REQUIRED');
    }
    final w = producer as coui.Dock;
    for (final item in w.items) {
      if (item.runtimeType != (coui.CoreDockItemData<coui.Component>)) {
        throw StateError('DOCK_CONCRETE_GENERIC_DATA_REQUIRED');
      }
      raw.add(item.icon);
      operation.add(item);
    }
  } else {
    throw StateError('NAVIGATION_TRIGGER_CLOSED_TUPLE_REQUIRED');
  }
  final seen = Set<coui.Component>.identity();
  for (final slot in raw.whereType<coui.Component>()) {
    if (!seen.add(slot)) throw StateError('DUPLICATE_RAW_SLOT_BEFORE_OMISSION');
  }
  return NavigationTriggerWebRawBinding._(
    producer,
    source,
    List.unmodifiable(raw),
    List.unmodifiable(operation),
  );
}

/// Returns source-bound current refs, complete opaque seats and authority.
/// No CSS value, geometry, capture-key suffix or preset chooses an owner.
String get navigationTriggerBoxSourceResolverScript =>
    '''
(layoutRoot,source,currentRaw) => {
  const fail=error=>({error});
  const tuples=${jsonEncode([
      BoxObservationSourceSpec.commandSearchTriggerContentInset,
      BoxObservationSourceSpec.navigationBarItemsContentInset,
      BoxObservationSourceSpec.dockBarContentInset,
    ].map((s) => s.toJson()).toList())};
  const spec=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!spec || Object.keys(source).length!==Object.keys(spec).length ||
      Object.keys(spec).some(k=>source[k]!==spec[k]))
    return fail('NAVIGATION_TRIGGER_TUPLE_CHANGED');
  if(!currentRaw || currentRaw.schema!=='navigation-trigger-current-raw-v1' ||
      !currentRaw.source || Object.keys(currentRaw.source).length!==Object.keys(spec).length || Object.keys(spec).some(k=>currentRaw.source[k]!==spec[k]))
    return fail('NAVIGATION_TRIGGER_CURRENT_RAW_WITNESS_REQUIRED');
  const children=n=>{
    if(!n || !n.children)return null;
    const all=Array.from(n.children);
    return all.length===new Set(all).size && all.every(c=>c.parentElement===n)?all:null;
  };
  const tag=(n,name)=>n && n.tagName===name;
  // Only the source-generated Icon seat has two namespace-specific forms.
  // HTML tag guards elsewhere remain exact and unchanged.
  const generatedIcon=n=>n && (
    (n.namespaceURI==='http://www.w3.org/2000/svg' &&
      n.localName==='svg' && n.tagName==='svg') ||
    (n.namespaceURI==='http://www.w3.org/1999/xhtml' &&
      n.localName==='iconify-icon' && n.tagName==='ICONIFY-ICON'));
  const has=(n,...names)=>n && names.every(c=>n.classList.contains(c));
  const empty=n=>children(n)?.length===0;
  const capture=layoutRoot?.parentElement,top=children(capture);
  if(!capture?.hasAttribute('data-parity-key') || !top || top.length!==1 ||
      top[0]!==layoutRoot || layoutRoot.isConnected===false)
    return fail('NAVIGATION_TRIGGER_CAPTURE_CHANGED');
  let field=layoutRoot;const foreignSeats=[],operation=[];
  const ownStyles=seats=>{
    let i=0;
    while(i<seats.length && tag(seats[i],'STYLE')){
      if(!empty(seats[i]))return -1;i++;
    }
    return i;
  };
  switch(source.logicalUnitId){
    case 'command-search-generated-trigger-content-inset': {
      // Canonical example's sole width wrapper; the source also accepts an
      // exact directly supplied public CommandSearch under raw prevalidation.
      if(layoutRoot.getAttribute('role')!=='button'){
        const wrapper=children(layoutRoot);
        if(!tag(layoutRoot,'DIV') || !wrapper || wrapper.length!==1 ||
            !tag(wrapper[0],'DIV'))return fail('COMMAND_SEARCH_REGISTRY_CHANGED');
        field=wrapper[0];
      }
      if(!tag(field,'DIV') || field.getAttribute('role')!=='button')
        return fail('COMMAND_SEARCH_CLICKABLE_CHANGED');
      const all=children(field);if(!all)return fail('COMMAND_SEARCH_CHILDREN_CHANGED');
      const i=ownStyles(all),seats=all.slice(i);
      if(typeof currentRaw.leadingSupplied!=='boolean' || typeof currentRaw.shortcutSupplied!=='boolean' ||
          i<0 || i>2 || seats.length!==(currentRaw.shortcutSupplied?6:4) ||
          !tag(seats[0],'DIV') || !empty(seats[0]) ||
          !has(seats[0],'pointer-events-none') || !tag(seats[2],'DIV') ||
          !empty(seats[2]) || !tag(seats[3],'DIV'))
        return fail('COMMAND_SEARCH_ORDERED_TRIGGER_SEATS_CHANGED');
      if(currentRaw.leadingSupplied)foreignSeats.push(seats[1]);
      else if(!generatedIcon(seats[1]))return fail('COMMAND_SEARCH_GENERATED_ICON_CHANGED');
      if(seats.length===6){
        if(!tag(seats[4],'DIV') || !empty(seats[4]))
          return fail('COMMAND_SEARCH_SHORTCUT_GAP_CHANGED');
        foreignSeats.push(seats[5]);
      }
      operation.push('wash-leading-gap-hint-shortcut');break;
    }
    case 'navigation-bar-generated-items-content-inset': {
      if(!tag(field,'NAV') || !has(field,'flex'))
        return fail('NAVIGATION_BAR_CANONICAL_NAV_CHANGED');
      const horizontal=has(field,'flex-row'),vertical=has(field,'flex-col');
      if(horizontal===vertical || typeof currentRaw.vertical!=='boolean' ||
          typeof currentRaw.sidebar!=='boolean' || currentRaw.vertical!==vertical ||
          (currentRaw.sidebar && !vertical))return fail('NAVIGATION_BAR_CURRENT_AXIS_CHANGED');
      // Glass owns extra moving layers. No private/runtime-state projection is
      // implied here; every unknown glass/current extra route remains HOLD.
      if(has(field,'coui-navigation-glass-active') || has(field,'coui-navigation-glass-vertical'))
        return fail('NAVIGATION_BAR_GLASS_ROUTE_UNPROVED');
      const axisOverflow=horizontal?'overflow-x-auto':'overflow-y-auto';
      let seats=children(field);
      if(!seats)return fail('NAVIGATION_BAR_CHILDREN_CHANGED');
      if(!has(field,axisOverflow)){
        // Exact framed source: optional whole header, sole items host,
        // optional whole footer. Identify the generated host by source class
        // topology, never by a padding/width/height value.
        if(typeof currentRaw.headerSupplied!=='boolean' || typeof currentRaw.footerSupplied!=='boolean' ||
            (!currentRaw.headerSupplied && !currentRaw.footerSupplied) ||
            seats.length!==1+Number(currentRaw.headerSupplied)+Number(currentRaw.footerSupplied))
          return fail('NAVIGATION_BAR_HEADER_FOOTER_ORDER_CHANGED');
        const host=seats[currentRaw.headerSupplied?1:0];
        if(!tag(host,'DIV') || !has(host,'flex',horizontal?'flex-row':'flex-col',axisOverflow))
          return fail('NAVIGATION_BAR_FOOTER_HOST_CHANGED');
        foreignSeats.push(...seats.filter(n=>n!==host));
        seats=children(host);operation.push('framed');
      }else {
        if(currentRaw.headerSupplied!==false || currentRaw.footerSupplied!==false)
          return fail('NAVIGATION_BAR_UNFRAMED_RAW_CHANGED');
        operation.push('unframed');
      }
      if(!seats || !Array.isArray(currentRaw.items))return fail('NAVIGATION_BAR_ITEMS_CHANGED');
      // The public bar/rail mode, raw kinds and header/footer operation
      // establish the source layer branch. This is independent of whether
      // the material is currently glass. No CSS numbers or preset decide it.
      const withLayers=!currentRaw.sidebar && !currentRaw.headerSupplied &&
        !currentRaw.footerSupplied && currentRaw.items.length>0 &&
        currentRaw.items.every(r=>r?.kind==='item');
      let i=0,end=seats.length;
      if(withLayers){
        const rootId=field.getAttribute('id');
        const marker=(n,name)=>tag(n,'SPAN') && has(n,'coui-navigation-'+name) &&
          n.getAttribute('aria-hidden')==='true' && empty(n) &&
          n.getAttribute('id')===rootId+'-'+name;
        if(!rootId || !tag(seats[i],'STYLE') || !empty(seats[i++]))
          return fail('NAVIGATION_BAR_GLASS_STYLE_CHANGED');
        if(marker(seats[i],'pane'))i++;
        if(!marker(seats[i++],'selection') || !marker(seats[end-1],'lens'))
          return fail('NAVIGATION_BAR_OWN_LAYER_SEQUENCE_CHANGED');
        end--;operation.push('source-owned-inert-layer-seats');
      }
      const rest=seats.slice(i,end),styles=ownStyles(rest);
      if(styles<0 || styles>2)return fail('NAVIGATION_BAR_STYLE_SEATS_CHANGED');
      const items=rest.slice(styles);let destination=0;
      if(items.length!==currentRaw.items.length)return fail('NAVIGATION_BAR_COMPLETE_RAW_ORDER_CHANGED');
      for(let itemIndex=0;itemIndex<items.length;itemIndex++){
        const seat=items[itemIndex],raw=currentRaw.items[itemIndex];
        if(!raw || !['item','label','divider','gap'].includes(raw.kind))
          return fail('NAVIGATION_BAR_RAW_KIND_CHANGED');
        if(raw.kind!=='item'){
          const c=children(seat);
          if(!tag(seat,'DIV') || !c)return fail('NAVIGATION_BAR_NONITEM_CHANGED');
          if(raw.kind==='label' && (!has(seat,'box-border') || c.length!==1 || !tag(c[0],'SPAN')))
            return fail('NAVIGATION_BAR_SECTION_LABEL_CHANGED');
          if(raw.kind==='gap' && c.length!==0)return fail('NAVIGATION_BAR_GAP_CHANGED');
          if(raw.kind==='divider' && (!has(seat,'shrink-0') || c.length!==1 ||
              !tag(c[0],'DIV') || !empty(c[0])))
            return fail('NAVIGATION_BAR_DIVIDER_CHANGED');
          foreignSeats.push(seat);continue;
        }
        let cell=seat;
        if(cell.hasAttribute('data-coui-nav-index')){
          // The direct source-composed Clickable destination.
        }else{
          const a=children(cell),b=a?.length===1?children(a[0]):null;
          if(tag(cell,'DIV') && a?.length===1 && tag(a[0],'DIV') &&
              b?.length===1 && b[0].hasAttribute('data-coui-nav-index'))cell=b[0];
          else return fail('NAVIGATION_BAR_DESTINATION_ROUTE_CHANGED');
        }
        if(!tag(cell,'DIV') || cell.getAttribute('role')!=='button' ||
            cell.getAttribute('data-coui-nav-index')!==String(destination++))
          return fail('NAVIGATION_BAR_ORDERED_DESTINATIONS_CHANGED');
        const c=children(cell);if(!c)return fail('NAVIGATION_BAR_DESTINATION_CHANGED');
        const j=ownStyles(c);
        if(j<0 || j>1 || c.length!==j+1 || !tag(c[j],'DIV') ||
            !c[j].hasAttribute('data-coui-nav-chrome'))
          return fail('NAVIGATION_BAR_OWN_CHROME_CHANGED');
        foreignSeats.push(seat);
      }
      if(items.length===0)return fail('NAVIGATION_BAR_EMPTY_UNPROVED');
      operation.push(horizontal?'horizontal':'vertical');break;
    }
    case 'dock-generated-bar-content-inset': {
      if(!tag(field,'DIV') || field.getAttribute('role')!=='navigation' ||
          !has(field,'flex','flex-row','w-full','items-center','justify-center','relative','isolate'))
        return fail('DOCK_CANONICAL_BAR_CHANGED');
      const all=children(field);if(!all)return fail('DOCK_ITEMS_CHANGED');
      let i=0;
      if(all[0]?.getAttribute('aria-hidden')==='true'){
        if(!tag(all[0],'DIV') || !empty(all[0]))return fail('DOCK_FLIGHT_CHANGED');i++;
      }
      if(!Array.isArray(currentRaw.items) || all.length-i!==currentRaw.items.length)
        return fail('DOCK_COMPLETE_RAW_ORDER_CHANGED');
      for(let itemIndex=0;itemIndex<currentRaw.items.length;itemIndex++){
        const seat=all[i+itemIndex],raw=currentRaw.items[itemIndex];
        if(!raw || ['interactive','labelSupplied','active'].some(k=>typeof raw[k]!=='boolean'))
          return fail('DOCK_RAW_ITEM_CHANGED');
        if((seat.getAttribute('role')==='button')!==raw.interactive)
          return fail('DOCK_CURRENT_INTERACTIVE_CHANGED');
        let body=seat;
        if(seat.getAttribute('role')==='button'){
          const c=children(seat),j=c?ownStyles(c):-1;
          if(j<0 || j>1 || c.length!==j+1 || !tag(c[j],'DIV'))
            return fail('DOCK_CLICKABLE_BODY_CHANGED');body=c[j];
        }
        if(!has(body,'flex','flex-col','items-center','justify-center','select-none'))
          return fail('DOCK_ORDERED_APP_BODY_CHANGED');
        const c=children(body);
        if(!c || ![1,3].includes(c.length) || (c.length===3 && !raw.labelSupplied) || !tag(c[0],'DIV'))
          return fail('DOCK_ICON_LABEL_SEATS_CHANGED');
        const icon=children(c[0]);
        if(!icon || icon.length!==1+Number(raw.active && i===0))return fail('DOCK_ICON_ROW_CHANGED');
        if(icon.length===2 && (!tag(icon[0],'DIV') ||
            icon[0].getAttribute('aria-hidden')!=='true' || !empty(icon[0])))
          return fail('DOCK_SETTLED_PLATE_CHANGED');
        foreignSeats.push(icon[icon.length-1]);
        if(c.length===3 && (!tag(c[1],'DIV') || !empty(c[1]) || !tag(c[2],'DIV')))
          return fail('DOCK_LABEL_GAP_CHANGED');
      }
      if(all.length===i)return fail('DOCK_EMPTY_UNPROVED');
      operation.push('bar-own-padding-only-inner-clearance-excluded');break;
    }
    default:return fail('UNSUPPORTED_NAVIGATION_TRIGGER_SOURCE');
  }
  if(new Set(foreignSeats).size!==foreignSeats.length ||
      foreignSeats.some(n=>n===field || n.contains?.(field)))
    return fail('NAVIGATION_TRIGGER_FOREIGN_FRAME');
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,registryIsLayoutRoot:true,
    foreignSeats,operationEvidence:operation,
    authority:'Closed typed raw preflight required; exact current source construction edges and complete opaque ordered seats; Dock bar only, excludes inner clearance; no CSS values/geometry/Core/private state/callback replay'};
}
''';
