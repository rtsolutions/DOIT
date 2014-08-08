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



- (void)setupView {
    
    self.textView.text = self.storyString;
    self.dateLabel.text = self.dateString;

    self.introTextLabel.numberOfLines = 0;
    [self.introTextLabel sizeToFit];
    self.introTextLabel.text = self.introString;
    
    
}



- (IBAction)showActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Home", @"Being Prepared", @"Checklist", @"Take the Quiz", nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet showFromBarButtonItem:self.menuButton animated:YES];
}


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
}


// Change the appearance of the action sheet buttons
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    
    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setBackgroundImage: [UIImage imageNamed:@"alert.png"] forState:UIControlStateNormal];
            
            [button setBackgroundColor:[UIColor darkGrayColor]];
            if ([button.currentTitle  isEqual: @"Add to Favorites"])
            {
                
                
            }
        }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
