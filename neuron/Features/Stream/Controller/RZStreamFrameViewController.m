/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "RZStreamFrameViewController.h"
#include <Foundation/NSObjCRuntime.h>
#import "StreamLoadingView.h"
#import "RzUtils.h"
#import "RzApp.h"
#import "StreamManager.h"
#include <VideoToolbox/VideoToolbox.h>
#import "ServerInfoResponse.h"
#import "Moonlight-Swift.h"
#import "RzUtils.h"
#import "Connection.h"

typedef enum : NSUInteger {
    Origin = 0,
    Host_Crash,
    Be_Kicked_Off_By_Others,
    User_Cancel
} ErrorFlowType;

@interface RZStreamFrameViewController ()
@property (weak, nonatomic) StreamLoadingView *loadingView;
@property (strong, nonatomic) UIView *loadingViewBg;

// For showing customized toast
@property (strong, nonatomic) UIView *toastContainerView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIImageView *iconView;

@property (strong, nonatomic) UILabel *debugMessageLabel;
@property (strong, nonatomic) UIVisualEffectView *blurView;

// root container to hold ALL views and scale as a whole
@property (strong, nonatomic) UIView *rootContainerView;
@property (assign, nonatomic) CGSize lastScaleSize;
// Track the orientation when the controller was first loaded (kept for reference)
@property (assign, nonatomic) BOOL initialPortrait;

- (void)storePCResolutionWidth:(CGFloat)width height:(CGFloat)height withLogMessage:(NSString *)message;

@end

@implementation RZStreamFrameViewController {
    BOOL _shouldReturnToMainVC;
    BOOL isCancelStreamingRetry;
    NSString *errorCodeRegister;
    long long startStreamingTime;
}
  bool isNeedUpdateDisplayLayer = false;
  bool lastOrientationIsPortrait = false;
  long displayMode = 0;

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialPortrait = NO;
    }
    return self;
}

- (CGSize)nativeScreenSize {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    int width  = (int)screenSize.width;
    int height = (int)screenSize.height;
    NSLog(@"[RZStream][nativeScreenSize] _initialPortrait: %d, streamWidth: %d, streamHeight: %d\n", _initialPortrait, width, height);
    return (CGSize){width, height};
}

// Calculate aspect ratio fit size for given content size within screen bounds
- (CGSize)calculateAspectFitSize:(CGSize)contentSize screenSize:(CGSize)screenSize {
    if (contentSize.width <= 0 || contentSize.height <= 0 || screenSize.width <= 0 || screenSize.height <= 0) {
        return screenSize;
    }

    CGFloat contentAspectRatio = contentSize.width / contentSize.height;
    CGFloat screenAspectRatio = screenSize.width / screenSize.height;
    CGFloat fitWidth, fitHeight;

    if (contentAspectRatio > screenAspectRatio) {
        // Content is wider than screen, fit to width
        fitWidth = screenSize.width;
        fitHeight = screenSize.width / contentAspectRatio;
    } else {
        // Content is taller than screen, fit to height
        fitHeight = screenSize.height;
        fitWidth = screenSize.height * contentAspectRatio;
    }

    NSLog(@"[RZStream][calculateAspectFitSize] contentSize: %@, screenSize: %@, fitSize: %@",
          NSStringFromCGSize(contentSize),
          NSStringFromCGSize(screenSize),
          NSStringFromCGSize(CGSizeMake(fitWidth, fitHeight)));

    return CGSizeMake(fitWidth, fitHeight);
}

// retrieve stream size based on configuration and orientation
- (CGSize)nativeContentSizeForScreenSize:(CGSize)currentScreenSize {
    TemporarySettings *settings = [self valueForKey:@   "_settings"];
    // long displayMode = [[ShareDataDB shared] readFrameSettings].displayMode;
    
    if (displayMode == 0) {   // 0: Duplicate PC Display
        return [self duplicateModeContentSizeForScreenSize:currentScreenSize];
    } else {                  // 1: Seperate Display, 2: Virtual Display (iPhone Optimized)
        return [self optimizedModeContentSizeForScreenSize:currentScreenSize];
    }
}

// iPhone Optimized mode: should fill the whole screen
- (CGSize)optimizedModeContentSizeForScreenSize:(CGSize)currentScreenSize {
    NSLog(@"[RZStream][optimizedMode] iPhone Optimized mode, using full screen size: %f x %f", currentScreenSize.width, currentScreenSize.height);
    return currentScreenSize;  // return the current screen size
}

// Duplicate PC Display mode: should scale the PC display to fit the screen
- (CGSize)duplicateModeContentSizeForScreenSize:(CGSize)currentScreenSize {
    TemporarySettings *settings = [self valueForKey:@"_settings"];
    int streamWidth = [settings.hostWidth intValue];
    int streamHeight = [settings.hostHeight intValue];
    
    // calculate the aspect fit size
    CGSize adjustedSize = [self calculateAspectFitSize:CGSizeMake(streamWidth, streamHeight) screenSize:currentScreenSize];
    NSLog(@"[RZStream][duplicateMode] Duplicate PC Display mode, host x %d y: %d, adjustedSize: %f x %f", streamWidth, streamHeight);
    return adjustedSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lastScaleSize = CGSizeZero;
    self.initialPortrait = [RzUtils isPortrait];
    lastOrientationIsPortrait = self.initialPortrait;
    displayMode = [[ShareDataDB shared] readFrameSettings].displayMode;
    NSLog(@"[RZStream] Initial orientation: %s\n", self.initialPortrait ? "Portrait" : "Landscape");

    // Remove parent class default subviews to avoid resize inconsistencies
    [self removeBaseSubviews];
    // add all view to root container
    [self setupUI];
    [self layoutStreamViews];

    errorCodeRegister = @"";
    
    //recode start streaming event
    NSString *gameName = ShareDataDB.shared.currentLaunchGame.name ?: @"Desktop";
    TemporarySettings *_settings = [self valueForKey:@"_settings"];
    int32_t newWidth = [_settings.width intValue];
    int32_t newHeight = [_settings.height intValue];
    if(_initialPortrait) {
        newWidth = [_settings.height intValue];
        newHeight = [_settings.width intValue];
    }
    NSDictionary *dimension = @{@"pc_app_name": gameName,
                                @"neuron_app_version": [RzUtils getAppVersion],
                                @"display_mode": _settings.displayMode==0 ? @"Duplicate PC Display" : @"iPhone Optimized",
                                @"negotiated_res": [NSString stringWithFormat:@"%@x%@", @(newWidth), @(newHeight)],
                                @"refresh_rate": [NSString stringWithFormat:@"%@", _settings.framerate]};
    NeuronEvent *event = [NeuronEvent createEventWithEventAction:@"neuron_stream_started" eventLabel:gameName dimension:dimension];
    [[ShareDataDB shared] writeNeuronEvent:event];
    startStreamingTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(applicationWillResignActive:)
//                                                 name:UIApplicationWillResignActiveNotification
//                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_shouldReturnToMainVC) {
        [self returnToMainFrameWithNoAnimation];
        _shouldReturnToMainVC = false;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSString *gameName = ShareDataDB.shared.currentLaunchGame.name ?: @"Desktop";
    long long durationMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000)-startStreamingTime;
    TemporarySettings *_settings = [self valueForKey:@"_settings"];
    int32_t newWidth = [_settings.width intValue];
    int32_t newHeight = [_settings.height intValue];
    if(_initialPortrait) {
        newWidth = [_settings.height intValue];
        newHeight = [_settings.width intValue];
    }
    NSDictionary *dimension = @{ @"pc_app_name": gameName,
                                 @"neuron_app_version": [RzUtils getAppVersion],
                                 @"display_mode": _settings.displayMode==0 ? @"Duplicate PC Display" : @"iPhone Optimized",
                                 @"negotiated_res": [NSString stringWithFormat:@"%@x%@", @(newHeight), @(newWidth)],
                                 @"refresh_rate": [NSString stringWithFormat:@"%@", _settings.framerate],
                                 @"total_duration_ms": [NSString stringWithFormat:@"%lld", durationMs]};
    NeuronEvent *event = [NeuronEvent createEventWithEventAction:@"neuron_stream_ended" eventLabel:gameName dimension:dimension];
    [[ShareDataDB shared] writeNeuronEvent:event];
    
    [[ShareDataDB shared] resetCurrentLaunchGameData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"[RZStream] viewDidAppear: bounds %fx%f\n", self.view.bounds.size.width, self.view.bounds.size.height);
    [self updateViewScale:self.view.bounds.size];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    SettingsMenuVC *mainVC = [[RzApp shared] getSettingsMenuVC];
    SettingsRouter.shared.startingStream = false;
    [mainVC handelReset];
    //can return some error message here
    if (_shouldReturnToNexus) {
        NSURL *url = [NSURL URLWithString:@"Nexus://"];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    //this controller will automatically disappear after streaming ends
    if ([errorCodeRegister  isEqual: @""]) {
        //Means Streaming is end in normal case. (No error code)
        [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:true];
        [[AppStoreReviewHandler shared] endGameStreaming];
    }
    isCancelStreamingRetry = true;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutStreamViews];                       // config layout again
    NSLog(@"[RZStream] viewDidLayoutSubviews: bounds %fx%f\n", self.view.bounds.size.width, self.view.bounds.size.height);
    [self updateViewScale:self.view.bounds.size];   // make sure view scale according to latest bounds
}

// Animate scale together with rotation/resize
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"[RZStream] viewWillTransitionToSize: new size %fx%f\n", size.width, size.height);
    [self checkNeedDisplayLayerUpdate:size];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateViewScale:size];
        // Update video renderer display layer when orientation changes in 
        // duplicate portrait<->landscape mode for preventing incorrect stream content display size
        if (isNeedUpdateDisplayLayer) {
            VideoDecoderRenderer *renderer = [Connection getCurrentRenderer];
            if (renderer) {
                NSLog(@"[RZStream] Updating video decoder renderer display layer for orientation change");
                [renderer updateDisplayLayer];
                isNeedUpdateDisplayLayer = false;
            }
    }

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateViewScale:size];
    }];
}

// set update flag since video renderer display layout only need to be updated when orientation changed
- (void)checkNeedDisplayLayerUpdate:(CGSize)size {
    if ([RzUtils isPortrait] != lastOrientationIsPortrait){
        lastOrientationIsPortrait = [RzUtils isPortrait];
        isNeedUpdateDisplayLayer = true;
        return;
    }
}

// Calculate root container screen size based on initial orientation and display mode for better display when orientation changes
- (CGSize)calculateRootContainerViewSize {
    CGSize nativeScreenSize = UIScreen.mainScreen.bounds.size;
    CGFloat shortSide = MIN(nativeScreenSize.width, nativeScreenSize.height);
    CGFloat longSide = MAX(nativeScreenSize.width, nativeScreenSize.height);
    
    if (_initialPortrait && displayMode == 0) {  // Duplicate PC Display mode and initial portrait
        // For initial portrait in duplicate mode, use current orientation
        if (nativeScreenSize.width > nativeScreenSize.height) {
            return CGSizeMake(longSide, shortSide); // landscape
        } else {
            return CGSizeMake(shortSide, longSide); // portrait
        }
    } else {                                    // iPhone Optimized mode or initial landscape in duplicate mode
        if (_initialPortrait) {
            return CGSizeMake(shortSide, longSide);
        } else {
            return CGSizeMake(longSide, shortSide);
        }
    }
}

- (void)storePCResolutionWidth:(CGFloat)width height:(CGFloat)height withLogMessage:(NSString *)message {
    [[NSUserDefaults standardUserDefaults] setFloat:width forKey:@"RZStreamPCWidth"];
    [[NSUserDefaults standardUserDefaults] setFloat:height forKey:@"RZStreamPCHeight"];
    NSLog(@"[RZStream] %@", message);
}

- (void)updateViewScale:(CGSize)size {
    self.lastScaleSize = size;

    CGSize screenSize = [self calculateRootContainerViewSize];
    CGFloat screenW = screenSize.width;
    CGFloat screenH = screenSize.height;

    const CGFloat winW = size.width;
    const CGFloat winH = size.height;

    // set no transform to avoid incorrect layout
    self->_rootContainerView.transform = CGAffineTransformIdentity;
    
    // Set rootContainerView frame
    self->_rootContainerView.frame = (CGRect){ .origin = CGPointZero, .size = screenSize };
    

    CGFloat scaleX = winW / self->_rootContainerView.frame.size.width;
    CGFloat scaleY = winH / self->_rootContainerView.frame.size.height;
    // Log the screen size
    NSString *orientation = [RzUtils isPortrait] ? @"portrait" : @"landscape";
    NSLog(@"[RZStream] updateViewScale: initialPortrait=%d, displayMode=%ld, screenW=%f, screenH=%f, winW=%f, winH=%f, RootContainerW=%f, RootContainerH=%f, scaleX=%f, scaleY=%f\n", _initialPortrait, displayMode, screenW, screenH, winW, winH, self->_rootContainerView.frame.size.width, self->_rootContainerView.frame.size.height, scaleX, scaleY);

    // scale & center
    CGFloat scale = MIN(scaleX, scaleY);
    self->_rootContainerView.transform = CGAffineTransformMakeScale(scale, scale);
    self->_rootContainerView.center = CGPointMake(winW / 2.0, winH / 2.0);
    
    // Store PC resolution for accurate touch coordinate mapping
    TemporarySettings *settings = [self valueForKey:@"_settings"];
    if (displayMode == 0) {   // Duplicate PC Display mode
        [self storePCResolutionWidth:[settings.hostWidth floatValue] height:[settings.hostHeight floatValue] withLogMessage:[NSString stringWithFormat:@"Stored PC resolution: %.0fx%.0f", [settings.hostWidth floatValue], [settings.hostHeight floatValue]]];
    } else {
        // For other modes, check if it's resolutionSafeArea case
        NeuronFrameSettings *frameSettings = [[ShareDataDB shared] readFrameSettings];
        CGFloat negotiatedWidth = [settings.width floatValue];
        CGFloat negotiatedHeight = [settings.height floatValue];

        // Check if this is safearea enabled mode case
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }

        if (window) {
            CGFloat screenScale = window.screen.scale;
            CGFloat leftArea = window.safeAreaInsets.left;
            CGFloat rightArea = window.safeAreaInsets.right;
            CGFloat safeAreaWidth = (window.frame.size.width - leftArea - rightArea) * screenScale;
            CGFloat fullWidth = window.frame.size.width * screenScale;
            CGFloat fullHeight = window.frame.size.height * screenScale;

            // If negotiated width matches safe area width, it's safe area mode
            if (fabs(negotiatedWidth - safeAreaWidth) < 1.0 && fabs(negotiatedHeight - fullHeight) < 1.0) {
                // This is safe area mode - use safe area width
                [self storePCResolutionWidth:safeAreaWidth height:fullHeight withLogMessage:[NSString stringWithFormat:@"Stored safe area resolution: %.0fx%.0f", safeAreaWidth, fullHeight]];
            } else {
                // other case like resolutionFull, custom, etc..
                [self storePCResolutionWidth:negotiatedWidth height:negotiatedHeight withLogMessage:[NSString stringWithFormat:@"Stored negotiated resolution: %.0fx%.0f", negotiatedWidth, negotiatedHeight]];
            }
        } else {
            // Fallback to negotiated resolution if window not available
            [self storePCResolutionWidth:negotiatedWidth height:negotiatedHeight withLogMessage:[NSString stringWithFormat:@"Stored negotiated resolution (fallback): %.0fx%.0f", negotiatedWidth, negotiatedHeight]];
        }
    }

    // keep subviews keep original size
    UIScrollView *rzScroll = [self valueForKey:@"_scrollView"];
    UIView *rzStream = [self valueForKey:@"_streamView"];
    CGSize streamSize = [self nativeContentSizeForScreenSize:CGSizeMake(screenW, screenH)];
    
    const CGFloat streamW = streamSize.width;
    const CGFloat streamH = streamSize.height;
    
    const CGFloat startPositionX = (screenW - streamW) / 2.0;
    const CGFloat startPositionY = (screenH - streamH) / 2.0;
    
    NSLog(@"[RZStream] updateViewScale frame: winW %f , winH %f , screenW: %f , screenH %f streamSize : %f x %f\n", winW, winH, screenW, screenH, streamW, streamH);
    NSLog(@"[RZStream] calculated position: startPositionX %f , startPositionY %f\n", startPositionX, startPositionY);
    
    if (rzScroll) {
        rzScroll.transform = CGAffineTransformIdentity;
        rzScroll.frame = (CGRect){ .origin = CGPointZero, .size = (CGSize){screenW, screenH} };
        rzScroll.minimumZoomScale = 1.0;
        rzScroll.maximumZoomScale = 1.0;
        rzScroll.zoomScale = 1.0;
        rzScroll.contentOffset = CGPointZero;
        rzScroll.contentInset = UIEdgeInsetsZero;
        rzScroll.contentSize = (CGSize){streamW, streamH};
        if (@available(iOS 11.0, *)) {
            rzScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    
    if (rzStream) {
        rzStream.transform = CGAffineTransformIdentity;
        rzStream.frame = (CGRect){ .origin = CGPointMake(startPositionX, startPositionY), .size = (CGSize){streamW, streamH} };
    }
    if (self->_blurView) {
        self->_blurView.transform = CGAffineTransformIdentity;
        self->_blurView.frame = (CGRect){ .origin = CGPointZero, .size = (CGSize){screenW, screenH} };
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden { 
    return true; 
}

- (void)stageStarting:(const char *)stageName {
    Log(LOG_I, @"Neuron Starting %s", stageName);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* stageString = [NSString stringWithFormat:@"%s in progress",stageName];
        NSString* lowerCase = [NSString stringWithFormat:@"%@…",Localized(stageString)];
        NSString* titleCase = [[[lowerCase substringToIndex:1] uppercaseString] stringByAppendingString:[lowerCase substringFromIndex:1]];
        [self.loadingView updateLoadingState:titleCase];
    });
}

- (void)connectionStarted {
    [super connectionStarted];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self->_blurView) {
            [self->_blurView removeFromSuperview];
            self->_blurView = nil;
        }
        
        [[AppStoreReviewHandler shared] startGameStreaming];

        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                self.loadingViewBg.alpha = 0.0;
                self.loadingView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.loadingViewBg.hidden = YES;
                self.loadingView.hidden = YES;
                [self.loadingView streamAppImageStopAnimation];
            }];
        });
    });
    
}

- (void) launchFailed:(NSString*)message errorCode:(NSInteger)code {
    Log(LOG_I, @"Launch failed: %@ code: %d", message, code);
    
    switch (code) {
        case 5031:
            message = Localized(@"conn_error_code_5031");
            break;
        case 5032:
            message = Localized(@"conn_error_code_5032");
            break;
        case 5033:
            message = Localized(@"conn_error_code_5033");
            break;
        case 5034:
            message = Localized(@"conn_error_code_5034");
            break;
        case 5037:
            message = Localized(@"conn_error_code_5037");
            break;
        case 5038:
            message = Localized(@"conn_error_code_5038");
            break;
        case 5039:
            message = Localized(@"conn_error_code_5039");
            break;
        case 5040:
            message = Localized(@"conn_error_code_5040");
            break;
        default:
            break;
    }
    
    BOOL shouldShowRetryAlert = !_haveRetry;
    if (shouldShowRetryAlert && code != 5032) {
        [self showRetryAlert:message];
    } else {
        [self showHelpAlert:message errorCode:code];
    }
}

- (void)launchFailed:(NSString *)currentApp device:(NSString *)currentDevice errorCode:(NSInteger)code isSameDevice:(BOOL)isSameDevice completion:(LaunchOptionCompletion)Completion {
    Log(LOG_I, @"Launch failed: %d app:%@ device:%@", code, currentApp, currentDevice);
    if (code == 5036) {
        NSString *message = Localized(@"&app is already streaming on &device, would you like to replace the current session or quit? All unsaved data will be lost.");
        if (currentApp != nil) {
            message = [message stringByReplacingOccurrencesOfString:@"&app" withString:currentApp];
        }
        if (currentDevice != nil) {
            message = [message stringByReplacingOccurrencesOfString:@"&device" withString:currentDevice];
        }
        NSString *title = Localized(@"Streaming session in progress");
        [self showReplaceAlert:message title:title compltion:Completion];
    }
}

- (void)showHelpAlert:(NSString *)message errorCode:(NSInteger)code {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:Localized(@"Connection Error")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        if(code == 5032) {
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Help") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                self->_shouldReturnToNexus = false;
                self->_shouldReturnToMainVC = true;
                WebVC *webVC = [[WebVC alloc] init];
                webVC.url = [NSURL URLWithString:FAQUrl];
                webVC.webViewTitle = NSLocalizedString(@"Connection Error", nil);
                [[SettingsRouter shared].navigationController pushViewController:webVC animated:YES];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                [self returnToMainFrame];
            }]];
        } else {
            [Utils addHelpOptionToDialog:alert];
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                [self returnToMainFrame];
            }]];
        }
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showReplaceAlert:(NSString *)message title:(NSString *)title compltion:(LaunchOptionCompletion)compltion {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            if (compltion) compltion(0);
            [self returnToMainFrame];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Replace") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            if (compltion) compltion(1);
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}


- (void)showRetryAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:Localized(@"Connection Error")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [self returnToMainFrame];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Retry") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            self.shouldReturnToNexus = NO;
            [self restartStreaming];
//            [self returnToMainFrame];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self postRetryNotification];
//            });
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showSessionIsTokenAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:Localized(@"Connection Error")
                                                                       message:Localized(@"Please ensure the Cortex host is running and that no other device is connected to it.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [self returnToMainFrame];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)postRetryNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRetryStreamingNotification object:nil];
}

- (void) returnToMainFrameWithNoAnimation {
    // Reset display mode back to default
    [self updatePreferredDisplayMode:NO];
    
    NSTimer *_statsUpdateTimer = [self valueForKey:@"_statsUpdateTimer"];
    [_statsUpdateTimer invalidate];
    [self setValue:nil forKey:@"_statsUpdateTimer"];
    
    [self.navigationController popToRootViewControllerAnimated:false];
}

- (void)updateOverlayText: (NSString*) text {
    if (text == nil || text.length == 0) {
        return;
    }
    if ([text hasPrefix:@"Video stream:"]) {
        if(!_debugMessageLabel) {
            _debugMessageLabel = [[UILabel alloc] init];
            _debugMessageLabel.font = [UIFont systemFontOfSize:13];
            _debugMessageLabel.numberOfLines = 0;
            _debugMessageLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent: 0.8];
            _debugMessageLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
            [self.rootContainerView addSubview:_debugMessageLabel];
        }
//        _debugMessageLabel.text = text;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 4;

        NSDictionary *attributes = @{
            NSFontAttributeName: _debugMessageLabel.font,
            NSParagraphStyleAttributeName: paragraphStyle
        };

        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        _debugMessageLabel.attributedText = attributedText;

        CGFloat maxWidth = 500.0;
        CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);

        CGSize requiredSize = [_debugMessageLabel sizeThatFits:maxSize];
        _debugMessageLabel.frame = CGRectMake(50, 10, requiredSize.width, requiredSize.height);
    } else {
        [self showToast: text];
    }
}

- (void)showToast: (NSString*) text {
    if(self.textView) {
        [self.textView removeFromSuperview];
        self.textView = nil;
    }
    
    if(self.iconView) {
        [self.iconView removeFromSuperview];
        self.iconView = nil;
    }
    
    if(self.toastContainerView) {
        [self.toastContainerView removeFromSuperview];
        self.toastContainerView = nil;
    }
    
    // Create and configure the UITextView
    self.textView = [[UITextView alloc] init];
    self.textView.text = text;
    self.textView.backgroundColor = [UIColor clearColor]; // Transparent background for container view background visibility
    self.textView.alpha = 1.0; // Visible text view
    self.textView.textColor = [UIColor blackColor];
    self.textView.editable = NO;
    self.textView.scrollEnabled = NO;
    [self.textView setFont:[UIFont systemFontOfSize:14]];

    // Calculate the size that best fits the content
    CGSize textSize = [self.textView sizeThatFits:CGSizeMake(CGFLOAT_MAX, FLT_MAX)];

    // Create and configure the UIImageView for the icon
    UIImage *iconImage = [UIImage imageNamed:@"alert_fill"]; // Replace with your icon image name
    self.iconView = [[UIImageView alloc] initWithImage:iconImage];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat iconSize = 30; // Define the icon size
    self.iconView.frame = CGRectMake(0, 0, iconSize, iconSize);

    // Create and configure the container UIView
    CGFloat containerPadding = 10;
    self.toastContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textSize.width + iconSize + containerPadding * 2, textSize.height + containerPadding)];
    self.toastContainerView.backgroundColor = [UIColor whiteColor];
    self.toastContainerView.layer.cornerRadius = 3;
    self.toastContainerView.layer.masksToBounds = YES;

    // Set frames for textView and iconView within the container
    self.textView.frame = CGRectMake(containerPadding, containerPadding / 2, textSize.width, textSize.height);
    self.iconView.frame = CGRectMake(CGRectGetMaxX(self.textView.frame), (self.toastContainerView.frame.size.height - iconSize) / 2, iconSize, iconSize);

    // Add the textView and iconView to the container
    [self.toastContainerView addSubview:self.textView];
    [self.toastContainerView addSubview:self.iconView];

    // Center the containerView at the bottom of the screen
    self.toastContainerView.center = CGPointMake(self.rootContainerView.bounds.size.width / 2, self.rootContainerView.bounds.size.height - self.toastContainerView.frame.size.height / 2 - 50);
    [self.rootContainerView addSubview:self.toastContainerView];

    self.toastContainerView.alpha = 0.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.toastContainerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        // After 3 seconds, hide the container view with animation
        [self performSelector:@selector(hideToast) withObject:nil afterDelay:2.6];
    }];
}

- (void)hideToast {
    [UIView animateWithDuration:1.0 animations:^{
        self.toastContainerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.toastContainerView removeFromSuperview];
        self.toastContainerView = nil;
    }];
}

//- (void)applicationWillResignActive:(NSNotification *)notification {
//    [self returnToMainFrame];
//}
- (void) dealloc {
    NSLog(@"RZStreamFrameViewController deallocated");
}

- (void)updateStatsOverlay {
    StreamManager *_streamMan = [self valueForKey:@"_streamMan"];
    NSString* overlayText = [_streamMan getStatsOverlayText];
    
    if([overlayText hasPrefix:@"Video stream:"]) {
        TemporarySettings *_settings = [self valueForKey:@"_settings"];
        overlayText = [overlayText stringByAppendingString: [NSString stringWithFormat:@"\nmode:%@x%@x%@",_settings.width,_settings.height,_settings.framerate]];
    }
    
    //host support codec
    NSString *hostSupportedCodec = [[NSUserDefaults standardUserDefaults] stringForKey:@"CurrentHostSupportedCodec"];
    overlayText = [overlayText stringByAppendingString:[NSString stringWithFormat:@"\nhost supported codec:%@ \n", hostSupportedCodec]];
    //client support codec
    NSString *clientSupportedCodec = [NSString string];
    
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
    if (VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)) {
        clientSupportedCodec = [clientSupportedCodec stringByAppendingString:@"--AV1"];
    }
#endif
    
    if (VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
        clientSupportedCodec = [clientSupportedCodec stringByAppendingString:@"--HEVC"];
    }
    
    clientSupportedCodec = [clientSupportedCodec stringByAppendingString:@"--H264"];
    
    overlayText = [overlayText stringByAppendingString:[NSString stringWithFormat:@"client supported codec:%@ \n", clientSupportedCodec]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateOverlayText:overlayText];
    });
}

- (void)connectionTerminated:(int)errorCode {
    errorCodeRegister = [NSString stringWithFormat:@"%d",errorCode];
    if (errorCode == -1){
        //0:origin flow 1:be kicked off by others 2:host crash
        ErrorFlowType flowType = Origin;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            
            if(!self->_blurView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
                self->_blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                
                self->_blurView.frame = self.view.bounds;
                self->_blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                
                StreamLoadingView *reconnectView = (StreamLoadingView *) [[NSBundle mainBundle] loadNibNamed:@"StreamLoadingView" owner:self options:nil].firstObject;
                reconnectView.frame = self.view.bounds;
                [reconnectView setAsReconnectingStyle];
                [self->_blurView.contentView addSubview:reconnectView];
            }
            [self.rootContainerView addSubview:self->_blurView];
        });
        StreamManager *_streamMan = [self valueForKey:@"_streamMan"];
        [_streamMan stopStream];
        
        [self checkHostStatus:&flowType];
        
        switch (flowType) {
            case Host_Crash:
            {
                //to Fix BIA-1712
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:false];
                    [self restartStreaming];
                });
                break;
            }
            case Be_Kicked_Off_By_Others:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showSessionIsTokenAlert];
                    [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:true];
                    [[AppStoreReviewHandler shared] endGameStreaming];
                });
                break;
            }
            case User_Cancel:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:true];
                    [self returnToMainFrame];
                });
                break;
            }
            default:
            {
                [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:false];
                [super connectionTerminated:errorCode];
                break;
            }
        }
    } else {
        if (errorCode == ML_ERROR_GRACEFUL_TERMINATION) {
            [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:true];
            [[AppStoreReviewHandler shared] endGameStreaming];
        }else{
            [[AppStoreReviewHandler shared] markNormalFinishStreamingWithNormal:false];
        }
        [super connectionTerminated:errorCode];
    }
    SettingsRouter.shared.startingStream = false;
}

- (void)cancelRetry {
    [self returnToMainFrame];
    NSLog(@"RZStreamFrameViewController connectionTerminated Stop Retry");
    isCancelStreamingRetry = true;
}

- (void)restartStreaming {
    NSLog(@"RZStreamFrameViewController connectionTerminated restartStreaming");
    
    StreamView *_streamView = [self valueForKey:@"_streamView"];
    StreamManager *streamMan = [[StreamManager alloc] initWithConfig:self.streamConfig
                                            renderView:_streamView
                                   connectionCallbacks:self];
    
    [self setValue:streamMan forKey:@"_streamMan"];
    
    NSOperationQueue* opQueue = [[NSOperationQueue alloc] init];
    [opQueue addOperation:streamMan];
    errorCodeRegister = @"";
}

- (void)checkHostStatus:(ErrorFlowType *)flowType {
    NSDate *startTime = [NSDate date];
    NSTimeInterval maxDuration = 30;
    NSTimeInterval interval = 1;
    
    HttpManager* hMan = [[HttpManager alloc] initWithHost:RzUtils.currentStreamingHost];
    ServerInfoResponse* serverInfoResp = [[ServerInfoResponse alloc] init];
    
    while ([[NSDate date] timeIntervalSinceDate:startTime] < maxDuration) {
        if (isCancelStreamingRetry) {
            isCancelStreamingRetry = false;
            *flowType = User_Cancel;
            return;
        }
        [hMan executeRequestSynchronously:[HttpRequest requestForResponse:serverInfoResp withUrlRequest:[hMan newServerInfoRequest:false]
                                           fallbackError:401 fallbackRequest:[hMan newHttpServerInfoRequest]]];
        if(serverInfoResp.isStatusOk) {
            
            NSString *hostVersion = [serverInfoResp getStringTag:@"hostversion"];
            NSString* currentDevice = [serverInfoResp getStringTag:@"currentdevice"];
            
            //host crash
            if ([self isSupportAutoRestart:hostVersion] && currentDevice == nil) {
                *flowType = Host_Crash;
                return;
            }
            
            //session was taken over
            if (currentDevice != nil && ![currentDevice isEqualToString:[RzUtils deviceName]]) {
                *flowType = Be_Kicked_Off_By_Others;
                return;
            }
            
            return;
        } else {
            [NSThread sleepForTimeInterval:interval];
        }
    }
    
}

//public var firmware_MajorVersion: Int
//public var firmware_MinorVersion: Int
//public var firmware_InternalVersion: Int
//public var firmware_RevisionVersion: Int
- (BOOL)isSupportAutoRestart:(NSString *)hostversion {
    NSArray *versions = [hostversion componentsSeparatedByString:@"."];
    if (versions.count < 2) return NO;
    NSInteger major = [versions[0] integerValue];
    NSInteger minor = [versions[1] integerValue];
    return major > 1 || (major == 1  &&  minor >= 1);
}

//- (BOOL)isAntherDeviceStreaming:(NSString *)deviceName current

- (void)removeBaseSubviews {
    UILabel *baseStageLabel = [self valueForKey:@"_stageLabel"];
    if (baseStageLabel) [baseStageLabel removeFromSuperview];
    UIActivityIndicatorView *baseSpinner = [self valueForKey:@"_spinner"];
    if (baseSpinner) [baseSpinner removeFromSuperview];
    UILabel *baseTipLabel = [self valueForKey:@"_tipLabel"];
    if (baseTipLabel) [baseTipLabel removeFromSuperview];
    UITextView *baseOverlay = [self valueForKey:@"_overlayView"];
    if (baseOverlay) [baseOverlay removeFromSuperview];
}

- (void)pinViewToSuperviewEdges:(UIView *)view superview:(UIView *)superview {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [view.leadingAnchor constraintEqualToAnchor:superview.leadingAnchor],
        [view.trailingAnchor constraintEqualToAnchor:superview.trailingAnchor],
        [view.topAnchor constraintEqualToAnchor:superview.topAnchor],
        [view.bottomAnchor constraintEqualToAnchor:superview.bottomAnchor],
    ]];
}

- (void)setupUI {
    // Set the main view's background color to black so that areas outside rootContainerView are black
    self.view.backgroundColor = [UIColor blackColor];
    // root container: for scaling & centering on iPad properly, we need to add or move all views into this container
    _rootContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    _rootContainerView.autoresizingMask = UIViewAutoresizingNone;
    _rootContainerView.userInteractionEnabled = YES;
    [self.view addSubview:_rootContainerView];

    // Setup _blurView for overlay usage (hidden by default)
    if (!_blurView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.translatesAutoresizingMaskIntoConstraints = NO;
        _blurView.hidden = NO;
        [_rootContainerView addSubview:_blurView];
        // Pin _blurView to all edges of rootContainerView
        [NSLayoutConstraint activateConstraints:@[
            [_blurView.leadingAnchor constraintEqualToAnchor:_rootContainerView.leadingAnchor],
            [_blurView.trailingAnchor constraintEqualToAnchor:_rootContainerView.trailingAnchor],
            [_blurView.topAnchor constraintEqualToAnchor:_rootContainerView.topAnchor],
            [_blurView.bottomAnchor constraintEqualToAnchor:_rootContainerView.bottomAnchor],
        ]];
    }

    // 1.add loading and loadingBg view into rootContainerView and remove constraints
    _loadingView = (StreamLoadingView *)[[NSBundle mainBundle] loadNibNamed:@"StreamLoadingView" owner:self options:nil].firstObject;
    // 确保关闭autoresizing masks转换为约束的功能,否则缩放会有问题
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [_rootContainerView addSubview:_loadingView];
    [self pinViewToSuperviewEdges:_loadingView superview:_rootContainerView];

    _loadingViewBg = [[UIView alloc] init];
    _loadingViewBg.backgroundColor = [UIColor colorWithRed:68/255.0 green:214/255.0 blue:44/255.0 alpha:1.0];
    _loadingViewBg.translatesAutoresizingMaskIntoConstraints = NO;
    [_rootContainerView insertSubview:_loadingViewBg atIndex:0];
    [self pinViewToSuperviewEdges:_loadingViewBg superview:_rootContainerView];

    // 2.move scroll and stream view into rootContainerView
    UIScrollView *rzScroll = [self valueForKey:@"_scrollView"];
    UIView *rzStream = [self valueForKey:@"_streamView"];
    if (rzScroll && rzScroll.superview != _rootContainerView) {
        [rzScroll removeFromSuperview];
        [_rootContainerView addSubview:rzScroll];
    }
    if (rzStream && rzStream.superview != (rzScroll ?: _rootContainerView)) {
        [rzStream removeFromSuperview];
        [(rzScroll ?: _rootContainerView) addSubview:rzStream];
    }

    // keep rzScroll zoom scale to 1 to prevent unexpected zooming
    if (rzScroll) {
        rzScroll.minimumZoomScale = 1.0;
        rzScroll.maximumZoomScale = 1.0;
        rzScroll.zoomScale = 1.0;
        rzScroll.bouncesZoom = NO;
        if (@available(iOS 11.0, *)) {
            rzScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
}

- (void)layoutStreamViews {
    UIScrollView *rzScroll = [self valueForKey:@"_scrollView"];
    UIView *rzStream = [self valueForKey:@"_streamView"];

    // Get current screen size based on initial orientation
    CGSize nativeScreenSize = UIScreen.mainScreen.bounds.size;
    CGFloat shortSide = MIN(nativeScreenSize.width, nativeScreenSize.height);
    CGFloat longSide  = MAX(nativeScreenSize.width, nativeScreenSize.height);
    CGSize currentScreenSize;
    if (_initialPortrait) {
        currentScreenSize = CGSizeMake(shortSide, longSide);
    } else {
        currentScreenSize = CGSizeMake(longSide, shortSide);
    }
    
    CGSize native = [self nativeContentSizeForScreenSize:currentScreenSize];
    NSLog(@"[RZStream] layoutStreamViews orientation: %@, update native size to %@",
          [RzUtils isPortrait] ? @"Portrait" : @"Landscape",
          NSStringFromCGSize(native));

    if (rzScroll) {
        rzScroll.translatesAutoresizingMaskIntoConstraints = YES;
        rzScroll.autoresizingMask = UIViewAutoresizingNone;
        rzScroll.transform = CGAffineTransformIdentity;
        rzScroll.frame = (CGRect){.origin = CGPointZero, .size = native};
        rzScroll.contentOffset = CGPointZero;
        rzScroll.contentInset = UIEdgeInsetsZero;
        rzScroll.contentSize = native;
        rzScroll.clipsToBounds = YES;
        rzScroll.backgroundColor = UIColor.clearColor;
    }

    if (rzStream) {
        // UIView *targetSuper = rzScroll ?: self->_rootContainerView;
        rzStream.translatesAutoresizingMaskIntoConstraints = YES;
        rzStream.autoresizingMask = UIViewAutoresizingNone;
        rzStream.transform = CGAffineTransformIdentity;
        rzStream.frame = (CGRect){.origin = CGPointZero, .size = native};
        NSLog(@"[RZStream] layoutStreamViews rzStream frame: width %f , height %f", rzStream.frame.size.width, rzStream.frame.size.height);
        rzStream.clipsToBounds = YES;
        rzStream.backgroundColor = UIColor.blackColor;
    }

    if (self.loadingView) {
        [self->_rootContainerView bringSubviewToFront:self.loadingView];
    }
}
@end
