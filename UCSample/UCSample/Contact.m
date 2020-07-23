//
//  Contact.m
//  UCSample
//
//  Created by Joe Lepple on 6/14/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "Contact.h"

@implementation Contact

- (Contact *)initWithSubscribe:(long)subscribeid andSipURL:(NSString *)sipURL {
  if ((self = [super init])) {
    self.subscribeID = subscribeid;
    self.sipURL = sipURL;
    self.basicState = @"close";
    self.note = nil;
  }
  return self;
}
@end
