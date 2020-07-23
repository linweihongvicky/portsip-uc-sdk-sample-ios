//
//  CallMananger.m
//  PortGo
//
//  Created by portsip on 16/11/25.
//  Copyright © 2016 PortSIP Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CallKit/CallKit.h>
#import "CallMananger.h"
#import "PortCxProvide.h"

@implementation CXTransaction (PortCXTEX)

+ (CXTransaction *)transactionWithActions:(NSArray<CXAction *> *)actions {
  CXTransaction *transcation = [[CXTransaction alloc] init];
  for (CXAction *action in actions) {
    [transcation addAction:action];
  }
  return transcation;
}

@end

@implementation CallManager {
  PortSIPSDK *_portSIPSDK;
  BOOL _enableCallKit;

  HSSession *_sessionArray[MAX_LINES];

  DTMF_METHOD _playDTMFMethod;
  BOOL _playDTMFTone;

  NSUUID *_conferenceGroupID;

  CXCallController *_callController;
}

- (id _Nonnull)initWithSDK:(PortSIPSDK *)portsipSdk {
  if (self = [super init]) {
    _portSIPSDK = portsipSdk;
    _isConference = false;

    _playDTMFMethod = DTMF_RFC2833;
    _playDTMFTone = YES;

    _conferenceGroupID = nil;

    _callController = [[CXCallController alloc] init];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
      _enableCallKit = YES;
    } else {
      _enableCallKit = NO;
    }
    // Force disable CallKit
    //_enableCallKit = NO;

    [_portSIPSDK enableCallKit:_enableCallKit];
  }

  return self;
}

- (void)setEnableCallKit:(BOOL)enableCallKit {
  @synchronized(self) {
    if (_enableCallKit == enableCallKit) {
      return;
    }
    _enableCallKit = enableCallKit;
    [_portSIPSDK enableCallKit:_enableCallKit];
  }
}

- (BOOL)enableCallKit {
  @synchronized(self) {
    return _enableCallKit;
  }
}

- (void)setPlayDTMFMethod:(DTMF_METHOD)dtmfMethod
             playDTMFTone:(BOOL)playDTMFTone {
  _playDTMFMethod = dtmfMethod;
  _playDTMFTone = playDTMFTone;
}

#pragma mark - CallKit Manager
- (void)requestTransaction:(NSArray<CXAction *> *)actions {
  [_callController
      requestTransaction:[CXTransaction transactionWithActions:actions]
              completion:^(NSError *_Nullable error) {
                if (error != nil) {
                  NSLog(@"Error requesting transaction, code:%ld error:%@",
                        (long)error.code, error.domain);
                } else {
                  NSLog(@"Requested transaction successfully");
                }
              }];
}

- (void)reportOutgoingCall:(NSUUID *)uuid
                    number:(NSString *)number
                 videoCall:(BOOL)video {
  CXHandle *handle =
      [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:number];

  // Fallback on earlier versions

  CXStartCallAction *startCallAction =
      [[CXStartCallAction alloc] initWithCallUUID:uuid handle:handle];

  startCallAction.video = video;

  [self requestTransaction:@[ startCallAction ]];
}

- (void)reportInComingCall:(NSUUID *)uuid
                  hasVideo:(BOOL)hasVideo
                      from:(NSString *)from
                completion:(PortCxProviderCompletion)completion {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;

  CXHandle *handle =
      [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
  CXCallUpdate *update = [[CXCallUpdate alloc] init];
  update.remoteHandle = handle;
  update.hasVideo = hasVideo;
  update.supportsGrouping = true;
  update.supportsDTMF = true;
  update.supportsUngrouping = true;

  [[PortCxProvider sharedInstance].cxprovider
      reportNewIncomingCallWithUUID:uuid
                             update:update
                         completion:completion];
}

- (void)reportUpdateCall:(NSUUID *)uuid
                hasVideo:(BOOL)hasVideo
                    from:(NSString *)from {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;

  CXHandle *handle =
      [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
  CXCallUpdate *update = [[CXCallUpdate alloc] init];
  update.remoteHandle = handle;
  update.hasVideo = hasVideo;
  update.supportsGrouping = true;
  update.supportsDTMF = true;
  update.supportsUngrouping = true;
  update.localizedCallerName = from;

  [[PortCxProvider sharedInstance].cxprovider reportCallWithUUID:uuid
                                                         updated:update];
}

- (void)reportAnswerCall:(NSUUID *)uuid {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;
  CXAnswerCallAction *answerCallAction =
      [[CXAnswerCallAction alloc] initWithCallUUID:uuid];

  [self requestTransaction:@[ answerCallAction ]];
}

- (void)reportEndCall:(NSUUID *)uuid {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;
  CXEndCallAction *endCallAction =
      [[CXEndCallAction alloc] initWithCallUUID:result.uuid];

  [self requestTransaction:@[ endCallAction ]];
}

- (void)reportSetHeldCall:(NSUUID *)uuid onHold:(BOOL)onHold {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;

  CXSetHeldCallAction *setHeldCallAction =
      [[CXSetHeldCallAction alloc] initWithCallUUID:result.uuid onHold:onHold];

  [self requestTransaction:@[ setHeldCallAction ]];
}

- (void)reportSetMutedCall:(NSUUID *)uuid muted:(BOOL)muted {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;

  if (result.sessionState) {
    CXSetMutedCallAction *setMutedCallAction =
        [[CXSetMutedCallAction alloc] initWithCallUUID:result.uuid muted:muted];
    [self requestTransaction:@[ setMutedCallAction ]];
  }
}

- (void)reportJoninConference:(NSUUID *)uuid {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil || nil != _conferenceGroupID)
    return;

  CXSetGroupCallAction *setGroupCallAction =
      [[CXSetGroupCallAction alloc] initWithCallUUID:uuid
                                 callUUIDToGroupWith:_conferenceGroupID];

  [self requestTransaction:@[ setGroupCallAction ]];
}

- (void)reportRemoveFromConference:(NSUUID *)uuid {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil || nil != _conferenceGroupID)
    return;

  CXSetGroupCallAction *setGroupCallAction =
      [[CXSetGroupCallAction alloc] initWithCallUUID:uuid
                                 callUUIDToGroupWith:nil];

  [self requestTransaction:@[ setGroupCallAction ]];
}

- (void)reportPlayDtmf:(NSUUID *)uuid tone:(int)tone {
  HSSession *result = [self findCallByUUID:uuid];
  NSString *digits;
  if (tone == 10) {
    digits = @"*";
  } else if (tone == 11) {
    digits = @"#";
  } else {
    digits = [NSString stringWithFormat:@"%d", tone];
  }
  if (result == nil)
    return;
  CXPlayDTMFCallAction *dtmfCallAction = [[CXPlayDTMFCallAction alloc]
      initWithCallUUID:result.uuid
                digits:digits
                  type:CXPlayDTMFCallActionTypeSingleTone];

  [self requestTransaction:@[ dtmfCallAction ]];
}

#pragma mark - Call Manager interface
- (long)makeCall:(NSString *)callee videoCall:(BOOL)videoCall {
  int num = [self getConnectCallNum];
  if (num >= MAX_LINES) {
    return INVALID_SESSION_ID;
  }

  long sessionId =
      [self makeCallWithUUID:callee videoCall:videoCall callUUID:nil];

  HSSession *session = [self findCallBySessionID:sessionId];

  if (session != nil && _enableCallKit) {
    [self reportOutgoingCall:session.uuid number:callee videoCall:videoCall];
    NSLog(@"reportOutgoingCall uuid =%@", session.uuid);
  }

  return sessionId;
}

- (void)incomingCall:(long)sessionId
              existsVideo:(BOOL)existsVideo
              remoteParty:(NSString *_Nonnull)remoteParty
        remoteDisplayName:(NSString *_Nonnull)remoteDisplayName
                 callUUID:(NSUUID *)uuid
    withCompletionHandler:(void (^)(void))completion {
  HSSession *session = [self findCallByUUID:uuid];
  if (session) { // This session is exists, update it.
    session.sessionId = sessionId;
    session.videoCall = existsVideo;

    if (_enableCallKit) {
      // Update CallKit incoming call UI Caller Name and audio/video, if the
      // Caller Name not change, not need update.
      if (session.callKitAnswered) { // the call is answered by callKit, answer
                                     // the call
        BOOL bRet = [self answerCallWithUUID:session.uuid isVideo:existsVideo];
        if (session.callKitCompletionCallback) {
          session.callKitCompletionCallback(bRet);
        }
        NSLog(@"CallKit is answered call, do the answer now");
      }

      [self reportUpdateCall:session.uuid
                    hasVideo:existsVideo
                        from:remoteParty];
    }
  } else {
    session = [[HSSession alloc] initWithSessionIdAndUUID:sessionId
                                                 callUUID:uuid
                                              remoteParty:remoteParty
                                              displayName:remoteDisplayName
                                               videoState:existsVideo
                                                  callOut:NO];
    [self addCall:session];

    if (_enableCallKit) {
      //[self startAudio];
      [self reportInComingCall:session.uuid
                      hasVideo:existsVideo
                          from:remoteParty
                    completion:^(NSError *_Nullable error) {
                      if (error != nil) {
                        [self hungUpCallWithUUID:session.uuid];
                        NSLog(@"incomingCall: %@", error);
                      } else {
                        NSLog(@"incomingCall");
                      }
                      if (completion) {
                        completion();
                      }
                    }];
    } else { // < iOS 10
      [_delegate onIncomingCallWithoutCallKit:sessionId
                                  existsVideo:existsVideo
                                  remoteParty:remoteParty
                            remoteDisplayName:remoteDisplayName];
    }
  }
}

- (BOOL)answerCall:(long)sessionId isVideo:(BOOL)isVideo {

  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil) {
    NSLog(@"Not exist this SessionId = %ld", sessionId);
    return NO;
  }

  if (_enableCallKit) {
    session.videoCall = isVideo;
    [self reportAnswerCall:session.uuid];
    return YES;
  } else {
    return [self answerCallWithUUID:session.uuid isVideo:isVideo];
  }
}

- (void)endCall:(long)sessionId {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (_enableCallKit) {
    [self reportEndCall:session.uuid];
  } else {
    [self hungUpCallWithUUID:session.uuid];
  }
};

- (void)holdCall:(long)sessionId onHold:(BOOL)onHold {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (!session.sessionState ||
      session.holdState ==
          onHold) { // Call isn't connected, or hold isn't change

    return;
  }

  //[self holdCallWithUUID:session.uuid onHold:onHold];
  ///*
  if (_enableCallKit) {
    [self reportSetHeldCall:session.uuid onHold:onHold];
  } else {
    [self holdCallWithUUID:session.uuid onHold:onHold];
  } //*/
}

- (void)holdAllCall:(BOOL)onHold {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && _sessionArray[i].sessionState &&
        _sessionArray[i].holdState != onHold) {
      [self holdCall:_sessionArray[i].sessionId onHold:onHold];
    }
  }
}

- (void)muteCall:(long)sessionId muted:(BOOL)muted {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (!session.sessionState) { // Call isn't connected
    return;
  }

  if (_enableCallKit) {
    [self reportSetMutedCall:session.uuid muted:muted];
  } else {
    [self muteCallWithUUID:session.uuid muted:muted];
  }
}

- (void)muteAllCall:(BOOL)muted {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && _sessionArray[i].sessionState) {
      [self muteCall:_sessionArray[i].sessionId muted:muted];
    }
  }
}

- (void)playDtmf:(long)sessionId tone:(int)tone {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (!session.sessionState) { // Call isn't connected
    return;
  }

  [self playDTMFWithUUID:session.uuid dtmf:tone];
  /*
  if (_enableCallKit)  {
      [self reportPlayDtmf:session.uuid tone:tone];
  }else{
      [self playDTMFWithUUID:session.uuid dtmf:tone];
  }*/
}

- (BOOL)createConference:(PortSIPVideoRenderView *)conferenceVideoWindow
              videoWidth:(int)videoWidth
             videoHeight:(int)videoHeight
       displayLocalVideo:(BOOL)displayLocalVideoInConference {
  if (_isConference) {
    // has created conference;
    return NO;
  }

  int ret = 0;
  if (conferenceVideoWindow != nil && videoWidth > 0 && videoHeight > 0) {
    ret = [_portSIPSDK createVideoConference:conferenceVideoWindow
                                  videoWidth:videoWidth
                                 videoHeight:videoHeight
                           displayLocalVideo:displayLocalVideoInConference];
  } else {
    ret = [_portSIPSDK createAudioConference];
  }

  if (ret != 0) {
    _isConference = NO;
    return NO;
  }

  _isConference = YES;
  _conferenceGroupID = [NSUUID UUID];

  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil) {
      // Join all exist call to conference
      [_portSIPSDK setRemoteVideoWindow:_sessionArray[i].sessionId
                      remoteVideoWindow:nil];
      [self joinToConference:_sessionArray[i].sessionId];
    }
  }

  return YES;
}

- (void)joinToConference:(long)sessionId {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (!session.sessionState) { // Call isn't connected
    return;
  }

  if (!_isConference) { // Conference not creaed
    return;
  }

  [self joinToConferenceWithUUID:session.uuid];
  if (_enableCallKit) {
    [self reportJoninConference:session.uuid];
  }
}

- (void)removeFromConference:(long)sessionId {
  HSSession *session = [self findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if (!_isConference) { // Conference not creaed
    return;
  }

  if (_enableCallKit) {
    [self reportRemoveFromConference:session.uuid];
  } else {
    [self removeFromConferenceWithUUID:session.uuid];
  }
}

- (void)destoryConference {
  if (_isConference) {

    for (int i = 0; i < MAX_LINES; i++) {
      if (_sessionArray[i] != nil) {
        // Remove all exist call from conference
        [self removeFromConference:_sessionArray[i].sessionId];
      }
    }

    [_portSIPSDK destroyConference];
    _conferenceGroupID = nil;
    _isConference = false;
    NSLog(@"DestoryConference");
  }
}

#pragma mark - Call Manager implementation
- (long)makeCallWithUUID:(NSString *)callee
               videoCall:(BOOL)videoCall
                callUUID:(NSUUID *)uuid {
  HSSession *session = [self findCallByUUID:uuid];
  if (session) { // This is in APP outgoing call, has created session
    return session.sessionId;
  }

  int num = [self getConnectCallNum];
  if (num >= MAX_LINES) {
    return INVALID_SESSION_ID;
  }

  long sessionId = [_portSIPSDK call:callee sendSdp:TRUE videoCall:videoCall];

  if (sessionId <= 0) {
    return sessionId;
  }

  session = [[HSSession alloc] initWithSessionIdAndUUID:sessionId
                                               callUUID:uuid
                                            remoteParty:callee
                                            displayName:callee
                                             videoState:videoCall
                                                callOut:YES];

  [self addCall:session];

  [_delegate onNewOutgoingCall:sessionId];

  return session.sessionId;
}

- (BOOL)answerCallWithUUID:(NSUUID *)uuid isVideo:(BOOL)isVideo {
  HSSession *sessionCall = [self findCallByUUID:uuid];
  if (sessionCall == nil)
    return NO;

  if (sessionCall.sessionId ==
      INVALID_SESSION_ID) { // this call is show by VoIP PUSH, but not received
                            // INVITE message, can't answer now,
    // set a flag, when received INVITE message, auto answer call.
    sessionCall.callKitAnswered = YES;
    [self reportUpdateCall:sessionCall.uuid
                  hasVideo:sessionCall.videoCall
                      from:@"Connecting Call..."];
    NSLog(@"ANSWER CALL not ready, waiting INVITE message");
    return YES;
  }

  int nRet = 0;
  if (!sessionCall.outgoing) { // Answer incoming Call
    nRet = [_portSIPSDK answerCall:sessionCall.sessionId videoCall:isVideo];
  } else { // outgoing call remote answer
  }
  if (nRet == 0) {
    sessionCall.sessionState = YES;
    sessionCall.videoCall = isVideo;

    if (isVideo) {
    }

    if (_isConference) {
      [self joinToConference:sessionCall.sessionId];
    }

    [_delegate onAnsweredCall:sessionCall.sessionId];
    NSLog(@"Answer Call on session %ld ", sessionCall.sessionId);

    return YES;
  } else {
    [_delegate onCloseCall:sessionCall.sessionId];
    NSLog(@"Answer Call on session %ld Failed! ret=%d", sessionCall.sessionId,
          nRet);
    return NO;
  }
}

- (void)hungUpCallWithUUID:(NSUUID *)uuid {
  HSSession *sessionCall = [self findCallByUUID:uuid];
  if (sessionCall == nil) {
    return;
  }

  if (_isConference) {
    [self removeFromConference:sessionCall.sessionId];
  }

  if (sessionCall.sessionState) { // Incoming/Outgoing Call is connected, fire
                                  // by hangupCall or onInviteClosed
    [_portSIPSDK hangUp:sessionCall.sessionId];
    if (sessionCall.videoCall) {
    }
    NSLog(@"Hungup call on session %ld", sessionCall.sessionId);
  } else if (sessionCall.outgoing) { // Outgoing call, fire by onInviteFailure
    [_portSIPSDK hangUp:sessionCall.sessionId];
    NSLog(@"Invite call Failure on session %ld", sessionCall.sessionId);
  } else { // Incoming call, reject call by user.
    [_portSIPSDK rejectCall:sessionCall.sessionId code:486];
    NSLog(@"Rejected call on session %ld", sessionCall.sessionId);
  }

  [_delegate onCloseCall:sessionCall.sessionId];
}

- (void)holdCallWithUUID:(NSUUID *)uuid onHold:(BOOL)onHold {
  HSSession *session = [self findCallByUUID:uuid];
  if (session == nil) {
    return;
  }

  if (!session.sessionState ||
      session.holdState ==
          onHold) { // Call isn't connected, or hold isn't change
    return;
  }

  if (onHold) {
    [_portSIPSDK hold:session.sessionId];
    session.holdState = true;
    NSLog(@"Hold call on session: %ld", session.sessionId);
  } else {
    [_portSIPSDK unHold:session.sessionId];
    session.holdState = false;
    NSLog(@"UnHold call on session: %ld", session.sessionId);
  }
  [_delegate onHoldCall:session.sessionId onHold:onHold];
}

- (void)muteCallWithUUID:(NSUUID *)uuid muted:(BOOL)muted {
  HSSession *session = [self findCallByUUID:uuid];
  if (session == nil)
    return;
  if (session.sessionState) {
    if (muted) { // mute Microphone and video
      [_portSIPSDK muteSession:session.sessionId
             muteIncomingAudio:false
             muteOutgoingAudio:true
             muteIncomingVideo:false
             muteOutgoingVideo:true];
    } else { // unmute Microphone and video
      [_portSIPSDK muteSession:session.sessionId
             muteIncomingAudio:false
             muteOutgoingAudio:false
             muteIncomingVideo:false
             muteOutgoingVideo:false];
    }

    [_delegate onMuteCall:session.sessionId muted:muted];
  }
}

- (void)playDTMFWithUUID:(NSUUID *)uuid dtmf:(int)dtmf {
  HSSession *result = [self findCallByUUID:uuid];
  if (result == nil)
    return;

  if (result.sessionState) {
    [_portSIPSDK sendDtmf:result.sessionId
               dtmfMethod:_playDTMFMethod
                     code:dtmf
              dtmfDration:160
             playDtmfTone:_playDTMFTone];
  }
}

- (void)joinToConferenceWithUUID:(NSUUID *)uuid {
  HSSession *session = [self findCallByUUID:uuid];
  if (session == nil)
    return;

  if (_isConference) {

    if (session.sessionState) {
      if (session.holdState) {
        [self holdCall:session.sessionId onHold:NO];

        //[_portSIPSDK unHold:session.sessionId];
        session.holdState = false;
      }

      [_portSIPSDK joinToConference:session.sessionId];
    }
  }
}

- (void)removeFromConferenceWithUUID:(NSUUID *)uuid {
  HSSession *session = [self findCallByUUID:uuid];
  if (session == nil)
    return;

  if (_isConference) {
    [_portSIPSDK removeFromConference:session.sessionId];
  }
}

#pragma mark - Session Array Controller
- (HSSession *)findAnotherCall:(long)sessionID {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && _sessionArray[i].sessionId != sessionID) {
      return _sessionArray[i];
    }
  }

  return nil;
}

- (HSSession *)findCallBySessionID:(long)sessionID {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && _sessionArray[i].sessionId == sessionID) {
      return _sessionArray[i];
    }
  }
  return nil;
}

- (HSSession *)findCallByOrignalSessionID:(long)orignalId {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && _sessionArray[i].sessionId == orignalId) {
      return _sessionArray[i];
    }
  }
  return nil;
}

- (HSSession *)findCallByUUID:(NSUUID *)uuid {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil && [_sessionArray[i].uuid isEqual:uuid]) {
      return _sessionArray[i];
    }
  }
  return nil;
}

- (int)addCall:(HSSession *)call {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] == nil) {
      _sessionArray[i] = call;
      return i;
    }
  }

  return -1;
}

- (void)removeCall:(HSSession *)call {

  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] == call) {
      _sessionArray[i] = nil;
    }
  }
}

- (void)clear {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil) {
      [_portSIPSDK hangUp:_sessionArray[i].sessionId];
      _sessionArray[i] = nil;
    }
  }
}

- (int)getConnectCallNum {
  int num = 0;
  for (int i = 0; i < MAX_LINES; i++) {
    if (_sessionArray[i] != nil) {
      num++;
    }
  }

  return num;
}

#pragma mark - Audio Controller

- (void)startAudio {
  NSLog(@"_portSIPSDK startAudio");

  if (_portSIPSDK) {
    [_portSIPSDK startAudio];
  }
}

- (void)stopAudio {
  NSLog(@"_portSIPSDK stopAudio");
  if (_portSIPSDK) {
    [_portSIPSDK stopAudio];
  }
}

@end
