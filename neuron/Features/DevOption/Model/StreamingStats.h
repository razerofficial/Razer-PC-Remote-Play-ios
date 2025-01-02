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

#import <Foundation/Foundation.h>
#import "StatsMeta.h"
#import "AvgFps.h"
#import "Connection.h"
#import "ExtraConfig.h"
#import "NetLatency.h"

NS_ASSUME_NONNULL_BEGIN

@interface StreamingStats : NSObject
@property (strong, nonatomic) StatsMeta *activeStats;
@property (strong, nonatomic) StatsMeta *lastStats;
@property (strong, nonatomic) StatsMeta *globalStats;
@property (strong, nonatomic) AvgFps *avgFps;
@property (assign, nonatomic) double avg_host_processing_latency;
@property (assign, nonatomic) double avg_net_latency;
@property (assign, nonatomic) double avg_net_latency_variance_ms;
@property (strong, nonatomic) NSString *decoder;
@property (assign, nonatomic) NSInteger initial_height;
@property (assign, nonatomic) NSInteger initial_width;
@property (assign, nonatomic) NSInteger last_updated_at;
@property (assign, nonatomic) double max_host_processing_latency;
@property (assign, nonatomic) double min_host_processing_latency;
@property (assign, nonatomic) double net_drops_percent;
@property (strong, nonatomic) NSString *random_id;
@property (assign, nonatomic) NSInteger started_at;
- (void)updateStats:(video_stats_t)active last:(video_stats_t)last global:(video_stats_t)global extra:(ExtraConfig *)config netLantency:(NetLatency *)latency;
- (NSString *)lastUpdateTime;
@end

NS_ASSUME_NONNULL_END
