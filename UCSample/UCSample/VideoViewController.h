//
//  VideoViewController.h
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoViewController : UIViewController {
@public
  PortSIPSDK *portSIPSDK;
}

@property(retain, nonatomic) IBOutlet PortSIPVideoRenderView *viewLocalVideo;
@property(retain, nonatomic) IBOutlet PortSIPVideoRenderView *viewRemoteVideo;

- (void)onStartVideo:(long)sessionId;
- (void)onStopVideo:(long)sessionId;

@end
