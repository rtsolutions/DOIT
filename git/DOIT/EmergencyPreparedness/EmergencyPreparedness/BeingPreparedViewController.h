//
//  BeingPreparedViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeingPreparedViewController : UIViewController  <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    IBOutlet UITableView *tableView;
}
- (IBAction)showActionSheet:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *showContentsButton;
@property (weak, nonatomic) IBOutlet UIButton *hideContentsButton;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeUp;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeDown;

@end

