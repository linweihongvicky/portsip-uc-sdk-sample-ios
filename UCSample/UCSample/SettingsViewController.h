//
//  SettingsViewController.h
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController {
@public
  PortSIPSDK *portSIPSDK;

@private
  NSMutableArray *settingsAudioCodec;
  NSMutableArray *settingsVideoCodec;
  NSMutableArray *settingsAdvanceFeature;
}

@end
