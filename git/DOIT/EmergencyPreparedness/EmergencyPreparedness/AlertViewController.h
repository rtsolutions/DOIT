//
//  AlertViewController.h
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertViewController : UIViewController <UITextViewDelegate> {
    IBOutlet UITextView *textView;
    
}

@property (nonatomic, readwrite) NSString *storyString;
@property (nonatomic, strong) IBOutlet UITextView *textView;

@end

