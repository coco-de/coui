// Native transport only. Dart supplies the canonical probes, readiness and clip.
const fs = await import('node:fs/promises');
const journalFS = await import('node:fs');
const journalPath = __INSTRUCTIONS__ + '.trace.jsonl';
const journalOperations = new Set(['worker','instructions','other','taskSpace','Page.events','Runtime.evaluate','Runtime.releaseObject','DOM.getBoxModel','Page.captureScreenshot','Page.navigate','Page.snapshot','Emulation.setDeviceMetricsOverride','Emulation.clearDeviceMetricsOverride','Emulation.setVisibleSize','Fetch.enable','Fetch.disable','Fetch.fulfillRequest','Network.emulateNetworkConditions','geometry','clips','result','cleanup']);
const journalCodes = new Set(['CAPTURE_CANCELLED','EGO_CDP_REQUEST_TIMEOUT','EGO_PAGE_NOT_AGENT_OWNED','EGO_SPACE_NOT_AGENT_OWNED','EGO_TASK_SPACE_NOT_FOUND','EGO_USER_TAKEOVER','EACCES','EPERM','ENOENT','EIO','ENOSPC','EROFS','EISDIR','EMFILE','EINVAL']);
let journalSequence=0,journalWriteFailed=false;
// Synchronous append keeps overlapping evaluate/event-pump records distinct.
// Writes survive worker exit, not power loss; no fsync in the polling loop.
// Diagnostics never queue native calls or determine capture/cleanup success.
const journal = (operation,phase,error) => {
  let fd;
  try {
    const errorCode=error ? (journalCodes.has(error.code)?error.code:'OTHER') : null;
    const row={sequence:++journalSequence,operation:journalOperations.has(operation)?operation:'other',phase,errorCode};
    fd=journalFS.openSync(journalPath,'a',0o600);
    journalFS.writeSync(fd,JSON.stringify(row)+'\n');
  } catch {journalWriteFailed=true;}
  finally {if(fd!==undefined)try{journalFS.closeSync(fd);}catch{journalWriteFailed=true;}}
};
journal('worker','entry');
journal('instructions','begin');
let input;
try {input=JSON.parse(await fs.readFile(__INSTRUCTIONS__, 'utf8'));journal('instructions','end');}
catch(error){journal('instructions','error',error);throw error;}
const requests = [];
const calls = [];
const remoteHandles = new Set();
let task, page, before, failure, terminalStop, terminalCause;
let metrics = false, offline = false, intercepting = false;
const cleanup = {steps:{},stateFlagsMean:'attempted, possibly applied',priorEmulationIdentityReconstructed:false};
const errorInfo = error => ({name:error?.name || 'Error',code:error?.code || null,message:String(error?.message || error)});
const terminalError = error => {
  const code=String(error?.code || '');
  const text=String(error?.message || error);
  // EGO_* is the public native error family. Conservatively stop on all of
  // it; this does not claim every native safety stop means user takeover.
  return /task space not found:/i.test(text) || code.startsWith('EGO_') || /\bEGO_[A-Z_]+\b/.test(text) ||
    /(?:space|page).*(?:inactive|unassigned|user.owned|user.controlled|not.*agent.owned)/i.test(text);
};
const stopNative = (call,error) => {
  terminalCause ||= error;
  terminalStop ||= {call,error:errorInfo(error),nativeCallsAtDetection:calls.length};
};
const writeJSON = async (path,value) => {
  const operation=path===input.geometryPath?'geometry':path===input.resultPath?'result':'cleanup';
  journal(operation,'begin');
  try {await fs.writeFile(`${path}.tmp`,JSON.stringify(value));await fs.rename(`${path}.tmp`,path);journal(operation,'end');}
  catch(error){journal(operation,'error',error);throw error;}
};
const checkCancellation = async () => {
  let cancelled=Date.now() >= input.softDeadlineEpochMs;
  try {await fs.stat(input.cancelPath);cancelled=true;} catch(error) {if(error.code!=='ENOENT')throw error;}
  if(cancelled){const error=new Error('Owned capture cooperatively cancelled');error.code='CAPTURE_CANCELLED';throw error;}
};
const native = async (name,operation) => {
  if(terminalStop)throw terminalCause;
  journal(name,'begin');
  await checkCancellation();calls.push(name);
  try {const value=await operation();journal(name,'end');return value;} catch(error) {
    journal(name,'error',error);
    if(terminalError(error))stopNative(name,error);
    throw error;
  }
};
const cdp = (method,params) => native(method,()=>page.cdp(method,params,{timeout:Math.max(1,Math.min(input.timeoutMs,input.softDeadlineEpochMs-Date.now()))}));
const expression = (script,...args) => `(${script})(${args.map(v=>JSON.stringify(v)).join(',')})`;
const evaluate = async script => {
  const result=await cdp('Runtime.evaluate',{expression:script,awaitPromise:true,returnByValue:true});
  if(result.exceptionDetails)throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
  return result.result?.value;
};
const environmentScript = `() => ({width:innerWidth,height:innerHeight,dpr:devicePixelRatio,
  offline:!navigator.onLine,mobile:navigator.userAgentData?.mobile ?? null,
  touchPoints:navigator.maxTouchPoints,
  screen:{width:screen.width,height:screen.height,availWidth:screen.availWidth,
    availHeight:screen.availHeight,colorDepth:screen.colorDepth,pixelDepth:screen.pixelDepth,
    orientation:screen.orientation?.type,angle:screen.orientation?.angle},
  visual:{width:visualViewport?.width,height:visualViewport?.height,
    scale:visualViewport?.scale,offsetLeft:visualViewport?.offsetLeft,
    offsetTop:visualViewport?.offsetTop}})`;
const pump = async () => {
  const buffered=await native('Page.events',()=>page.events());
  const events=Array.isArray(buffered)?buffered:buffered?.events;
  if(!Array.isArray(events))throw new Error('Unsupported native event buffer');
  for(const event of events){
    if(event.method!=='Fetch.requestPaused')continue;
    const request=event.params;
    if(request.resourceType!=='Image')throw new Error('Unexpected paused resource type');
    // Request headers/credentials and bodies are never included in logs.
    requests.push({url:request.request.url,type:request.resourceType,id:request.requestId});
    await cdp('Fetch.fulfillRequest',{requestId:request.requestId,responseCode:200,
      responseHeaders:[{name:'Content-Type',value:'image/png'},{name:'access-control-allow-origin',value:'*'}],
      body:input.networkImageBase64});
  }
};
const wait = async (condition,label) => {
  const deadline=Date.now()+input.timeoutMs;
  while(Date.now()<deadline){
    await checkCancellation();await pump();
    if(await condition())return;
    await new Promise(done=>setTimeout(done,10));
  }
  throw new Error(`Ego capture timed out: ${label}`);
};
const withNetworkEvents = async operation => {
  let settled=false,value,error;
  const finished=operation.then(result=>{value=result;settled=true;},failure=>{error=failure;settled=true;});
  await wait(()=>settled,'asynchronous canonical script');await finished;
  if(error)throw error;return value;
};
// Real remote element and DOM border quad; no synthetic ElementHandle.
const measureBox = async selector => {
  const remote=await cdp('Runtime.evaluate',{expression:expression(input.scripts.box,selector),returnByValue:false});
  if(remote.exceptionDetails)throw new Error(remote.exceptionDetails.exception?.description || remote.exceptionDetails.text);
  const objectId=remote.result?.objectId;
  if(!objectId)return null;
  remoteHandles.add(objectId);
  const model=await native('DOM.getBoxModel',async()=>{
    try{return await page.cdp('DOM.getBoxModel',{objectId},{timeout:Math.max(1,Math.min(input.timeoutMs,input.softDeadlineEpochMs-Date.now()))});}
    catch(error){if(terminalError(error))throw error;if(String(error?.message || error).includes('Could not compute box model.'))return null;throw error;}
  });
  if(model===null)return null;
  const scroll=await evaluate('({x:scrollX,y:scrollY})');
  return {borderQuad:model.model.border,scrollX:scroll.x,scrollY:scroll.y};
};
const captureShots = async state => {
  await writeJSON(input.geometryPath,state);
  let clips;journal('clips','begin');
  await wait(async()=>{
    try{clips=JSON.parse(await fs.readFile(input.clipsPath,'utf8'));return true;}
    catch(error){if(error.code==='ENOENT')return false;throw error;}
  },'Dart canonical clip response');
  journal('clips','end');
  if(clips.error)throw new Error(clips.error);
  const pngPaths={};
  for(const [role,clip] of Object.entries(clips)){
    const shot=await cdp('Page.captureScreenshot',{format:'png',fromSurface:true,captureBeyondViewport:true,clip});
    const path=`${input.pngDirectory}/${role}.png`;
    await fs.writeFile(path,Buffer.from(shot.data,'base64'));pngPaths[role]=path;
  }
  return {pngPaths,clips};
};
try {
  task=await native('taskSpace',()=>taskSpace(input.space));
  if(task.ownership!=='agent'){
    const error=new Error('Existing space is not agent-owned');
    stopNative('taskSpace',error);throw error;
  }
  page=task.page(input.page);
  before=await evaluate(expression(environmentScript));
  const orientations={'portrait-primary':'portraitPrimary','portrait-secondary':'portraitSecondary','landscape-primary':'landscapePrimary','landscape-secondary':'landscapeSecondary'};
  const desktop=before.mobile===false && before.touchPoints===0 &&
    before.visual?.scale===1 && before.visual.offsetLeft===0 && before.visual.offsetTop===0 &&
    Number.isFinite(before.width) && Number.isFinite(before.height) && before.dpr>0 &&
    before.screen?.width>0 && before.screen.height>0 &&
    Object.hasOwn(orientations,before.screen.orientation) && Number.isFinite(before.screen.angle);
  if(!desktop)throw new Error('Unsupported incoming emulation; capture refused before mutation');
  metrics=true;await cdp('Emulation.setDeviceMetricsOverride',{width:input.width,height:1200,deviceScaleFactor:1,mobile:false});
  intercepting=true;await cdp('Fetch.enable',{patterns:input.imagePatterns});
  offline=true;await cdp('Network.emulateNetworkConditions',{offline:true,latency:0,downloadThroughput:-1,uploadThroughput:-1});
  await native('Page.events',()=>page.events());
  const navigation=await cdp('Page.navigate',{url:input.url});
  if(navigation.errorText)throw new Error(`Canonical file navigation failed: ${navigation.errorText}`);
  await wait(()=>evaluate(`location.href === ${JSON.stringify(input.url)} && document.readyState === 'complete'`),'file load');
  if(await evaluate('navigator.onLine')!==false)throw new Error('Target offline policy did not apply');
  if(input.runtimeReady)await wait(()=>evaluate(expression(input.runtimeReady)),'client readiness');
  await wait(()=>evaluate(expression(input.scripts.iconify)),'icon readiness');
  await withNetworkEvents(evaluate(expression(input.scripts.fonts)));
  await withNetworkEvents(evaluate(expression(input.scripts.images)));
  if(input.fixedTime)await evaluate(expression(input.scripts.initialAnimation));
  await evaluate(expression(input.scripts.twoFrames));
  if(input.runtimeReady)await wait(()=>evaluate(expression(input.runtimeReady)),'settled client readiness');
  const captureContext=JSON.parse(await evaluate(expression(input.scripts.context)));
  const root=input.probes.find(probe=>probe.role==='root');
  if(!root)throw new Error('Canonical manifest has no root probe');
  const boxes={root:await measureBox(root.webSelector)};
  const byRole={};
  const boxPaddingByRole={};
  const state={boxes,byRole,captureContext};
  const stages=input.probes.filter(probe=>probe.role==='stage');
  // Canonical non-stage order: PNG, then raw probes.
  let shots=stages.length===0?await captureShots(state):null;
  for(const probe of input.probes){
    if(input.additiveBoxObservations){
      const observed=JSON.parse(await evaluate(expression(input.scripts.probeAndBox,{selector:probe.webSelector,layoutSelector:probe.webSelector,requested:probe.fields.includes('paddingPx'),source:probe.boxObservationSource || null,runtimeOperationReceipt:input.runtimeOperationReceipt || null,...(input.requiredCurrentSsrKind?{requiredCurrentSsrKind:input.requiredCurrentSsrKind}:{}),currentSsrSource:input.currentSsrSource || null,...(input.currentClientBoxSource?{currentClientBoxSource:input.currentClientBoxSource}:{})})));
      byRole[probe.role]=observed.legacy;boxPaddingByRole[probe.role]=observed.box;
    }else{
      byRole[probe.role]=JSON.parse(await evaluate(expression(input.scripts.probe,probe.webSelector)));
    }
  }
  // Canonical stage order: raw probes, then one stage PNG. Dart crops it.
  if(stages.length){
    for(const probe of stages)boxes[probe.role]=await measureBox(probe.webSelector);
    shots=await captureShots(state);
  }
  const userAgent=await evaluate('navigator.userAgent');
  await writeJSON(input.resultPath,{...state,...shots,userAgent,requests,
    ...(input.additiveBoxObservations?{boxPaddingByRole}:{}),
    environment:await evaluate('({width:innerWidth,height:innerHeight,dpr:devicePixelRatio,offline:!navigator.onLine})'),
    backend:'Ego Lite native CDP',rasterBackend:'Managed Ego; GPU/software mode not established'});
} catch(error) {
  journal('worker','error',error);failure=errorInfo(error);
} finally {
  journal('cleanup','begin');
  const step=async(name,applied,operation)=>{
    if(!applied){cleanup.steps[name]={status:'not-applied'};return;}
    if(terminalStop){cleanup.steps[name]={status:'not-restored',reason:'terminal native safety stop'};return;}
    calls.push(`cleanup:${name}`);
    try{await operation();cleanup.steps[name]={status:'restored'};}
    catch(error){cleanup.steps[name]={status:'failed',error:errorInfo(error)};if(terminalError(error))stopNative(`cleanup:${name}`,error);}
  };
  const restore=async(method,params)=>{
    journal(method,'cleanup-begin');
    try{const value=await page.cdp(method,params,{timeout:input.cleanupCallTimeoutMs});journal(method,'cleanup-end');return value;}
    catch(error){journal(method,'cleanup-error',error);throw error;}
  };
  for(const objectId of remoteHandles){
    await step(`remoteHandle:${objectId}`,true,()=>restore('Runtime.releaseObject',{objectId}));
  }
  await step('fetch',intercepting,()=>restore('Fetch.disable'));
  await step('offline',offline,()=>restore('Network.emulateNetworkConditions',{offline:before.offline,latency:0,downloadThroughput:-1,uploadThroughput:-1}));
  await step('metrics',metrics,async()=>{
    cleanup.metricsRestoration={strategy:'clear-first, visible-size, observable equality'};
    await restore('Emulation.clearDeviceMetricsOverride');
    const readback=async()=>{
      const response=await restore('Runtime.evaluate',{
        expression:expression(environmentScript),returnByValue:true});
      if(response.exceptionDetails)throw new Error('Metrics restoration readback failed');
      return response.result.value;
    };
    const cleared=await readback();
    cleanup.metricsRestoration.afterClear=cleared;
    if(JSON.stringify(before)===JSON.stringify(cleared))return;
    // Resize the cleared viewport without replacing its native screen work area.
    const visibleSize={width:before.width,height:before.height};
    cleanup.metricsRestoration.visibleSizeParameters=visibleSize;
    await restore('Emulation.setVisibleSize',visibleSize);
    const visible=await readback();
    cleanup.metricsRestoration.afterVisibleSize=visible;
    if(JSON.stringify(before)===JSON.stringify(visible))return;
    const explicitMetrics={width:before.width,height:before.height,
      deviceScaleFactor:before.dpr,mobile:false,scale:before.visual.scale};
    // Retain the native work area when only the viewport/DPR needs restoring.
    if(JSON.stringify(before.screen)!==JSON.stringify(visible.screen)){
      explicitMetrics.screenWidth=before.screen.width;
      explicitMetrics.screenHeight=before.screen.height;
      explicitMetrics.screenOrientation={type:before.screen.orientation.replace(/-([a-z])/g,(_,c)=>c.toUpperCase()),angle:before.screen.angle};
    }
    cleanup.metricsRestoration.explicitParameters=explicitMetrics;
    await restore('Emulation.setDeviceMetricsOverride',explicitMetrics);
    const explicit=await readback();
    cleanup.metricsRestoration.afterExplicit=explicit;
    if(JSON.stringify(before)!==JSON.stringify(explicit)){
      throw new Error('Observed desktop metrics were not restored');
    }
  });
  cleanup.beforeEnvironment=before || null;
  cleanup.restorationScope='Observed supported desktop viewport/DPR/screen/visual scale; prior hidden override identity is unknown';
  if(page && !terminalStop && (metrics||offline||intercepting)){
    calls.push('cleanup:observe');
    try{const observed=await restore('Runtime.evaluate',{expression:expression(environmentScript),returnByValue:true});if(observed.exceptionDetails)throw new Error('Environment observation failed');cleanup.afterEnvironment=observed.result.value;cleanup.observedEnvironmentEqual=JSON.stringify(before)===JSON.stringify(cleanup.afterEnvironment);}
    catch(error){cleanup.observationError=errorInfo(error);if(terminalError(error))stopNative('cleanup:observe',error);}
  }
  cleanup.complete=!terminalStop && Object.values(cleanup.steps).every(step=>['restored','not-applied'].includes(step.status)) &&
    (!(metrics||offline||intercepting) || cleanup.observedEnvironmentEqual===true);
  cleanup.journalWriteFailed=journalWriteFailed;
  cleanup.terminalStop=terminalStop || null;cleanup.failure=failure || null;cleanup.nativeCalls=calls;cleanup.pageCalls=calls.filter(name=>name!=='taskSpace');
  await writeJSON(input.cleanupPath,cleanup);
}
if(!failure && cleanup.complete){
  try{console.log(await native('Page.snapshot',()=>page.snapshot()));}
  catch(error){failure=errorInfo(error);cleanup.complete=false;cleanup.terminalStop=terminalStop || null;cleanup.failure=failure;await writeJSON(input.cleanupPath,cleanup);}
}
if(failure || !cleanup.complete){console.error(JSON.stringify({failure,cleanupComplete:cleanup.complete,terminalStop:!!terminalStop}));process.exitCode=1;}
