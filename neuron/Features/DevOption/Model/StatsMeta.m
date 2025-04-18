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

#import "StatsMeta.h"

@implementation StatsMeta
+ (instancetype)createWithMeta:(video_stats_t)stats {
    StatsMeta *meta = [StatsMeta new];
    meta.frames_with_host_processing_latency = stats.framesWithHostProcessingLatency;
    meta.max_host_processing_latency = stats.maxHostProcessingLatency;
    meta.measurement_start_timestamp = (NSInteger)stats.startTime;
    meta.min_host_processing_latency = (NSInteger)stats.minHostProcessingLatency;
    meta.total_frames = (NSInteger)stats.totalFrames;
    meta.total_frames_received = (NSInteger)stats.receivedFrames;
    meta.total_host_processing_latency = (NSInteger)stats.totalHostProcessingLatency;
    if (stats.endTime != 0) {
        meta.total_time_ms = (NSInteger)((stats.endTime - stats.startTime)*1000);
    }
    return meta;
}
@end
