//
//  QuizQuestionViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 8/8/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuizQuestionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,UIActionSheetDelegate> {
    IBOutlet UITableView *tableView;
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (nonatomic, readwrite) NSMutableArray *questionsArray;
@property (nonatomic, readwrite) NSString *titleString;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *questionNumberLabel;
@property (weak, nonatomic) IBOutlet UITextView *questionTextView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
