//
//  ChecklistViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ChecklistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    IBOutlet UITableView *tableView;

}

- (IBAction)showActionSheet:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

