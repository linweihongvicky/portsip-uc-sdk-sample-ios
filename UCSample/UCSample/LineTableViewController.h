//
//  LineTableViewController.h
//  UCSample
//
//  Created by Joe Lepple on 7/11/14.
//  Copyright (c) 2014 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LineViewControllerDelegate <NSObject>
- (void)didSelectLine:(NSInteger)activeLine;
@end

@interface LineTableViewController : UITableViewController
@property NSInteger    activeLine;
@property (nonatomic, weak) id <LineViewControllerDelegate> delegate;

@end
