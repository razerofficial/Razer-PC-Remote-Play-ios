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

#import "StreamingStats.h"
#import "StatsMeta.h"
#import "RzUtils.h"

@implementation StreamingStats

- (instancetype)init {
    self = [super init];
    if (self) {
        self.started_at = [RzUtils getCurrentTimestampInMilliseconds];
        self.random_id = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (void)updateStats:(video_stats_t)active last:(video_stats_t)last global:(video_stats_t)global extra:(ExtraConfig *)config netLantency:(NetLatency *)latency {
    StatsMeta *activeMeta = [StatsMeta createWithMeta:active];
    StatsMeta *lastMeta = [StatsMeta createWithMeta:last];
    StatsMeta *globalMeta = [StatsMeta createWithMeta:global];
    
    self.activeStats = activeMeta;
    self.lastStats = lastMeta;
    self.globalStats = globalMeta;
    
    AvgFps *avgFps = [AvgFps new];
    avgFps.received_fps = lastMeta.total_frames_received/(lastMeta.total_time_ms / 1000.0);
    avgFps.total_fps = lastMeta.total_frames/(lastMeta.total_time_ms / 1000.0);
    self.avgFps = avgFps;
    
    self.avg_host_processing_latency = last.framesWithHostProcessingLatency != 0 ? (float)last.totalHostProcessingLatency / last.framesWithHostProcessingLatency / 10.f : 0.0;
    self.avg_net_latency = latency.rtt;
    self.avg_net_latency_variance_ms = latency.variance;
    self.decoder = [config getActiveCodecName];
    self.initial_width = config.width;
    self.initial_height = config.height;
    
    self.last_updated_at = [RzUtils getCurrentTimestampInMilliseconds];
    self.max_host_processing_latency = lastMeta.max_host_processing_latency / 10.0f;
    self.min_host_processing_latency = lastMeta.min_host_processing_latency / 10.0f;
    self.net_drops_percent = last.networkDroppedFrames / (lastMeta.total_time_ms / 1000.0);
}

- (NSString *)lastUpdateTime {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.last_updated_at/1000];
    NSDateFormatter *format = [NSDateFormatter new];
    format.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    format.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+08:00"];
    return [format stringFromDate:date];
}

@end
