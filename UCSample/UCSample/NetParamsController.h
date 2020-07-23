//
//  NetParamsController.h
//  UCSample
//
//  Copyright (c) 2016 PortSIP Solutions, Inc. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol NetParamsControllerDelegate <NSObject>
@required
- (void)didSelectValue:(NSString *)title value:(NSInteger)value;
@end

@interface NetParamsController
    : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property(atomic, retain) IBOutlet UITableView *tbView;
@property(atomic, copy) NSArray *data;
@property(nonatomic, weak) id<NetParamsControllerDelegate> delegate;

@end
