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

#import "ShareDataDB.h"
#import "YYModel.h"
#import "DataManager.h"
#import "TemporarySettings.h"
#import "SWRevealViewController.h"
#import "SettingsViewController+Neuron.h"
#import "ShareDataHost.h"

@interface ShareDataDB ()

@end

@implementation ShareDataDB

+ (instancetype)shared {
    static ShareDataDB *dataDB;
    if (!dataDB) {
        dataDB = [ShareDataDB new];
    }
    return dataDB;
}

- (NSURL *)groupUrl {
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupID];
    return url;
}

- (NSString *)readJsonStringFromPath:(NSString *)item {
    NSURL *fileUrl = [self.groupUrl URLByAppendingPathComponent:item];
    NSString *json = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:nil];
    return json;
}

- (NSData *)readDataFromPath:(NSString *)item {
    NSURL *fileUrl = [self.groupUrl URLByAppendingPathComponent:item];
    NSData *data = [NSData dataWithContentsOfURL:fileUrl];
    return data;
}

- (void)writeData:(NSData *)data toFile:(NSString *)item {
    NSURL *fileUrl = [self.groupUrl URLByAppendingPathComponent:item];
    BOOL success = [data writeToURL:fileUrl atomically:YES];
    if (success == true) {
        printf("write to sharedb success \n");
    }else{
        printf("write to sharedb failed \n");
    }
}

- (RzTemporaryApp *)currentLaunchGame {
    NSData *data = [self readDataFromPath:currentLaunchGamePath];
    RzTemporaryApp *app = [RzTemporaryApp yy_modelWithJSON:data];
    return app;
}

- (void)readSettingDataFromShareDB {
    NSData *data = [self readDataFromPath:frameSettingsPath];
    Log(LOG_I ,@"[read]data String: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    TemporarySettings *setting = [TemporarySettings yy_modelWithJSON:data];
    if (!data || !setting) {
        Log(LOG_E, @"Setting data:%@ setting:%@",data,setting);
        return;
    }
    
    //update data at local db
    DataManager* dataMan = [[DataManager alloc] init];
    
    //fix bug:when uniqueId is nil, settings data will fail to be stored.
    NSString *uniqueId = [dataMan getUniqueId];
    if (!uniqueId) [dataMan updateUniqueId:setting.uniqueId];
    
    [dataMan saveSettingsWithBitrate:setting.bitrate.integerValue
                           framerate:setting.framerate.integerValue
                              height:setting.height.integerValue
                               width:setting.width.integerValue
                         audioConfig:setting.audioConfig.integerValue
                    onscreenControls:setting.onscreenControls.integerValue
                       optimizeGames:setting.optimizeGames
                     multiController:setting.multiController
                     swapABXYButtons:setting.swapABXYButtons
                           audioOnPC:setting.playAudioOnPC
                      preferredCodec:setting.preferredCodec
                      useFramePacing:setting.useFramePacing
                           enableHdr:setting.enableHdr
                      btMouseSupport:setting.btMouseSupport
                   absoluteTouchMode:setting.absoluteTouchMode
                        statsOverlay:setting.statsOverlay];
    
    //update setting page's UI
    SWRevealViewController *revealVC = [self getSWRevealViewController];
    if (!revealVC) {
        Log(LOG_I ,@"[read]revealVC is nil:%@",revealVC);
    }
    SettingsViewController *settingVC = (SettingsViewController *)revealVC.rearViewController;
    if (settingVC) [settingVC updateSettingUI:setting];
    
}


- (void)writeSettingDataToShareDB {
    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings *setting = [dataMan getSettings];
    Log(LOG_I ,@"[write]data String:%@",[setting yy_modelToJSONString]);
    if (!setting) {
        Log(LOG_E, @"Setting is nil...");
        return;
    }
    
    NSData *data = [setting yy_modelToJSONData];
    [self writeData:data toFile:frameSettingsPath];
}

- (void)writeSettingDataToShareDB: (TemporarySettings *)setting {
    Log(LOG_I ,@"[write]data String:%@",[setting yy_modelToJSONString]);
    if (!setting) {
        Log(LOG_E, @"Setting is nil...");
        return;
    }
    
    NSData *data = [setting yy_modelToJSONData];
    [self writeData:data toFile:frameSettingsPath];
}

//save settings to db
- (void)saveSettings {
    SWRevealViewController *revealVC = [self getSWRevealViewController];
    if (!revealVC) {
        Log(LOG_I ,@"[saveSettings]revealVC is nil:%@",revealVC);
    }
    SettingsViewController *settingVC = (SettingsViewController *)revealVC.rearViewController;
    //Only when settingVC's view is loaded,prevent to save invalid setting values.
    if (settingVC.viewIfLoaded) [settingVC saveSettings];
}

- (void)saveFrameSettings:(NeuronFrameSettings *)settings {
    
    NSData *data = [settings yy_modelToJSONData];
    [self writeData:data toFile:frameSettingsPath];
}

- (NeuronFrameSettings *)readFrameSettings {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.groupUrl URLByAppendingPathComponent:frameSettingsPath].path] == false) {
        NeuronFrameSettings *settings = [[NeuronFrameSettings alloc] init];
        [self saveFrameSettings:settings];
    }
    NSData *data = [self readDataFromPath:frameSettingsPath];
    NeuronFrameSettings *settings = [NeuronFrameSettings yy_modelWithJSON:data];
    return settings;
}

- (void)wirteHostListDataToShareDB {
    
    //DataManager* dataMan = [[DataManager alloc] init];
    NSMutableArray *hostList = [[NSMutableArray alloc]initWithArray:[[SettingsRouter shared].dataManager getHosts]];
    NSMutableArray *pairedHostList = [[NSMutableArray alloc]init];
    for (TemporaryHost *host in hostList) {
        if ( [host pairState] == PairStatePaired) {
            
            ShareDataHost *shareHost = [[ShareDataHost alloc] init];
            [shareHost copyWith:host];
            [shareHost setServerCertDataBase64:[shareHost.serverCert base64Encoding]];
            [pairedHostList addObject:shareHost];
        }
    }
    NSArray *dataArray = [[NSArray alloc]initWithArray:pairedHostList];
    //printf("write to sharedb hostlist cout: %lu \n",(unsigned long)dataArray.count);
    NSLog(@"write share hosts count : %lu", (unsigned long)dataArray.count);
    NSData *data = [dataArray yy_modelToJSONData];
    [self writeData:data toFile:hostPath];
}

- (void)readHostListDataFromeShareDB {
    
    NSArray *hostList = [self getShareHostList];
    //DataManager* dataMan = [[DataManager alloc] init];
    NSArray *loaclArray = [[SettingsRouter shared].dataManager getHosts];
    //NSMutableArray *newArray = [[NSMutableArray alloc]init];
    NSLog(@"read share hosts count : %lu", (unsigned long)hostList.count);
    for (TemporaryHost *host in loaclArray) {
        [host setPairState:PairStateUnpaired];
        for (ShareDataHost *shareHost in hostList) {
            if ([shareHost isEqualHost:host]) {
                //[newArray addObject:shareHost];
                [host setPairState:PairStatePaired];
                if (host.serverCert.length < 1 &&  shareHost.serverCertDataBase64.length > 0) {
                    host.serverCert = [[NSData alloc] initWithBase64EncodedString:shareHost.serverCertDataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                }
            }
        }
        [[SettingsRouter shared].dataManager updateHost:host];
    }
    
    for (ShareDataHost *shareHost in hostList) {
        bool isInlist = false;
        for (TemporaryHost *host in loaclArray) {
            if ([shareHost isEqualHost:host]) {
                isInlist = true;
                break;
            }
        }
        if (isInlist == false) {
            if (shareHost.serverCert.length < 1 &&  shareHost.serverCertDataBase64.length > 0) {
                shareHost.serverCert = [[NSData alloc] initWithBase64EncodedString:shareHost.serverCertDataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
            }
            [[SettingsRouter shared].dataManager updateHost:shareHost];
        }
    }
    
    
}

- (void)removePairedHostFromeShareDB:(TemporaryHost *)host {
    NSArray *hostList = [self getShareHostList];
    NSMutableArray *newList = [[NSMutableArray alloc] init];
    for (ShareDataHost *tmpHost in hostList) {
        if ([tmpHost.uuid isEqualToString:host.uuid] == false){
            [newList addObject:tmpHost];
        }
    }
    NSArray *dataArray = [[NSArray alloc]initWithArray:newList];
    //printf("write to sharedb hostlist cout: %lu \n",(unsigned long)dataArray.count);
    NSLog(@"unapir host : %@ , write share hosts count : %lu", host.name,(unsigned long)dataArray.count);
    NSData *data = [dataArray yy_modelToJSONData];
    [self writeData:data toFile:hostPath];
}

- (NSDictionary *)readDevOptionsDataFromShareDB {
    NSError *error;
    NSData *data = [self readDataFromPath:devOptionsPath];
    Log(LOG_I ,@"[read]data String: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSDictionary *devOptions;
    if (data) {
        devOptions = [NSJSONSerialization JSONObjectWithData:data
                                                     options:kNilOptions
                                                       error:&error];
    } else {
        return nil;
    }
    
    if (error) {
        Log(LOG_I ,@"DevOptionsData read error: %@",error);
        return nil;
    } else {
        return devOptions;
    }
}

- (void)writeDevOptionsDataToshareDB:(NSDictionary *)devOptions  {
    NSError *error;
    NSData *devOptionsData = [NSJSONSerialization dataWithJSONObject:devOptions
                                                             options:kNilOptions
                                                               error:&error];
    
    if (error) {
        Log(LOG_I ,@"DevOptionsData error: %@",error);
    } else {
        [self writeData:devOptionsData toFile:devOptionsPath];
    }
}

- (NSArray *)readManuallyUnpairedHostDataFromShareDB {
    NSError *error;
    NSData *data = [self readDataFromPath:manuallyUnpairedHostPath];
    Log(LOG_I ,@"[read]data String: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSDictionary *manuallyUnpairedHostDic;
    if (data) {
        manuallyUnpairedHostDic = [NSJSONSerialization JSONObjectWithData:data
                                                     options:kNilOptions
                                                       error:&error];
    } else {
        return nil;
    }
    
    if (error) {
        Log(LOG_I ,@"readManuallyUnpairedHostDataFromShareDB read error: %@",error);
        return nil;
    } else {
        NSString *manuallyUnpairedHostString = manuallyUnpairedHostDic[@"manuallyUnpairedHost"];
        if (manuallyUnpairedHostString) {
            return [manuallyUnpairedHostString componentsSeparatedByString:@","];
        }
        return nil;
    }
}

- (void)writeManuallyUnpairedHostDataToshareDB:(NSString *)hostUuid  {
    NSMutableArray *hostUuidArray = [NSMutableArray arrayWithArray:[self readManuallyUnpairedHostDataFromShareDB]];
    if (hostUuidArray) {
        if ([hostUuidArray containsObject: hostUuid]) {
            return;
        } else {
            [hostUuidArray addObject:hostUuid];
        }
    } else {
        hostUuidArray = [NSMutableArray arrayWithArray:@[hostUuid]];
    }
    
    NSDictionary *manuallyUnpairedHostDic = @{@"manuallyUnpairedHost": [hostUuidArray componentsJoinedByString:@","]};
    NSError *error;
    NSData *manuallyUnpairedHostData = [NSJSONSerialization dataWithJSONObject:manuallyUnpairedHostDic
        options:kNilOptions
        error:&error];
    
    if (error) {
        Log(LOG_I ,@"writeManuallyUnpairedHostDataToshareDB error: %@",error);
    } else {
        [self writeData:manuallyUnpairedHostData toFile:manuallyUnpairedHostPath];
    }
}

- (NSArray *)getShareHostList {
    NSData *data = [self readDataFromPath:hostPath];
    NSArray *hostList = [NSArray yy_modelArrayWithClass:ShareDataHost.class json:data];
    return  hostList;
}

- (SWRevealViewController *)getSWRevealViewController {
    UINavigationController *rootNav = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    SWRevealViewController *revealVC = nil;
    for (UIViewController *vc in rootNav.viewControllers) {
        if ([vc isKindOfClass:[SWRevealViewController class]]) {
            revealVC = (SWRevealViewController *)vc;
            break;
        }
    }
    return revealVC;
}

- (NSURL *)fileUrlFromGroup:(NSString *)item {
    return [self.groupUrl URLByAppendingPathComponent:item];;
}

- (TemporarySettings *)getStreamingSettings {
    NSData *data = [self readDataFromPath:frameSettingsPath];
    Log(LOG_I ,@"[read]data String: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    TemporarySettings *setting = [TemporarySettings yy_modelWithJSON:data];
    return setting;
}

//- (void)updateHost:(TemporaryHost *)host {
//    NSMutableArray *hosts = [[self getShareHostList] mutableCopy];
//    for (TemporaryHost *old in hosts) {
//        if ([old.machineIdentifier isEqualToString:host.machineIdentifier]) {
//            old.uuid = host.uuid;
//            old.name = host.name;
//            old.localAddress = host.localAddress;
//            old.activeAddress = host.activeAddress;
//            old.address = host.address;
//            old.state = host.state;
//            break;
//        }
//    }
//    NSArray *dataArray = [[NSArray alloc] initWithArray:hosts];
//    //printf("write to sharedb hostlist cout: %lu \n",(unsigned long)dataArray.count);
//    NSLog(@"write share hosts count : %lu", (unsigned long)dataArray.count);
//    NSData *data = [dataArray yy_modelToJSONData];
//    [self writeData:data toFile:hostPath];
//}

@end
