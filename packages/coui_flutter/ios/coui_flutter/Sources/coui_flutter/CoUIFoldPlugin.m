#import "./include/coui_flutter/CoUIFoldPlugin.h"

#import <UIKit/UIKit.h>

// The hinge and the reserved regions arrive with the iOS 27.1 SDK. The
// headers decide, not the compiler's version: an Xcode without them builds
// this file to "no fold", so an app built there reads the answer it read
// before this plugin existed. On a newer SDK the calls are still gated at
// run time, for the devices below iOS 27.1 the same binary runs on.
#if __has_include(<UIKit/UIHingeInteraction.h>) && __has_include(<UIKit/UIViewReservedRegion.h>)
#define COUI_FOLD_HAS_SDK 1
#else
#define COUI_FOLD_HAS_SDK 0
#endif

static NSString *const kCoUIFoldChannelName = @"coui_flutter/fold";
static NSString *const kCoUIFoldReadMethod = @"read";
static NSString *const kCoUIFoldChangedMethod = @"changed";

// The hinge, in the words the Dart half reads (`FoldHingeStatus`).
static NSString *const kCoUIFoldStatusUnavailable = @"unavailable";
static NSString *const kCoUIFoldStatusUnknown = @"unknown";
static NSString *const kCoUIFoldStatusClosed = @"closed";
static NSString *const kCoUIFoldStatusPartiallyOpen = @"partiallyOpen";
static NSString *const kCoUIFoldStatusFullyOpen = @"fullyOpen";

#if COUI_FOLD_HAS_SDK

/// Reads the divisions of the view it fills, during layout.
///
/// UIKit has no notification for reserved regions. It tracks a read made
/// while a view lays out and runs that pass again when a region the view
/// read changes — the same tracking that follows a trait read there. So a
/// view with no content that reads the regions in `layoutSubviews` is told
/// of every change, and one that read them anywhere else is told of none.
///
/// It fills the Flutter view, so the frames it reads are in the Flutter
/// view's coordinates: the logical pixels `MediaQuery` measures in.
API_AVAILABLE(ios(27.1))
@interface CoUIFoldRegionObserver : UIView

/// Called with the divisions after each layout pass.
@property(nonatomic, copy, nullable) void (^onRead)(NSArray<NSDictionary<NSString *, id> *> *divisions);

@end

@implementation CoUIFoldRegionObserver

- (void)layoutSubviews {
  [super layoutSubviews];
  // Inactive regions are asked for too: the fold of a device lying flat is
  // inactive but still where it is, and the Dart half reports its place.
  NSArray<UIViewReservedRegion *> *regions =
      [self reservedRegionsOfKind:[UIViewReservedRegionKind divisionRegionKind]
                          options:UIViewReservedRegionQueryOptionsIncludeInactive];
  NSMutableArray<NSDictionary<NSString *, id> *> *divisions =
      [NSMutableArray arrayWithCapacity:regions.count];
  for (UIViewReservedRegion *region in regions) {
    CGRect frame = region.frame;
    [divisions addObject:@{
      @"left" : @(frame.origin.x),
      @"top" : @(frame.origin.y),
      @"width" : @(frame.size.width),
      @"height" : @(frame.size.height),
      @"active" : @(region.isActive),
    }];
  }
  if (self.onRead != nil) {
    self.onRead(divisions);
  }
}

@end

#endif  // COUI_FOLD_HAS_SDK

@interface CoUIFoldPlugin ()

@property(nonatomic, strong) FlutterMethodChannel *channel;

/// The registrar is asked for the view controller each time: at registration
/// the engine may not have one yet, and an engine can be handed another.
@property(nonatomic, strong, nullable) NSObject<FlutterPluginRegistrar> *registrar;

/// The Flutter view the hinge interaction and the observer are attached to.
@property(nonatomic, weak, nullable) UIView *hostView;

/// The `UIHingeInteraction` on [hostView]. Typed loosely so the property
/// compiles on an SDK without the class.
@property(nonatomic, strong, nullable) id hingeInteraction;

@property(nonatomic, weak, nullable) UIView *regionObserver;

@property(nonatomic, copy) NSString *status;

@property(nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *divisions;

/// The reading Dart was last told, so an unchanged one is not sent again.
@property(nonatomic, copy, nullable) NSDictionary<NSString *, id> *sentReading;

/// Counts hinge updates, so a delayed re-read knows a later update took over.
@property(nonatomic, assign) NSUInteger hingeGeneration;

@end

@implementation CoUIFoldPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  CoUIFoldPlugin *instance = [[CoUIFoldPlugin alloc] init];
  instance.registrar = registrar;
  instance.channel = [FlutterMethodChannel methodChannelWithName:kCoUIFoldChannelName
                                                 binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _status = kCoUIFoldStatusUnavailable;
    _divisions = @[];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (![call.method isEqualToString:kCoUIFoldReadMethod]) {
    result(FlutterMethodNotImplemented);
    return;
  }
  // Asking is also what attaches: Dart asks once it has a view, when the
  // registrar can finally name the view controller.
  [self attachIfNeeded];
  NSDictionary<NSString *, id> *reading = [self reading];
  self.sentReading = reading;
  result(reading);
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [self detach];
  self.registrar = nil;
}

#pragma mark - Reading

- (NSDictionary<NSString *, id> *)reading {
  return @{@"status" : self.status, @"divisions" : self.divisions};
}

/// Tells Dart the reading, unless it is the one Dart already has.
- (void)publish {
  NSDictionary<NSString *, id> *reading = [self reading];
  if ([reading isEqualToDictionary:self.sentReading]) {
    return;
  }
  self.sentReading = reading;
  [self.channel invokeMethod:kCoUIFoldChangedMethod arguments:reading];
}

#pragma mark - Attaching

- (void)attachIfNeeded {
#if COUI_FOLD_HAS_SDK
  if (@available(iOS 27.1, *)) {
    UIView *view = self.registrar.viewController.viewIfLoaded;
    if (view == nil || view == self.hostView) {
      return;
    }
    [self detach];
    [self attachToView:view];
  }
#endif
}

- (void)detach {
  UIView *view = self.hostView;
  id interaction = self.hingeInteraction;
  if (view != nil && interaction != nil) {
    [view removeInteraction:interaction];
  }
  [self.regionObserver removeFromSuperview];
  self.hingeInteraction = nil;
  self.regionObserver = nil;
  self.hostView = nil;
  self.status = kCoUIFoldStatusUnavailable;
  self.divisions = @[];
}

#if COUI_FOLD_HAS_SDK

- (void)attachToView:(UIView *)view API_AVAILABLE(ios(27.1)) {
  __weak typeof(self) weakSelf = self;

  CoUIFoldRegionObserver *observer = [[CoUIFoldRegionObserver alloc] initWithFrame:view.bounds];
  observer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  // It draws nothing, takes no touch and is nothing to read aloud: it is
  // there to be laid out.
  observer.userInteractionEnabled = NO;
  observer.opaque = NO;
  observer.isAccessibilityElement = NO;
  observer.accessibilityElementsHidden = YES;
  observer.onRead = ^(NSArray<NSDictionary<NSString *, id> *> *divisions) {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    strongSelf.divisions = divisions;
    [strongSelf publish];
  };
  // Behind everything Flutter puts in its view.
  [view insertSubview:observer atIndex:0];

  // The handler is called with the hinge as it is and again on every change,
  // and with no hinge on a device that has none.
  UIHingeInteraction *interaction = [[UIHingeInteraction alloc]
      initWithUpdateHandler:^(__unused UIHingeInteraction *_Nonnull hingeInteraction,
                              UIHingeInteractionUpdate *_Nonnull update) {
        [weakSelf hingeDidUpdate:update.hinge];
      }];
  [view addInteraction:interaction];

  self.hostView = view;
  self.regionObserver = observer;
  self.hingeInteraction = interaction;

  // So the first answer already carries the divisions.
  [observer setNeedsLayout];
  [observer layoutIfNeeded];
}

- (void)hingeDidUpdate:(nullable UIHinge *)hinge API_AVAILABLE(ios(27.1)) {
  if (hinge == nil) {
    self.status = kCoUIFoldStatusUnavailable;
  } else {
    switch (hinge.status) {
      case UIHingeStatusClosed:
        self.status = kCoUIFoldStatusClosed;
        break;
      case UIHingeStatusPartiallyOpen:
        self.status = kCoUIFoldStatusPartiallyOpen;
        break;
      case UIHingeStatusFullyOpen:
        self.status = kCoUIFoldStatusFullyOpen;
        break;
      case UIHingeStatusUnknown:
      default:
        self.status = kCoUIFoldStatusUnknown;
        break;
    }
  }
  [self publish];
  [self rereadDivisionsAfterHingeUpdate];
}

/// Reads the divisions again now and a little later.
///
/// A division follows the hinge with a delay: it turns active once the hinge
/// has come to rest partly open, and inactive just after it is laid flat. The
/// tracked layout pass is what reports both; these reads are the net under
/// it, bounded so a hinge at rest costs nothing.
- (void)rereadDivisionsAfterHingeUpdate API_AVAILABLE(ios(27.1)) {
  self.hingeGeneration += 1;
  NSUInteger generation = self.hingeGeneration;
  [self.regionObserver setNeedsLayout];
  __weak typeof(self) weakSelf = self;
  for (NSNumber *delay in @[ @0.35, @1.25, @2.5 ]) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     typeof(self) strongSelf = weakSelf;
                     if (strongSelf == nil || strongSelf.hingeGeneration != generation) {
                       return;
                     }
                     [strongSelf.regionObserver setNeedsLayout];
                   });
  }
}

#endif  // COUI_FOLD_HAS_SDK

@end
