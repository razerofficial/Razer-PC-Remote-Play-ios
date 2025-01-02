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

#import "RzTemporaryApp.h"
#import "YYModel.h"
#import "Moonlight-Swift.h"
#import "DiscoveryWorker.h"

@implementation RzTemporaryApp

- (TemporaryApp *)convert2TemporaryApp {
    NSString *json = [self yy_modelToJSONString];
    TemporaryApp *app = [TemporaryApp yy_modelWithJSON:json];
    app.host.serverCert = [[NSData alloc] initWithBase64EncodedString:self.host.serverCertDataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    DiscoveryWorker* worker = [[DiscoveryWorker alloc] initWithHost:app.host uniqueId:@"0123456789ABCDEF"];
//    [worker discoverHost];
        
//    if (NetworkMonitor.shared.isWifi == true) {
//        if (app.host.activeAddress.length < 1 ){
//            app.host.activeAddress = app.host.localAddress;
//        }
//    }else{
//        app.host.activeAddress = app.host.externalAddress;
//    }
//        
//    app.host.serverCert = [[NSData alloc] initWithBase64EncodedString:self.host.serverCertDataBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return app;
}

@end
