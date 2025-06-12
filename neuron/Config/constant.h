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

#ifndef constant_h
#define constant_h

static NSString *groupID = @"group.com.razer.kishiv2";
static NSString *frameSettingsPath = @"frameSettings.db";
static NSString *currentLaunchGamePath = @"currentLaunchGame.db";
static NSString *hostPath = @"host.db";
static NSString *statsPath = @"stats.txt";
static NSString *frameSettingsTXTPath = @"frameSetings.txt";
static NSString *devOptionsPath = @"devOptions.db";
static NSString *manuallyUnpairedHostPath = @"manuallyUnpairedHost.db";
static NSString *shareLogPath = @"shareLog.txt";
static NSString *neuronInfoPath = @"neuronInfo.db";
static NSString *neuronEventPath = @"neuronEvent.db";

//notifications
static NSString *kRetryStreamingNotification = @"retryStreamingNotification";
static NSString *kStreamingStatsUpdateNotification = @"streamingStatsUpdateNotification";

//UserDefault
static NSString *kIsNotFirstLaunch = @"IsNotFirstLaunch";
static NSString *kIsDebugMode = @"IsDebugMode";

static NSString *kNexusAppId = @"1565916457";

#define RZ_DEFAULT_HTTP_PORT 51337 //defalut http port
#define RZ_DEFAULT_HTTPS_PORT 51332 //51337 - 5

#define Localized(a) NSLocalizedString(a, a)

#endif /* constant_h */
