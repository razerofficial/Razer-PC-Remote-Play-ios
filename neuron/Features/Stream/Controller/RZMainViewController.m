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

#import "RZMainViewController.h"
#import "DataManager.h"
#import "SWRevealViewController.h"
#import "RZStreamFrameViewController.h"
#import "RZAboutViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "RzUtils.h"
#import "Moonlight-Swift.h"

#include <Limelight.h>

@interface RZMainViewController ()<DownloadOverlayDelegate>
@property (weak, nonatomic) IBOutlet UIButton *launchNexusBtn;
@property (strong, nonatomic) LocalNetworkAuthorization *localNetworkAuthorization;
@property (assign, nonatomic) BOOL isShowDownloadOverlay;
@end

@implementation RZMainViewController {
    StreamConfiguration* _streamConfig;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupNotifications];
    [self maybeGotoTutorialPage];
}

- (void)setupData {
    self.isShowDownloadOverlay = NO;
}

- (void)setupNotifications {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kRetryStreamingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [weakSelf retryStreaming:notification];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [weakSelf updateButtonsUI];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [weakSelf dimissDownloadOverlay];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BOOL isInstalledNexus = [self checkIsNexusInstalled];
//    if(!isInstalledNexus) {
//        [self showNexusNotInstalledAlert];
//    }
    [self _updateButtonsUI:isInstalledNexus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dimissDownloadOverlay];
}

- (void)updateButtonsUI {
    BOOL isInstalledNexus = [self checkIsNexusInstalled];
    [self _updateButtonsUI:isInstalledNexus];
}
- (void)_updateButtonsUI:(BOOL)isInstalledNexus {
    NSString *btnTitle = isInstalledNexus ? @"Launch Nexus" : @"Streaming Configuration";
    [self.launchNexusBtn setTitle:btnTitle forState:UIControlStateNormal];
}

- (IBAction)navigateToDevPage:(id)sender {
    //RZAboutViewController *aboutVC = [[RZAboutViewController alloc] initWithNibName:@"RZAboutViewController" bundle:nil];
    //[self.navigationController pushViewController:aboutVC animated:true];
    SettingsMenuVC *menuVC = [[SettingsMenuVC alloc]init];
    [self.navigationController pushViewController:menuVC animated:true];
}
- (IBAction)maybeOpenNexus:(id)sender {
    NSURL *url = [NSURL URLWithString:@"Nexus://"];
    BOOL isInstalledNexus = [self checkIsNexusInstalled];
    if(!isInstalledNexus) {
        [self navigateToDev];
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)maybeGotoTutorialPage {
    if (![RzUtils isAcceptedTOS]) {
        [self gotoTutorialPage];
    } else if (![RzUtils isRequestedLocalNetworkPermission]) {
        [self gotoTutorialPage];
    } else if (![RzUtils isAlreadySetDisplayMode]){
        [self gotoTutorialPage];
    }else {
        __weak typeof(self) weakSelf = self;
        LocalNetworkAuthorization *localNetworkAuthorization = [[LocalNetworkAuthorization alloc] init];
        [localNetworkAuthorization requestAuthorizationWithCompletion:^(BOOL result) {
            Log(LOG_D,@"maybeGotoTutorialPage requestAuthorization result:%d,",result);
            [RzUtils setGrantedLocalNetworkPermission:result];
            if (!result || ![RzUtils checkIsNexusInstalled]){
                [weakSelf gotoTutorialPage];
            }
        }];
    }
}

- (void)gotoTutorialPage {
//    TutorialViewController *tutorialVC = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
//    tutorialVC.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:tutorialVC animated:false completion:nil];
}

- (void) prepareToStreamApp:(TemporaryApp *)app {
    _streamConfig = [[StreamConfiguration alloc] init];
    _streamConfig.host = app.host.activeAddress;
    _streamConfig.httpsPort = app.host.httpsPort;
    _streamConfig.appID = app.id;
    _streamConfig.appName = app.name;
    _streamConfig.serverCert = app.host.serverCert;
    
    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings* streamSettings = [dataMan getSettings];
    
    _streamConfig.frameRate = [streamSettings.framerate intValue];
    if (@available(iOS 10.3, *)) {
        // Don't stream more FPS than the display can show
        if (_streamConfig.frameRate > [UIScreen mainScreen].maximumFramesPerSecond) {
            _streamConfig.frameRate = (int)[UIScreen mainScreen].maximumFramesPerSecond;
            Log(LOG_W, @"Clamping FPS to maximum refresh rate: %d", _streamConfig.frameRate);
        }
    }
    
    _streamConfig.height = [streamSettings.height intValue];
    _streamConfig.width = [streamSettings.width intValue];
#if TARGET_OS_TV
    // Don't allow streaming 4K on the Apple TV HD
    struct utsname systemInfo;
    uname(&systemInfo);
    if (strcmp(systemInfo.machine, "AppleTV5,3") == 0 && _streamConfig.height >= 2160) {
        Log(LOG_W, @"4K streaming not supported on Apple TV HD");
        _streamConfig.width = 1920;
        _streamConfig.height = 1080;
    }
#endif
    
    _streamConfig.bitRate = [streamSettings.bitrate intValue];
    _streamConfig.optimizeGameSettings = streamSettings.optimizeGames;
    _streamConfig.playAudioOnPC = streamSettings.playAudioOnPC;
    _streamConfig.useFramePacing = streamSettings.useFramePacing;
    _streamConfig.swapABXYButtons = streamSettings.swapABXYButtons;
    
    // multiController must be set before calling getConnectedGamepadMask
    _streamConfig.multiController = streamSettings.multiController;
    _streamConfig.gamepadMask = [ControllerSupport getConnectedGamepadMask:_streamConfig];
    
    // Probe for supported channel configurations
    int physicalOutputChannels = (int)[AVAudioSession sharedInstance].maximumOutputNumberOfChannels;
    Log(LOG_I, @"Audio device supports %d channels", physicalOutputChannels);
    
    int numberOfChannels = MIN([streamSettings.audioConfig intValue], physicalOutputChannels);
    Log(LOG_I, @"Selected number of audio channels %d", numberOfChannels);
    if (numberOfChannels >= 8) {
        _streamConfig.audioConfiguration = AUDIO_CONFIGURATION_71_SURROUND;
    }
    else if (numberOfChannels >= 6) {
        _streamConfig.audioConfiguration = AUDIO_CONFIGURATION_51_SURROUND;
    }
    else {
        _streamConfig.audioConfiguration = AUDIO_CONFIGURATION_STEREO;
    }
    
    _streamConfig.serverCodecModeSupport = app.host.serverCodecModeSupport;
    
    switch (streamSettings.preferredCodec) {
        case CODEC_PREF_AV1:
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
            if (VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)) {
                _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_AV1_MAIN8;
            }
#endif
            // Fall-through
            
        case CODEC_PREF_AUTO:
        case CODEC_PREF_HEVC:
            if (VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
                _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265;
            }
            // Fall-through
            
        case CODEC_PREF_H264:
            _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H264;
            break;
    }
    
    // HEVC is supported if the user wants it (or it's required by the chosen resolution) and the SoC supports it
    if ((_streamConfig.width > 4096 || _streamConfig.height > 4096 || streamSettings.enableHdr) && VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
        _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265;
        
        // HEVC Main10 is supported if the user wants it and the display supports it
        if (streamSettings.enableHdr && (AVPlayer.availableHDRModes & AVPlayerHDRModeHDR10) != 0) {
            _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265_MAIN10;
        }
    }
    
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
    // Add the AV1 Main10 format if AV1 and HDR are both enabled and supported
    if ((_streamConfig.supportedVideoFormats & VIDEO_FORMAT_MASK_AV1) && streamSettings.enableHdr &&
        VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1) && (AVPlayer.availableHDRModes & AVPlayerHDRModeHDR10) != 0) {
        _streamConfig.supportedVideoFormats |= VIDEO_FORMAT_AV1_MAIN10;
    }
#endif
}

- (void) navigateToStreamViewController:(TemporaryApp *)app {
    [self prepareToStreamApp: app];
    __weak typeof(self) weakSelf = self;
    self.localNetworkAuthorization = [[LocalNetworkAuthorization alloc] init];
    if(![RzUtils isRequestedLocalNetworkPermission]) {
        [RzUtils setRequestedLocalNetworkPermission];
    }
    [self.localNetworkAuthorization requestAuthorizationWithCompletion:^(BOOL result) {
        if (result) {
            [RzUtils setGrantedLocalNetworkPermission:true];
            Log(LOG_I,@"requestAuthorization result:%d",result);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf _navigateToStreamViewController:app];
            });
        }
    }];
    [RzUtils setRequestedLocalNetworkPermission];
}

- (void) _navigateToStreamViewController:(TemporaryApp *)app {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"StreamFrame" bundle:nil];
    
    // 使用Storyboard ID初始化MyViewController
    RZStreamFrameViewController *streamFrameVC = [storyboard instantiateViewControllerWithIdentifier:@"StreamFrameViewController"];
    
    
    streamFrameVC.streamConfig = _streamConfig;
    [self.navigationController pushViewController:streamFrameVC animated:false];
}


- (void)showNexusNotInstalledAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Razer recommends that users download Razer Nexus, a launcher specifically designed for gaming, to enhance the use of Razer PC Remote Play"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self)weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download Razer Nexus"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf showDownloadOverlay];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No Thanks"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showDownloadOverlay {
    if (self.isShowDownloadOverlay) {
        NSLog(@"isShowDownloadOverlay is YES, return...");
        return;
    }
    [[DownloadOverlayManager shared] showOverlayWithAppid:kNexusAppId delegate:self];
}

/*
 *case1:app resign active
 *case2:user click on the blank space
 *case3:view disappear
 */
- (void)dimissDownloadOverlay {
    [[DownloadOverlayManager shared] dismissOverlay];
}

- (BOOL)checkIsNexusInstalled {
    NSURL *url = [NSURL URLWithString:@"Nexus://"];
    BOOL isInstalledNexus = [[UIApplication sharedApplication] canOpenURL: url];
    return isInstalledNexus;
}

- (void)navigateToDev {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    SWRevealViewController *revealVC = [storyboard instantiateInitialViewController];
    
    [self.navigationController pushViewController:revealVC animated:true];
}

#pragma mark -- notifications
- (void)retryStreaming:(NSNotification *)not {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"StreamFrame" bundle:nil];
    
    // 使用Storyboard ID初始化MyViewController
    RZStreamFrameViewController *streamFrameVC = [storyboard instantiateViewControllerWithIdentifier:@"StreamFrameViewController"];
    streamFrameVC.haveRetry = YES;
    
    
    streamFrameVC.streamConfig = _streamConfig;
    [self.navigationController pushViewController:streamFrameVC animated:false];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -- DownloadOverlayDelegate
- (void)storeOverlayDidFailToLoad:(SKOverlay *)overlay error:(NSError *)error {
    self.isShowDownloadOverlay = NO;
}

- (void)storeOverlayDidFinishDismissal:(SKOverlay *)overlay transitionContext:(SKOverlayTransitionContext *)transitionContext {
    self.isShowDownloadOverlay = NO;
}

- (void)storeOverlayDidShow {
    self.isShowDownloadOverlay = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dimissDownloadOverlay];
}

@end
