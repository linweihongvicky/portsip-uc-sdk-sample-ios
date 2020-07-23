//
//  SettingCell.h
//  UCSample
//
//  Created by Joe Lepple on 9/25/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingItem : NSObject

@property(nonatomic, assign) int index;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL enable;
@property(nonatomic, assign) int codeType;
@end

@interface SettingCell : UITableViewCell {
  SettingItem *settingItem;
}
@property(retain, nonatomic) IBOutlet UILabel *nameLabel;
@property(retain, nonatomic) IBOutlet UISwitch *switchOperation;

- (IBAction)onSwitchChange:(UISwitch *)sender;

- (void)SetItem:(SettingItem *)item;
@end

