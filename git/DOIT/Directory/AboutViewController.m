//
//  AboutViewController.m
//  DynamoDBSample
//
//  Created by rts on 8/15/14.
//  Copyright (c) 2014 Amazon Web Services. All rights reserved.
//

#import "AboutViewController.h"
#import "Constants.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

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
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.versionLabel.text = [NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleShortVersionString"]];
    
    self.directoryLabel.text = [@"Database: " stringByAppendingString: AWSSampleDynamoDBTableName];
    
    self.title = @"About";
    
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
