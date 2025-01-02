//
//  DiscoveryWorker.h
//  Moonlight
//
//  Created by Diego Waxemberg on 1/2/15.
//  Copyright (c) 2015 Moonlight Stream. All rights reserved.
//

#import "TemporaryHost.h"

@protocol DiscoveryWorkerDelegate <NSObject>

- (void)removeDuplicatedHost:(TemporaryHost *)host;

@end

@interface DiscoveryWorker : NSOperation

- (id) initWithHost:(TemporaryHost*)host uniqueId:(NSString*)uniqueId delegate:(id<DiscoveryWorkerDelegate>)delegate;
- (void) discoverHost;
- (TemporaryHost*) getHost;

@end
