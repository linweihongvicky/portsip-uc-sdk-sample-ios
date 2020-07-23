//
//  Contact.h
//  UCSample
//
//  Created by Joe Lepple on 6/14/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject {
}
@property long subscribeID;
@property(nonatomic, retain) NSString *sipURL;
@property(nonatomic, retain) NSString *basicState;
@property(nonatomic, retain) NSString *note;

- (Contact *)initWithSubscribe:(long)_subscribeid andSipURL:(NSString *)_sipURL;
@end
