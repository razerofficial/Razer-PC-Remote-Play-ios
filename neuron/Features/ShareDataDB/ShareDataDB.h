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
#import "RzTemporaryApp.h"

NS_ASSUME_NONNULL_BEGIN

@class NeuronFrameSettings;
@class NeuronEvent;
@interface ShareDataDB : NSObject
+ (instancetype)shared;
- (NSData *)readDataFromPath:(NSString *)item;
- (void)writeData:(NSData *)data toFile:(NSString *)item;
- (RzTemporaryApp *)currentLaunchGame;
- (void)resetCurrentLaunchGameData;
- (void)readSettingDataFromShareDB;
- (void)writeSettingDataToShareDB;
- (void)writeSettingDataToShareDB: (TemporarySettings *)setting;
- (void)wirteHostListDataToShareDB;
- (void)readHostListDataFromeShareDB;
- (void)saveSettings;
- (NSArray *)getShareHostList;
- (NSURL *)fileUrlFromGroup:(NSString *)item;
- (nullable TemporarySettings *)getStreamingSettings;
- (void)saveFrameSettings:(NeuronFrameSettings *)settings;
- (NeuronFrameSettings *)readFrameSettings;
- (NSDictionary *)readDevOptionsDataFromShareDB;
- (void)writeDevOptionsDataToshareDB:(NSDictionary *)devOptions;
- (NSArray *)readManuallyUnpairedHostDataFromShareDB;
- (void)writeManuallyUnpairedHostDataToshareDB:(NSString *)hostUuid;
- (void)removePairedHostFromeShareDB:(TemporaryHost *)host;
- (void)writeNeuronInfo;
- (void)writeNeuronEvent:(NeuronEvent *)event;
//- (void)updateHost:(TemporaryHost *)host;

@end

NS_ASSUME_NONNULL_END
