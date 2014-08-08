//
//  PageContentViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 8/4/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageContentViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *introTextField;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;


@property NSUInteger pageIndex;
@property NSString *introString;
@property NSString *dateString;
@property NSString *storyString;

@end
