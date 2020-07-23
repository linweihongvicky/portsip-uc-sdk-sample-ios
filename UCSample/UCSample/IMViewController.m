//
//  IMViewController.m
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "IMViewController.h"
#import "ContactCell.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>

@interface IMViewController ()
@end

@implementation IMViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textContact.delegate = self;
    _textMessage.delegate = self;
	// Do any additional setup after loading the view.
    
    if(!self.contacts){
		_contacts = [[NSMutableArray alloc] init];
	}
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
    
    [self obseveKeyboard ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)obseveKeyboard {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}


- (void) keyboardWillShow:(NSNotification *)notification {
    CGFloat kbHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

   
    CGFloat offset = (_textMessage.frame.origin.y+_textMessage.frame.size.height) - (self.view.frame.size.height - kbHeight);

    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    if(offset > 0) {
        [UIView animateWithDuration:duration animations:^{
            self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}

- (void) keyboardWillHide:(NSNotification *)notify {

    double duration = [[notify.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}

- (IBAction) onSubscribeClick: (id)sender
{
    long subscribeID = [portSIPSDK presenceSubscribe:[_textContact text]  subject:@"hello"];
    
    Contact* contact = [[Contact alloc] initWithSubscribe:subscribeID andSipURL:[_textContact text]];
    
    [_contacts addObject:contact];
    [_tableView reloadData];
}

- (IBAction) onOnlineClick: (id)sender
{
    for(int i = 0 ; i < [_contacts count] ; i++)
    {
        Contact* contact = [_contacts objectAtIndex: i];
        if(contact){
            [portSIPSDK setPresenceStatus:[contact subscribeID] statusText:@"I'm here"];
        }
    }
}


- (IBAction) onOfflineClick: (id)sender
{
    for(int i = 0 ; i < [_contacts count] ; i++)
    {
        Contact* contact = [_contacts objectAtIndex: i];
        if(contact){
            [portSIPSDK setPresenceStatus:[contact subscribeID]  statusText:@"offline"];
        }
    }
}

- (IBAction) onSendMessageClick: (id)sender
{
    NSData* message = [[_textMessage text] dataUsingEncoding:NSUTF8StringEncoding];
    long messageID = [portSIPSDK sendOutOfDialogMessage:[_textContact text] mimeType:@"text" subMimeType:@"plain" isSMS:NO message:message messageLength:(int)[message length]];

    NSLog(@"send Message %zd",messageID);
}

//Instant Message/Presence Event
-(int)onSendMessageSuccess:(long)messageId
{
    NSLog(@"%zd message send success",messageId);
    return 0;
}

-(int)onSendMessageFailure:(long)messageId reason:(char*)reason code:(int)code
{
    NSLog(@"%zd message send failure",messageId);
    return 0;
};

-(int)onPresenceRecvSubscribe:(long)subscribeId
              fromDisplayName:(char*)fromDisplayName
                         from:(char*)from
                      subject:(char*)subject
{
    for(int i = 0 ; i < [_contacts count] ; i++)
    {
        Contact* contact = [_contacts objectAtIndex: i];
        if(contact){
            if([[contact sipURL] isEqualToString:[NSString stringWithUTF8String:from]])
            {//has exist this contact
                //update subscribedId
                contact.subscribeID = subscribeId;
                
                //Accept subscribe.
                [portSIPSDK presenceAcceptSubscribe:subscribeId];
                [portSIPSDK setPresenceStatus:subscribeId statusText:@"Available"];
                return 0;
            }
        }
    }
    
    Contact* contact = [[Contact alloc] initWithSubscribe:subscribeId andSipURL:[NSString  stringWithUTF8String:from]];
    
    [_contacts addObject:contact];
    [_tableView reloadData];


    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Recv Subscribe" message:[NSString  stringWithFormat:@"Recv Subscribe <%s>%s : %s", fromDisplayName,from,subject]
 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction *action) {
        [self->portSIPSDK presenceRejectSubscribe:subscribeId];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Accept" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction *action) {
        for(int i = 0 ; i < [self->_contacts count] ; i++)
        {
            Contact* contact = [self->_contacts objectAtIndex: i];
            if(contact.subscribeID == subscribeId){
                [self->portSIPSDK presenceAcceptSubscribe:subscribeId];
                [self->portSIPSDK setPresenceStatus:subscribeId statusText:@"Available"];
                
                [self->portSIPSDK presenceSubscribe:contact.sipURL subject:@"Hello"];
            }
        }
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
    return 0;
}

- (void)onPresenceOnline:(char*)fromDisplayName
                    from:(char*)from
               stateText:(char*)stateText
{
    for(int i = 0 ; i < [_contacts count] ; i++)
    {
        Contact* contact = [_contacts objectAtIndex: i];
        if(contact){
            if([[contact sipURL] isEqualToString:[NSString stringWithUTF8String:from]])
            {
                contact.basicState = @"open";
                contact.note = [NSString stringWithUTF8String:stateText];
                [_tableView reloadData];
                break;
            }
        }
    }
}

- (void)onPresenceOffline:(char*)fromDisplayName from:(char*)from
{
    for(int i = 0 ; i < [_contacts count] ; i++)
    {
        Contact* contact = [_contacts objectAtIndex: i];
        if(contact){
            if([[contact sipURL] isEqualToString:[NSString stringWithUTF8String:from]])
            {
                contact.basicState = @"close";
                [_tableView reloadData];
                break;
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(0 == section){
        return [_contacts count];
    }
    
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell *cell = (ContactCell*)[tableView dequeueReusableCellWithIdentifier: @"ContactCellIdentifier"];
	
    //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    if([_contacts count] > indexPath.row){
        Contact* contact = [_contacts objectAtIndex: indexPath.row];
        if(contact){
            cell.urlLabel.text = contact.sipURL;
            cell.noteLabel.text = contact.note;
            if([contact.basicState isEqualToString:@"open"])
            {
                cell.onlineImageView.image = [UIImage imageNamed:@"online.png"];
            }
            else
            {
                cell.onlineImageView.image = [UIImage imageNamed:@"offline.png"];
            }
        }
    }
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Contact* contact = [_contacts objectAtIndex: indexPath.row];
        if (contact) {
            //[mPortSIPSDK presenceUnsubscribeContact :contact.subscribeID];
		}
        [_contacts removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


@end
