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

#import "RzUtils.h"
#import "TemporaryApp.h"
#import "DataManager.h"
#import "StreamConfiguration.h"
#import "ControllerSupport.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFAudio/AVFAudio.h>
#import <AVFoundation/AVPlayer.h>
#import <Limelight.h>

NSString *const kTutorialCompletedCount = @"KEY_TUTORIAL_COMPLETED_COUNT";
NSString *const kAcceptedTOS = @"KEY_ACCEPTED_TOS";
NSString *const kRequestedLocalNetworkPermission = @"KEY_REQUESTED_LOCAL_NETWORK_PERMISSION";
NSString *const kGrantedLocalNetworkPermission = @"KEY_GRANTED_LOCAL_NETWORK_PERMISSION";
NSString *const kAlreadySetDisplayMode = @"KEY_ALREADY_SET_DISPLAY_MODE";
NSString *const kAlreadyShowDownloadNexus = @"KEY_ALREADY_DOWNLOAD_NEXUS";
@interface RzUtils ()
@property (assign, nonatomic) BOOL isGrantedLocalNetworkPermission;
@end

@implementation RzUtils
static BOOL isGrantedLocalNetworkPermission;

+ (void)setObject:(id)obj forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setTutorialCompleted:(NSInteger)count {
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kTutorialCompletedCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

+ (NSInteger)getTutorialCompletedCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kTutorialCompletedCount];
}

+ (void)setAcceptedTOS {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:kAcceptedTOS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

+ (BOOL)isAcceptedTOS {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAcceptedTOS];
}

+ (void)setRequestedLocalNetworkPermission {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:kRequestedLocalNetworkPermission];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isRequestedLocalNetworkPermission {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRequestedLocalNetworkPermission];
}

+ (void)setGrantedLocalNetworkPermission:(BOOL)isGranted {
    isGrantedLocalNetworkPermission = isGranted;
}

+ (BOOL)isGrantedLocalNetworkPermission {
    return isGrantedLocalNetworkPermission;
}

+ (void)setAlreadyShowDownloadNexus {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:kAlreadyShowDownloadNexus];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isAlreadyShowDownloadNexus {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAlreadyShowDownloadNexus];
}

+ (void)setAlreadySetDisplayMode{
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:kAlreadySetDisplayMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isAlreadySetDisplayMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAlreadySetDisplayMode];
}


+ (BOOL)checkIsNexusInstalled {
    NSURL *url = [NSURL URLWithString:@"Nexus://"];
    BOOL isInstalledNexus = [[UIApplication sharedApplication] canOpenURL: url];
    return isInstalledNexus;
}

+ (void)gotoNexus {
    NSURL *url = [NSURL URLWithString:@"Nexus://"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}


+ (StreamConfiguration *) streamConfigForStreamApp:(TemporaryApp *)app {
    StreamConfiguration *streamConfig = [[StreamConfiguration alloc] init];
    streamConfig.host = app.host.activeAddress;
    streamConfig.httpsPort = app.host.httpsPort;
    streamConfig.appID = app.id;
    streamConfig.appName = app.name;
    streamConfig.serverCert = app.host.serverCert;

    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings* streamSettings = [dataMan getSettings];

    streamConfig.frameRate = [streamSettings.framerate intValue];
    if (@available(iOS 10.3, *)) {
       // Don't stream more FPS than the display can show
       if (streamConfig.frameRate > [UIScreen mainScreen].maximumFramesPerSecond) {
           streamConfig.frameRate = (int)[UIScreen mainScreen].maximumFramesPerSecond;
           Log(LOG_W, @"Clamping FPS to maximum refresh rate: %d", streamConfig.frameRate);
       }
    }

    streamConfig.height = [streamSettings.height intValue];
    streamConfig.width = [streamSettings.width intValue];
    #if TARGET_OS_TV
    // Don't allow streaming 4K on the Apple TV HD
    struct utsname systemInfo;
    uname(&systemInfo);
    if (strcmp(systemInfo.machine, "AppleTV5,3") == 0 && streamConfig.height >= 2160) {
       Log(LOG_W, @"4K streaming not supported on Apple TV HD");
       streamConfig.width = 1920;
       streamConfig.height = 1080;
    }
    #endif

    streamConfig.bitRate = [streamSettings.bitrate intValue];
    streamConfig.optimizeGameSettings = streamSettings.optimizeGames;
    streamConfig.playAudioOnPC = streamSettings.playAudioOnPC;
    streamConfig.useFramePacing = streamSettings.useFramePacing;
    streamConfig.swapABXYButtons = streamSettings.swapABXYButtons;

    // multiController must be set before calling getConnectedGamepadMask
    streamConfig.multiController = streamSettings.multiController;
    streamConfig.gamepadMask = [ControllerSupport getConnectedGamepadMask:streamConfig];

    // Probe for supported channel configurations
    int physicalOutputChannels = (int)[AVAudioSession sharedInstance].maximumOutputNumberOfChannels;
    Log(LOG_I, @"Audio device supports %d channels", physicalOutputChannels);

    int numberOfChannels = MIN([streamSettings.audioConfig intValue], physicalOutputChannels);
    Log(LOG_I, @"Selected number of audio channels %d", numberOfChannels);
    if (numberOfChannels >= 8) {
       streamConfig.audioConfiguration = AUDIO_CONFIGURATION_71_SURROUND;
    }
    else if (numberOfChannels >= 6) {
       streamConfig.audioConfiguration = AUDIO_CONFIGURATION_51_SURROUND;
    }
    else {
       streamConfig.audioConfiguration = AUDIO_CONFIGURATION_STEREO;
    }

    streamConfig.serverCodecModeSupport = app.host.serverCodecModeSupport;
   
    switch (streamSettings.preferredCodec) {
       case CODEC_PREF_AV1:
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
           if (VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)) {
               streamConfig.supportedVideoFormats |= VIDEO_FORMAT_AV1_MAIN8;
           }
#endif
           // Fall-through
           
       case CODEC_PREF_AUTO:
       case CODEC_PREF_HEVC:
//           if (VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
//               streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265;
//           }
            //Since Apple released iOS 11 in 2017, HEVC codec is fully supported by newer iPhones:https://support.apple.com/en-sg/116944,so remove the VTIsHardwareDecodeSupported,because it takes time
            streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265;
           // Fall-through
           
       case CODEC_PREF_H264:
           streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H264;
           break;
    }

    // HEVC is supported if the user wants it (or it's required by the chosen resolution) and the SoC supports it
    if ((streamConfig.width > 4096 || streamConfig.height > 4096 || streamSettings.enableHdr)) {
       streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265;
       
       // HEVC Main10 is supported if the user wants it and the display supports it
       if (streamSettings.enableHdr && (AVPlayer.availableHDRModes & AVPlayerHDRModeHDR10) != 0) {
           streamConfig.supportedVideoFormats |= VIDEO_FORMAT_H265_MAIN10;
       }
    }
   
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
    // Add the AV1 Main10 format if AV1 and HDR are both enabled and supported
    if ((streamConfig.supportedVideoFormats & VIDEO_FORMAT_MASK_AV1) && streamSettings.enableHdr &&
       VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1) && (AVPlayer.availableHDRModes & AVPlayerHDRModeHDR10) != 0) {
       streamConfig.supportedVideoFormats |= VIDEO_FORMAT_AV1_MAIN10;
    }
#endif
    
    return streamConfig;
}

+ (NSUInteger)getCurrentTimestampInMilliseconds {
    NSDate *currentDate = [NSDate date];
    NSUInteger millisecondsSince1970 = (NSUInteger)([currentDate timeIntervalSince1970] * 1000.0);
    
    return millisecondsSince1970;
}

//just use to when launch game is first launch Razer PC Remote Play
static BOOL isNeedContinueLaunchGame = NO;

+ (void)setNeedContinueLaunchGame:(BOOL)isNeed {
    isNeedContinueLaunchGame = isNeed;
}

+ (BOOL)isNeedContinueLaunchGame {
    return isNeedContinueLaunchGame;
}

@end
