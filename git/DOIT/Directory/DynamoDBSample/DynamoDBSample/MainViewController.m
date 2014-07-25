//
//  MainViewController.m
//  DynamoDBSample
//
//  Created by rts on 7/15/14.
//  Copyright (c) 2014 Amazon Web Services. All rights reserved.
//

#import "MainViewController.h"
#import "DynamoDB.h"
#import "DDBDetailViewController.h"
#import "DDBDynamoDBManager.h"
#import "SingletonArrayObject.h"



@interface MainViewController ()

@property (nonatomic, readonly) NSMutableArray *tableRows;
@property (nonatomic, readonly) NSLock *refreshLock;
@property (nonatomic, readonly) NSLock *checkForUpdateLock;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;
@property (nonatomic, retain) NSMutableArray *timeStamp;

@end

@implementation MainViewController

- (BFTask *)checkDatabaseForUpdate:(BOOL)check {
    _checkForUpdateLock = [NSLock new];

    if ([self.checkForUpdateLock tryLock]){
        if (check) {
            self.lastEvaluatedKey = nil;
            self.doneLoading = NO;
        }
        
        // Turn on the network activity indicator on the status bar
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        // Set up query expression to query all items with hashkey "0000"
        AWSDynamoDBQueryExpression *queryExpression = [AWSDynamoDBQueryExpression new];
        queryExpression.limit = @20;
        queryExpression.hashKeyValues = (@"0000");
        
        AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
        
        // Query the database. Use BFTask to keep the method safe
        return [[[dynamoDBObjectMapper query:[DDBTableRow class]
                                  expression:queryExpression]
                 continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {

                     
                     AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                     
                     
                     // Write time stamp back to array from .archive file
                     self.timeStamp = [NSKeyedUnarchiver unarchiveObjectWithFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/timeStamp.archive"];
                     
                     BOOL updateDirectory = [self.timeStamp isEqualToArray:paginatedOutput.items];
                     
                     if (!updateDirectory) {
                         // Write the new time stamp to timeStamp.archive
                         [NSKeyedArchiver archiveRootObject: self.timeStamp toFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/timeStamp.archive"];
                         
                         [self refreshList:YES];
                     }
                     
                     
                     return nil;
                 }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     
                     [self.checkForUpdateLock unlock];
                     
                     // Turn of network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     
                     return nil;
                 }];
    }
    return nil;
}


- (BFTask *)refreshList:(BOOL)startFromBeginning {
    if ([self.refreshLock tryLock]){
        if (startFromBeginning) {
            self.lastEvaluatedKey = nil;
            self.doneLoading = NO;
        }
        
        // Turn on the network activity indicator on the status bar
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        // Set up query expression to query all items with hashkey "0001"
        AWSDynamoDBQueryExpression *queryExpression = [AWSDynamoDBQueryExpression new];
        queryExpression.exclusiveStartKey = self.lastEvaluatedKey;
        queryExpression.limit = @20;
        queryExpression.hashKeyValues = (@"0001");
        
        AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];

        // Query the database. Use BFTask to keep the method safe
        return [[[dynamoDBObjectMapper query:[DDBTableRow class]
                                 expression:queryExpression]
                 continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
                     if (!self.lastEvaluatedKey) {
                         [self.tableRows removeAllObjects];
                     }
                     
                     AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                     
                     // Write directory back to array from .archive file
                     [SingletonArrayObject sharedInstance].directoryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/directoryArray.archive"];
                     
                     BOOL updateDirectory = [[SingletonArrayObject sharedInstance].directoryArray isEqualToArray:paginatedOutput.items];
                     
                     if (!updateDirectory) {
                         [SingletonArrayObject sharedInstance].directoryArray = paginatedOutput.items;
                         
                         // Write the directory array to an archive file
                         [NSKeyedArchiver archiveRootObject: [SingletonArrayObject sharedInstance].directoryArray toFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/directoryArray.archive"];
                     }
                     
                     
                     return nil;
                     }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     
                     [self.refreshLock unlock];
                         
                     // Turn of network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                     return nil;
                 }];
         }
     return nil;
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
    // Do any additional setup after loading the view.
    
    // Hide the navigation bar on startup
    [self.navigationController setNavigationBarHidden:YES];
    
    // Create a locks to keep the methods thread safe
    _refreshLock = [NSLock new];
    
    //
    [self checkDatabaseForUpdate:YES];
   // [self refreshList:YES];
    [SingletonArrayObject sharedInstance].directoryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/directoryArray.archive"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
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
