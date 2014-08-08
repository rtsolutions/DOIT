//
//  AlertViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertViewController : UIViewController <UITextViewDelegate, UIActionSheetDelegate> {
    IBOutlet UITextView *textView;
    __weak IBOutlet UILabel *dateLabel;
    
    __weak IBOutlet UITextView *introTextLabel;
}

- (IBAction)showActionSheet:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (nonatomic, readwrite) NSString *storyString;
@property (nonatomic, readwrite) NSString *introString;
@property (nonatomic, readwrite) NSString *dateString;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *introTextLabel;

@end

