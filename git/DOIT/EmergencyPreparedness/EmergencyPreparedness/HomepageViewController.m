//
//  HomepageViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 7/31/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "HomepageViewController.h"
#import "DynamoDB.h"
#import "DDBManager.h"
#import "SingletonArray.h"
#import "AlertViewController.h"

#import "QuartzCore/QuartzCore.h"

@interface HomepageViewController ()

@property (nonatomic, readonly) NSMutableArray *tableRows;
@property (nonatomic, readonly) NSCondition *lock;
@property (nonatomic, assign) BOOL startSetupStories;
@property (nonatomic, assign) BOOL startSetupView;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;
@property (nonatomic, retain) NSMutableArray *timeStamp;
@property (nonatomic, assign) BOOL updateDirectory;
@property (nonatomic, readwrite) NSMutableArray *stories;
@property (nonatomic, readwrite) NSMutableArray *dates;
@property NSString *storyString;
@property NSString *introString;
@property NSString *dateString;


@end

@implementation HomepageViewController

- (BFTask *)checkDatabaseForUpdate:(BOOL)check {
    
    if (check) {
        self.lastEvaluatedKey = nil;
        self.doneLoading = NO;
    }
    
    // Turn on the network activity indicator on the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    //Set up query expression to query all items with hashkey "update" (just the timestamp)
    AWSDynamoDBQueryExpression *queryExpression = [AWSDynamoDBQueryExpression new];
    queryExpression.limit = @20;
    queryExpression.hashKeyValues = (@"update");
    
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    
    // Query the database. Use BFTask to keep the method safe
    return [[[dynamoDBObjectMapper query:[DDBTableRow class]
                              expression:queryExpression]
             continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
                 
                 
                 AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                 
                 // Write time stamp back to array from .archive file
                 
                 NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timeStamp" ofType:@".archive"];
                 
                 
                 NSFileManager *manager = [NSFileManager defaultManager];
                 
                 if([manager fileExistsAtPath:filePath])
                 {
                     NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
                     unsigned long long size = [attributes fileSize];
                     if (attributes && size > 0)
                     {
                         self.timeStamp = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                         
                     }
                 }
                 
                 self.updateDirectory = [self.timeStamp isEqualToArray:paginatedOutput.items];
                 
                 if (!self.updateDirectory) {
                     // Write the new time stamp to timeStamp.archive
                     
                     [NSKeyedArchiver archiveRootObject: paginatedOutput.items toFile:filePath];
                 }
                 
                 
                 return nil;
             }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                 if (task.error) {
                     NSLog(@"Error: [%@]", task.error);
                 }
                 if (!(self.updateDirectory))
                 {
                     // Call refreshList to update the directory array
                     [self refreshList:YES];
                 }
                 
                 // Turn off network activity indicator in status bar
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 
                 return nil;
             }];
    
    
    return nil;
}


- (BFTask *)refreshList:(BOOL)startFromBeginning {
    

    
    if (startFromBeginning) {
        self.lastEvaluatedKey = nil;
        self.doneLoading = NO;
    }
    
    // Turn on the network activity indicator on the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center = self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    // Set up scan expression to download the database
    AWSDynamoDBScanExpression *scanExpression = [AWSDynamoDBScanExpression new];
    scanExpression.exclusiveStartKey = self.lastEvaluatedKey;
    scanExpression.limit = @10000;
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    
    // Scan the database. Use BFTask to keep the method safe
    return [[[dynamoDBObjectMapper scan:[DDBTableRow class]
                             expression:scanExpression]
             continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
                 if (!self.lastEvaluatedKey) {
                     [self.tableRows removeAllObjects];
                 }
                 
                 AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                 
                 
                 // Copy the new directory to the directory array
                 [SingletonArray sharedInstance].sharedArray = paginatedOutput.items;
                 
                 
                 // Write the directory array to an archive file
                 NSString *filePath = [[NSBundle mainBundle] pathForResource:@"alertArray" ofType:@".archive"];
                 
                 BOOL success = [NSKeyedArchiver archiveRootObject: [SingletonArray sharedInstance].sharedArray toFile:filePath];
                 
                 
                 
                 return nil;
             }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                 if (task.error) {
                     NSLog(@"Error: [%@]", task.error);
                 }
                 
                 [self sortItems];

                 // Turn of network activity indicator in status bar
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 [activityView stopAnimating];
                 
                 [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                 
                 return nil;
             }];
    
    return nil;
}


- (void)sortItems
{
    

    _stories = [NSMutableArray new];
    
    // Add the items with stories into the array
    for (DDBTableRow *item in [SingletonArray sharedInstance].sharedArray)
    {
        if ([item.intro length] > 0)
        {
            [self.stories addObject:item];
        }
    }
    
    // Sort the array by timestamp
    NSSortDescriptor *sortByTimestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                              ascending:NO];
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByTimestampDescriptor, nil];
    NSMutableArray *temp = self.stories;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.stories = temp;
    
    // Remove all but the last five items in the story array
    while ([self.stories count] > 5)
    {
        [self.stories removeLastObject];
    }
    
    // Put the intro strings in a separate array
    _introArray = [NSMutableArray new];
    
    for (DDBTableRow *item in self.stories)
    {
        [self.introArray addObject:item.intro];
    }
    
    
    // Parse the dates and add them to another array
    _dates = [NSMutableArray new];
    NSString *date = nil;
    NSString *year = nil;
    NSString *month = nil;
    NSString *day = nil;
    NSString *hour = nil;
    NSString *min = nil;
    NSString *ampm = nil;
    NSRange monthRange = NSMakeRange(4, 2);
    NSRange dayRange = NSMakeRange(6, 2);
    NSRange hourRange = NSMakeRange(8, 2);
    NSRange firstChar = NSMakeRange(0, 1);
    
    NSString *parsedDate = nil;
    
    for (DDBTableRow *item in self.stories)
    {
        date = item.timestamp;
        year = [date substringToIndex:4];
        month = [date substringWithRange:monthRange];
        day = [date substringWithRange:dayRange];
        hour = [date substringWithRange:hourRange];
        min = [date substringFromIndex:10];
        
        month = [month stringByReplacingOccurrencesOfString:@"0" withString:@"" options:0 range:firstChar];
        day = [day stringByReplacingOccurrencesOfString:@"0" withString:@"" options:0 range:firstChar];
        hour = [hour stringByReplacingOccurrencesOfString:@"0" withString:@"" options:0 range:firstChar];
        
        if ([hour integerValue] > 12)
        {
            NSInteger hourInt = [hour integerValue];
            hourInt -= 12;
            hour = [NSString stringWithFormat:@"%d",hourInt];
            ampm = @" PM";
        }
        else
        {
            ampm = @" AM";
        }
        
        month = [month stringByAppendingString:@"/"];
        day = [day stringByAppendingString:@"/"];
        year = [year stringByAppendingString:@"  "];
        hour = [hour stringByAppendingString:@":"];
        min = [min stringByAppendingString:ampm];
        
        parsedDate = [month stringByAppendingString:day];
        year = [year stringByAppendingString:hour];
        year = [year stringByAppendingString:min];
        parsedDate = [parsedDate stringByAppendingString:year];
        [self.dates addObject:parsedDate];
    }

    
    
    [self setupView];
}

- (void)setupView
{
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    self.pageViewController.view.frame = CGRectMake(14, 248, 292, 200);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound))
    {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound)
    {
        return nil;
    }
    
    index++;
    if (index == [self.introArray count])
    {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}


- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.introArray count] == 0) || (index >= [self.introArray count]))
    {
        return nil;
    }
    
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentController"];
    
    pageContentViewController.introString = self.introArray[index];
    pageContentViewController.dateString = self.dates[index];
    
    DDBTableRow *item = self.stories[index];
    pageContentViewController.storyString = item.text;


    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.introArray count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
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
        [self performSegueWithIdentifier:@"navigateToChecklist" sender:self];
    }
    else if ([buttonTitle isEqual:@"Being Prepared"])
    {
        [self performSegueWithIdentifier:@"navigateToBeingPreparedController" sender:self];
    }
}

/*
// Change the appearance of the action sheet buttons
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];

    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            

            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [button setBackgroundColor:[UIColor darkGrayColor]];
            //[button setBackgroundColor:[UIColor colorWithRed:84/255 green:90/255 blue:93/255 alpha:1.0]];
            //[button setTintColor:[UIColor lightGrayColor]];
            
            //[button setTintColor:[UIColor colorWithRed:84/255 green:90/255 blue:93/255 alpha:1.0]];
            if ([button.currentTitle  isEqual: @"Add to Favorites"])
            {
                
               
            }
        }
    }
}*/

- (void)popAndPushToChecklist
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [self performSegueWithIdentifier:@"navigateToChecklist" sender:self];
}

- (void)popAndPushToBeingPrepared
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [self performSegueWithIdentifier:@"navigateToBeingPreparedController" sender:self];
}



- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    
}


- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popAndPushToChecklist) name:@"popAndPushToChecklist" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popAndPushToBeingPrepared) name:@"popAndPushToBeingPrepared" object:nil];
    
    [super viewDidLoad];
    self.startSetupView = NO;
    self.startSetupStories = NO;
    _lock = [NSCondition new];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"alertArray" ofType:@".archive"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if([manager fileExistsAtPath:filePath])
    {
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long size = [attributes fileSize];
        if (attributes && size > 0)
        {
            [SingletonArray sharedInstance].sharedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            
        }
    }

    [self checkDatabaseForUpdate:YES];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
