//
//  SettingsViewController.m
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingCell.h"
#include "AppDelegate.h"

#define kNumbersOfSections 3

static NSString *kAudioCodecsKey = @"Audio Codecs";
static NSString *kVideoCodecsKey = @"Video Codecs";
static NSString *kAdvanceFeatureKey = @"Advance Feature";
@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  settingsAudioCodec = [NSMutableArray arrayWithCapacity:20];
  SettingItem *item = [[SettingItem alloc] init];
  item.index = 0;
  item.name = @"OPUS";
  item.enable = YES;
  item.codeType = AUDIOCODEC_OPUS;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 1;
  item.name = @"G.729";
  item.enable = YES;
  item.codeType = AUDIOCODEC_G729;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 2;
  item.name = @"PCMA";
  item.enable = YES;
  item.codeType = AUDIOCODEC_PCMA;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 3;
  item.name = @"PCMU";
  item.enable = YES;
  item.codeType = AUDIOCODEC_PCMU;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 4;
  item.name = @"GSM";
  item.enable = NO;
  item.codeType = AUDIOCODEC_GSM;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 5;
  item.name = @"G.722";
  item.enable = NO;
  item.codeType = AUDIOCODEC_G722;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 6;
  item.name = @"iLBC";
  item.enable = NO;
  item.codeType = AUDIOCODEC_ILBC;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 7;
  item.name = @"AMR";
  item.enable = NO;
  item.codeType = AUDIOCODEC_AMR;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 8;
  item.name = @"AMRWB";
  item.enable = NO;
  item.codeType = AUDIOCODEC_AMRWB;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 9;
  item.name = @"SpeexNB(8Khz)";
  item.enable = NO;
  item.codeType = AUDIOCODEC_SPEEX;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 10;
  item.name = @"SpeexWB(16Khz)";
  item.enable = NO;
  item.codeType = AUDIOCODEC_SPEEXWB;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 11;
  item.name = @"ISACWB(16Khz)";
  item.enable = NO;
  item.codeType = AUDIOCODEC_ISACWB;
  [settingsAudioCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 12;
  item.name = @"ISACSWB(32Khz)";
  item.enable = NO;
  item.codeType = AUDIOCODEC_ISACSWB;
  [settingsAudioCodec addObject:item];

  // Video codec item
  settingsVideoCodec = [NSMutableArray arrayWithCapacity:10];

  item = [[SettingItem alloc] init];
  item.index = 101;
  item.name = @"H.264";
  item.enable = YES;
  item.codeType = VIDEO_CODEC_H264;
  [settingsVideoCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 102;
  item.name = @"VP8";
  item.enable = NO;
  item.codeType = VIDEO_CODEC_VP8;
  [settingsVideoCodec addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 103;
  item.name = @"VP9";
  item.enable = NO;
  item.codeType = VIDEO_CODEC_VP9;
  [settingsVideoCodec addObject:item];

  // Advance Feature
  settingsAdvanceFeature = [NSMutableArray arrayWithCapacity:10];
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
    item = [[SettingItem alloc] init];
    item.index = 300;
    item.name = @"Integrated Calling";
    item.enable = shareAppDelegate.callManager.enableCallKit;
    item.codeType = -1;
    [settingsAdvanceFeature addObject:item];
  }

  item = [[SettingItem alloc] init];
  item.index = 301;
  item.name = @"Push Notification";
  item.enable = shareAppDelegate.enablePushNotification;
  item.codeType = -1;
  [settingsAdvanceFeature addObject:item];

  item = [[SettingItem alloc] init];
  item.index = 302;
  item.name = @"Force Background";
  item.enable = shareAppDelegate.enableForceBackground;
  item.codeType = -1;
  [settingsAdvanceFeature addObject:item];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
  // save change
  [portSIPSDK clearAudioCodec];

  for (SettingItem *item in settingsAudioCodec) {
    if (item.enable) {
      [portSIPSDK addAudioCodec:(AUDIOCODEC_TYPE)item.codeType];
    }
  }

  [portSIPSDK clearVideoCodec];
  for (SettingItem *item in settingsVideoCodec) {
    if (item.enable) {
      [portSIPSDK addVideoCodec:(VIDEOCODEC_TYPE)item.codeType];
    }
  }

  // Save Value
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  for (SettingItem *item in settingsAdvanceFeature) {
    switch (item.index) {
    case 300: // Integrated Calling
      shareAppDelegate.callManager.enableCallKit = item.enable;
      [settings setBool:item.enable forKey:@"CallKit"];
      break;
    case 301: // Push Notification
      if (shareAppDelegate.enablePushNotification != item.enable) {
        shareAppDelegate.enablePushNotification = item.enable;
        [shareAppDelegate refreshPushStatusToSipServer:item.enable];
      }

      [settings setBool:item.enable forKey:@"PushNotification"];
      break;
    case 302: // Force Background
      shareAppDelegate.enableForceBackground = item.enable;
      [settings setBool:item.enable forKey:@"ForceBackground"];
      break;
    }
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return kNumbersOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  switch (section) {
  case 0:
    return [settingsAudioCodec count];
  case 1:
    return [settingsVideoCodec count];
  case 2:
    return [settingsAdvanceFeature count];
  default:
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  switch (section) {
  case 0:
    return kAudioCodecsKey;
  case 1:
    return kVideoCodecsKey;
  case 2:
    return kAdvanceFeatureKey;
  default:
    return nil;
  }
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCell *cell = (SettingCell *)[tableView
      dequeueReusableCellWithIdentifier:@"settingCell"];

  SettingItem *item = nil;
  switch (indexPath.section) {
  case 0:
    item = [settingsAudioCodec objectAtIndex:indexPath.row];
    break;
  case 1:
    item = [settingsVideoCodec objectAtIndex:indexPath.row];
    break;
  case 2:
    item = [settingsAdvanceFeature objectAtIndex:indexPath.row];
    break;
  default:
    return cell;
  }

  [cell SetItem:item];

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here. Create and push another view controller.
  /*
   <#DetailViewController#> *detailViewController = [[<#DetailViewController#>
   alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
   // ...
   // Pass the selected object to the new view controller.
   [self.navigationController pushViewController:detailViewController
   animated:YES];
   */
}

@end
