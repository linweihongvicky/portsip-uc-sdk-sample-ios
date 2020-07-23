//
//  FirstViewController.h
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetParamsController.h"

@interface LoginViewController
    : UIViewController <UITextFieldDelegate, NetParamsControllerDelegate> {
@public
  PortSIPSDK *portSIPSDK;

@protected

  BOOL sipInitialized;
  int sipRegistrationStatus; // 0 - Not Register 1 - Registering 2 - Registered
                             // 3 - Register Failure/has been unregister
  BOOL startByVoIPPush;

  NSTimer *autoRegisterTimer;
  int autoRegisterRetryTimes;
  NSArray *transPortItems;
  NSArray *srtpItems;
}

@property(nonatomic, retain)
    IBOutlet UIActivityIndicatorView *activityIndicator;
@property(retain, nonatomic) IBOutlet UIView *viewStatus;
@property(retain, nonatomic) IBOutlet UILabel *labelStatus;
@property(retain, nonatomic) IBOutlet UILabel *labelDebugInfo;
@property(retain, nonatomic) IBOutlet UILabel *labelTrans;
@property(retain, nonatomic) IBOutlet UILabel *labelSrtp;
@property(weak, nonatomic) IBOutlet UITextView *textToken;

@property(retain, nonatomic) IBOutlet UITextField *textUsername;
@property(retain, nonatomic) IBOutlet UITextField *textPassword;
@property(retain, nonatomic) IBOutlet UITextField *textUserDomain;
@property(retain, nonatomic) IBOutlet UITextField *textSIPserver;
@property(retain, nonatomic) IBOutlet UITextField *textSIPPort;
@property(retain, nonatomic) IBOutlet UITextField *textAuthname;

@property(retain, nonatomic) IBOutlet UIButton *btTrans;
@property(retain, nonatomic) IBOutlet UIButton *btSrtp;
@property(retain, nonatomic) IBOutlet UIScrollView *rootView;
@property(weak, nonatomic) IBOutlet UILabel *websiteLabel;
@property(weak, nonatomic) IBOutlet UILabel *emailLabel;

- (void)refreshRegister;
- (void)unRegister;

- (IBAction)onOnlineButtonClick:(id)sender;
- (IBAction)onOfflineButtonClick:(id)sender;

- (int)onRegisterSuccess:(int)statusCode withStatusText:(char *)statusText;
- (int)onRegisterFailure:(int)statusCode withStatusText:(char *)statusText;
@end

