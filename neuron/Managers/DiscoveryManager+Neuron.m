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

#import "DiscoveryManager+Neuron.h"
#import "RzSwizzling.h"
#import "DiscoveryManager.h"
#import "RzUtils.h"

@implementation DiscoveryManager (Neuron)
+ (void)load {
    [self methodSwizzling];
}

+ (void)methodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RzSwizzling instanceTarget:[DiscoveryManager new] origSel:@selector(startDiscovery) swizzleSel:@selector(rz_startDiscovery)];
    });
}
- (void)rz_startDiscovery {
    [self rz_startDiscovery];
    [RzUtils setRequestedLocalNetworkPermission];
}
@end
