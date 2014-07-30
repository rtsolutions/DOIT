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
@property (nonatomic, readwrite) NSMutableArray *tableRows;


// tableRows filtered by the search bar
@property (nonatomic, readwrite) NSMutableArray *filteredTableRows;

// Array of counties -- possibly not needed
@property (nonatomic, readwrite) NSArray *countyArray;

// Number of sections the table will need when sorting items by county
@property (nonatomic, strong) NSMutableDictionary *sections;

// The current item from tableRows
@property (nonatomic, strong) DDBTableRow *tableRow;


// The number of parents of the current items, which is the hashKey. Use this string to specify
// which array to search in
@property (nonatomic, readwrite) NSInteger numParents;

// The item that was selected in the last table
@property (nonatomic, strong) DDBTableRow *parentItem;

// The rangeKey and title of the the item that was selected in the last table
@property (nonatomic, readwrite) NSString *parentID;
@property (nonatomic, readwrite) NSString *parentTitle;


// The dialable phone number and address on the current table for creating URLs.
// The URLs are used to open the dialer app or the maps app
// PHONE NUMBER MUST BE OF FORM 555-555-5555 -- NO SPACES ALLOWED
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
@property (nonatomic, readwrite) NSInteger phoneIndex;
@property (nonatomic, assign) BOOL faxUsed;
@property (nonatomic, readwrite) NSInteger faxIndex;
@property (nonatomic, assign) BOOL addressUsed;
@property (nonatomic, readwrite) NSInteger addressIndex;
@property (nonatomic, readwrite)  NSInteger arrayOffset;

// BOOL that indicates whether to list items by county
@property (nonatomic, assign) BOOL listingByCounty;
@property (nonatomic, assign) BOOL changedListingByCounty;
@property (nonatomic, readwrite) NSString *currentCounty;

// BOOL that indicates the search bar is being used
@property (nonatomic, assign) BOOL isFiltered;

// BOOL that indicates we're viewing favorites
@property (nonatomic, assign) BOOL showingFavorites;

@end

@implementation DDBMainViewController

#pragma mark - DynamoDB management


// Lists all items in the top level of the directory
- (void)refreshList: (BOOL)needsToRefresh {
    
    [self.tableRows removeAllObjects];
    
    for (DDBTableRow *item in self.array0000) {
        [self.tableRows addObject:item];
    }
    
    // Include elected officials in A to Z directory?
    /*
     for (DDBTableRow *item in self.electedOfficials) {
     [self.tableRows addObject:item];
     }*/
}


// Adds the children of the selected object to the table
- (void)navigateDirectory {
    
    [self.tableRows removeAllObjects];
    
    NSMutableArray *currentArray = nil;
    
    // Switch between arrays of items sorted by hashkey. This cuts down the time it takes to
    // scan through arrays.
    switch (self.numParents) {
        case (1):
        {
            currentArray = self.array0001;
            break;
        }
        case (2):
        {
            currentArray = self.array0002;
            break;
        }
        case (3):
        {
            currentArray = self.array0003;
            break;
        }
        case (6):
        {
            currentArray = self.electedOfficials;
            break;
        }
    }
    
    for (DDBTableRow *item in currentArray) {
        
        if ([item.parentID isEqual:self.parentID])
            [self.tableRows addObject:item];
    }
}


// Adds all items in the global favoritesArray to tableRows
- (void)showFavorites {
    
    [self.tableRows removeAllObjects];
    self.showingFavorites = YES;
    
    for (DDBTableRow *item in [SingletonFavoritesArray sharedInstance].favoritesArray)
    {
        [self.tableRows addObject:item];
    }
}

// Shows just two menu options: Senate and House of Representatives
- (void)showElectedOfficials {
    [self.tableRows removeAllObjects];
    for (DDBTableRow *item in self.houseAndSenate)
    {
        [self.tableRows addObject:item];
    }
}

// Sorts the directory by county, rather than alphabetically
- (void)showCounties {
    self.listingByCounty = YES;
    
    [self.tableRows removeAllObjects];
    
    // Add the items which have counties to tableRows
    for (DDBTableRow *item in [SingletonArrayObject sharedInstance].directoryArray)
    {
        if ([item.county length] > 0)
        {
            [self.tableRows addObject:item];
        }
    }
    
    // Sort the array alphabetically by county, then alphabetically by title
    NSSortDescriptor *sortByTitleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                          ascending:YES];
    NSSortDescriptor *sortByCountyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"county" ascending:YES];
    
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByCountyDescriptor, sortByTitleDescriptor, nil];
    NSMutableArray *temp = self.tableRows;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.tableRows = [temp mutableCopy];
    
    // Create sections in a dictionary for each county
    self.sections = [NSMutableDictionary dictionary];
    
    for (DDBTableRow *item in self.tableRows)
    {
        NSMutableArray *listingsInCountyArray = [self.sections objectForKey:@"county"];
        
        if (listingsInCountyArray == nil)
        {
            listingsInCountyArray = [NSMutableArray array];
            
            [self.sections setObject:listingsInCountyArray forKey:item.county];
        }
        
        [listingsInCountyArray addObject:item];
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
                if (_parentItem == nil)
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
    
    // If there is no text in the search bar, don't do anything
    if (searchText.length == 0)
    {
        self.isFiltered = NO;
    }
    else
    {
        self.isFiltered = YES;
        
        if (self.listingByCounty == YES)
        {
            self.changedListingByCounty = YES;
        }
        
        self.listingByCounty = NO;
        
        // Clear filteredTableRows
        [self.filteredTableRows removeAllObjects];
        
        // Scan through tableRows for the text in the search bar
        for (DDBTableRow *item in self.tableRows)
        {
            NSRange titleRange = [item.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(titleRange.location != NSNotFound)
            {
                // If a match is found, add the current item to filteredTableRows
                [self.filteredTableRows addObject:item];
            }
        }
    }
    // Refresh the table
    [self.tableView reloadData];
}


-(void)searchBarCancelButtonClicked: (UISearchBar *) searchbar {
    // If the cancel button is clicked, reload the table with all of the data instead of the
    // filtered results
    self.isFiltered = NO;
    
    if (self.changedListingByCounty == YES);
    {
        self.listingByCounty = YES;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    // Selection Index for quick scrolling through the table. Lists the alphabet on the right
    // side of the screen
    
    // if (!(self.showDetails = YES))
    {
        NSArray *alphabet = [NSArray new];
        
        alphabet = [@"A B C D E F G H I J K L M N O P Q R S T U V W X Y Z" componentsSeparatedByString:@" "];
        
        return alphabet;
    }
    
    //  return nil;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.listingByCounty)
    {
        return [self.sections count];
    }
    else
    {
        return 1;
    }
}


// heightForRowAtIndexPath changes the height of a particular cell on the tableView.
// In this case, the only height we want to change is the cell with an address inside,
// because it takes up multiple lines.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // If the screen is desplaying details, and the current table row contains an address,
    // and we haven't added the address to the table yet
    if (self.showDetails == YES && ([_tableRow.address length] > 0) && (!(self.addressFlag == YES)))
    {
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
        
        // Create a rectangle that bounds the text. Width is 200, and height is calculated based on
        // how much space the text would need if it wraps.
        CGRect rect = [_tableRow.address boundingRectWithSize:CGSizeMake(200.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil];
        
        // Mark that the current table already has an address on it, and we don't need to change the size
        // of any other cells
        self.addressFlag = YES;
        
        // The height of the cell is equal to the height of the rectangle, plus 10 to give the
        // text a little bit of room on the top and bottom
        CGSize size = rect.size;
        return size.height + 10;
    }
    
    // If we're not displaying an address, just use 40 as the size of each cell
    return 44.0;
    
    
}


// numberOfRowsInSection has three cases: displaying details, displaying search results, and displaying
// the whole table. numberOfRowsInSection must be calculated before drawing each table.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // If we're displaying details, check to see if the item has a phone number, fax, and address.
    // Add one to rowCount for phone number and fax. For address, add two, so we can display a dummy
    // cell at the end. If we don't do this, the size of every cell will be the size of the address
    // cell (big) and that looks messy.
    
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
            rowCount++;
        }
    }
    // If we're viewing search results, return the number of items in the filteredTableRows array
    if (self.isFiltered == YES)
    {
        return (rowCount + [self.filteredTableRows count]);
    }
    if (self.listingByCounty == YES)
    {
        DDBTableRow *item = [self.tableRows objectAtIndex:section];
        NSArray *listingsInCountyArray = [self.sections objectForKey:item.county];
        return [listingsInCountyArray count];
    }
    // Otherwise just return the number of items in tableRows
    rowCount += [self.tableRows count];
    
    return rowCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.listingByCounty == YES)
    {
        DDBTableRow *item = [self.tableRows objectAtIndex:section];
        return item.county;
    }
    else
    {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    // I am so sorry for this.
    // In future directory apps, each detail should get its own entry in the database to avoid
    // nasty workarounds like this. If the detail has already been loaded, keep track of its
    // index so we can load it again if we scroll down and up. Otherwise, we get an out of range
    // error.
    
    if (indexPath.row == self.addressIndex)
    {
        goto label1;
    }
    if (indexPath.row == self.phoneIndex)
    {
        goto label2;
    }
    if (indexPath.row == self.faxIndex)
    {
        goto label3;
    }

    
    if (self.showDetails == YES) {
        
        // If the tableRow has an address
        if ([_tableRow.address length] > 0)
        {
            // If we haven't displayed an address yet
            if (!(self.addressUsed == YES))
            {
                // Don't try to make another address cell
                self.addressUsed = YES;
                
                self.arrayOffset++;
                
                self.addressIndex = indexPath.row;
                
            label1:
                
                // Create a cell with the string in _tableRow.address
                cell.textLabel.text = @"Address:";
                cell.detailTextLabel.text = _tableRow.address;
                
                // Word wrap so we can see the whole address. Setting the numberOfLines to 0 allows
                // the string to use as many lines as it needs.
                [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
                cell.detailTextLabel.numberOfLines = 0;
                
                // Let users click on the cell, which brings up the maps app with the address string
                cell.userInteractionEnabled = YES;
                
                // Don't display the arrow on the right side of the cell
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
                // Don't use the phone number anymore
                self.phoneUsed = YES;
                self.arrayOffset++;
                self.phoneIndex = indexPath.row;
                
            label2:
                
                // Add the phone number to a cell
                cell.textLabel.text = @"Phone:";
                cell.detailTextLabel.text = _tableRow.phone;
                
                // Don't display the arrow on the right side of the cell
                cell.accessoryType = UITableViewCellAccessoryNone;
                

                return cell;
            }
            
        }
        
        // If the tableRow has a fax number
        if ([_tableRow.fax length] > 0)
        {
            // If there is not already a cell with a fax number
            if (!(self.faxUsed == YES))
            {
                // Don't use the fax number anymore
                self.faxUsed = YES;
                self.arrayOffset++;
                self.faxIndex = indexPath.row;
                
            label3:
                
                // Add the fax number to a cell
                cell.textLabel.text = @"Fax:";
                cell.detailTextLabel.text = _tableRow.fax;
                
                
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
    
    if (self.isFiltered == YES)
    {
        // Add rows that don't contain details
        DDBTableRow *item = self.filteredTableRows[indexPath.row-self.arrayOffset];
        cell.textLabel.text = item.title;
        cell.detailTextLabel.text = nil;
        return cell;
    }
    /*****Trying to put a little more information on the favorites screen. Not really enough room, though*****
     else if (self.showingFavorites == YES)
     {
     
     [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
     cell.detailTextLabel.numberOfLines = 1;
     
     DDBTableRow *item = self.tableRows[indexPath.row];
     if ([item.hashKey integerValue] <= 4)
     {
     for (DDBTableRow *possibleParent in [SingletonArrayObject sharedInstance].directoryArray)
     {
     if ([possibleParent.hashKey integerValue] <= 4)
     {
     if ([item.parentID isEqual: possibleParent.rangeKey])
     {
     cell.textLabel.text = possibleParent.title;
     }
     }
     }
     }
     
     else if ([item.hashKey integerValue] > 4)
     {
     for (DDBTableRow *possibleParent in [SingletonArrayObject sharedInstance].directoryArray)
     {
     if ([possibleParent.hashKey integerValue] > 4)
     {
     if ([item.parentID isEqual: possibleParent.rangeKey])
     {
     cell.textLabel.text = possibleParent.title;
     }
     }
     }
     
     }
     
     
     cell.detailTextLabel.text = item.title;
     }*/
    
    if (self.listingByCounty == YES)
    {
        DDBTableRow *item = [self.tableRows objectAtIndex:indexPath.section];
        NSArray *listingsInCountyArray = [self.sections objectForKey:item.county];
        
        DDBTableRow *listing = [listingsInCountyArray objectAtIndex:indexPath.row];
        
        cell.textLabel.text=listing.title;
        cell.detailTextLabel.text = nil;
        
        return cell;
    }
    
    // Add rows that don't contain details
    if (_tableRows.count)
    {
        DDBTableRow *item = self.tableRows[indexPath.row-self.arrayOffset];
        cell.textLabel.text = item.title;
        cell.detailTextLabel.text = nil;
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    return cell;
}


// Disable user editing. This keeps users from swiping on table cells to reveal a "delet" button
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


// didSelectRowAtIndexPath is called when the user selects a cell on a tableview. It passes the index
// of the selected cell.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Show the deselect animation when the user lifts their finger
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Get the text from the cell label so we can tell if we have an address or a phone number
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = cell.textLabel.text;
    
    // On a details screen....

        if ([cellText  isEqual: @"Address:"])
        {
            // Create a string that's compatible with the maps app ("Albuquerque, New Mexico" becomes
            // "Albuquerque,+New+Mexico") and append it to the Apple maps URL. Open the maps app
            // with this string.
            NSString *addressNoSpaces = [self.address stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            NSString *addressURL = [@"http://maps.apple.com?q=" stringByAppendingString:addressNoSpaces];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:addressURL]];
            return;
        }
        if ([cellText  isEqual: @"phone"])
        {
            // Create a phone URL, and open up the dialer with the number.
            NSString *formattedPhoneNumber = [self.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
            
            
            NSString *phoneNumberURL = [@"tel://" stringByAppendingString:formattedPhoneNumber];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberURL]];
            return;
        }

        // If we're not on a details screen, the only other option is to open up a new tableview
        // with the children of the selected cell.
        if (self.listingByCounty == YES)
        {
            self.currentCounty = [self tableView:tableView titleForHeaderInSection:indexPath.section];
        }
        [self performSegueWithIdentifier:@"navigateToMainView" sender:[tableView cellForRowAtIndexPath:indexPath]];
  
}

#pragma mark - Navigation


// prepareForSegue sends information to the destination viewcontroller. It is called by
// performSegueWithIdentifier
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    DDBMainViewController *mainVewController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    DDBTableRow *indexRow = nil;
    
    if (self.listingByCounty == YES)
    {
        NSArray *listingsInCounty = [self.sections objectForKey:self.currentCounty];
        indexRow = [listingsInCounty objectAtIndex:indexPath.row];
    }
    else
    {
        indexRow = [self.tableRows objectAtIndex:(indexPath.row-self.arrayOffset)];
    }
    
    
    // If the indexRow is an item that contains details...
    if ([indexRow.details isEqual:@"YES"])
    {
        // Setup the mainViewController for displaying details
        //mainVewController.viewType = DDBMainViewTypeDetails;
        mainVewController.tableRow = indexRow;
        mainVewController.showDetails = YES;
        mainVewController.phoneNumber = indexRow.phone;
        mainVewController.address = indexRow.address;
        mainVewController.title = indexRow.title;
        
    }
    
    
    mainVewController.parentID = indexRow.rangeKey;
    mainVewController.viewType = DDBMainViewTypeChildren;
    mainVewController.title = indexRow.title;
    
    
    mainVewController.parentItem = indexRow;
    NSInteger temp = [indexRow.hashKey integerValue];
    temp++;
    mainVewController.numParents = temp;
    
    if (temp <= 4)
    {
        mainVewController.array0000 = self.array0000;
        mainVewController.array0001 = self.array0001;
        mainVewController.array0002 = self.array0002;
        mainVewController.array0003 = self.array0003;
    }
    else if (temp >= 5 && temp <=7)
    {
        mainVewController.electedOfficials = self.electedOfficials;
        mainVewController.houseAndSenate = self.houseAndSenate;
    }
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
            [self showElectedOfficials];
            break;
        }
            
        case DDBMainViewTypeByCounty:
        {
            [self showCounties];
            //Need to create a new case for favorites
            //[self showFavorites];
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
    
    _lock = [NSLock new];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    // Trying to hide search bar on a details page, but I can't get it to work. Perhaps a better
    // approach would be to hide the search bar if the number of cells in the tableview is less than ten,
    // but I can't seem to find the code that hides the search bar at all.
    if (self.showDetails == YES)
    {
        //     self.tableView.contentOffset = CGPointMake(0,44);
    }
    
    [self setupView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reset all of the detail flags
    _phoneUsed = NO;
    _faxUsed = NO;
    _addressUsed = NO;
    _arrayOffset = 0;
    _addressIndex = -1;
    _phoneIndex = -1;
    _faxIndex = -1;
    
    [self setupView];
    [self.tableView reloadData];
}

@end
