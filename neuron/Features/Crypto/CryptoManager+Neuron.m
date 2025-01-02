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

#import "CryptoManager.h"
#import "HttpManager.h"
#import "RzSwizzling.h"
#import "ShareDataDB.h"
#import "CryptoManager+Neuron.h"

@implementation CryptoManager (Neuron)

+ (void)load {
    [self methodSwizzling];
}

+ (void)methodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RzSwizzling classTarget:[self class] origSel:@selector(readCryptoObject:) swizzleSel:@selector(rz_readCryptoObject:)];
        [RzSwizzling classTarget:[self class] origSel:@selector(writeCryptoObject:data:) swizzleSel:@selector(rz_writeCryptoObject:data:)];
        [RzSwizzling classTarget:[self class] origSel:@selector(keyPairExists) swizzleSel:@selector(rz_keyPairExists)];
    });
}

#pragma mark -- Swizzle methods
+ (NSData*)rz_readCryptoObject:(NSString*)item {
    Log(LOG_I, NSStringFromSelector(_cmd));
#if TARGET_OS_TV
    return [self rz_readCryptoObject:item];
#else
    return [[ShareDataDB shared] readDataFromPath:item];
#endif
}

+ (void)rz_writeCryptoObject:(NSString*)item data:(NSData*)data {
    Log(LOG_I, NSStringFromSelector(_cmd));
#if TARGET_OS_TV
    return [self rz_writeCryptoObject:item data:data];
#else
    return [[ShareDataDB shared] writeData:data toFile:item];
#endif
}
    
+ (bool)rz_keyPairExists {
    bool keyFileExists = [self readCryptoObject:@"client.key"].length != 0;
    bool p12FileExists = [self readCryptoObject:@"client.p12"].length != 0;
    bool certFileExists = [self readCryptoObject:@"client.crt"].length != 0;
    
    return keyFileExists && p12FileExists && certFileExists;
}

@end
