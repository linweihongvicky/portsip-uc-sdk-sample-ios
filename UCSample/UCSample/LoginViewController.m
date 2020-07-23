 
//
//  FirstViewController.m
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "LoginViewController.h"
#include "AppDelegate.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <UIKit/UIKit.h>


@implementation LoginViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  _textUsername.delegate = self;
  _textPassword.delegate = self;
  _textUserDomain.delegate = self;
  _textSIPserver.delegate = self;
  _textSIPPort.delegate = self;
  _textAuthname.delegate = self;

  sipInitialized = NO;
  sipRegistrationStatus = 0;
  autoRegisterRetryTimes = 0;
  [_labelDebugInfo setText:@"PortSIP VoIP SDK for iOS"];
  [self.navigationController setNavigationBarHidden:YES];
  _btTrans.titleLabel.textAlignment = NSTextAlignmentRight;

  transPortItems = [[NSArray alloc]
      initWithObjects:@"UDP", @"TLS", @"TCP", @"PERS_UDP", @"PERS_TCP", nil];

  srtpItems =
      [[NSArray alloc] initWithObjects:@"NONE", @"FORCE", @"PREFER", nil];

  // Load Value
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  _textUsername.text = [settings stringForKey:@"kUserName"];
  _textAuthname.text = [settings stringForKey:@"kAuthName"];
  _textPassword.text = [settings stringForKey:@"kPassword"];
  _textUserDomain.text = [settings stringForKey:@"kUserDomain"];
  _textSIPserver.text = [settings stringForKey:@"kSIPServer"];
  _textSIPPort.text = [settings stringForKey:@"kSIPServerPort"];

  [self doAutoRegister];

  [self setwebsiteLabel];
}

- (void)doAutoRegister {
  if ([_textUsername.text length] > 1 && [_textPassword.text length] > 1 &&
      [_textSIPserver.text length] > 1 && [_textSIPPort.text length] > 1) {
    [self onLine];
  }
}

- (void)viewDidLayoutSubviews {
  self.rootView.contentSize = CGSizeMake(320, 568);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)keyboardWillShow:(NSNotification *)noti {
  float height = 216.0;
  CGRect frame = self.view.frame;
  frame.size = CGSizeMake(frame.size.width, frame.size.height - height);
  [UIView beginAnimations:@"Curl" context:nil];
  [UIView setAnimationDuration:0.30];
  [UIView setAnimationDelegate:self];
  [self.view setFrame:frame];
  [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // When the user presses return, take focus away from the text field so that
  // the keyboard is dismissed.
  NSTimeInterval animationDuration = 0.30f;
  [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
  [UIView setAnimationDuration:animationDuration];
  CGRect rect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width,
                           self.view.frame.size.height);
  self.view.frame = rect;
  [UIView commitAnimations];
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  CGRect frame = textField.frame;
  int offset = frame.origin.y + 32 - (self.view.frame.size.height - 216.0);
  NSTimeInterval animationDuration = 0.30f;
  [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
  [UIView setAnimationDuration:animationDuration];

  float width = self.view.frame.size.width;
  float height = self.view.frame.size.height;

  if (offset > 0) {
    CGRect rect = CGRectMake(0.0f, -offset, width, height);
    self.view.frame = rect;
  }
  [UIView commitAnimations];
}

- (void)showAlertView:(NSString*) message
{
    //create alertcontroller object
   UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Information" message:message preferredStyle:UIAlertControllerStyleAlert];
   //add action
   [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
   handler:nil]];
     
   [self presentViewController:alertView animated:YES completion:nil];
}

- (void)onLine {
  if (sipInitialized) {
    [_labelDebugInfo setText:@"You already registered, Offline first!"];
    return;
  }

  NSString *kUserName = _textUsername.text;
  NSString *kDisplayName = _textUsername.text;
  NSString *kAuthName = _textAuthname.text;
  NSString *kPassword = _textPassword.text;
  NSString *kUserDomain = _textUserDomain.text;
  NSString *kSIPServer = _textSIPserver.text;
  int kSIPServerPort = [_textSIPPort.text intValue];

    if ([kUserName length] < 1) {
        [self showAlertView:@"Please enter user name!"];
        return;
    }

    if ([kPassword length] < 1) {
        [self showAlertView:@"Please enter password!"];
      return;
    }

    if ([kSIPServer length] < 1) {
        [self showAlertView:@"Please enter SIP Server!"];
      return;
    }

  TRANSPORT_TYPE transport = TRANSPORT_UDP; // TRANSPORT_TCP

  switch (_btTrans.tag) {
  case 0:
    transport = TRANSPORT_UDP;
    break;
  case 1:
    transport = TRANSPORT_TLS;
    break;
  case 2:
    transport = TRANSPORT_TCP;
    break;
  case 3:
    transport = TRANSPORT_PERS_UDP;
    break;

  case 4:
    transport = TRANSPORT_PERS_TCP;
    break;

  default:
    break;
  }

  SRTP_POLICY srtp = SRTP_POLICY_NONE;
  switch (_btSrtp.tag) {
  case 0:
    srtp = SRTP_POLICY_NONE;
    break;
  case 1:
    srtp = SRTP_POLICY_FORCE;
    break;
  case 2:
    srtp = SRTP_POLICY_PREFER;
    break;
  default:
    break;
  }

  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setObject:kUserName forKey:@"kUserName"];
  [settings setObject:kAuthName forKey:@"kAuthName"];
  [settings setObject:kPassword forKey:@"kPassword"];
  [settings setObject:kUserDomain forKey:@"kUserDomain"];
  [settings setObject:kSIPServer forKey:@"kSIPServer"];
  [settings setObject:_textSIPPort.text forKey:@"kSIPServerPort"];
  [settings setInteger:transport forKey:@"kTRANSPORT"];

  int localSIPPort = 5000 + arc4random() % 2000; // local port range 5k-7k
  NSString *loaclIPaddress = @"0.0.0.0";         // Auto select IP address

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  int ret = [portSIPSDK initialize:transport
                           localIP:loaclIPaddress
                      localSIPPort:localSIPPort
                          loglevel:PORTSIP_LOG_DEBUG
                           logPath:documentsDirectory
                           maxLine:8
                             agent:@"PortSIP SDK for IOS"
                  audioDeviceLayer:0
                  videoDeviceLayer:0
           TLSCertificatesRootPath:@""
                     TLSCipherList:@""
              verifyTLSCertificate:NO];
  if (ret != 0) {
    NSLog(@"initialize failure ErrorCode = %d", ret);
    return;
  }

  ret = [portSIPSDK setUser:kUserName
                displayName:kDisplayName
                   authName:kAuthName
                   password:kPassword
                 userDomain:kUserDomain
                  SIPServer:kSIPServer
              SIPServerPort:kSIPServerPort
                 STUNServer:@""
             STUNServerPort:0
             outboundServer:@""
         outboundServerPort:0];

  if (ret != 0) {
    NSLog(@"setUser failure ErrorCode = %d", ret);
    return;
  }

[self showAlertView:@"This PortSIP UC SDK is free to use. It could be only works with PortSIP PBX. To use with other PBX, please use PortSIP VoIP SDK instead. Feel free to contact us by sales@portsip.com to get more details."];


  [portSIPSDK addAudioCodec:AUDIOCODEC_OPUS];
  [portSIPSDK addAudioCodec:AUDIOCODEC_G729];
  [portSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
  [portSIPSDK addAudioCodec:AUDIOCODEC_PCMU];

  //[mPortSIPSDK addAudioCodec:AUDIOCODEC_GSM];
  //[mPortSIPSDK addAudioCodec:AUDIOCODEC_ILBC];
  //[mPortSIPSDK addAudioCodec:AUDIOCODEC_AMR];
  //[portSIPSDK addAudioCodec:AUDIOCODEC_SPEEX];
  //[mPortSIPSDK addAudioCodec:AUDIOCODEC_SPEEXWB];

  [portSIPSDK addVideoCodec:VIDEO_CODEC_H264];
  //[portSIPSDK addVideoCodec:VIDEO_CODEC_VP8];
  //[portSIPSDK addVideoCodec:VIDEO_CODEC_VP9];

  [portSIPSDK setVideoBitrate:-1
                  bitrateKbps:500]; // Default video send bitrate,500kbps
  [portSIPSDK setVideoFrameRate:-1 frameRate:10]; // Default video frame rate,10
  [portSIPSDK setVideoResolution:352 height:288];
  [portSIPSDK setAudioSamples:20 maxPtime:60]; // ptime 20

  [portSIPSDK setInstanceId:[[[UIDevice currentDevice] identifierForVendor]
                                UUIDString]];

  if (shareAppDelegate.enablePushNotification) {
    [shareAppDelegate addPushSupportWithPortPBX:YES];
  }

  // 1 - FrontCamra 0 - BackCamra
  [portSIPSDK setVideoDeviceId:1];

  // enable video RTCP nack
  [portSIPSDK setVideoNackStatus:YES];

  // enable srtp
  [portSIPSDK setSrtpPolicy:srtp];

  // Try to register the default identity.
  // Registration refreshment interval is 90 seconds
  ret = [portSIPSDK registerServer:90 retryTimes:0];
  if (ret != 0) {
    [portSIPSDK unInitialize];
    NSLog(@"registerServer failure ErrorCode = %d", ret);
    return;
  }

  if (transport == TRANSPORT_TCP || transport == TRANSPORT_TLS) {
    [portSIPSDK setKeepAliveTime:0];
  }

  [_activityIndicator startAnimating];

  [_labelDebugInfo setText:@"Registration..."];
  NSString *sipURL = nil;
  if (kSIPServerPort == 5060)
    sipURL =
        [[NSString alloc] initWithFormat:@"sip:%@:%@", kUserName, kUserDomain];
  else
    sipURL = [[NSString alloc]
        initWithFormat:@"sip:%@:%@:%d", kUserName, kUserDomain, kSIPServerPort];
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.sipURL = sipURL;

  sipInitialized = YES;
  sipRegistrationStatus = 1;
}

- (void)offLine:(BOOL)keepPush {
  if (sipInitialized) {
    if (shareAppDelegate.enablePushNotification && !keepPush) {
      [shareAppDelegate addPushSupportWithPortPBX:NO];
    }

    [portSIPSDK unRegisterServer];
    [_viewStatus setBackgroundColor:[UIColor redColor]];

    [_labelStatus setText:@"Not Connected"];
    [_labelDebugInfo setText:[NSString stringWithFormat:@"unRegisterServer"]];
    [NSThread sleepForTimeInterval:1.0];
    [portSIPSDK unInitialize];
    sipInitialized = NO;
  }

  if ([_activityIndicator isAnimating])
    [_activityIndicator stopAnimating];

  sipRegistrationStatus = 0;
}

- (IBAction)onOnlineButtonClick:(id)sender {
  [self onLine];
};

- (IBAction)onOfflineButtonClick:(id)sender {
  [self offLine:NO];
};

- (IBAction)onOfflineKeepPushClick:(id)sender {
  [self offLine:YES];
}
// refreshRegistration just use for NetworkStatus not change case

- (void)refreshRegister {
  if (sipRegistrationStatus == 0) {
    // Not Register
    return;
  } else if (sipRegistrationStatus == 1) {
    // is registering
    return;
  } else if (sipRegistrationStatus == 2) {
    // has registered, refreshRegistration
    [portSIPSDK refreshRegistration:0];
    [_labelDebugInfo setText:@"Refresh Registration..."];
    NSLog(@"Refresh Registration...");
  } else if (sipRegistrationStatus == 3) {
    NSLog(@"retry a new register");
    // Register Failure
    [portSIPSDK unRegisterServer];
    [portSIPSDK unInitialize];
    sipInitialized = NO;
    [self onLine];
  }
}

- (void)unRegister {
  if (sipRegistrationStatus == 1 || sipRegistrationStatus == 2) {
    [portSIPSDK unRegisterServer];

    [_labelDebugInfo setText:@"unRegister when background"];
    NSLog(@"unRegister when background");
    sipRegistrationStatus = 3;
  }
}

- (int)onRegisterSuccess:(int)statusCode withStatusText:(char *)statusText {
  [_viewStatus setBackgroundColor:[UIColor greenColor]];

  [_labelStatus setText:@"Connected"];

  [_labelDebugInfo
      setText:[NSString stringWithFormat:@"onRegisterSuccess: %s", statusText]];

  [_activityIndicator stopAnimating];

  sipRegistrationStatus = 2;
  autoRegisterRetryTimes = 0;
  return 0;
}

- (int)onRegisterFailure:(int)statusCode withStatusText:(char *)statusText {
  [_viewStatus setBackgroundColor:[UIColor redColor]];

  [_labelStatus setText:@"Not Connected"];

  [_labelDebugInfo
      setText:[NSString stringWithFormat:@"onRegisterFailure: %s", statusText]];
  NSLog(@"onRegisterFailure:%d %s", statusCode, statusText);

  [_activityIndicator stopAnimating];
  sipRegistrationStatus = 3;
  if (statusCode != 401 && statusCode != 403 && statusCode != 404) {

    // If the NetworkStatus not change, received onRegisterFailure event. can
    // added a atuo reRegister Timer like this:
    // added a atuo reRegister Timer
    int interval = autoRegisterRetryTimes * 2 + 1;
    // max interval is 60
    interval = interval > 60 ? 60 : interval;
    autoRegisterRetryTimes++;
    autoRegisterTimer =
        [NSTimer scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(refreshRegister)
                                       userInfo:nil
                                        repeats:NO];
  }
  return 0;
};

- (void)didSelectValue:(NSString *)title value:(NSInteger)value {
  if ([title isEqualToString:@"TransPort"]) {
    [_btTrans setTag:value];
    [_labelTrans setText:transPortItems[value]];
  } else {
    [_btSrtp setTag:value];
    [_labelSrtp setText:srtpItems[value]];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if (sender == _btTrans) {
    [segue.destinationViewController setValue:transPortItems forKey:@"data"];
    [segue.destinationViewController setValue:@"TransPort" forKey:@"title"];
    [segue.destinationViewController setValue:self forKey:@"delegate"];
  } else if (sender == _btSrtp) {
    [segue.destinationViewController setValue:srtpItems forKey:@"data"];
    [segue.destinationViewController setValue:@"SRTP" forKey:@"title"];
    [segue.destinationViewController setValue:self forKey:@"delegate"];
  }
}

- (void)setwebsiteLabel {

  NSDictionary *attribtDic = @{
    NSUnderlineStyleAttributeName :
        [NSNumber numberWithInteger:NSUnderlineStyleSingle]
  };
  NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]
      initWithString:@"website: http://www.portsip.com"
          attributes:attribtDic];
  _websiteLabel.attributedText = attribtStr;

  NSDictionary *attribtDic2 = @{
    NSUnderlineStyleAttributeName :
        [NSNumber numberWithInteger:NSUnderlineStyleSingle]
  };
  NSMutableAttributedString *attribtStr2 = [[NSMutableAttributedString alloc]
      initWithString:@"email: sales@portsip.com"
          attributes:attribtDic2];
  _emailLabel.attributedText = attribtStr2;

  UITapGestureRecognizer *ges0 =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(weibo)];
  [_websiteLabel addGestureRecognizer:ges0];
  _websiteLabel.userInteractionEnabled = YES;

  UITapGestureRecognizer *ges1 =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(email)];
  [_emailLabel addGestureRecognizer:ges1];
  _emailLabel.userInteractionEnabled = YES;
}

- (void)weibo {

  NSURL *url = [NSURL URLWithString:@"http://www.portsip.com"];

  [[UIApplication sharedApplication] openURL:url];
}

- (void)email {

  NSString *mailStr = [NSString stringWithFormat:@"mailto://sales@portsip.com"];

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailStr]];
}

@end
