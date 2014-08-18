//
//  AlertViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "AlertViewController.h"

@interface AlertViewController ()

@end

@implementation AlertViewController


/// Very simple setup for a very simple viewController. Add text to the appropriate fields,
/// and let the introTextLabel take up as many lines as it needs.
- (void)setupView {
    
    self.textView.text = self.storyString;
    self.dateLabel.text = self.dateString;

    self.introTextLabel.numberOfLines = 0;
    [self.introTextLabel sizeToFit];
    self.introTextLabel.text = self.introString;
    
    
}


/// Present an actionSheet with buttons to navigate to the four pages in the app
- (IBAction)showActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Home", @"Being Prepared", @"Checklist", @"Take the Quiz", nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet showFromBarButtonItem:self.menuButton animated:YES];
}

/// If the user selects a button from the actionSheet menu, send a notification to the homepageViewController to pop and push to the chosen viewController
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqual: @"Home"])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if ([buttonTitle isEqual:@"Checklist"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToChecklist" object:nil];
    }
    else if ([buttonTitle isEqual:@"Being Prepared"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToBeingPrepared" object:nil];
    }
    else if ([buttonTitle isEqual:@"Take the Quiz"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToQuiz" object:nil];
    }
}


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
    [self.navigationController setNavigationBarHidden:NO];

    [self.textView setScrollEnabled:YES];
    [self.textView setUserInteractionEnabled:YES];
    [self setupView];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
