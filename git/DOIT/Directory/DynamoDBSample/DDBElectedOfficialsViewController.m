/*
 * Copyright 2010-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "DDBElectedOfficialsViewController.h"

#import "DynamoDB.h"
#import "DDBDetailViewController.h"
#import "DDBDynamoDBManager.h"
#import "SingletonArrayObject.h"

@interface DDBElectedOfficialsViewController ()

@property (nonatomic, readwrite) NSMutableArray *tableRows;
@property (nonatomic, readonly) NSLock *lock;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;

@end

@implementation DDBElectedOfficialsViewController

#pragma mark - DynamoDB management

/*
 - (void)setupTable {
 // See if the test table exists.
 [[DDBDynamoDBManager describeTable]
 continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
 // If the test table doesn't exist, create one.
 if ([task.error.domain isEqualToString:AWSDynamoDBErrorDomain]
 && task.error.code == AWSDynamoDBErrorResourceNotFound) {
 [self performSegueWithIdentifier:@"DDBLoadingViewSegue"
 sender:self];
 
 return [[DDBDynamoDBManager createTable]
 continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
 // Handle errors.
 if (task.error) {
 NSLog(@"Error: [%@]", task.error);
 
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
 message:@"Failed to setup a test table."
 delegate:nil
 cancelButtonTitle:@"OK"
 otherButtonTitles:nil];
 [alert show];
 
 } else {
 [self dismissViewControllerAnimated:NO completion:nil];
 }
 
 return nil;
 }];
 }
 
 return nil;
 }];
 }
 */

/*- (BFTask *)refreshList: (BOOL)needsToRefresh {
    
    [self.tableRows removeAllObjects];
    
    
    for (DDBTableRow *item in [SingletonArrayObject sharedDirectory].directoryArray) {
        if ([item.electedofficial  isEqual: @"true"])
        [self.tableRows addObject:item];
    }
    return nil;
}
*/

- (void)deleteTableRow:(DDBTableRow *)row {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    [[dynamoDBObjectMapper remove:row]
     continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         
         if (task.error) {
             NSLog(@"Error: [%@]", task.error);
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Failed to delete a row."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
             
             [self.tableView reloadData];
         }
         
         return nil;
     }];
}

/*- (void)generateTestData {
 [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
 
 AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
 
 NSMutableArray *tasks = [NSMutableArray array];
 for (int32_t i = 1; i <= 100; i++) {
 DDBTableRow *tableRow = [DDBTableRow new];
 tableRow.rangeKey = [NSString stringWithFormat:@"RangeKey-%03d", i];
 tableRow.attribute1 = [NSString stringWithFormat:@"Attribute1-%03d", i];
 
 [tasks addObject:[dynamoDBObjectMapper save:tableRow]];
 }
 
 [[BFTask taskForCompletionOfAllTasks:tasks]
 continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
 if (task.error) {
 NSLog(@"Error: [%@]", task.error);
 }
 
 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 
 return [self refreshList:YES];
 }];
 }*/

#pragma mark - Action sheet

- (IBAction)showActionSheet:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Your Action"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Add",
                                  self.tableView.editing ? @"End Editing" : @"Edit",
                                  @"Generate Test Data",
                                  @"Refresh", nil];
    [actionSheet showInView:self.tableView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self performSegueWithIdentifier:@"DDBSegueElectedPushDetailViewController"
                                      sender:actionSheet];
            break;
            
        case 1:
            if (self.tableView.editing) {
                self.tableView.editing = NO;
            } else {
                self.tableView.editing = YES;
            }
            break;
            
            /*case 2:
             [self generateTestData];
             break;*/
            
        case 3:
            //[self refreshList:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    NSArray *alphabet = [@"A B C D E F G H I J K L M N O P Q R S T U V W X Y Z" componentsSeparatedByString:@" "];
    
    return alphabet;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    DDBTableRow *item = self.tableRows[indexPath.row];
    cell.textLabel.text = item.rangeKey;
    cell.detailTextLabel.text = nil; //item.attribute1;
        
    if (indexPath.row == [self.tableRows count] - 1 && !self.doneLoading) {
       // [self refreshList:NO];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DDBTableRow *row = self.tableRows[indexPath.row];
        [self deleteTableRow:row];
        
        [self.tableRows removeObject:row];
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"DDBSeguePushElectedDetailViewController"
                              sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDBDetailViewController *detailViewController = [segue destinationViewController];
    if ([sender isKindOfClass:[UIActionSheet class]]) {
        detailViewController.viewType = DDBDetailViewTypeInsert;
    } else if ([sender isKindOfClass:[UITableViewCell class]]) {
        detailViewController.viewType = DDBDetailViewTypeUpdate;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        DDBTableRow *tableRow = [self.tableRows objectAtIndex:indexPath.row];
        detailViewController.tableRow = tableRow;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableRows = [NSMutableArray new];
    _lock = [NSLock new];
    
    //[self setupTable];
    [self.navigationController setNavigationBarHidden:NO];
    //[self refreshList:YES];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
}

@end
