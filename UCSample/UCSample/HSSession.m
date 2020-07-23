//
//  Session.m
//  UCSample
//
//  Created by Joe Lepple on 5/1/15.
//  Copyright (c) 2015 PortSIP Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSSession.h"

@implementation HSSession

- (instancetype)init {
  self = [super init];
  if (self) {
    [self reset];
  }
  return self;
}

- (id)initWithSessionIdAndUUID:(long)sessionId
                      callUUID:(NSUUID *)uuid
                   remoteParty:(NSString *)remoteParty
                   displayName:(NSString *)displayName
                    videoState:(BOOL)video
                       callOut:(BOOL)outState {

  if (self = [super init]) {
    [self reset];
    _sessionId = sessionId;
    if (uuid == nil) {
      uuid = [NSUUID UUID];
    }
    _uuid = uuid;

    _orignalId = -1;
    _videoCall = video;
    _outgoing = outState;
  }

  return self;
}

- (void)reset {
  _uuid = nil;
  _groupUUID = nil;
  _sessionId = INVALID_SESSION_ID;
  _holdState = NO;
  _sessionState = NO;
  _conferenceState = NO;
  _recvCallState = NO;
  _isReferCall = NO;
  _orignalId = INVALID_SESSION_ID;
  _existEarlyMedia = NO;
  _videoCall = NO;
  _outgoing = NO;
  _callKitAnswered = NO;
  _callKitCompletionCallback = nil;
}

@end

