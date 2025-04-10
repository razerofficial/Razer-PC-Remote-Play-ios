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
#import "Utils.h"
#import "StreamConfiguration.h"
#import "TemporaryApp.h"

NS_ASSUME_NONNULL_BEGIN
#define TermOfServiceUrl @"https://www.razer.com/legal/services-and-software-terms-of-use-mobile"
#define PrivacyPolicyUrl @"https://www.razer.com/legal/customer-privacy-policy-mobile"
#define FAQUrl @"https://mysupport.razer.com/app/answers/detail/a_id/14919"

@interface RzUtils : NSObject
+ (void)setObject:(id)obj forKey:(NSString *)key;
+ (void)setTutorialCompleted:(NSInteger)count;
+ (NSInteger)getTutorialCompletedCount;
+ (void)setAcceptedTOS;

+ (BOOL)isAcceptedTOS;

+ (void)setRequestedLocalNetworkPermission;

+ (BOOL)isRequestedLocalNetworkPermission;

+ (void)setGrantedLocalNetworkPermission:(BOOL)isGranted;

+ (BOOL)isGrantedLocalNetworkPermission;

+ (BOOL)checkIsNexusInstalled;

+ (StreamConfiguration *) streamConfigForStreamApp:(TemporaryApp *)app;

+ (void)gotoNexus;

+ (NSUInteger)getCurrentTimestampInMilliseconds;

+ (void)setAlreadySetDisplayMode;

+ (BOOL)isAlreadySetDisplayMode;

+ (void)setAlreadyShowDownloadNexus;

+ (BOOL)isAlreadyShowDownloadNexus;

+ (void)setNeedContinueLaunchGame:(BOOL)isNeed;
+ (BOOL)isNeedContinueLaunchGame;

+ (TemporaryHost *)currentStreamingHost;

+ (NSString *)deviceName;

+ (BOOL)CheckIPAddressISValidWithIP: (NSString *)address;
@end

NS_ASSUME_NONNULL_END
