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
#import "Connection.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatsMeta : NSObject
@property(assign, nonatomic) NSInteger frames_with_host_processing_latency;
@property(assign, nonatomic) NSInteger max_host_processing_latency;
@property(assign, nonatomic) NSInteger measurement_start_timestamp;
@property(assign, nonatomic) NSInteger min_host_processing_latency;
@property(assign, nonatomic) NSInteger total_frames;
@property(assign, nonatomic) NSInteger total_frames_received;
@property(assign, nonatomic) NSInteger total_host_processing_latency;
@property(assign, nonatomic) NSInteger total_time_ms;
+ (instancetype)createWithMeta:(video_stats_t)stats;
@end

NS_ASSUME_NONNULL_END
