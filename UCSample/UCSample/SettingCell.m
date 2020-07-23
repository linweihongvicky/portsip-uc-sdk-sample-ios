//
//  SettingCell.m
//  UCSample
//
//  Created by Joe Lepple on 9/25/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "SettingCell.h"

@implementation SettingItem

@end

@implementation SettingCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialization code
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)SetItem:(SettingItem *)item {
  settingItem = item;

  _switchOperation.on = item.enable;
  _switchOperation.tag = item.index;
  _nameLabel.text = item.name;
}

- (IBAction)onSwitchChange:(UISwitch *)sender {
  if (settingItem != nil) {
    settingItem.enable = [sender isOn];
  }
}
@end
