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

#import "DDBDetailViewController.h"

#import "DynamoDB.h"
#import "DDBDynamoDBManager.h"
#import "DDBMainViewController.h"
#import "DDBElectedOfficialsViewController.h"
#import "SingletonArrayObject.h"
#import "SingletonFavoritesArray.h"

@interface DDBDetailViewController ()

@property (nonatomic, assign) BOOL dataChanged;

@end

@implementation DDBDetailViewController

- (void)favoriteSetup {
    
    // Check if the current item is already in favoritesArray
    BOOL alreadyFavorite = [[SingletonFavoritesArray sharedInstance].favoritesArray containsObject:self.tableRow];
    
    if(alreadyFavorite)
    {
        self.favorite = YES;
    }
    else
    {
        self.favorite = NO;
    }
    // Set the rightBarButton to yellow or gray
    [self changeBarButton];
}

- (void)changeBarButton {
    if (self.favorite == YES)
    {
        // If the current item is a favorite, set the background image to Favorite.png--a yellow star
        [self.navigationItem.rightBarButtonItem setBackgroundImage:[UIImage imageNamed:@"Favorite.png"] forState:UIControlStateNormal barMetrics:0];
    }
    else if (self.favorite == NO)
    {
        // If the current item is not a favorite, set the background image to NotFavorite.png--
        // a gray star
        [self.navigationItem.rightBarButtonItem setBackgroundImage:[UIImage imageNamed: @"NotFavorite.png"] forState:UIControlStateNormal barMetrics:0];
    }
}

- (void)getTableRow {

    // Display the properties of the table row in static text boxes
    // TODO: turn this into a dynamic table, like the DDBMainViewController
    self.rangeKeyTextField.text = _tableRow.rangeKey;
    self.attribute1TextField.text = _tableRow.address;
    self.attribute2TextField.text = _tableRow.phone;
    self.attribute3TextField.text = _tableRow.fax;

}

- (void)insertTableRow:(DDBTableRow *)tableRow {
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    [[dynamoDBObjectMapper save:tableRow]
     continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
         if (!task.error) {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succeeded"
                                                             message:@"Successfully inserted the data into the table."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
             
             self.rangeKeyTextField.text = nil;
             self.attribute1TextField.text = nil;
             self.attribute2TextField.text = nil;
             self.attribute3TextField.text = nil;
             
             self.dataChanged = YES;
         } else {
             NSLog(@"Error: [%@]", task.error);
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Failed to insert the data into the table."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
         }
         
         return nil;
     }];
}

- (void)updateTableRow:(DDBTableRow *)tableRow {
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    [[dynamoDBObjectMapper save:tableRow]
     continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
         if (!task.error) {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succeeded"
                                                             message:@"Successfully updated the data in the table."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
             
             if (self.viewType == DDBDetailViewTypeInsert) {
                 self.rangeKeyTextField.text = nil;
                 self.attribute1TextField.text = nil;
             }
             
             self.dataChanged = YES;
         } else {
             NSLog(@"Error: [%@]", task.error);
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Failed to update the data in the table."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
         }
         
         return nil;
     }];
}

- (IBAction)submit:(id)sender {
    
    
    //ADD SORTING FUNCTION
    
    //COPY GLOBAL ARRAY TO NEW ARRAY TO SORT
    
    // If the current item is not a favorite...
    if (self.favorite == NO)
    {
        // Add the current item to the global favoritesArray
        [[SingletonFavoritesArray sharedInstance].favoritesArray addObject:self.tableRow];
        
        // Sort the favoritesArray by rangeKey
        NSSortDescriptor *sortByRangeKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rangeKey"
                                                                       ascending:YES];
        NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByRangeKeyDescriptor, nil];
        NSMutableArray *temp = [SingletonFavoritesArray sharedInstance].favoritesArray;
        [temp sortUsingDescriptors:sortingDescriptor];
        [SingletonFavoritesArray sharedInstance].favoritesArray = [temp mutableCopy];
        
        // Write the global favoritesArray to the .archive file so it persists
        [NSKeyedArchiver archiveRootObject: [SingletonFavoritesArray sharedInstance].favoritesArray toFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/favoritesArray.archive"];
        
        // Prepare confirmation message
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Added to favorites!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        // Display confirmation message
        [alert show];
        self.favorite = YES;
    }
    // If the current item is a favorite...
    else if (self.favorite == YES)
    {
        // Remove the current item to the global favoritesArray
        [[SingletonFavoritesArray sharedInstance].favoritesArray removeObject:self.tableRow];
        
        // Write the global favoritesArray to the .archive file so it persists
        [NSKeyedArchiver archiveRootObject: [SingletonFavoritesArray sharedInstance].favoritesArray toFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/favoritesArray.archive"];
        
        // Prepare a confirmation message
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Removed from favorites."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        // Display confirmation message
        [alert show];
        self.favorite = NO;
    }
    // Change the rightBarButton so it is appropriately yellow or gray
    [self changeBarButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self favoriteSetup];
    
    switch (self.viewType) {
        case DDBDetailViewTypeInsert:
            self.title = @"Insert";
            self.rangeKeyTextField.enabled = YES;
            
            break;
            
        case DDBDetailViewTypeUpdate:
            self.title = @"Update";
            self.rangeKeyTextField.enabled = YES;
            [self getTableRow];
            
            break;
            
        default:
            NSAssert(YES, @"Invalid viewType.");
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dataChanged) {
        DDBMainViewController *mainViewController = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 1];
        mainViewController.needsToRefresh = YES;
    }
}

@end
