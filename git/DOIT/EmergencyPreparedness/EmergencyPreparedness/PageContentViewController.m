//
//  PageContentViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/4/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "PageContentViewController.h"
#import "AlertViewController.h"

@interface PageContentViewController ()

@end

@implementation PageContentViewController

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
    
    self.introTextField.text = self.introString;
    self.dateLabel.text = self.dateString;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AlertViewController *alertViewController = [segue destinationViewController];
    alertViewController.storyString = self.storyString;
    alertViewController.dateString = self.dateString;
    alertViewController.introString = self.introString;
}


@end
