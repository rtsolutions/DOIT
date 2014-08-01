//
//  HomepageViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomepageViewController : UIViewController <UITableViewDelegate,UITableViewDataSource> {
    IBOutlet UITableView *tableView;
    
}

@property (nonatomic, assign) BOOL needsToRefresh;
@property (nonatomic, strong) IBOutlet UITableView *tableView;


@end
