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

#import "ShareDataHost.h"

@implementation ShareDataHost


- (void) copyWith:(TemporaryHost *)host {
    
    self.address = host.address;
    self.externalAddress = host.externalAddress;
    self.localAddress = host.localAddress;
    self.ipv6Address = host.ipv6Address;
    self.mac = host.mac;
    self.name = host.name;
    self.uuid = host.uuid;
    self.serverCodecModeSupport = host.serverCodecModeSupport;
    self.serverCert = host.serverCert;
    self.ipv6Address = host.ipv6Address;
    self.pairState = host.pairState;
    self.activeAddress = host.activeAddress;
    self.appList = host.appList;
    self.httpPort = host.httpPort;
    self.httpsPort = host.httpsPort;
    
}

- (BOOL)isEqualHost:(TemporaryHost *)host {
    return [host.uuid isEqual:self.uuid]; //([self.localAddress hasPrefix:host.localAddress] || [host.localAddress hasPrefix:self.localAddress]);
}

@end
