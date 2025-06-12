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
#import "StreamLoadingView.h"
#import "RzUtils.h"
#import "RzApp.h"
#import "StreamManager.h"
#include <VideoToolbox/VideoToolbox.h>
#import "ServerInfoResponse.h"
#import "Moonlight-Swift.h"

typedef enum : NSUInteger {
    Origin = 0,
    Host_Crash,
    Be_Kicked_Off_By_Others,
    User_Cancel
} ErrorFlowType;

@interface RZStreamFrameViewController ()
@property (weak, nonatomic) StreamLoadingView *loadingView;

// For showing customized toast
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIImageView *iconView;

@property (strong, nonatomic) UILabel *debugMessageLabel;

@property (strong, nonatomic) UIVisualEffectView *blurView;
@end

@implementation RZStreamFrameViewController {
    BOOL _shouldReturnToMainVC;
    BOOL isCancelStreamingRetry;
    NSString *errorCodeRegister;
    long long startStreamingTime;
}

@class AppStoreReviewHandler;

- (void)viewDidLoad {
    [super viewDidLoad];
    _loadingView = (StreamLoadingView *) [[NSBundle mainBundle] loadNibNamed:@"StreamLoadingView" owner:self options:nil].firstObject;
    _loadingView.frame = [[UIScreen mainScreen] bounds];
    [self.view addSubview:self.loadingView];
//    _shouldReturnToNexus = YES;
    
    //BIA-1387, remove streaming view zoom action
    UIScrollView *scrollView = [self valueForKey:@"_scrollView"];
    if (scrollView) {
        NSLog(@"Accessed _scrollView during initialization");
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 1.0;
    }

    errorCodeRegister = @"";
    
    //recode start streaming event
    TemporarySettings *_settings = [self valueForKey:@"_settings"];
    NSDictionary *dimension = @{ @"neuron_app_version ": [RzUtils getAppVersion],
                                 @"display_mode": _settings.displayMode==0 ? @"Duplicate PC Display" : @"iPhone Optimized",
                                 @"negotiated_res": [NSString stringWithFormat:@"%@x%@", _settings.width, _settings.height] ,
                                 @"refresh_rate": [NSString stringWithFormat:@"%@", _settings.framerate] };
    NSString *gameName = ShareDataDB.shared.currentLaunchGame.name ?: @"Desktop";
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
    
    long long durationMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000)-startStreamingTime;
    TemporarySettings *_settings = [self valueForKey:@"_settings"];
    NSDictionary *dimension = @{ @"neuron_app_version ": [RzUtils getAppVersion],
                                 @"display_mode": _settings.displayMode==0 ? @"Duplicate PC Display" : @"iPhone Optimized",
                                 @"negotiated_res": [NSString stringWithFormat:@"%@x%@", _settings.height, _settings.width] ,
                                 @"refresh_rate": [NSString stringWithFormat:@"%@", _settings.framerate],
                                 @"total_duration_ms": [NSString stringWithFormat:@"%lld", durationMs]};
    NSString *gameName = ShareDataDB.shared.currentLaunchGame.name ?: @"Desktop";
    NeuronEvent *event = [NeuronEvent createEventWithEventAction:@"neuron_stream_ended" eventLabel:gameName dimension:dimension];
    [[ShareDataDB shared] writeNeuronEvent:event];
    
    [[ShareDataDB shared] resetCurrentLaunchGameData];
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
                self.loadingView.alpha = 0.0;
            } completion:^(BOOL finished) {
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
        if (isSameDevice) {
            NSString *message = Localized(@"&app is already streaming on &device, would you like to replace the current session or quit? All unsaved data will be lost.");
            message = [message stringByReplacingOccurrencesOfString:@"&app" withString:currentApp];
            message = [message stringByReplacingOccurrencesOfString:@"&device" withString:currentDevice];
            NSString *title = Localized(@"Streaming session in progress");
            [self showReplaceAlert:message title:title compltion:Completion];
        } else {
            NSString *message = Localized(@"Connection errors detected. Do you want to cancel this connection or replace the previous session?");
            message = [message stringByReplacingOccurrencesOfString:@"&app" withString:currentApp];
            message = [message stringByReplacingOccurrencesOfString:@"&device" withString:currentDevice];
            NSString *title = Localized(@"Reconnecting to PC Streaming");
            [self showReplaceAlert:message title:title compltion:Completion];
        }
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
            [self.view addSubview:_debugMessageLabel];
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
    
    if(self.containerView) {
        [self.containerView  removeFromSuperview];
        self.containerView  = nil;
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
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textSize.width + iconSize + containerPadding * 2, textSize.height + containerPadding)];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 3;
    self.containerView.layer.masksToBounds = YES;

    // Set frames for textView and iconView within the container
    self.textView.frame = CGRectMake(containerPadding, containerPadding / 2, textSize.width, textSize.height);
    self.iconView.frame = CGRectMake(CGRectGetMaxX(self.textView.frame), (self.containerView.frame.size.height - iconSize) / 2, iconSize, iconSize);

    // Add the textView and iconView to the container
    [self.containerView addSubview:self.textView];
    [self.containerView addSubview:self.iconView];

    // Center the containerView at the bottom of the screen
    self.containerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - self.containerView.frame.size.height / 2 - 50);

    [self.view addSubview:self.containerView];

    // Animate the appearance of the containerView
    self.containerView.alpha = 0.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.containerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        // After 3 seconds, hide the container view with animation
        [self performSelector:@selector(hideToast) withObject:nil afterDelay:2.6];
    }];
}

- (void)hideToast {
    [UIView animateWithDuration:1.0 animations:^{
        self.containerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.containerView removeFromSuperview];
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
                reconnectView.frame = [[UIScreen mainScreen] bounds];
                [reconnectView setAsReconnectingStyle];
                [self->_blurView.contentView addSubview:reconnectView];
            }
            [self.view addSubview:self->_blurView];
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

@end
