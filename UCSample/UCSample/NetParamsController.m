//
//  NetParamsController.m
//  UCSample
//
//  Copyright (c) 2016 PortSIP Solutions, Inc. All rights reserved.
//

#import "NetParamsController.h"

@interface NetParamsController ()

@end

@implementation NetParamsController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:NO];
  [_tbView setDataSource:self];
  [_tbView setDelegate:self];
}

- (IBAction)backButtonClicked:(id)sender {
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (self.data) {
    return self.data.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.data || self.data.count == 0) {
    return nil;
  }

  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:self.data[indexPath.row]];
  cell.textLabel.text = self.data[indexPath.row];
  return cell;
}

- (CGFloat)itemCellHeight:(NSIndexPath *)indexPath {
  return 44.0f;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.navigationController popToRootViewControllerAnimated:YES];
  [self.delegate didSelectValue:self.title value:indexPath.row];
}
@end
