//
//  PortCxProvider.h
//  PortGo
//
//  Created by portsip on 16/11/18.
//  Copyright © 2016 PortSIP Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>
#import "CallMananger.h"

NS_ASSUME_NONNULL_BEGIN

@interface PortCxProvider : NSObject

@property(nonatomic, strong) CXProvider *cxprovider;
@property(nonatomic, strong)
    dispatch_queue_t completionQueue; // Default to mainQueue
@property(nonatomic, retain) CallManager *callManager;

+ (PortCxProvider *)sharedInstance;

- (void)configurationCallProvider;
@end
NS_ASSUME_NONNULL_END
