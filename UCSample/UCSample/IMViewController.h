//
//  IMViewController.h
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@interface IMViewController : UIViewController<UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource>{
@public
    PortSIPSDK *portSIPSDK;
}

@property (retain, nonatomic) IBOutlet UITextField *textContact;
@property (retain, nonatomic) IBOutlet UITextField *textMessage;
@property(nonatomic,retain) IBOutlet UITableView *tableView;

@property NSMutableArray* contacts;

- (IBAction) onSubscribeClick: (id)sender;
- (IBAction) onOnlineClick: (id)sender;
- (IBAction) onOfflineClick: (id)sender;
- (IBAction) onSendMessageClick: (id)sender;


//Instant Message/Presence Event
-(int)onSendMessageSuccess:(long)messageId ;
-(int)onSendMessageFailure:(long)messageId reason:(char*)reason code:(int)code;

-(int)onPresenceRecvSubscribe:(long)subscribeId
              fromDisplayName:(char*)fromDisplayName
                         from:(char*)from
                      subject:(char*)subject;

- (void)onPresenceOnline:(char*)fromDisplayName
                    from:(char*)from
               stateText:(char*)stateText;
- (void)onPresenceOffline:(char*)fromDisplayName from:(char*)from;
@end
