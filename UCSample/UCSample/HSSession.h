/*
    PortSIP 11.2
    Copyright (C) 2014 PortSIP Solutions, Inc.

    support@portsip.com

    Visit us at http://www.portsip.com
*/

#define LINE_BASE 0
#define MAX_LINES 8

@interface HSSession : NSObject
@property(nonatomic, retain) NSUUID *uuid;
@property(nonatomic, retain) NSUUID *groupUUID;
@property(nonatomic, assign) long sessionId;
@property(nonatomic, assign) BOOL holdState;
@property(nonatomic, assign) BOOL sessionState;
@property(nonatomic, assign) BOOL outgoing; // Yes:outgoing call No:incoming
                                            // call
@property(nonatomic, assign) BOOL conferenceState;
@property(nonatomic, assign) BOOL recvCallState;
@property(nonatomic, assign) BOOL isReferCall;
@property(nonatomic, assign) long orignalId;
@property(nonatomic, assign) BOOL existEarlyMedia;
@property(nonatomic, assign) BOOL videoCall;
@property(nonatomic, assign) BOOL callKitAnswered;
@property(nonatomic, strong) void (^callKitCompletionCallback)(BOOL);

- (void)reset;

- (id)initWithSessionIdAndUUID:(long)sessionId
                      callUUID:(NSUUID *)uuid
                   remoteParty:(NSString *)remoteParty
                   displayName:(NSString *)displayName
                    videoState:(BOOL)video
                       callOut:(BOOL)outState;
@end

