//
//  HomepageViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PageContentViewController.h"

@interface HomepageViewController : UIViewController <UIPageViewControllerDataSource, UIActionSheetDelegate>
- (IBAction)showActionSheet:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (nonatomic, assign) BOOL needsToRefresh;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSMutableArray *introArray;


@end
