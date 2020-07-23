//
//  VideoViewController.m
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "VideoViewController.h"
#import "AppDelegate.h"

@interface VideoViewController () {
@protected
  NSUInteger mCameraDeviceId; // 1 - FrontCamra 0 - BackCamra
  int mLocalVideoWidth;
  int mLocalVideoHeight;
  BOOL isStartVideo;
  BOOL isInitVideo;
  long sessionId;

  BOOL hidden;
}
@property(weak, nonatomic) IBOutlet UIButton *buttonConference;

- (void)checkDisplayVideo;
@end

@implementation VideoViewController

- (void)checkDisplayVideo {
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if (isInitVideo && !appDelegate.isConference) {
    if (isStartVideo) {
      [portSIPSDK setRemoteVideoWindow:sessionId remoteVideoWindow:nil];
      [portSIPSDK setRemoteVideoWindow:sessionId
                     remoteVideoWindow:_viewRemoteVideo];
      [portSIPSDK setLocalVideoWindow:_viewLocalVideo];
      [portSIPSDK displayLocalVideo:YES mirror:YES];
      [portSIPSDK sendVideo:sessionId sendState:YES];
    } else {
      [portSIPSDK displayLocalVideo:NO mirror:NO];
      [portSIPSDK setLocalVideoWindow:nil];
      [portSIPSDK setRemoteVideoWindow:sessionId remoteVideoWindow:nil];
    }
  }
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  isInitVideo = YES;
  // 1 - FrontCamra 0 - BackCamra
  mCameraDeviceId = 1;

  [_viewLocalVideo initVideoRender];
  [_viewRemoteVideo initVideoRender];

  mLocalVideoWidth = 352;
  mLocalVideoHeight = 288;
  [self updateLocalVideoPosition:[UIScreen mainScreen].bounds.size];

  [self setHides];
}

- (void)viewDidAppear:(BOOL)animated;
{ [self checkDisplayVideo]; }

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {

  return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {
  // best call super just in case
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  // will execute before rotation

  [coordinator animateAlongsideTransition:^(id _Nonnull context) {
    // will execute during rotation
    [self updateLocalVideoPosition:size];
  }
                               completion:^(id _Nonnull context){
                                   // will execute after rotation
                               }];
}

- (IBAction)onSwitchSpeakerClick:(id)sender {
  UIButton *buttonSpeaker = (UIButton *)sender;

  if ([[[buttonSpeaker titleLabel] text] isEqualToString:@"Speaker"]) {
    [portSIPSDK setLoudspeakerStatus:YES];
    [buttonSpeaker setTitle:@"Headphone" forState:UIControlStateNormal];
  } else {
    [portSIPSDK setLoudspeakerStatus:NO];
    [buttonSpeaker setTitle:@"Speaker" forState:UIControlStateNormal];
  }
}

- (IBAction)onSwitchCameraClick:(id)sender {
  UIButton *buttonCamera = (UIButton *)sender;
  if ([[[buttonCamera titleLabel] text] isEqualToString:@"FrontCamera"]) {
    if ([portSIPSDK setVideoDeviceId:1] == 0) {
      mCameraDeviceId = 1;
      [buttonCamera setTitle:@"BackCamera" forState:UIControlStateNormal];
    }

  } else {
    if ([portSIPSDK setVideoDeviceId:0] == 0) {
      mCameraDeviceId = 0;
      [buttonCamera setTitle:@"FrontCamera" forState:UIControlStateNormal];
    }
  }
}

- (IBAction)onSendingVideoClick:(id)sender {
  UIButton *buttonSendingVideo = (UIButton *)sender;

  if ([[[buttonSendingVideo titleLabel] text]
          isEqualToString:@"PauseSending"]) {
    [portSIPSDK sendVideo:sessionId sendState:NO];

    [buttonSendingVideo setTitle:@"StartSending" forState:UIControlStateNormal];
  } else {
    [portSIPSDK sendVideo:sessionId sendState:YES];
    [buttonSendingVideo setTitle:@"PauseSending" forState:UIControlStateNormal];
  }
}
- (IBAction)onConference:(id)sender {
  UIButton *buttonConference = (UIButton *)sender;
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if ([[[buttonConference titleLabel] text] isEqualToString:@"Conference"]) {
    [appDelegate createConference:_viewRemoteVideo];

    [buttonConference setTitle:@"UnConference" forState:UIControlStateNormal];
  } else {
    [appDelegate destoryConference:_viewRemoteVideo];

    [portSIPSDK setRemoteVideoWindow:sessionId
                   remoteVideoWindow:_viewRemoteVideo];

    [buttonConference setTitle:@"Conference" forState:UIControlStateNormal];
  }
}

- (void)onStartVideo:(long)sessionID {
  isStartVideo = YES;
  sessionId = sessionID;
  [self checkDisplayVideo];
}

- (void)onStopVideo:(long)sessionId {
  isStartVideo = NO;
  [self checkDisplayVideo];
}

- (void)updateLocalVideoPosition:(CGSize)screenSize {
  if (screenSize.width > screenSize.height) {
    // Landscape
    CGRect rectLocal = _viewLocalVideo.frame;
    rectLocal.size.width = 176;
    rectLocal.size.height =
        rectLocal.size.width * mLocalVideoHeight / mLocalVideoWidth;
    rectLocal.origin.x = screenSize.width - rectLocal.size.width - 10;
    ;
    rectLocal.origin.y = 10;
    _viewLocalVideo.frame = rectLocal;
  } else {
    CGRect rectLocal = _viewLocalVideo.frame;
    rectLocal.size.width = 144;
    rectLocal.size.height =
        rectLocal.size.width * mLocalVideoWidth / mLocalVideoHeight;
    rectLocal.origin.x = screenSize.width - rectLocal.size.width - 10;
    ;
    rectLocal.origin.y = 30;
    _viewLocalVideo.frame = rectLocal;
  }
}

- (void)updateLocalVideoCaptureSize:(int)width height:(int)height {
  if (height <= 0 || width <= 0)
    return;

  if (mLocalVideoHeight != height || mLocalVideoWidth != width) {
    mLocalVideoWidth = width;
    mLocalVideoHeight = height;

    [self updateLocalVideoPosition:[UIScreen mainScreen].bounds.size];
    NSLog(@"updateLocalVideoCaptureSize width=%d height=%d", width, height);
  }
}

- (void)setHides {

  UITapGestureRecognizer *ges =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(setHideOption)];
  [_viewRemoteVideo addGestureRecognizer:ges];
  _viewRemoteVideo.userInteractionEnabled = YES;
}

- (void)setHideOption {

  if (hidden) {

    [self showTabBar];
  } else {
    [self hideTabBar];
  }

  hidden = !hidden;
}

- (void)hideTabBar {
  if (self.tabBarController.tabBar.hidden == YES) {
    return;
  }

  [_viewRemoteVideo
      setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,
                          [UIScreen mainScreen].bounds.size.height)];

  for (UIView *tempview in self.view.subviews) {

    if (tempview == _viewLocalVideo || tempview == _viewRemoteVideo) {
    } else {
      tempview.hidden = YES;
    }
  }

  UIView *contentView;
  if ([[self.tabBarController.view.subviews objectAtIndex:0]
          isKindOfClass:[UITabBar class]])
    contentView = [self.tabBarController.view.subviews objectAtIndex:1];
  else
    contentView = [self.tabBarController.view.subviews objectAtIndex:0];
  contentView.frame =
      CGRectMake(contentView.bounds.origin.x, contentView.bounds.origin.y,
                 contentView.bounds.size.width,
                 contentView.bounds.size.height +
                     self.tabBarController.tabBar.frame.size.height);
  self.tabBarController.tabBar.hidden = YES;
}

- (void)showTabBar {
  if (self.tabBarController.tabBar.hidden == NO) {
    return;
  }

  [_viewRemoteVideo
      setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,
                          [UIScreen mainScreen].bounds.size.height)];

  for (UIView *tempview in self.view.subviews) {
    tempview.hidden = NO;
  }

  UIView *contentView;
  if ([[self.tabBarController.view.subviews objectAtIndex:0]
          isKindOfClass:[UITabBar class]])
    contentView = [self.tabBarController.view.subviews objectAtIndex:1];

  else

    contentView = [self.tabBarController.view.subviews objectAtIndex:0];
  contentView.frame =
      CGRectMake(contentView.bounds.origin.x, contentView.bounds.origin.y,
                 contentView.bounds.size.width,
                 contentView.bounds.size.height -
                     self.tabBarController.tabBar.frame.size.height);
  self.tabBarController.tabBar.hidden = NO;
}

@end
