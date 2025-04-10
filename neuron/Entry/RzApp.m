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

#import "RzApp.h"
#import "ShareDataDB.h"
#import "SWRevealViewController.h"
#import "RzMainFrameViewController.h"
#import "AppDelegate.h"
#import "HttpManager.h"
#import "ServerInfoResponse.h"
#import "AppListResponse.h"
#import "Moonlight-Swift.h"
#import "RZServerInfoResponse.h"

@interface RzApp ()

@property (nonatomic, strong) LocalNetworkAuthorization *networkAuthorization;
@property (nonatomic, assign) BOOL isLaunchingDesktop;

@end

@implementation RzApp

+ (instancetype)shared {
    static RzApp *app;
    if (!app) {
        app = [RzApp new];
        app.networkAuthorization = [[LocalNetworkAuthorization alloc] init];
    }
    return app;
}

- (void)maybeStartStreaming {
    //if first time launch game and tutorial hasn't been displayed yet, will show tutorial first then launch game
    [RzUtils setNeedContinueLaunchGame:true];
    // [SettingsRouter.shared setStartingStream:YES];
    
    if (![RzUtils isAcceptedTOS] || ![RzUtils isRequestedLocalNetworkPermission]) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"START_STREAMING_NEED_SHOW_TUTORIAL" object:nil];
        [SettingsRouter.shared setStartingStream:NO];
        return;
    } else {
        [SettingsRouter.shared showStreamLoadingView];
    }
     
    __weak typeof(self) weakSelf = self;
    __weak SettingsRouter *weakRouter = SettingsRouter.shared;
    [self.networkAuthorization requestAuthorizationWithIsNeedToResetCompletionBlock:true completion:^(BOOL result) {
        if (result) {
            Log(LOG_I, @"maybeStartStreaming: will start streaming.");
            [weakRouter dismissTutorialView];
            [weakSelf startStreaming];
            
        } else {
            [NSNotificationCenter.defaultCenter postNotificationName:@"START_STREAMING_NEED_SHOW_TUTORIAL" object:nil];
            [weakRouter hideStreamLoadingView];
        }
    }];
}

- (void)startStreaming {
    
    RzTemporaryApp *app = [[ShareDataDB shared] currentLaunchGame];
    
    TemporaryApp *newApp = [app convert2TemporaryApp];
    if (!newApp) {
        Log(LOG_E, @"startStreaming: app is null...");
        [SettingsRouter.shared hideStreamLoadingView];
        return;
    }
    
    newApp.host.appList = [NSMutableSet setWithObject:newApp];
    //read setting data from share db
    [[ShareDataDB shared] readSettingDataFromShareDB];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self maybeUpdateStreamingSettingForHost:newApp.host];
        HttpManager* hMan = [[HttpManager alloc] initWithHost:newApp.host];
        
        ServerInfoResponse* serverInfoResp = [[ServerInfoResponse alloc] init];
        [hMan executeRequestSynchronously:[HttpRequest requestForResponse:serverInfoResp withUrlRequest:[hMan newServerInfoRequest:false]
                                           fallbackError:401 fallbackRequest:[hMan newHttpServerInfoRequest]]];
        
        AppListResponse* appListResp = [[AppListResponse alloc] init];
        [hMan executeRequestSynchronously:[HttpRequest requestForResponse:appListResp withUrlRequest:[hMan newAppListRequest]]];
        
        NSString* currentGameId = [serverInfoResp getStringTag:TAG_CURRENT_GAME];
        TemporaryApp* currentGame;
        Log(LOG_I, @"startStreaming: newAppid:%@, runningAppid:%@", newApp.id, currentGameId);
        
        for (TemporaryApp* app in appListResp.getAppList) {
            if ([app.id isEqualToString:currentGameId]) {
                currentGame = app;
                break;
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            UINavigationController *navVC = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
//            [navVC popToRootViewControllerAnimated:false];
//            SettingsMenuVC *mainVC = [self getSettingsMenuVC];
//            //before streaming need check PC current running game
//            [mainVC maybeLaunch:newApp currentApp:currentGame];
            [SettingsRouter.shared maybeLaunch:newApp currentApp:currentGame];
        });
    });
}

- (void)launchDesktopStreaming: (TemporaryHost*) host {
    if (self.isLaunchingDesktop) {
        return;
    }
    self.isLaunchingDesktop = true;
    //read setting data from share db
    [[ShareDataDB shared] readSettingDataFromShareDB];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self maybeUpdateStreamingSettingForHost:host];
        
        HttpManager* hMan = [[HttpManager alloc] initWithHost:host];
        
        AppListResponse* appListResp = [[AppListResponse alloc] init];
        [hMan executeRequestSynchronously:[HttpRequest requestForResponse:appListResp withUrlRequest:[hMan newAppListRequest]]];
        
        TemporaryApp* desktop;
       
        for (TemporaryApp* app in appListResp.getAppList) {
            if ([app.name.uppercaseString isEqualToString:@"DESKTOP"]) {
                desktop = app;
                desktop.host = host;
                host.activeAddress = [[host.activeAddress componentsSeparatedByString:@":"] firstObject];
                host.localAddress = [[host.localAddress componentsSeparatedByString:@":"] firstObject];
                break;
            }
        }
        
        Log(LOG_I, @"startStreaming: launch %@ desktop", host.name);
        dispatch_async(dispatch_get_main_queue(), ^{
//            UINavigationController *navVC = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
//            [navVC popToRootViewControllerAnimated:false];
//            SettingsMenuVC *mainVC = [self getSettingsMenuVC];
//            //before streaming need check PC current running game
//            [mainVC navigateToStreamViewController:desktop shouldReturnToNexus:false];
            [SettingsRouter.shared prepareNavigateToStreamViewController:desktop shouldReturnToNexus:false];
            self.isLaunchingDesktop = false;
        });
    });
}

- (void)maybeUpdateStreamingSettingForHost: (TemporaryHost*) host {
    
    //if displayMode is duplicate(displayMode==0), use the host resolution start streaming
    if ( ![NeuronFrameSettingsViewModel isDuplicateDisplayMode] ) {
        return;
    }
    HttpManager* hMan = [[HttpManager alloc] initWithHost:host];
    
    RZServerInfoResponse* serverInfoResp = [[RZServerInfoResponse alloc] init];
    [hMan executeRequestSynchronously:[HttpRequest requestForResponse:serverInfoResp withUrlRequest:[hMan newServerInfoRequest:false]
                                       fallbackError:401 fallbackRequest:[hMan newHttpServerInfoRequest]]];
    
    NSMutableDictionary *displayModeDic= (NSMutableDictionary*)[serverInfoResp getObjectTag: @"PrimaryDisplayMode"];
    NSString *width = displayModeDic[@"DisplayMode"][@"Width"];
    NSString *height = displayModeDic[@"DisplayMode"][@"Height"];
    NSString *refreshRate = displayModeDic[@"DisplayMode"][@"RefreshRate"];
    
    if (width.integerValue <= 0 || height.integerValue <= 0 || refreshRate.integerValue <= 0) {
        width = @"1280";
        height = @"720";
        refreshRate = @"60";
        Log(LOG_E, @"request host resolution and refresh rate error, will use default value instead");
    }
    
    UIScreen *mainScreen = [UIScreen mainScreen];
    NSInteger phoneRefreshRate = mainScreen.maximumFramesPerSecond;
    
    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings *setting = [dataMan getSettings];

    [dataMan saveSettingsWithBitrate:setting.bitrate.integerValue
                           framerate:setting.framerate.integerValue
                              height:setting.height.integerValue
                               width:setting.width.integerValue
                         audioConfig:setting.audioConfig.integerValue
                    onscreenControls:setting.onscreenControls.integerValue
                       optimizeGames:setting.optimizeGames
                     multiController:setting.multiController
                     swapABXYButtons:setting.swapABXYButtons
                           audioOnPC:setting.playAudioOnPC
                      preferredCodec:setting.preferredCodec
                      useFramePacing:setting.useFramePacing
                           enableHdr:setting.enableHdr
                      btMouseSupport:setting.btMouseSupport
                   absoluteTouchMode:setting.absoluteTouchMode
                        statsOverlay:setting.statsOverlay
                       hostFramerate:refreshRate.integerValue > phoneRefreshRate ? phoneRefreshRate : refreshRate.integerValue
                          hostHeight:height.integerValue
                           hostWidth:width.integerValue];
}

- (SettingsMenuVC *)getSettingsMenuVC {
    UINavigationController *rootNav = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    SettingsMenuVC *mainVC = nil;
    for (UIViewController *vc in rootNav.viewControllers) {
        if ([vc isKindOfClass:[SettingsMenuVC class]]) {
            mainVC = (SettingsMenuVC *)vc;
            break;
        }
    }
    return mainVC;
}

@end
