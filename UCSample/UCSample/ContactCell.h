//
//  ContactCell.h
//  UCSample
//
//  Created by Joe Lepple on 6/14/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactCell : UITableViewCell{
}
@property (nonatomic, strong) IBOutlet UILabel *urlLabel;
@property (nonatomic, strong) IBOutlet UILabel *noteLabel;
@property (nonatomic, strong) IBOutlet UIImageView *onlineImageView;
@end
