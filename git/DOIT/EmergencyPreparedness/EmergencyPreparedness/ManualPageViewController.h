//
//  ManualPageViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 8/7/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ManualPageViewController : UIViewController <UIActionSheetDelegate>
- (IBAction)showActionSheet:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, readwrite) NSString *titleLabelString;
@property (nonatomic, readwrite) NSString *textViewString;

@end
