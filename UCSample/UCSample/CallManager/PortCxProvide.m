 
      
  
//
//  PortCxProvider.m
//  PortGo
//
//  Created by portsip on 16/11/18.
//  Copyright © 2016 PortSIP Solutions, Inc. All rights reserved.
//

#import "PortCxProvide.h"
#import <Intents/Intents.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PortCxProvider () <CXProviderDelegate>

@property(nonatomic, strong) CXCallController *callController;
@end

@implementation PortCxProvider

+ (PortCxProvider *)sharedInstance {
  static PortCxProvider *instance = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    instance = [[super allocWithZone:nil] init];
    [instance configurationCallProvider];
  });
  return instance;
}

#pragma mark--providerConfiguration

- (void)configurationCallProvider {
  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  NSString *localizedName = [infoDict objectForKey:@"CFBundleName"]; // APP Name
  CXProviderConfiguration *configuration =
      [[CXProviderConfiguration alloc] initWithLocalizedName:localizedName];
  configuration.supportsVideo = YES;
  configuration.maximumCallsPerCallGroup = 1;
  configuration.supportedHandleTypes = [NSSet
      setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
  configuration.iconTemplateImageData =
      UIImagePNGRepresentation([UIImage imageNamed:@"IconMask"]);
  //    configuration.ringtoneSound = @"Ringtone.caf";//Use system ringtone
  self.cxprovider = [[CXProvider alloc] initWithConfiguration:configuration];
  [self.cxprovider
      setDelegate:self
            queue:self.completionQueue ? self.completionQueue
                                       : dispatch_get_main_queue()];
#if 0
    if (CXProvider.authorizationStatus == CXAuthorizationStatusNotDetermined) {
        [self.provider requestAuthorization];
    }
#endif
  self.callController =
      [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
}

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue {
  _completionQueue = completionQueue;
  if (self.cxprovider) {
    [self.cxprovider setDelegate:self queue:_completionQueue];
  }
}

- (NSUUID *)reportOutgoingCall:(NSUUID *)callUUID
       startedConnectingAtDate:(NSDate *)startDate {
  //_callUUID=callUUID;
  [self.cxprovider reportOutgoingCallWithUUID:callUUID
                      startedConnectingAtDate:startDate];
  return callUUID;
}

// DTMF
- (void)provider:(CXProvider *)provider
    performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
  NSLog(@"%s", __func__);

  const char *data = [action.digits UTF8String];
  int digitDtmf = 0;

  switch (*data) {
  case '0':
    digitDtmf = 0;
    break;
  case '1':
    digitDtmf = 1;
    break;
  case '2':
    digitDtmf = 2;
    break;
  case '3':
    digitDtmf = 3;
    break;
  case '4':
    digitDtmf = 4;
    break;
  case '5':
    digitDtmf = 5;
    break;
  case '6':
    digitDtmf = 6;
    break;
  case '7':
    digitDtmf = 7;
    break;
  case '8':
    digitDtmf = 8;
    break;
  case '9':
    digitDtmf = 9;
    break;
  case '*':
    digitDtmf = 10;
    break;
  case '#':
    digitDtmf = 11;
    break;
  default:
    return;
  }

  [_callManager playDTMFWithUUID:action.callUUID dtmf:digitDtmf];

  [action fulfill];
}

// timeout to end
- (void)provider:(CXProvider *)provider
    timedOutPerformingAction:(CXAction *)action {
  NSLog(@"%s", __func__);
  /// Called when an action was not performed in time and has been inherently
  /// failed. Depending on the action, this timeout may also force the call to
  /// end. An action that has already timed out should not be fulfilled or
  /// failed by the provider delegate
}
// group
- (void)provider:(CXProvider *)provider
    performSetGroupCallAction:(CXSetGroupCallAction *)action {
  HSSession *call = [_callManager findCallByUUID:action.callUUID];
  if (call == nil) {
    [action fail];
    return;
  }

  //        action.fulfill()
  //        return
  NSLog(@"CXSetGroupCallAction ");
  if (action.callUUIDToGroupWith != nil) {
    [_callManager joinToConferenceWithUUID:action.callUUID];
  } else {
    [_callManager removeFromConferenceWithUUID:action.callUUID];
  }

  // print("#function"+"\(action.callUUID)" )
  // print("#function"+"\(action.callUUIDToGroupWith!)" )
  [action fulfill];
}

- (void)provider:(CXProvider *)provider
    didActivateAudioSession:(AVAudioSession *)audioSession {
  [_callManager startAudio];
}

- (void)provider:(CXProvider *)provider
    didDeactivateAudioSession:(AVAudioSession *)audioSession {
  [_callManager stopAudio];
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
  NSLog(@"%s", __func__);
  [_callManager stopAudio];
  /*
   End any ongoing calls if the provider resets, and remove them from the app's
   list of calls,
   since they are no longer valid.
   */

  // Remove all calls from the app's list of calls.
  [_callManager clear];
}

- (void)performAnswerCallWithUUID:(NSUUID *)uuid
                       completion:(void (^)(BOOL success))completionHandler {
  HSSession *session = [_callManager findCallByUUID:uuid];

  if (session != nil) {
    if (session.sessionId <= INVALID_SESSION_ID) {
      // Haven't received INVITE CALL
      session.callKitAnswered = YES;
      session.callKitCompletionCallback = completionHandler;
    } else {
      if ([_callManager answerCallWithUUID:uuid isVideo:session.videoCall]) {
        completionHandler(YES);
      } else {
        NSLog(@"Answer Call Failed!");
        completionHandler(NO);
      }
    }
  } else {
    NSLog(@"Session not found");

    completionHandler(NO);
  }
}

- (void)provider:(CXProvider *)provider
    performAnswerCallAction:(nonnull CXAnswerCallAction *)action {
  [self performAnswerCallWithUUID:action.callUUID
                       completion:^(BOOL success) {
                         if (success) {
                           [action fulfill];
                         } else {
                           [action fail];
                         }
                       }];
  //[action fulfill];
  NSLog(@"performAnswerCallAction fail");
}

- (void)provider:(CXProvider *)provider
    performEndCallAction:(nonnull CXEndCallAction *)action {
  NSLog(@"performEndCallAction uuid =%@", action.callUUID);
  HSSession *session = [_callManager findCallByUUID:action.callUUID];
  if (session != nil) {
    [_callManager hungUpCallWithUUID:action.callUUID];
  }
  [action fulfill];
}

- (void)provider:(CXProvider *)provider
    performStartCallAction:(nonnull CXStartCallAction *)action {
  NSLog(@"performStartCallAction uuid =%@", action.callUUID);

  long sessionId = [_callManager makeCallWithUUID:action.handle.value
                                        videoCall:action.video
                                         callUUID:action.callUUID];

  if (sessionId >= 0) {
    [action fulfill];
  } else {
    [action fail];
  }
}

- (void)provider:(CXProvider *)provider
    performSetMutedCallAction:(nonnull CXSetMutedCallAction *)action {
  HSSession *session = [_callManager findCallByUUID:action.callUUID];
  if (session != nil) {
    [_callManager muteCallWithUUID:action.callUUID muted:action.muted];
  }
  [action fulfill];
}

- (void)provider:(CXProvider *)provider
    performSetHeldCallAction:(nonnull CXSetHeldCallAction *)action {
  HSSession *session = [_callManager findCallByUUID:action.callUUID];
  if (session != nil) {
    [_callManager holdCallWithUUID:action.callUUID onHold:action.onHold];
  }
  [action fulfill];
}
@end
NS_ASSUME_NONNULL_END
