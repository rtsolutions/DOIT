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

#import "DDBMainViewController.h"

#import "DynamoDB.h"
#import "DDBDetailViewController.h"
#import "DDBDynamoDBManager.h"
#import "SingletonArrayObject.h"
#import "SingletonFavoritesArray.h"
#import "MainViewController.h"

@interface DDBMainViewController ()

// Array to hold items that will be displayed in cells
@property (nonatomic, readonly) NSMutableArray *tableRows;

// tableRows filtered by the search bar
@property (nonatomic, readwrite) NSMutableArray *filteredTableRows;

// Arrays to hold items with hashKeys 0000, 0001, 0002, 0003 so the app doesn't have
// to search through the whole array every time
@property (nonatomic, readonly) NSMutableArray *array0000;
@property (nonatomic, readonly) NSMutableArray *array0001;
@property (nonatomic, readonly) NSMutableArray *array0002;
@property (nonatomic, readonly) NSMutableArray *array0003;

// The current item from tableRows
@property (nonatomic, strong) DDBTableRow *tableRow;

// The item that was selected in the last table
@property (nonatomic, strong) DDBTableRow *parentItem;

// The rangeKey and title of the the item that was selected in the last table
@property (nonatomic, readwrite) NSString *parentID;
@property (nonatomic, readwrite) NSString *parentTitle;

// The dialable phone number and address on the current table for creating URLs.
// The URLs are used to open the dialer app or the maps app
@property (nonatomic, readwrite) NSString *phoneNumber;
@property (nonatomic, readwrite) NSString *address;

// Items leftover from DynamoDBSample. Not sure if still needed.
@property (nonatomic, readonly) NSLock *lock;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;

// Activate detail mode
@property (nonatomic, assign) BOOL showDetails;

// BOOLs to keep track of which items are already on the detail view
@property (nonatomic, assign) BOOL addressFlag;
@property (nonatomic, assign) BOOL phoneUsed;
@property (nonatomic, assign) BOOL faxUsed;
@property (nonatomic, assign) BOOL addressUsed;

// BOOL that indicates the search bar is being used
@property (nonatomic, assign) BOOL isFiltered;

@end

@implementation DDBMainViewController

#pragma mark - DynamoDB management


// Lists all items in the top level of the directory
- (void)refreshList: (BOOL)needsToRefresh {
    
    [self.tableRows removeAllObjects];
    
    for (DDBTableRow *item in self.array0000) {
        [self.tableRows addObject:item];
    }
}


// Adds the children of the selected object to the table
- (void)navigateDirectory {
    
    [self.tableRows removeAllObjects];
    
    for (DDBTableRow *item in [SingletonArrayObject sharedInstance].directoryArray) {
        
        if (item.parentID == self.parentID)
            [self.tableRows addObject:item];
    }
}


// Adds all items in the global favoritesArray to tableRows
- (void)showFavorites {
    
    [self.tableRows removeAllObjects];
    
    for (DDBTableRow *item in [SingletonFavoritesArray sharedInstance].favoritesArray)
    {
        [self.tableRows addObject:item];
    }
}


// Leftover from DynamoDBSample
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


// Sorts the directory into categories based on hashKey. hashKey really indicates the number
// of parents the item has. This is just to split the array so that the app doesn't have to scan through
// every item whenever it loads a tableView
- (void)sortItems {
    for (DDBTableRow *item in [SingletonArrayObject sharedInstance].directoryArray) {
        if ([item.hashKey  isEqual: @"0000"])
        {
            [self.array0000 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0001"])
        {
            [self.array0001 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0002"])
        {
            [self.array0002 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0003"])
        {
            [self.array0003 addObject:item];
        }
    }
}


#pragma mark - Action sheet


// Setup for the actionsheet (accessed by pressing the rightBarButtonItem)
- (IBAction)showActionSheet:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Your Action"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Home Menu",
                                  @"Add to Favorites", nil];
    
    [actionSheet showInView:self.tableView];
}


// Change the appearance of the action sheet buttons
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    
    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            
            // Only worry about the Add to Favorites button
            if ([button.currentTitle  isEqual: @"Add to Favorites"])
            {
                
                // Disable the Add to Favorites button if we're looking at the whole directory
                if (_parentItem.parentID == nil)
                {
                    [button setEnabled:NO];
                    return;
                }
                
                // If the current item is a favorite...
                BOOL alreadyFavorite = [[SingletonFavoritesArray sharedInstance].favoritesArray containsObject:self.parentItem];
            
                if (alreadyFavorite)
                {
                    // Change the button text to "Remove from Favorites
                    [button setTitle:@"Remove from Favorites" forState:UIControlStateNormal];
                }
            }
        }
    }
}


// Define actions for the action sheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            // Navigate back to the root view
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
            
        case 1:
        {
            BOOL alreadyFavorite = [[SingletonFavoritesArray sharedInstance].favoritesArray containsObject:self.parentItem];
            
            // If the item is already a favorite
            if (alreadyFavorite)
            {
                // Remove from favorites
                [[SingletonFavoritesArray sharedInstance].favoritesArray removeObject:self.parentItem];
                
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
            }
            else
            {
                // Add to favorites
                [[SingletonFavoritesArray sharedInstance].favoritesArray addObject:self.parentItem];
                
                // Sort the favoritesArray by title
                NSSortDescriptor *sortByTitleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
                
                NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByTitleDescriptor, nil];
                NSMutableArray *temp = [SingletonFavoritesArray sharedInstance].favoritesArray;
                [temp sortUsingDescriptors:sortingDescriptor];
                [SingletonFavoritesArray sharedInstance].favoritesArray = [temp mutableCopy];
                
                // Write the global favoritesArray to the .archive file so it persists
                [NSKeyedArchiver archiveRootObject: [SingletonFavoritesArray sharedInstance].favoritesArray toFile:@"/Users/rts/Desktop/DynamoDBSample/DynamoDBSample/favoritesArray.archive"];
                
                // Prepare a confirmation message
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Added to favorites!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                // Display confirmation message
                [alert show];
            }
            break;
        }
        default:
            break;
    }
}


// Search bar implementation
- (void)searchBar:(UISearchBar*) searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0)
    {
        self.isFiltered = NO;
    }
    else
    {
        self.isFiltered = YES;
        [self.filteredTableRows removeAllObjects];
        for (DDBTableRow *item in self.tableRows)
        {
            NSRange titleRange = [item.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(titleRange.location != NSNotFound)
            {
                [self.filteredTableRows addObject:item];
            }
        }
    }
    [self.tableView reloadData];
}

-(void)searchBarCancelButtonClicked: (UISearchBar *) searchbar {
    self.isFiltered = NO;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    NSArray *alphabet = [NSArray new];
    
    //if (!(self.showDetails = YES))
    {
        alphabet = [@"A B C D E F G H I J K L M N O P Q R S T U V W X Y Z" componentsSeparatedByString:@" "];
        
    }
    
    return alphabet;
    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.showDetails == YES && ([_tableRow.address length] > 0) && (!(self.addressFlag == YES)))
    {
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
        
        CGRect rect = [_tableRow.address boundingRectWithSize:CGSizeMake(200.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil];
        
        CGSize size = rect.size;
        self.addressFlag = YES;
        return size.height + 10;
    }
    
    return 40.0;
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    
    if (self.showDetails == YES) {
        if ([_tableRow.phone length] > 0)
        {
            rowCount++;
        }
        if ([_tableRow.fax length] > 0)
        {
            rowCount++;
        }
        if ([_tableRow.address length] > 0)
        {
            rowCount++;
        }
        return rowCount + 1;
    }
    else if (self.isFiltered == YES)
    {
        return [self.filteredTableRows count];
    }
    else
    {
        return [self.tableRows count];
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    
    if (self.showDetails == YES) {
        
        // If the tableRow has an address
        if ([_tableRow.address length] > 0)
        {
            if (!(self.addressUsed == YES))
            {
                cell.textLabel.text = @"Address:";
                cell.detailTextLabel.text = _tableRow.address;
                self.addressUsed = YES;
                
                [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
                cell.detailTextLabel.numberOfLines = 0;
                
                cell.userInteractionEnabled = YES;
                cell.accessoryType = UITableViewCellAccessoryNone;
                return cell;
            }
        }
        
        // If the tableRow has a phone number...
        if ([_tableRow.phone length] > 0)
        {
            // If there is not already a cell with phone number
            if (!(self.phoneUsed == YES))
            {
                // Add the phone number to a cell
                cell.textLabel.text = @"Phone:";
                cell.detailTextLabel.text = _tableRow.phone;
                cell.accessoryType = UITableViewCellAccessoryNone;
                
                // Don't use the phone number anymore
                self.phoneUsed = YES;
                return cell;
            }
            
        }
        
        // If the tableRow has a fax number
        if ([_tableRow.fax length] > 0)
        {
            // If there is not already a cell with a fax number
            if (!(self.faxUsed == YES))
            {
                // Add the fax number to a cell
                cell.textLabel.text = @"Fax:";
                cell.detailTextLabel.text = _tableRow.fax;
                
                // Don't use the fax number anymore
                self.faxUsed = YES;
                
                // Disable user interaciton so you can't call the fax number by touching it
                cell.userInteractionEnabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryNone;
                
                return cell;
            }
        }
        
        // Create dummy cell at the end so on pages with only addresses, the label
        // size is only 40
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.userInteractionEnabled = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        if (self.isFiltered == YES)
        {
            // Add rows that don't contain details
            DDBTableRow *item = self.filteredTableRows[indexPath.row];
            cell.textLabel.text = item.title;
            cell.detailTextLabel.text = nil;
            return cell;
        }
        else
        {
            // Add rows that don't contain details
            DDBTableRow *item = self.tableRows[indexPath.row];
            cell.textLabel.text = item.title;
            cell.detailTextLabel.text = nil;
            return cell;
        }
    }
    return cell;
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = cell.textLabel.text;
    
    
    if (self.showDetails == YES)
    {
        if ([cellText  isEqual: @"Address:"])
        {
            NSString *addressNoSpaces = [self.address stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            NSString *addressURL = [@"http://maps.apple.com?q=" stringByAppendingString:addressNoSpaces];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:addressURL]];
        }
        if ([cellText  isEqual: @"phone"])
        {
            NSString *phoneNumberURL = [@"tel://" stringByAppendingString:self.phoneNumber];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberURL]];
        }
    }
    
    else
    {
        [self performSegueWithIdentifier:@"navigateToMainView" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    DDBTableRow *indexRow = [self.tableRows objectAtIndex:indexPath.row];
    DDBMainViewController *mainVewController = [segue destinationViewController];
    
    // If the indexRow is an item that contains details...
    if ([indexRow.details isEqual:@"YES"])
    {
        // Setup the mainViewController for displaying details
        mainVewController.viewType = DDBMainViewTypeDetails;
        mainVewController.tableRow = indexRow;
        mainVewController.showDetails = YES;
        mainVewController.phoneNumber = indexRow.phone;
        mainVewController.address = indexRow.address;
        mainVewController.title = indexRow.title;
        
    }
    else
    {
        mainVewController.parentID = indexRow.rangeKey;
        mainVewController.viewType = DDBMainViewTypeChildren;
        mainVewController.title = indexRow.title;
        
    }
    mainVewController.parentItem = indexRow;
}

#pragma mark - View lifecycle

- (void)setupView{
    
    switch (self.viewType) {
            
        case DDBMainViewTypeAtoZ:
        {
            [self refreshList:YES];
            break;
        }
            
        case DDBMainViewTypeElectedOfficials:
        {
            [self navigateDirectory];
            break;
        }
            
        case DDBMainViewTypeByCounty:
        {
            [self showFavorites];
            break;
        }
            
        case DDBMainViewTypeChildren:
        {
            [self navigateDirectory];
            break;
        }
            
        case DDBMainViewTypeDetails:
        {
            break;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _tableRows = [NSMutableArray new];
    _filteredTableRows = [NSMutableArray new];
    _array0000 = [NSMutableArray new];
    _array0001 = [NSMutableArray new];
    _array0002 = [NSMutableArray new];
    _array0003 = [NSMutableArray new];
    _lock = [NSLock new];
    
    [self.navigationController.navigationBar setTranslucent:NO];

    [self.navigationController setNavigationBarHidden:NO];
    if (self.showDetails == YES)
    {
   //     self.tableView.contentOffset = CGPointMake(0,44);
    }
    
    [self sortItems];
    
    [self setupView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupView];
    [self.tableView reloadData];
}

@end
