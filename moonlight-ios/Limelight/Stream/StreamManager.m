//
//  StreamManager.m
//  Moonlight
//
//  Created by Diego Waxemberg on 10/20/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import "StreamManager.h"
#import "CryptoManager.h"
#import "HttpManager.h"
#import "Utils.h"

#import "StreamView.h"
#import "ServerInfoResponse.h"
#import "HttpResponse.h"
#import "HttpRequest.h"
#import "IdManager.h"
#import "DevUtils.h"

#include <Limelight.h>
static NSMutableDictionary *riKeyDictM = NULL;

@interface StreamManager ()
@property (nonatomic, assign) BOOL isTerminated;
@end

@implementation StreamManager {
    StreamConfiguration* _config;

    UIView* _renderView;
    id<ConnectionCallbacks> _callbacks;
    Connection* _connection;
}

- (id) initWithConfig:(StreamConfiguration*)config renderView:(UIView*)view connectionCallbacks:(id<ConnectionCallbacks>)callbacks {
    self = [super init];
    _config = config;
    _renderView = view;
    _callbacks = callbacks;
    
    if (!riKeyDictM) riKeyDictM = [NSMutableDictionary new];
    NSString *uuid = _config.uuid;
    NSString *key = [NSString stringWithFormat:@"%@_key",uuid];
    NSString *keyId = [NSString stringWithFormat:@"%@_keyId",uuid];
    NSData *oldRiKey = riKeyDictM[key];
    int oldRiKeyId = [riKeyDictM[keyId] intValue];
    if (riKeyDictM[key] && riKeyDictM[keyId]) {
        _config.riKey = oldRiKey;
        _config.riKeyId = oldRiKeyId;
    } else {
        _config.riKey = [Utils randomBytes:16];
        _config.riKeyId = arc4random();
        
        riKeyDictM[key] = _config.riKey;
        riKeyDictM[keyId] = @(_config.riKeyId);
    }
    
    return self;
}

- (void)main {
    [CryptoManager generateKeyPairUsingSSL];
    
    HttpManager* hMan = [[HttpManager alloc] initWithAddress:_config.host httpsPort:_config.httpsPort
                                                    httpPort:_config.httpPort serverCert:_config.serverCert];
    
    ServerInfoResponse* serverInfoResp = [[ServerInfoResponse alloc] init];
    [hMan executeRequestSynchronously:[HttpRequest requestForResponse:serverInfoResp withUrlRequest:[hMan newServerInfoRequest:false]
                                       fallbackError:401 fallbackRequest:[hMan newHttpServerInfoRequest]]];
    NSString* pairStatus = [serverInfoResp getStringTag:@"PairStatus"];
    NSString* appversion = [serverInfoResp getStringTag:@"appversion"];
    NSString* gfeVersion = [serverInfoResp getStringTag:@"GfeVersion"];
    NSString* serverState = [serverInfoResp getStringTag:@"state"];
    NSString* currentDevice = [serverInfoResp getStringTag:@"currentdevice"];
    NSString* currentGameId = [serverInfoResp getStringTag:@"currentgame"];
    BOOL isHostNeedToReplace = NO;
    BOOL isOngoingStreaming = NO;
    
    NSLog(@">> code:%ld msg:%@",serverInfoResp.statusCode, serverInfoResp.statusMessage);
    
    if (serverInfoResp.statusCode == 5035) {
        isHostNeedToReplace = YES;
    } else if (serverInfoResp.statusCode == 5036) {
        isOngoingStreaming = YES;
    } else if (![serverInfoResp isStatusOk]) {
        [_callbacks launchFailed:serverInfoResp.statusMessage errorCode:serverInfoResp.statusCode];
        return;
    }
    else if (pairStatus == NULL || appversion == NULL || serverState == NULL) {
        [_callbacks launchFailed:Localized(@"Failed to connect to PC") errorCode:serverInfoResp.statusCode];
        return;
    }
    
    if (![pairStatus isEqualToString:@"1"]) {
        // Not paired
        [_callbacks launchFailed:Localized(@"Device not paired to PC") errorCode:serverInfoResp.statusCode];
        return;
    }
    
    // Only perform this check on GFE (as indicated by MJOLNIR in state value)
    if ((_config.width > 4096 || _config.height > 4096) && [serverState containsString:@"MJOLNIR"]) {
        // Pascal added support for 8K HEVC encoding support. Maxwell 2 could encode HEVC but only up to 4K.
        // We can't directly identify Pascal, but we can look for HEVC Main10 which was added in the same generation.
        NSString* codecSupport = [serverInfoResp getStringTag:@"ServerCodecModeSupport"];
        if (codecSupport == nil || !([codecSupport intValue] & 0x200)) {
            [_callbacks launchFailed:Localized(@"Your host PC's GPU doesn't support streaming video resolutions over 4K.") errorCode:serverInfoResp.statusCode];
            return;
        }
    }
    
    // Populate the config's version fields from serverinfo
    _config.appVersion = appversion;
    _config.gfeVersion = gfeVersion;
    
    // resumeApp and launchApp handle calling launchFailed
    NSString* sessionUrl;
    if (isHostNeedToReplace) {
        // Replace app
        if (![self replaceApp:hMan receiveSessionUrl:&sessionUrl]) {
            return;
        }
    } else if(isOngoingStreaming) {
        __weak typeof(self) weakSelf = self;
        BOOL isSameDevice = [currentGameId isEqualToString:_config.appID] && [currentDevice isEqualToString:[RzUtils deviceName]];
        [_callbacks launchFailed:_config.appName device:currentDevice errorCode:serverInfoResp.statusCode isSameDevice:isSameDevice  completion:^(NSInteger option) {
            if (option == 1) {
                NSString* replaceSessionUrl;
                if ([weakSelf replaceApp:hMan receiveSessionUrl:&replaceSessionUrl]) {
                    [weakSelf startStream:replaceSessionUrl];
                }
            }
        }];
        return;
    } else if ([serverState hasSuffix:@"_SERVER_BUSY"]) {
        // App already running, resume it
        if (![self resumeApp:hMan receiveSessionUrl:&sessionUrl currentGame:currentGameId currentDevice:currentDevice]) {
            return;
        }
    } else {
        // Start app
        if (![self launchApp:hMan receiveSessionUrl:&sessionUrl]) {
            return;
        }
    }
    
    [self startStream:sessionUrl];
}

- (void) startStream:(NSString *)sessionUrl {
    // Populate RTSP session URL from launch/resume response
    _config.rtspSessionUrl = sessionUrl;
    
    // Initializing the renderer must be done on the main thread
    
    dispatch_async(dispatch_get_main_queue(), ^{
        VideoDecoderRenderer* renderer = [[VideoDecoderRenderer alloc] initWithView:self->_renderView callbacks:self->_callbacks streamAspectRatio:(float)self->_config.width / (float)self->_config.height useFramePacing:self->_config.useFramePacing];
        self->_connection = [[Connection alloc] initWithConfig:self->_config renderer:renderer connectionCallbacks:self->_callbacks];
        NSOperationQueue* opQueue = [[NSOperationQueue alloc] init];
        self->_connection.isTerminated = self.isTerminated;
        [opQueue addOperation:self->_connection];
    });
}

- (void) stopStream
{
    self.isTerminated = YES;
    [_connection terminate];
}

- (BOOL) launchApp:(HttpManager*)hMan receiveSessionUrl:(NSString**)sessionUrl {
    HttpResponse* launchResp = [[HttpResponse alloc] init];
    [hMan executeRequestSynchronously:[HttpRequest requestForResponse:launchResp withUrlRequest:[hMan newLaunchOrResumeRequest:@"launch" config:_config]]];
    NSString *gameSession = [launchResp getStringTag:@"gamesession"];
    if (![launchResp isStatusOk]) {
        [_callbacks launchFailed:launchResp.statusMessage errorCode:launchResp.statusCode];
        Log(LOG_E, @"Failed Launch Response: %@", launchResp.statusMessage);
        return FALSE;
    } else if (gameSession == NULL || [gameSession isEqualToString:@"0"]) {
        [_callbacks launchFailed:Localized(@"Failed to launch app") errorCode:launchResp.statusCode];
        Log(LOG_E, @"Failed to parse game session");
        return FALSE;
    }
    
    *sessionUrl = [launchResp getStringTag:@"sessionUrl0"];
    return TRUE;
}

- (BOOL) resumeApp:(HttpManager*)hMan receiveSessionUrl:(NSString**)sessionUrl currentGame:(NSString *)currentGameId currentDevice:(NSString *)currentDevice {
    HttpResponse* resumeResp = [[HttpResponse alloc] init];
    [hMan executeRequestSynchronously:[HttpRequest requestForResponse:resumeResp withUrlRequest:[hMan newLaunchOrResumeRequest:@"resume" config:_config]]];
    NSString* resume = [resumeResp getStringTag:@"resume"];
    if (![resumeResp isStatusOk]) {
        if (resumeResp.statusCode == 5036) {
            __weak typeof(self) weakSelf = self;
            BOOL isSameDevice = [currentGameId isEqualToString:_config.appID] && [currentDevice isEqualToString:[RzUtils deviceName]];
            [_callbacks launchFailed:_config.appName device:currentDevice errorCode:resumeResp.statusCode isSameDevice:isSameDevice completion:^(NSInteger option) {
                NSOperationQueue* opQueue = [[NSOperationQueue alloc] init];
                [opQueue addOperationWithBlock:^{
                    if (option == 1) {
                        NSString* replaceSessionUrl;
                        if ([weakSelf replaceApp:hMan receiveSessionUrl:&replaceSessionUrl]) {
                            [weakSelf startStream:replaceSessionUrl];
                        }
                    }
                }];
            }];
        } else {
            [_callbacks launchFailed:resumeResp.statusMessage errorCode:resumeResp.statusCode];
        }
        Log(LOG_E, @"Failed Resume Response: %@", resumeResp.statusMessage);
        return FALSE;
    } else if (resume == NULL || [resume isEqualToString:@"0"]) {
        [_callbacks launchFailed:Localized(@"Failed to resume app") errorCode:resumeResp.statusCode];
        Log(LOG_E, @"Failed to parse resume response");
        return FALSE;
    }
    
    *sessionUrl = [resumeResp getStringTag:@"sessionUrl0"];
    return TRUE;
}

- (BOOL) replaceApp:(HttpManager*)hMan receiveSessionUrl:(NSString**)sessionUrl {
    HttpResponse* replaceResp = [[HttpResponse alloc] init];
    [hMan executeRequestSynchronously:[HttpRequest requestForResponse:replaceResp withUrlRequest:[hMan newLaunchOrResumeRequest:@"replace" config:_config]]];
    NSString* gamesession = [replaceResp getStringTag:@"gamesession"];
    NSString* resume = [replaceResp getStringTag:@"resume"];
    if (![replaceResp isStatusOk]) {
        [_callbacks launchFailed:replaceResp.statusMessage errorCode:replaceResp.statusCode];
        Log(LOG_E, @"Failed Replace Response: %@", replaceResp.statusMessage);
        return FALSE;
    } else if ([gamesession isEqualToString:@"0"] || [resume isEqualToString:@"0"]) {
        [_callbacks launchFailed:Localized(@"Failed to launch app") errorCode:replaceResp.statusCode];
        Log(LOG_E, @"Failed to parse replace response");
        return FALSE;
    }
    
    *sessionUrl = [replaceResp getStringTag:@"sessionUrl0"];
    return TRUE;
}

- (NSString*) getStatsOverlayText {
    video_stats_t stats;
    
    if (!_connection) {
        return nil;
    }
    
    if (![_connection getVideoStats:&stats]) {
        return nil;
    }
    
    uint32_t rtt, variance;
    NSString* latencyString;
    if (LiGetEstimatedRttInfo(&rtt, &variance)) {
        latencyString = [NSString stringWithFormat:@"%u ms (variance: %u ms)", rtt, variance];
        [[DevUtils shared] updateNetRtt:rtt variance:variance];
    }
    else {
        latencyString = @"N/A";
        [[DevUtils shared] updateNetRtt:0 variance:0];
    }
    
    NSString* hostProcessingString;
    if (stats.framesWithHostProcessingLatency != 0) {
        hostProcessingString = [NSString stringWithFormat:@"\nHost processing latency min/max/avg: %.1f/%.1f/%.1f ms",
                                stats.minHostProcessingLatency / 10.f,
                                stats.maxHostProcessingLatency / 10.f,
                                (float)stats.totalHostProcessingLatency / stats.framesWithHostProcessingLatency / 10.f];
    }
    else {
        hostProcessingString = @"";
    }
    
    float interval = stats.endTime - stats.startTime;
    return [NSString stringWithFormat:@"Video stream: %dx%d %.2f FPS (Codec: %@)\nFrames dropped by your network connection: %.2f%%\nAverage network latency: %@%@",
            _config.width,
            _config.height,
            stats.totalFrames / interval,
            [_connection getActiveCodecName],
            stats.networkDroppedFrames / interval,
            latencyString,
            hostProcessingString];
}

@end
