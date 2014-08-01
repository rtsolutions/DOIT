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

@interface HomepageViewController ()

@property (nonatomic, readonly) NSMutableArray *tableRows;
@property (nonatomic, readonly) NSLock *lock;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;
@property (nonatomic, retain) NSMutableArray *timeStamp;
@property (nonatomic, assign) BOOL updateDirectory;
@property (nonatomic, readwrite) NSMutableArray *stories;
@property (nonatomic, readwrite) NSString *storyString;

@end

@implementation HomepageViewController

- (BFTask *)checkDatabaseForUpdate:(BOOL)check {
    _lock = [NSLock new];
    if ([self.lock tryLock]){
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
                     self.timeStamp = [NSKeyedUnarchiver unarchiveObjectWithFile:@"timeStamp.archive"];
                     
                     self.updateDirectory = [self.timeStamp isEqualToArray:paginatedOutput.items];
                     
                     if (!self.updateDirectory) {
                         // Write the new time stamp to timeStamp.archive
                         [NSKeyedArchiver archiveRootObject: paginatedOutput.items toFile:@"timeStamp.archive"];
                     }
                     
                     
                     return nil;
                 }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     if (!(self.updateDirectory))
                     {
                         // Call refreshList to update the directory array
                         [self.lock unlock];
                         [self refreshList:YES];
                     }
                     
                     // Turn off network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     
                     return nil;
                 }];
        
        
    }
    return nil;
}


- (BFTask *)refreshList:(BOOL)startFromBeginning {
    if ([self.lock tryLock]){
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
                     [SingletonArray sharedInstance].alertsArray = paginatedOutput.items;
                     
                     // Sort the array by title
                     NSSortDescriptor *sortByRangeKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                              ascending:YES];
                     NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByRangeKeyDescriptor, nil];
                     NSMutableArray *temp = [SingletonArray sharedInstance].alertsArray;
                     [temp sortUsingDescriptors:sortingDescriptor];
                     [SingletonArray sharedInstance].alertsArray = [temp mutableCopy];
                     
                     // Write the directory array to an archive file
                     [NSKeyedArchiver archiveRootObject: [SingletonArray sharedInstance].alertsArray toFile:@"alertArray.archive"];
                     
                     
                     
                     return nil;
                 }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     
                     [self.lock unlock];
                     [self sortItems];
                     
                     // Turn of network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     [activityView stopAnimating];
                     
                     [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                     
                     return nil;
                 }];
    }
    return nil;
}


- (void) sortItems {
    for (DDBTableRow *item in [SingletonArray sharedInstance].alertsArray)
    {
        [self.stories addObject:item];

    }
    [self.tableView reloadData];
}


/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.stories count];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // If the screen is desplaying details, and the current table row contains an address,
    // and we haven't added the address to the table yet
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
    DDBTableRow *item = [self.stories objectAtIndex:indexPath.row];
    
    // Create a rectangle that bounds the text. Width is 200, and height is calculated based on
    // how much space the text would need if it wraps.
    CGRect rect = [item.intro boundingRectWithSize:CGSizeMake(200.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil];
    
    // The height of the cell is equal to the height of the rectangle, plus 10 to give the
    // text a little bit of room on the top and bottom
    CGSize size = rect.size;
    return size.height + 10;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    DDBTableRow *item = [self.stories objectAtIndex:indexPath.row];
    
    cell.textLabel.text = item.intro;
    
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    
    cell.textLabel.numberOfLines = 2;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    

    // Show the deselect animation when the user lifts their finger
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DDBTableRow *item = [self.stories objectAtIndex:indexPath.row];
    
    self.storyString = item.story;
    
    [self performSegueWithIdentifier:@"pushToAlert" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    AlertViewController *alertViewController = [segue destinationViewController];
    
    alertViewController.storyString = self.storyString;

}


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    self.stories = [NSMutableArray new];
    self.storyString = [NSString new];
    
    
    [SingletonArray sharedInstance].alertsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:@"alertArray.archive"];
    
    [self checkDatabaseForUpdate:YES];
    [self.tableView reloadData];
    

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
