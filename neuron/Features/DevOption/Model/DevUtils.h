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
#import "ExtraConfig.h"
#import "StreamingStats.h"

NS_ASSUME_NONNULL_BEGIN

@interface DevUtils : NSObject
@property (assign, nonatomic) BOOL isDebugMode;
+ (instancetype)shared;
- (void)setupStats:(ExtraConfig *)config;
- (void)update:(video_stats_t)active last:(video_stats_t)last;
- (void)updateNetRtt:(uint32_t)rtt variance:(uint32_t)variance;
- (nullable StreamingStats *)lastestStreamingStats;
- (nullable TemporarySettings *)lastestStreamingFrameSettings;
- (void)saveStatsToShareDB;
@end

NS_ASSUME_NONNULL_END
