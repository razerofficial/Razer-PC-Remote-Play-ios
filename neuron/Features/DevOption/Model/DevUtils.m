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

#import "DevUtils.h"
#import "StreamingStats.h"
#import "ShareDataDB.h"
#import "YYModel.h"
#import "NetLatency.h"

static video_stats_t active;
static video_stats_t last;
static video_stats_t global;

@interface DevUtils ()
@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) StreamingStats *stats;
@property (assign, nonatomic) CFTimeInterval lastStatsLogTime;
@property (strong, nonatomic) ExtraConfig *config;
@property (strong, nonatomic) NetLatency *netLatency;
@end

@implementation DevUtils

+ (instancetype)shared {
    static DevUtils *singled;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singled = [DevUtils new];
        [singled setupNotifications];
        singled.isDebugMode = [singled isDebugModeFromUserDefault];
    });
    return singled;
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        _queue = dispatch_queue_create("com.razer.stats.dev", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

- (BOOL)isDebugModeFromUserDefault {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsDebugMode];
}

- (void)setIsDebugMode:(BOOL)isDebugMode {
    _isDebugMode = isDebugMode;
    [[NSUserDefaults standardUserDefaults] setBool:isDebugMode forKey:kIsDebugMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [self saveStatsToShareDB];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [self saveStatsToShareDB];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)saveStatsToShareDB {
    if (self.stats.started_at == 0) {
        Log(LOG_E, @"Invalid stats!");
        return;
    }
    [self.stats updateStats:active last:last global:global extra:self.config netLantency:self.netLatency];
    NSData *statsData = [self.stats yy_modelToJSONData];
    [[ShareDataDB shared] writeData:statsData toFile:statsPath];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStreamingStatsUpdateNotification object:nil];
}

- (void)setupStats:(ExtraConfig *)config {
    memset(&active, 0, sizeof(active));
    memset(&last, 0, sizeof(last));
    memset(&global, 0, sizeof(global));
    self.stats = [StreamingStats new];
    self.config = config;
    self.lastStatsLogTime = 0;
    self.netLatency = [NetLatency new];
}

- (void)update:(video_stats_t)active_stats last:(video_stats_t)last_stats {
    memcpy(&active, &active_stats, sizeof(active));
    memcpy(&last, &last_stats, sizeof(last));
    
    if (global.startTime == 0) {
        global.startTime = last_stats.startTime;
    }
    global.endTime = last_stats.endTime;
    global.totalFrames += last_stats.totalFrames;
    global.receivedFrames += last_stats.receivedFrames;
    global.networkDroppedFrames += last_stats.networkDroppedFrames;
    global.totalHostProcessingLatency += last_stats.totalHostProcessingLatency;
    global.framesWithHostProcessingLatency += last_stats.framesWithHostProcessingLatency;
    global.maxHostProcessingLatency += last_stats.maxHostProcessingLatency;
    global.minHostProcessingLatency += last_stats.minHostProcessingLatency;
    
    if (last_stats.endTime - self.lastStatsLogTime > 10) {
        self.lastStatsLogTime = global.endTime;
        dispatch_async(self.queue, ^{
            video_stats_t activeCopy,lastCopy,globalCopy;
            memcpy(&activeCopy, &active, sizeof(activeCopy));
            memcpy(&lastCopy, &last, sizeof(lastCopy));
            memcpy(&globalCopy, &global, sizeof(globalCopy));
            NSLog(@"active:\n");
            NSLog(@"startTime:%f",activeCopy.startTime);
            NSLog(@"endTime:%f",activeCopy.endTime);
            NSLog(@"totalFrames:%i",activeCopy.totalFrames);
            NSLog(@"receivedFrames:%i",activeCopy.receivedFrames);
            NSLog(@"networkDroppedFrames:%i",activeCopy.networkDroppedFrames);
            NSLog(@"totalHostProcessingLatency:%i",activeCopy.totalHostProcessingLatency);
            NSLog(@"framesWithHostProcessingLatency:%i",activeCopy.framesWithHostProcessingLatency);
            NSLog(@"maxHostProcessingLatency:%i",activeCopy.maxHostProcessingLatency);
            NSLog(@"minHostProcessingLatency:%i",activeCopy.minHostProcessingLatency);
            
            NSLog(@"last:\n");
            NSLog(@"startTime:%f",lastCopy.startTime);
            NSLog(@"endTime:%f",lastCopy.endTime);
            NSLog(@"totalFrames:%i",lastCopy.totalFrames);
            NSLog(@"receivedFrames:%i",lastCopy.receivedFrames);
            NSLog(@"networkDroppedFrames:%i",lastCopy.networkDroppedFrames);
            NSLog(@"totalHostProcessingLatency:%i",lastCopy.totalHostProcessingLatency);
            NSLog(@"framesWithHostProcessingLatency:%i",lastCopy.framesWithHostProcessingLatency);
            NSLog(@"maxHostProcessingLatency:%i",lastCopy.maxHostProcessingLatency);
            NSLog(@"minHostProcessingLatency:%i",lastCopy.minHostProcessingLatency);
            
            NSLog(@"global:\n");
            NSLog(@"startTime:%f",globalCopy.startTime);
            NSLog(@"endTime:%f",globalCopy.endTime);
            NSLog(@"totalFrames:%i",globalCopy.totalFrames);
            NSLog(@"receivedFrames:%i",globalCopy.receivedFrames);
            NSLog(@"networkDroppedFrames:%i",globalCopy.networkDroppedFrames);
            NSLog(@"totalHostProcessingLatency:%i",globalCopy.totalHostProcessingLatency);
            NSLog(@"framesWithHostProcessingLatency:%i",globalCopy.framesWithHostProcessingLatency);
            NSLog(@"maxHostProcessingLatency:%i",globalCopy.maxHostProcessingLatency);
            NSLog(@"minHostProcessingLatency:%i",globalCopy.minHostProcessingLatency);
        });
    }
}

- (void)updateNetRtt:(uint32_t)rtt variance:(uint32_t)variance {
    self.netLatency.rtt = rtt;
    self.netLatency.variance = variance;
}

- (nullable StreamingStats *)lastestStreamingStats {
    NSData *data = [[ShareDataDB shared] readDataFromPath:statsPath];
    StreamingStats *stats = [StreamingStats yy_modelWithJSON:data];
    return stats;
}

- (nullable TemporarySettings *)lastestStreamingFrameSettings {
    NSData *data = [[ShareDataDB shared] readDataFromPath:frameSettingsPath];
    TemporarySettings *setting = [TemporarySettings yy_modelWithJSON:data];
    return setting;
}

@end
