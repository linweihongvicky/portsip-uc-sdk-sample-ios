//
//  AppDelegate.h
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoginViewController.h"
#import "NumpadViewController.h"
#import "VideoViewController.h"
#import "IMViewController.h"
#import "SettingsViewController.h"
#import "HSSession.h"
#import "LineTableViewController.h"
#import "CallMananger.h"
#import "PortCxProvide.h"

#define shareAppDelegate [AppDelegate sharedInstance]

@interface AppDelegate : UIResponder {
  PortSIPSDK *portSIPSDK;
  LoginViewController *loginViewController;
  NumpadViewController *numpadViewController;
  VideoViewController *videoViewController;
  IMViewController *imViewController;
  SettingsViewController *settingsViewController;

  BOOL sipRegistered;
}

@property NSInteger activeLine;
@property(strong, nonatomic) UIWindow *window;
@property(nonatomic, retain) NSString *sipURL;
@property(nonatomic, assign) BOOL isConference;
@property(nonatomic, assign) BOOL enablePushNotification;
@property(nonatomic, assign) BOOL enableForceBackground;

@property(nonatomic, retain) PortCxProvider *cxProvide;
@property(nonatomic, retain) CallManager *callManager;

+ (AppDelegate *)sharedInstance;

- (void)pressNumpadButton:(char)dtmf;
- (long)makeCall:(NSString *)callee videoCall:(BOOL)videoCall;
- (void)hungUpCall;
- (void)holdCall;
- (void)unholdCall;
- (void)referCall:(NSString *)referTo;
- (void)muteCall:(BOOL)mute;
- (void)setLoudspeakerStatus:(BOOL)enable;
- (void)getStatistics;
- (void)updateCall;
- (void)makeTest;
- (void)attendedRefer:(NSString *)referTo;
- (void)switchSessionLine;
- (void)addPushSupportWithPortPBX:(BOOL)enablePush;
- (void)refreshPushStatusToSipServer:(BOOL)addPushHeader;

- (BOOL)createConference:(PortSIPVideoRenderView *)conferenceVideoWindow;
- (void)setConferenceVideoWindow:
    (PortSIPVideoRenderView *)conferenceVideoWindow;
//- (void)removeFromConference:(long)sessionId;
//- (BOOL)joinToConference:(long)sessionId;
- (void)destoryConference:(UIView *)viewRemoteVideo;
@end
