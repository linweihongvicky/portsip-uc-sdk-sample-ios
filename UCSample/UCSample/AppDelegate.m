//
//  AppDelegate.m
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "SoundService.h"
#import "Reachability.h"
#import <Intents/Intents.h>
#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <UIApplicationDelegate, PKPushRegistryDelegate,
                           PortSIPEventDelegate, 
                           UNUserNotificationCenterDelegate,
                           LineViewControllerDelegate, CallManagerDelegate> {
  SoundService *_mSoundService;
  Reachability *internetReach;
  long _activeSessionId;
  long _lineSessions[MAX_LINES];

  NSString *_VoIPPushToken; // for VoIP call
  NSString *_APNsPushToken; // for message
  UIBackgroundTaskIdentifier _backtaskIdentifier;
}
- (NSString *)stringFromDeviceToken:(NSData *)deviceToken;
@end

@implementation AppDelegate

+ (AppDelegate *)sharedInstance {
  return ((AppDelegate *)[[UIApplication sharedApplication] delegate]);
}

- (int)findSession:(long)sessionId {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_lineSessions[i] == sessionId) {
      return i;
    }
  }
  NSLog(@"Can't find session, Not exist this SessionId = %ld", sessionId);
  return -1;
};

- (int)findIdleLine {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_lineSessions[i] == INVALID_SESSION_ID) {
      return i;
    }
  }
  NSLog(@"No idle line available. All lines are in use.");
  return -1;
};

- (void)freeLine:(long)sessionId {
  for (int i = 0; i < MAX_LINES; i++) {
    if (_lineSessions[i] == sessionId) {
      _lineSessions[i] = INVALID_SESSION_ID;
      return;
    }
  }
  NSLog(@"Can't Free Line, Not exist this SessionId = %ld", sessionId);
};

- (void)pressNumpadButton:(char)dtmf {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [_callManager playDtmf:_activeSessionId tone:dtmf];
  }
}

- (long)makeCall:(NSString *)callee videoCall:(BOOL)videoCall {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [self showAlertView:@"Warning" message:@"Current line is busy now, please switch a line"];

    return INVALID_SESSION_ID;
  }

  long newSessionId = [_callManager makeCall:callee videoCall:videoCall];
  if (newSessionId >= 0) {
    [numpadViewController
        setStatusText:[NSString stringWithFormat:@"Calling:%@ on line %zd",
                                                 callee, _activeLine]];
    _activeSessionId = newSessionId;
    return _activeSessionId;
  } else {
    [numpadViewController
        setStatusText:[NSString
                          stringWithFormat:@"make call failure ErrorCode =%zd",
                                           newSessionId]];
    return newSessionId;
  }
}

- (void)hungUpCall {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [_mSoundService stopRingTone];
    [_mSoundService stopRingBackTone];

    [_callManager endCall:_activeSessionId];

    [numpadViewController
        setStatusText:[NSString stringWithFormat:@"Hungup call on line %zd",
                                                 _activeLine]];
  }
}

- (void)holdCall {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [_callManager holdCall:_activeSessionId onHold:YES];
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"hold call on line %zd",
                                               _activeLine]];

  if (_isConference) {
    [_callManager holdAllCall:YES];
  }
}

- (void)unholdCall {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [_callManager holdCall:_activeSessionId onHold:NO];
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"UnHold the call on line %zd",
                                               _activeLine]];

  if (_isConference) {
    [_callManager holdAllCall:NO];
  }
}

- (void)referCall:(NSString *)referTo {
  HSSession *session = [_callManager findCallBySessionID:_activeSessionId];
  if (session == nil || !session.sessionState) {
    [self showAlertView:@"Warning" message:@"Need to make the call established first"];
    return;
  }

  int errorCodec = [portSIPSDK refer:_activeSessionId referTo:referTo];
  if (errorCodec != 0) {
    [self showAlertView:@"Warning" message:@"Refer failed"];
  }
}

- (void)getStatistics {
  {
    // audio Statistics
    int sendBytes;
    int sendPackets;
    int sendPacketsLost;
    int sendFractionLost;
    int sendRttMS;
    int sendCodecType;
    int sendJitterMS;
    int sendAudioLevel;
    int recvBytes;
    int recvPackets;
    int recvPacketsLost;
    int recvFractionLost;
    int recvCodecType;
    int recvJitterMS;
    int recvAudioLevel;

    int errorCodec = [portSIPSDK getAudioStatistics:_activeSessionId
                                          sendBytes:&sendBytes
                                        sendPackets:&sendPackets
                                    sendPacketsLost:&sendPacketsLost
                                   sendFractionLost:&sendFractionLost
                                          sendRttMS:&sendRttMS
                                      sendCodecType:&sendCodecType
                                       sendJitterMS:&sendJitterMS
                                     sendAudioLevel:&sendAudioLevel
                                          recvBytes:&recvBytes
                                        recvPackets:&recvPackets
                                    recvPacketsLost:&recvPacketsLost
                                   recvFractionLost:&recvFractionLost
                                      recvCodecType:&recvCodecType
                                       recvJitterMS:&recvJitterMS
                                     recvAudioLevel:&recvAudioLevel];

    if (errorCodec == 0) {
      NSLog(@"Audio Send Statistics sendBytes:%d sendPackets:%d "
            @"sendPacketsLost:%d sendFractionLost:%d sendRttMS:%d "
            @"sendCodecType:%d sendJitterMS:%d sendAudioLevel:%d ",
            sendBytes, sendPackets, sendPacketsLost, sendFractionLost,
            sendRttMS, sendCodecType, sendJitterMS, sendAudioLevel);
      NSLog(@"Audio Received Statistics recvBytes:%d recvPackets:%d "
            @"recvPacketsLost:%d recvFractionLost:%d recvCodecType:%d "
            @"recvJitterMS:%d recvAudioLevel:%d",
            recvBytes, recvPackets, recvPacketsLost, recvFractionLost,
            recvCodecType, recvJitterMS, recvAudioLevel);
    }
  }

  {
    // Video Statistics
    int sendBytes;
    int sendPackets;
    int sendPacketsLost;
    int sendFractionLost;
    int sendRttMS;
    int sendCodecType;
    int sendFrameWidth;
    int sendFrameHeight;
    int sendBitrateBPS;
    int sendFramerate;
    int recvBytes;
    int recvPackets;
    int recvPacketsLost;
    int recvFractionLost;
    int recvCodecType;
    int recvFrameWidth;
    int recvFrameHeight;
    int recvBitrateBPS;
    int recvFramerate;

    int errorCodec = [portSIPSDK getVideoStatistics:_activeSessionId
                                          sendBytes:&sendBytes
                                        sendPackets:&sendPackets
                                    sendPacketsLost:&sendPacketsLost
                                   sendFractionLost:&sendFractionLost
                                          sendRttMS:&sendRttMS
                                      sendCodecType:&sendCodecType
                                     sendFrameWidth:&sendFrameWidth
                                    sendFrameHeight:&sendFrameHeight
                                     sendBitrateBPS:&sendBitrateBPS
                                      sendFramerate:&sendFramerate
                                          recvBytes:&recvBytes
                                        recvPackets:&recvPackets
                                    recvPacketsLost:&recvPacketsLost
                                   recvFractionLost:&recvFractionLost
                                      recvCodecType:&recvCodecType
                                     recvFrameWidth:&recvFrameWidth
                                    recvFrameHeight:&recvFrameHeight
                                     recvBitrateBPS:&recvBitrateBPS
                                      recvFramerate:&recvFramerate];

    if (errorCodec == 0) {
      NSLog(@"Video Send Statistics sendBytes:%d sendPackets:%d "
            @"sendPacketsLost:%d sendFractionLost:%d sendRttMS:%d "
            @"sendCodecType:%d sendFrameWidth:%d sendFrameHeight:%d "
            @"sendBitrateBPS:%d sendFramerate:%d ",
            sendBytes, sendPackets, sendPacketsLost, sendFractionLost,
            sendRttMS, sendCodecType, sendFrameWidth, sendFrameHeight,
            sendBitrateBPS, sendFramerate);
      NSLog(@"Video Received Statistics  recvBytes:%d recvPackets:%d "
            @"recvPacketsLost:%d recvFractionLost:%d recvCodecType:%d "
            @"recvFrameWidth:%d recvFrameHeight:%d recvBitrateBPS:%d "
            @"recvFramerate:%d",
            recvBytes, recvPackets, recvPacketsLost, recvFractionLost,
            recvCodecType, recvFrameWidth, recvFrameHeight, recvBitrateBPS,
            recvFramerate);
    }
  }
}

- (void)updateCall {
  [portSIPSDK updateCall:_activeSessionId enableAudio:YES enableVideo:YES];
}

- (void)makeTest {
  //[portSIPSDK audioPlayLoopbackTest:YES];
    [portSIPSDK enableAudioStreamCallback:_activeSessionId enable:YES callbackMode:AUDIOSTREAM_REMOTE_PER_CHANNEL];
}

- (void)attendedRefer:(NSString *)referTo {
  HSSession *session = [_callManager findAnotherCall:_activeSessionId];
  if (session) {
    [portSIPSDK attendedRefer:_activeSessionId
             replaceSessionId:session.sessionId
                      referTo:referTo];
  }
}

- (void)muteCall:(BOOL)mute {
  if (_activeSessionId != INVALID_SESSION_ID) {
    [_callManager muteCall:_activeSessionId muted:mute];
  }

  if (_isConference) {
    [_callManager muteAllCall:mute];
  }
}

- (void)setLoudspeakerStatus:(BOOL)enable {
  [portSIPSDK setLoudspeakerStatus:enable];
}

- (BOOL)createConference:(PortSIPVideoRenderView *)conferenceVideoWindow {
  if ([_callManager createConference:conferenceVideoWindow
                          videoWidth:352
                         videoHeight:288
                   displayLocalVideo:YES]) {
    _isConference = YES;
    return YES;
  };
  return NO;
}

- (void)setConferenceVideoWindow:
    (PortSIPVideoRenderView *)conferenceVideoWindow {
  [portSIPSDK setConferenceVideoWindow:conferenceVideoWindow];
}

- (void)destoryConference:(UIView *)viewRemoteVideo {
  [_callManager destoryConference];
  HSSession *session = [_callManager findCallBySessionID:_activeSessionId];
  if (session && session.holdState) {
    [_callManager holdCall:session.sessionId onHold:NO];
  }
  _isConference = NO;
}

- (void)didSelectLine:(NSInteger)activeLine {
  UITabBarController *tabBarController =
      (UITabBarController *)self.window.rootViewController;

  [tabBarController dismissViewControllerAnimated:YES completion:nil];

  if (!sipRegistered || _activeLine == activeLine) {
    return;
  }

  if (!_isConference) { // Need to hold this line
    [_callManager holdCall:_activeSessionId onHold:YES];
  }

  _activeLine = activeLine;
  _activeSessionId = _lineSessions[_activeLine];

  [numpadViewController.buttonLine
      setTitle:[NSString stringWithFormat:@"Line%zd:", activeLine]
      forState:UIControlStateNormal];

  if (!_isConference && _activeSessionId != INVALID_SESSION_ID) {
    // Need to unhold this line
    [_callManager holdCall:_activeSessionId onHold:NO];
  }
}

- (void)switchSessionLine {
  UIStoryboard *stryBoard =
      [UIStoryboard storyboardWithName:@"Main" bundle:nil];

  LineTableViewController *selectLineView = [stryBoard
      instantiateViewControllerWithIdentifier:@"LineTableViewController"];

  selectLineView.delegate = self;
  selectLineView.activeLine = _activeLine;

  UITabBarController *tabBarController =
      (UITabBarController *)self.window.rootViewController;

  [tabBarController presentViewController:selectLineView
                                 animated:YES
                               completion:nil];
}

#pragma mark - CallManager delegate Implement
- (void)onIncomingCallWithoutCallKit:(long)sessionId
                         existsVideo:(BOOL)existsVideo
                         remoteParty:(NSString *)remoteParty
                   remoteDisplayName:
                       (NSString *)
                           remoteDisplayName { // Call this by CallManager
  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session == nil)
    return;

  if ([UIApplication sharedApplication].applicationState ==
          UIApplicationStateBackground &&
      !_enablePushNotification) {
    // Is Background and not enable CallKit, show the Notification
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];

    if (localNotif) {
      NSString *stringAlert = [NSString
          stringWithFormat:@"%@ \n<%@>%@",
                           NSLocalizedString(@"Call from", @"Call from"),
                           remoteDisplayName, remoteParty];
      if (existsVideo) {
        stringAlert =
            [NSString stringWithFormat:@"%@ \n<%@>%@",
                                       NSLocalizedString(@"Video call from",
                                                         @"Video call from"),
                                       remoteDisplayName, remoteParty];
      }
      localNotif.soundName = @"ringtone29.mp3";

      localNotif.alertBody = stringAlert;
      localNotif.repeatInterval = 0;
      [[UIApplication sharedApplication]
          presentLocalNotificationNow:localNotif];
    }
  }

  // Not support callkit,show the incoming Alert
  int index = [self findSession:sessionId];
  if (index < 0) { // not found this session
    return;
  }
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Incoming Call" message:[NSString
    stringWithFormat:@"Call from <%@>%@ on line %d",
                     remoteDisplayName, remoteParty,
                     index]
    preferredStyle:UIAlertControllerStyleAlert];
       
       [alertView addAction:[UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleDefault
          handler:^(UIAlertAction *action) {
           [self->_mSoundService stopRingTone];
           [self->_mSoundService stopRingBackTone];
           
           [self->_callManager endCall:session.sessionId];

           [self->numpadViewController
               setStatusText:[NSString stringWithFormat:@"Reject Call on line %d", index]];
       }]];
       
       [alertView addAction:[UIAlertAction actionWithTitle:@"Answer" style:UIAlertActionStyleDefault
          handler:^(UIAlertAction *action) {
           [self->_mSoundService stopRingTone];
           [self->_mSoundService stopRingBackTone];
           
           if ([self->_callManager answerCall:session.sessionId isVideo:false]) {
             [self->numpadViewController
                 setStatusText:[NSString stringWithFormat:@"Answer audio Call on line %d", index]];
           } else {
             [self->numpadViewController
                 setStatusText:[NSString stringWithFormat:@"Answer audio Call on line %d Failed",index]];
           };
       }]];
    if(existsVideo){
        [alertView addAction:[UIAlertAction actionWithTitle:@"Video" style:UIAlertActionStyleDefault
           handler:^(UIAlertAction *action) {
            [self->_mSoundService stopRingTone];
            [self->_mSoundService stopRingBackTone];
            if ([self->_callManager answerCall:session.sessionId isVideo:true]) {
              [self->numpadViewController
                  setStatusText:[NSString stringWithFormat:@"Answer  video Call on line %d", index]];
            } else {
              [self->numpadViewController
                  setStatusText:[NSString stringWithFormat:@"Answer video Call on line %d Failed",index]];
            };
        }]];
    }
    
    [self.window.rootViewController presentViewController:alertView animated:YES completion:^{

    }];
  [_mSoundService playRingTone];
}

- (void)onNewOutgoingCall:(long)sessionId {
  _lineSessions[_activeLine] = sessionId;
}

- (void)onAnsweredCall:(long)sessionId {
  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session) {
    if (session.videoCall) {
      [videoViewController onStartVideo:sessionId];
      [self setLoudspeakerStatus:YES];
    } else {
      [self setLoudspeakerStatus:NO];
    }

    int line = [self findSession:sessionId];
    if (line >= 0) {
      [self didSelectLine:line];
    }
  }
  [_mSoundService stopRingTone];
  [_mSoundService stopRingBackTone];

  if (_activeSessionId == INVALID_SESSION_ID) {
    _activeSessionId = sessionId;
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Call Established on line  %d",
                                               [self findSession:sessionId]]];
}

- (void)onCloseCall:(long)sessionId {
  // call by callmanager, session call has closed

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Call Close on line  %d",
                                               [self findSession:sessionId]]];

  [self freeLine:sessionId];

  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session) {
    [_callManager removeCall:session];

    if (session.videoCall) {
      [videoViewController onStopVideo:sessionId];
    }
  }

  if (sessionId == _activeSessionId) {
    _activeSessionId = INVALID_SESSION_ID;
  }
  [_mSoundService stopRingTone];
  [_mSoundService stopRingBackTone];

  if ([_callManager getConnectCallNum] == 0) {
    // Setting speakers for sound output (The system default behavior)
    [self setLoudspeakerStatus:YES];
  }
}

- (void)onMuteCall:(long)sessionId muted:(BOOL)muted {
  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session) { // update Mute status
  }
}

- (void)onHoldCall:(long)sessionId onHold:(BOOL)onHold {
  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session && sessionId == _activeSessionId) { // update Hold status
    if (onHold) {
      [portSIPSDK setRemoteVideoWindow:sessionId remoteVideoWindow:nil];

      [numpadViewController
          setStatusText:[NSString stringWithFormat:@"Hold call on line %zd",
                                                   _activeLine]];
    } else {
      [portSIPSDK setRemoteVideoWindow:sessionId
                     remoteVideoWindow:videoViewController.viewRemoteVideo];

      [numpadViewController
          setStatusText:[NSString stringWithFormat:@"unHold call on line %zd",
                                                   _activeLine]];
    }
  }
}

#pragma mark - PortSIPSDK sip callback events Delegate
// Register Event
- (void)onRegisterSuccess:(char *)statusText
               statusCode:(int)statusCode
               sipMessage:(char *)sipMessage

{
  sipRegistered = YES;
  [loginViewController onRegisterSuccess:statusCode withStatusText:statusText];
};

- (void)onRegisterFailure:(char *)statusText
               statusCode:(int)statusCode
               sipMessage:(char *)sipMessage {
  sipRegistered = NO;
  [loginViewController onRegisterFailure:statusCode withStatusText:statusText];
  [self endBackgroundTaskForRegister];
};

// Call Event
- (void)onInviteIncoming:(long)sessionId
       callerDisplayName:(char *)callerDisplayName
                  caller:(char *)caller
       calleeDisplayName:(char *)calleeDisplayName
                  callee:(char *)callee
             audioCodecs:(char *)audioCodecs
             videoCodecs:(char *)videoCodecs
             existsAudio:(BOOL)existsAudio
             existsVideo:(BOOL)existsVideo
              sipMessage:(char *)sipMessage {
  int num = [_callManager getConnectCallNum];
  int index = [self findIdleLine];
  if (num >= MAX_LINES || index < 0) {
    [portSIPSDK rejectCall:sessionId code:486];
    return;
  }

  NSLog(@"onInviteIncoming from: %s", caller);

  NSString *remoteParty =
      [[NSString alloc] initWithCString:(const char *)caller
                               encoding:NSASCIIStringEncoding];
  NSString *remoteDisplayName =
      [[NSString alloc] initWithCString:(const char *)callerDisplayName
                               encoding:NSASCIIStringEncoding];
  NSUUID *uuid = nil;

  if (_enablePushNotification) {
    NSString *message =
        [[NSString alloc] initWithCString:(const char *)sipMessage
                                 encoding:NSASCIIStringEncoding];
    NSString *headerName = @"x-push-id";

    NSString *pushId =
        [portSIPSDK getSipMessageHeaderValue:message headerName:headerName];
    if (pushId != nil) {
      //[NSThread sleepForTimeInterval:3.0];
      uuid = [[NSUUID alloc] initWithUUIDString:pushId];
      NSLog(@"onInviteIncoming uuid: %@", uuid);
    }
  }

  if (uuid == nil) {
    uuid = [NSUUID new];
  }
    
  _lineSessions[index] = sessionId;

  [_callManager incomingCall:sessionId
                 existsVideo:existsVideo
                 remoteParty:remoteParty
           remoteDisplayName:remoteDisplayName
                    callUUID:uuid
       withCompletionHandler:nil];

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Incoming call:%@ on line %d",
                                               remoteParty, index]];
};

- (void)onInviteTrying:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Call is trying on line %d", index]];
};

- (void)onInviteSessionProgress:(long)sessionId
                    audioCodecs:(char *)audioCodecs
                    videoCodecs:(char *)videoCodecs
               existsEarlyMedia:(BOOL)existsEarlyMedia
                    existsAudio:(BOOL)existsAudio
                    existsVideo:(BOOL)existsVideo
                     sipMessage:(char *)sipMessage {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  if (existsEarlyMedia) {
    // Checking does this call has video
    if (existsVideo) {
      // This incoming call has video
      // If more than one codecs using, then they are separated with "#",
      // for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by
      // yourself.
    }

    if (existsAudio) {
      // If more than one codecs using, then they are separated with "#",
      // for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by
      // yourself.
    }
  }

  HSSession *session = [_callManager findCallBySessionID:sessionId];

  session.existEarlyMedia = existsEarlyMedia;

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Call session progress on line %d",
                                         index]];
}

- (void)onInviteRinging:(long)sessionId
             statusText:(char *)statusText
             statusCode:(int)statusCode
             sipMessage:(char *)sipMessage {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (!session.existEarlyMedia) {
    // No early media, you must play the local WAVE file for ringing tone
    [_mSoundService playRingBackTone];
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Call ringing on line %d", index]];
}

- (void)onInviteAnswered:(long)sessionId
       callerDisplayName:(char *)callerDisplayName
                  caller:(char *)caller
       calleeDisplayName:(char *)calleeDisplayName
                  callee:(char *)callee
             audioCodecs:(char *)audioCodecs
             videoCodecs:(char *)videoCodecs
             existsAudio:(BOOL)existsAudio
             existsVideo:(BOOL)existsVideo
              sipMessage:(char *)sipMessage {
  // If more than one codecs using, then they are separated with "#",
  // for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by
  // yourself.
  // Checking does this call has video
  if (existsVideo) {
    [videoViewController onStartVideo:sessionId];
  }

  if (existsAudio) {
  }

  [_mSoundService stopRingTone];
  [_mSoundService stopRingBackTone];

  [_callManager answerCall:sessionId isVideo:existsVideo];
}

- (void)onInviteFailure:(long)sessionId
                 reason:(char *)reason
                   code:(int)code
             sipMessage:(char *)sipMessage {
  HSSession *session = [_callManager findCallBySessionID:sessionId];

  if (session == nil) {
    NSLog(@"Not exist this SessionId = %ld", sessionId);
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Failed to call on line  %d,%s(%d)",
                                         [self findSession:sessionId], reason,
                                         code]];

  if (session.isReferCall) {
    // Take off the origin call from HOLD if the refer call is failure
    HSSession *originSession =
        [_callManager findCallByOrignalSessionID:session.orignalId];

    if (originSession != nil) {
      [numpadViewController
          setStatusText:[NSString
                            stringWithFormat:@"Call failure on line  %d,%s(%d)",
                                             [self findSession:sessionId],
                                             reason, code]];

      // Now take off the origin call
      [_callManager holdCall:originSession.sessionId onHold:false];

      // Switch the currently line to origin call line
      int originLine = [self findSession:originSession.sessionId];
      [self didSelectLine:originLine];

      NSLog(@"Current line is: %zd", _activeLine);
    }
  }

  [_callManager endCall:sessionId];
}

- (void)onInviteUpdated:(long)sessionId
            audioCodecs:(char *)audioCodecs
            videoCodecs:(char *)videoCodecs
            existsAudio:(BOOL)existsAudio
            existsVideo:(BOOL)existsVideo
             sipMessage:(char *)sipMessage {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  // Checking does this call has video
  if (existsVideo) {
    [videoViewController onStartVideo:sessionId];
  }
  if (existsAudio) {
  }

  [numpadViewController
      setStatusText:
          [NSString stringWithFormat:@"The call has been updated on line %d",
                                     [self findSession:sessionId]]];
}

- (void)onInviteConnected:(long)sessionId {
  HSSession *session = [_callManager findCallBySessionID:sessionId];

  if (session == nil) {
    NSLog(@"Not exist this SessionId = %ld", sessionId);
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"The call is connected on line %d",
                                         [self findSession:sessionId]]];
  if (session.videoCall) {
    [self setLoudspeakerStatus:YES];
  } else {
    [self setLoudspeakerStatus:NO];
  }
  NSLog(@"onInviteConnected...");
}

- (void)onInviteBeginingForward:(char *)forwardTo {
  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Call has been forward to:%s",
                                               forwardTo]];
}

- (void)onInviteClosed:(long)sessionId {
  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Call closed by remote on line %d",
                                         [self findSession:sessionId]]];

  HSSession *session = [_callManager findCallBySessionID:sessionId];
  if (session != nil) {
    [_callManager endCall:sessionId];
  }

  NSLog(@"onInviteClosed...");
}

- (void)onDialogStateUpdated:(char *)BLFMonitoredUri
              BLFDialogState:(char *)BLFDialogState
                 BLFDialogId:(char *)BLFDialogId
          BLFDialogDirection:(char *)BLFDialogDirection {
  NSLog(
      @"The user %s dialog state is updated:%s, dialog id: %s, direction: %s ",
      BLFMonitoredUri, BLFDialogState, BLFDialogId, BLFDialogDirection);
}

- (void)onRemoteHold:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Placed on hold by remote on line %d",
                                         index]];
}

- (void)onRemoteUnHold:(long)sessionId
           audioCodecs:(char *)audioCodecs
           videoCodecs:(char *)videoCodecs
           existsAudio:(BOOL)existsAudio
           existsVideo:(BOOL)existsVideo {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Take off hold by remote on line  %d",
                                         index]];
}

// Transfer Event
- (void)onReceivedRefer:(long)sessionId
                referId:(long)referId
                     to:(char *)to
                   from:(char *)from
        referSipMessage:(char *)referSipMessage {
  HSSession *session = [_callManager findCallBySessionID:sessionId];

  if (session == nil) {
    // Not found the refer session, reject refer.
    [portSIPSDK rejectRefer:referId];
    NSLog(@"Not exist this SessionId = %ld", sessionId);
    return;
  }

  int index = [self findIdleLine];
  if (index < 0) {
    // Not found the idle line, reject refer.
    [portSIPSDK rejectRefer:referId];
    return;
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:
                                  @"Received the refer on line %d, refer to %s",
                                  [self findSession:sessionId], to]];

  // auto accept refer
  long referSessionId =
      [portSIPSDK acceptRefer:referId
               referSignaling:[NSString stringWithUTF8String:referSipMessage]];
  if (referSessionId <= 0) {
    [numpadViewController
        setStatusText:[NSString
                          stringWithFormat:@"Failed to accept the refer."]];
  } else {
    [_callManager endCall:sessionId];

    NSString *remote = [NSString stringWithUTF8String:to];
    HSSession *session =
        [[HSSession alloc] initWithSessionIdAndUUID:referSessionId
                                           callUUID:nil
                                        remoteParty:remote
                                        displayName:remote
                                         videoState:YES
                                            callOut:YES];

    [_callManager addCall:session];
    _lineSessions[index] = referSessionId;

    session.sessionState = YES;
    session.isReferCall = YES;
    session.orignalId = sessionId;

    [numpadViewController
        setStatusText:[NSString stringWithFormat:@"Accepted the refer, new "
                                                 @"call is trying on line %d",
                                                 index]];
  }

  /*if you want to reject Refer
   [mPortSIPSDK rejectRefer:referId];
   [numpadViewController setStatusText:@"Rejected the the refer."];
   */
}

- (void)onReferAccepted:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Line %d, the REFER was accepted.",
                                         index]];
}

- (void)onReferRejected:(long)sessionId reason:(char *)reason code:(int)code {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Line %d, the REFER was rejected.",
                                         index]];
}

- (void)onTransferTrying:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Transfer trying on line %d", index]];
}

- (void)onTransferRinging:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Transfer ringing on line %d",
                                               index]];
}

- (void)onACTVTransferSuccess:(long)sessionId {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Transfer succeeded on line %d",
                                               index]];

  // Transfer has success, hangup call.
  [_callManager endCall:sessionId];
}

- (void)onACTVTransferFailure:(long)sessionId
                       reason:(char *)reason
                         code:(int)code {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString stringWithFormat:@"Failed to transfer on line %d",
                                               index]];
}

// Signaling Event
- (void)onReceivedSignaling:(long)sessionId message:(char *)message {
  // This event will be fired when the SDK received a SIP message
  // you can use signaling to access the SIP message.
  NSLog(@"onReceivedSignaling %ld:%s", sessionId, message);
}

- (void)onSendingSignaling:(long)sessionId message:(char *)message {
  // This event will be fired when the SDK sent a SIP message
  // you can use signaling to access the SIP message.
  NSLog(@"onSendingSignaling %ld:%s", sessionId, message);
}

- (void)onWaitingVoiceMessage:(char *)messageAccount
        urgentNewMessageCount:(int)urgentNewMessageCount
        urgentOldMessageCount:(int)urgentOldMessageCount
              newMessageCount:(int)newMessageCount
              oldMessageCount:(int)oldMessageCount {
  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Has voice messages,%s(%d,%d,%d,%d)",
                                         messageAccount, urgentNewMessageCount,
                                         urgentOldMessageCount, newMessageCount,
                                         oldMessageCount]];
}

- (void)onWaitingFaxMessage:(char *)messageAccount
      urgentNewMessageCount:(int)urgentNewMessageCount
      urgentOldMessageCount:(int)urgentOldMessageCount
            newMessageCount:(int)newMessageCount
            oldMessageCount:(int)oldMessageCount {
  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Has Fax messages,%s(%d,%d,%d,%d)",
                                         messageAccount, urgentNewMessageCount,
                                         urgentOldMessageCount, newMessageCount,
                                         oldMessageCount]];
}

- (void)onRecvDtmfTone:(long)sessionId tone:(int)tone {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:[NSString
                        stringWithFormat:@"Received DTMF tone: %d  on line %d",
                                         tone, index]];
}

- (void)onRecvOptions:(char *)optionsMessage {
  NSLog(@"Received an OPTIONS message:%s", optionsMessage);
}

- (void)onRecvInfo:(char *)infoMessage {
  NSLog(@"Received an INFO message:%s", infoMessage);
}

- (void)onRecvNotifyOfSubscription:(long)subscribeId
                     notifyMessage:(char *)notifyMessage
                       messageData:(unsigned char *)messageData
                 messageDataLength:(int)messageDataLength {
  NSLog(@"Received an Notify message");
}
// Instant Message/Presence Event
// Instant Message/Presence Event
- (void)onPresenceRecvSubscribe:(long)subscribeId
                fromDisplayName:(char *)fromDisplayName
                           from:(char *)from
                        subject:(char *)subject {
  [imViewController onPresenceRecvSubscribe:subscribeId
                            fromDisplayName:fromDisplayName
                                       from:from
                                    subject:subject];
}

- (void)onPresenceOnline:(char *)fromDisplayName
                    from:(char *)from
               stateText:(char *)stateText {
  [imViewController onPresenceOnline:fromDisplayName
                                from:from
                           stateText:stateText];
}

- (void)onPresenceOffline:(char *)fromDisplayName from:(char *)from {
  [imViewController onPresenceOffline:fromDisplayName from:from];
}

- (void)onRecvMessage:(long)sessionId
             mimeType:(char *)mimeType
          subMimeType:(char *)subMimeType
          messageData:(unsigned char *)messageData
    messageDataLength:(int)messageDataLength {
  int index = [self findSession:sessionId];
  if (index == -1) {
    return;
  }

  [numpadViewController
      setStatusText:
          [NSString stringWithFormat:@"Received a MESSAGE message on line %d",
                                     index]];

  if (strcmp(mimeType, "text") == 0 && strcmp(subMimeType, "plain") == 0) {
    NSString *recvMessage =
        [NSString stringWithUTF8String:(const char *)messageData];
    [self showAlertView:@"recvMessage" message:recvMessage];
  } else if (strcmp(mimeType, "application") == 0 &&
             strcmp(subMimeType, "vnd.3gpp.sms") == 0) {
    // The messageData is binary data
  } else if (strcmp(mimeType, "application") == 0 &&
             strcmp(subMimeType, "vnd.3gpp2.sms") == 0) {
    // The messageData is binary data
  }
}

- (void)onRecvOutOfDialogMessage:(char *)fromDisplayName
                            from:(char *)from
                   toDisplayName:(char *)toDisplayName
                              to:(char *)to
                        mimeType:(char *)mimeType
                     subMimeType:(char *)subMimeType
                     messageData:(unsigned char *)messageData
               messageDataLength:(int)messageDataLength
                      sipMessage:(char *)sipMessage {
  [numpadViewController
      setStatusText:[NSString stringWithFormat:
                                  @"Received a message(out of dialog) from %s",
                                  from]];

  if (strcasecmp(mimeType, "text") == 0 &&
      strcasecmp(subMimeType, "plain") == 0) {
    NSString *recvMessage =
        [NSString stringWithUTF8String:(const char *)messageData];
    [self showAlertView:[NSString stringWithUTF8String:from] message:recvMessage];
  } else if (strcasecmp(mimeType, "application") == 0 &&
             strcasecmp(subMimeType, "vnd.3gpp.sms") == 0) {
    // The messageData is binary data
  } else if (strcasecmp(mimeType, "application") == 0 &&
             strcasecmp(subMimeType, "vnd.3gpp2.sms") == 0) {
    // The messageData is binary data
  }
}

- (void)onSendMessageSuccess:(long)sessionId messageId:(long)messageId {
  [imViewController onSendMessageSuccess:messageId];
}

- (void)onSendMessageFailure:(long)sessionId
                   messageId:(long)messageId
                      reason:(char *)reason
                        code:(int)code {
  [imViewController onSendMessageFailure:messageId reason:reason code:code];
}

- (void)onSendOutOfDialogMessageSuccess:(long)messageId
                        fromDisplayName:(char *)fromDisplayName
                                   from:(char *)from
                          toDisplayName:(char *)toDisplayName
                                     to:(char *)to {
  [imViewController onSendMessageSuccess:messageId];
}

- (void)onSendOutOfDialogMessageFailure:(long)messageId
                        fromDisplayName:(char *)fromDisplayName
                                   from:(char *)from
                          toDisplayName:(char *)toDisplayName
                                     to:(char *)to
                                 reason:(char *)reason
                                   code:(int)code {
  [imViewController onSendMessageFailure:messageId reason:reason code:code];
}

- (void)onSubscriptionFailure:(long)subscribeId statusCode:(int)statusCode {
  NSLog(@"SubscriptionFailure subscribeId=%ld statusCode:%d", subscribeId,
        statusCode);
}
// Play file event
- (void)onSubscriptionTerminated:(long)subscribeId {
  NSLog(@"onSubscriptionTerminated subscribeId=%ld", subscribeId);
}

// Play file event
- (void)onPlayAudioFileFinished:(long)sessionId fileName:(char *)fileName {
}

- (void)onPlayVideoFileFinished:(long)sessionId {
}

// RTP/Audio/video stream callback data
- (void)onReceivedRTPPacket:(long)sessionId
                    isAudio:(BOOL)isAudio
                  RTPPacket:(unsigned char *)RTPPacket
                 packetSize:(int)packetSize {
  /* !!! IMPORTANT !!!

   Don't call any PortSIP SDK API functions in here directly. If you want to
   call the PortSIP API functions or
   other code which will spend long time, you should post a message to main
   thread(main window) or other thread,
   let the thread to call SDK API functions or other code.
   */
}

- (void)onSendingRTPPacket:(long)sessionId
                   isAudio:(BOOL)isAudio
                 RTPPacket:(unsigned char *)RTPPacket
                packetSize:(int)packetSize {
  /* !!! IMPORTANT !!!

   Don't call any PortSIP SDK API functions in here directly. If you want to
   call the PortSIP API functions or
   other code which will spend long time, you should post a message to main
   thread(main window) or other thread,
   let the thread to call SDK API functions or other code.
   */
}

- (void)onAudioRawCallback:(long)sessionId
         audioCallbackMode:(int)audioCallbackMode
                      data:(unsigned char *)data
                dataLength:(int)dataLength
            samplingFreqHz:(int)samplingFreqHz {
  /* !!! IMPORTANT !!!

   Don't call any PortSIP SDK API functions in here directly. If you want to
   call the PortSIP API functions or
   other code which will spend long time, you should post a message to main
   thread(main window) or other thread,
   let the thread to call SDK API functions or other code.
   */
    NSLog(@"onAudioRawCallback audioCallbackMode=%d dataLength=%d", audioCallbackMode,dataLength );
}

- (int)onVideoRawCallback:(long)sessionId
        videoCallbackMode:(int)videoCallbackMode
                    width:(int)width
                   height:(int)height
                     data:(unsigned char *)data
               dataLength:(int)dataLength {
  /* !!! IMPORTANT !!!

   Don't call any PortSIP SDK API functions in here directly. If you want to
   call the PortSIP API functions or
   other code which will spend long time, you should post a message to main
   thread(main window) or other thread,
   let the thread to call SDK API functions or other code.
   */
  return 0;
}

- (void)showAlertView:(NSString*)title message:(NSString*)message
{
     UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];

    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Network Status
- (void)reachabilityChanged:(NSNotification *)note {
  Reachability *curReach = [note object];
  NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

  NetworkStatus netStatus = [internetReach currentReachabilityStatus];

  switch (netStatus) {
  case NotReachable:
    NSLog(@"reachabilityChanged:kNotReachable");
    break;
  case ReachableViaWWAN:
    [loginViewController refreshRegister];
    NSLog(@"reachabilityChanged:kReachableViaWWAN");
    break;
  case ReachableViaWiFi:
    [loginViewController refreshRegister];
    NSLog(@"reachabilityChanged:kReachableViaWiFi");
    break;
  default:
    break;
  }
}

- (void)startNotifierNetwork {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(reachabilityChanged:)
             name:kReachabilityChangedNotification
           object:nil];

  [internetReach startNotifier];
}

- (void)stopNotifierNetwork {
  [internetReach stopNotifier];

  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kReachabilityChangedNotification
              object:nil];
}
#pragma mark - APNs message PUSH
- (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.0) {
    NSUInteger length = deviceToken.length;
    if (length == 0) {
      return nil;
    }
    const unsigned char *buffer = deviceToken.bytes;
    NSMutableString *hexString =
        [NSMutableString stringWithCapacity:(length * 2)];
    for (int i = 0; i < length; ++i) {
      [hexString appendFormat:@"%02x", buffer[i]];
    }
    return [hexString copy];
  } else {
    NSString *token = [NSString stringWithFormat:@"%@", deviceToken];

    token =
        [token stringByTrimmingCharactersInSet:
                   [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    return [token stringByReplacingOccurrencesOfString:@" " withString:@""];
  }
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

  _APNsPushToken = [self stringFromDeviceToken:deviceToken];
  NSLog(@"_APNsPushToken :%@", deviceToken);
  [self refreshPushStatusToSipServer:YES];
}
// 8.0 < iOS version < 10.0
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:
              (void (^)(UIBackgroundFetchResult))completionHandler {

  NSLog(@"didReceiveRemoteNotification %@", userInfo);

  completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@",
        error.localizedDescription);
}

// iOS version > 10.0 Background
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response
             withCompletionHandler:(nonnull void (^)(void))completionHandler {

  NSDictionary *userInfo = response.notification.request.content.userInfo;
  NSLog(@"Background Notification:%@", userInfo);

  completionHandler();
}

// iOS version > 10.0 foreground
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions))completionHandler {

  NSDictionary *userInfo = notification.request.content.userInfo;
  NSLog(@"Foreground Notification:%@", userInfo);

  // completionHandler(UNNotificationPresentationOptionBadge |
  // UNNotificationPresentationOptionSound |
  // UNNotificationPresentationOptionAlert);
  completionHandler(UNNotificationPresentationOptionBadge);
}

#pragma mark - VoIP PUSH
- (void)addPushSupportWithPortPBX:(BOOL)enablePush {
  if (_VoIPPushToken == nil || _APNsPushToken == nil ||
      !_enablePushNotification)
    return;

  // This VoIP Push is only work with
  // PortPBX(https://www.portsip.com/portsip-pbx/)
  // if you want work with other PBX, please contact your PBX Provider
  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  [portSIPSDK clearAddedSipMessageHeaders];
  NSString *pushMessage;
  NSString *token = [[NSString alloc]
      initWithFormat:@"%@|%@", _VoIPPushToken, _APNsPushToken];
  if (enablePush) {
    pushMessage = [[NSString alloc]
        initWithFormat:@"device-os=ios;device-uid=%@;allow-call-push=true;"
                       @"allow-message-push=true;app-id=%@",
                       token, bundleIdentifier];

    NSLog(@"Enable pushMessage:{%@}", pushMessage);
  } else {
    pushMessage = [[NSString alloc]
        initWithFormat:@"device-os=ios;device-uid=%@;allow-call-push=false;"
                       @"allow-message-push=false;app-id=%@",
                       token, bundleIdentifier];
    NSLog(@"Disable pushMessage:{%@}", pushMessage);
  }

  [portSIPSDK addSipMessageHeader:-1
                       methodName:@"REGISTER"
                          msgType:1
                       headerName:@"x-p-push"
                      headerValue:pushMessage];
}

- (void)refreshPushStatusToSipServer:(BOOL)addPushHeader {
  if (addPushHeader) {
    [self addPushSupportWithPortPBX:YES];
  } else {
    // remove push header
    [portSIPSDK clearAddedSipMessageHeaders];
  }

  [loginViewController refreshRegister];
}

- (void)processPushMessageFromPortPBX:(NSDictionary *)dictionaryPayload
                withCompletionHandler:(void (^)(void))completion {
  /* dictionaryPayload JSON Format
   Payload: {
   "message_id" = "96854b5d-9d0b-4644-af6d-8d97798d9c5b";
   "msg_content" = "Received a call.";
   "msg_title" = "Received a new call";
   "msg_type" = "audio";//audo or video
   "x-push-id" = "96854b5d-9d0b-4644-af6d-8d97798d9c5b";
   "send_from" = "102";
   "send_to" = "sip:105@portsip.com";
   }
   */

  NSDictionary *parsedObject = dictionaryPayload;

  BOOL isVideoCall = NO;
  NSString *msgType = [parsedObject valueForKey:@"msg_type"];
  // if(msgType.count > 0 && [msgType[0]  isEqual: @"call"])
  if (msgType.length > 0) {
    if ([msgType isEqual:@"audio"]) {
      isVideoCall = NO;
    }
    if ([msgType isEqual:@"video"]) {
      isVideoCall = YES;
    }
  }

  NSUUID *uuid = nil;
  NSString *pushId = [parsedObject valueForKey:@"x-push-id"];
  if (pushId != nil) {
    uuid = [[NSUUID alloc] initWithUUIDString:pushId];

    NSLog(@"processPushMessageFromPortPBX uuid: %@", uuid);
  }
  if (uuid == nil) {
    return;
  }
  if (!_callManager.enableCallKit) {
    // If not enable Call Kit, show the local Notification
    // From iOS 13, must enable CallKit with VoIP PUSH
    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];

    NSString *sendFrom = [parsedObject valueForKey:@"send_from"];
    NSString *sendTo = [parsedObject valueForKey:@"send_to"];

    NSString *alertBody =
        [NSString stringWithFormat:@"You receive a new call From:%@ To:%@",
                                   sendFrom, sendTo];

    backgroudMsg.alertBody = alertBody;
    backgroudMsg.soundName = @"ringtone.mp3";
    backgroudMsg.applicationIconBadgeNumber =
        [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    [[UIApplication sharedApplication]
        presentLocalNotificationNow:backgroudMsg];
  } else {
    NSString *remoteFrom = [parsedObject valueForKey:@"send_from"];
    NSString *remoteDisplayName = [parsedObject valueForKey:@"send_to"];

    [_callManager incomingCall:-1
                   existsVideo:isVideoCall
                   remoteParty:remoteFrom
             remoteDisplayName:remoteDisplayName
                      callUUID:uuid
         withCompletionHandler:completion];

    [loginViewController refreshRegister];
    [self beginBackgroundTaskForRegister];
  }
}

- (void)pushRegistry:(PKPushRegistry *)registry
    didUpdatePushCredentials:(PKPushCredentials *)credentials
                     forType:(PKPushType)type {
  _VoIPPushToken = [self stringFromDeviceToken:credentials.token];

  NSLog(@"didUpdatePushCredentials:%@", _VoIPPushToken);
  [self refreshPushStatusToSipServer:YES];
}

// iOS version > 11.0
- (void)pushRegistry:(PKPushRegistry *)registry
    didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                              forType:(PKPushType)type
                withCompletionHandler:(void (^)(void))completion {
  if (sipRegistered && ([UIApplication sharedApplication].applicationState ==
                            UIApplicationStateActive ||
                        [_callManager getConnectCallNum] > 0)) {
    NSLog(@"didReceiveIncomingPushWith:ignore push message when "
          @"ApplicationStateActive or have active call. Payload: %@",
          payload.dictionaryPayload);
    return;
  }

  [self processPushMessageFromPortPBX:payload.dictionaryPayload
                withCompletionHandler:completion];
}

// 8.0 < iOS version < 11.0
- (void)pushRegistry:(PKPushRegistry *)registry
    didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                              forType:(PKPushType)type {
  if (sipRegistered && ([UIApplication sharedApplication].applicationState ==
                            UIApplicationStateActive ||
                        [_callManager getConnectCallNum] > 0)) {
    NSLog(@"didReceiveIncomingPushWith:ignore push message when "
          @"ApplicationStateActive or have active call. Payload: %@",
          payload.dictionaryPayload);
    return;
  }

  NSLog(@"Payload: %@", payload.dictionaryPayload);
  [self processPushMessageFromPortPBX:payload.dictionaryPayload
                withCompletionHandler:nil];
};

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  NSDictionary *defaultValues = [NSDictionary
      dictionaryWithObjectsAndKeys:@YES, @"CallKit", @NO, @"PushNotification",
                                   @YES, @"ForceBackground", nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];

  // load the settings
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  BOOL enableCallKit = [settings boolForKey:@"CallKit"];
  _enablePushNotification = [settings boolForKey:@"PushNotification"];
  _enableForceBackground = [settings boolForKey:@"ForceBackground"];

  // Override point for customization after application launch.
  _mSoundService = [[SoundService alloc] init];

  portSIPSDK = [[PortSIPSDK alloc] init];
  portSIPSDK.delegate = self;

  _cxProvide = [PortCxProvider sharedInstance];
  _callManager = [[CallManager alloc] initWithSDK:portSIPSDK];
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
    _callManager.enableCallKit = enableCallKit;
  }

  _callManager.delegate = self;
  _cxProvide.callManager = _callManager;

  _activeLine = 0;
  _activeSessionId = INVALID_SESSION_ID;
  for (int i = 0; i < MAX_LINES; i++) {
    _lineSessions[i] = INVALID_SESSION_ID;
  }

  sipRegistered = NO;

  _isConference = NO;
  // Register VoIP PUSH
  PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
  pushRegistry.delegate = self;
  pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

  // Register APNs PUSH
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
    // iOS > 10
    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge |
                                             UNAuthorizationOptionSound |
                                             UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted,
                                              NSError *_Nullable error) {

                            if (!error) {
                              NSLog(@"request User Notification succeeded!");
                            }
                          }];
  } else { // iOS 8-10
    if ([UIApplication instancesRespondToSelector:
                           @selector(registerUserNotificationSettings:)]) {
      [[UIApplication sharedApplication]
          registerUserNotificationSettings:
              [UIUserNotificationSettings
                  settingsForTypes:UIUserNotificationTypeAlert |
                                   UIUserNotificationTypeBadge |
                                   UIUserNotificationTypeSound
                        categories:nil]];
    }
  }

  // Calling this will result in either
  // application:didRegisterForRemoteNotificationsWithDeviceToken: or
  // application:didFailToRegisterForRemoteNotificationsWithError: to be called
  // on the application delegate.
  [application registerForRemoteNotifications];

  UITabBarController *tabBarController =
      (UITabBarController *)self.window.rootViewController;

  UINavigationController *loginbase =
      [[tabBarController viewControllers] objectAtIndex:0];
  loginViewController = [[loginbase viewControllers] objectAtIndex:0];

  numpadViewController = [[tabBarController viewControllers] objectAtIndex:1];
  videoViewController = [[tabBarController viewControllers] objectAtIndex:2];
  imViewController = [[tabBarController viewControllers] objectAtIndex:3];
  settingsViewController = [[tabBarController viewControllers] objectAtIndex:4];

  loginViewController->portSIPSDK = portSIPSDK;

  videoViewController->portSIPSDK = portSIPSDK;
  imViewController->portSIPSDK = portSIPSDK;
  settingsViewController->portSIPSDK = portSIPSDK;

  internetReach = [Reachability reachabilityForInternetConnection];
  [self startNotifierNetwork];

  application.applicationIconBadgeNumber = 0;
  return YES;
}

- (void)beginBackgroundTaskForRegister {
  _backtaskIdentifier = [[UIApplication sharedApplication]
      beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTaskForRegister];
      }];
  int interval = 5; // waiting 5 sec, stop endBackgroundTaskForRegister
  [NSTimer
      scheduledTimerWithTimeInterval:interval
                              target:self
                            selector:@selector(endBackgroundTaskForRegister)
                            userInfo:nil
                             repeats:NO];
  NSLog(@"beginBackgroundTaskForRegister");
}

- (void)endBackgroundTaskForRegister {
  if (_backtaskIdentifier != UIBackgroundTaskInvalid) {
    [[UIApplication sharedApplication] endBackgroundTask:_backtaskIdentifier];
    _backtaskIdentifier = UIBackgroundTaskInvalid;
    NSLog(@"endBackgroundTaskForRegister");
  }
}

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:
        (UIUserNotificationSettings *)notificationSettings {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.

  NSLog(@"applicationDidEnterBackground");
  if (_enableForceBackground) { // Disable to save battery, or when you don't
                                // need incoming calls while APP is in
                                // background.
    [portSIPSDK startKeepAwake];
  } else {
    [loginViewController unRegister];
    [self beginBackgroundTaskForRegister];
  }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
  NSLog(@"applicationWillEnterForeground");
  if (_enableForceBackground) {
    [portSIPSDK stopKeepAwake];
  } else {
    [loginViewController refreshRegister];
  }
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
  if (_enablePushNotification) {
    [portSIPSDK unRegisterServer];
    [NSThread sleepForTimeInterval:3.0];
    NSLog(@"applicationWillTerminate");
  }
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:
                (NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  return YES;
}

// Called on the main thread after the NSUserActivity object is available. Use
// the data you stored in the NSUserActivity object to re-create what the user
// was doing.
// You can create/fetch any restorable objects associated with the user
// activity, and pass them to the restorationHandler. They will then have the
// UIResponder restoreUserActivityState: method
// invoked with the user activity. Invoking the restorationHandler is optional.
// It may be copied and invoked later, and it will bounce to the main thread to
// complete its work and call
// restoreUserActivityState on all objects.
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(nonnull NSUserActivity *)userActivity
      restorationHandler:
          (nonnull void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))
              restorationHandler {
  if (![userActivity.activityType isEqualToString:@"INStartVideoCallIntent"] &&
      ![userActivity.activityType isEqualToString:@"INStartAudioCallIntent"]) {
    return NO;
  }

  BOOL isVideo = NO;
  if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
    isVideo = YES;
  }

  INInteraction *interaction = userActivity.interaction;
  INStartAudioCallIntent *startAudioCallIntent =
      (INStartAudioCallIntent *)interaction.intent;
  // INStartVideoCallIntent *startVideoCallIntent = (INStartVideoCallIntent
  // *)interaction.intent;
  INPerson *contact = startAudioCallIntent.contacts[0];
  INPersonHandle *personHandle = contact.personHandle;
  NSString *phoneNumber = personHandle.value;

  [self makeCall:phoneNumber videoCall:isVideo];

  return YES;
}

@end
