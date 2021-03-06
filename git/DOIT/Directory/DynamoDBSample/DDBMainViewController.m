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

// Array to hold favorites items ([singletonArrayObject SharedInstance].favoritesArray only
// holds rangeKeys
@property (nonatomic, readwrite) NSMutableArray *favoritesArray;

// Array of counties -- possibly not needed
@property (nonatomic, readwrite) NSArray *countyArray;

// Number of sections the table will need when sorting items by county
@property (nonatomic, strong) NSMutableDictionary *sections;

// Array of counties in _sections
@property (nonatomic, strong) NSArray *sortedSections;

// The current item from tableRows
@property (nonatomic, strong) DDBTableRow *tableRow;


// The number of parents of the current items, which is the hashKey. Use this string to specify
// which array to search in
@property (nonatomic, readwrite) NSInteger directoryLevel;

// The item that was selected in the last table
@property (nonatomic, strong) DDBTableRow *parentItem;

// The rangeKey and title of the the item that was selected in the last table
@property (nonatomic, readwrite) NSString *parentID;
@property (nonatomic, readwrite) NSString *parentTitle;


// The dialable phone number and address on the current table for creating URLs.
// The URLs are used to open the dialer app or the maps app
// PHONE NUMBER MUST BE OF FORM 555-555-5555 -- NO SPACES ALLOWED (1-800 numbers are fine)
@property (nonatomic, readwrite) NSString *phoneNumber;
@property (nonatomic, readwrite) NSString *address;
@property (nonatomic, readwrite) NSString *tollFree;
@property (nonatomic, readwrite) NSString *phoneNumber2;


// Activate detail mode
@property (nonatomic, assign) BOOL showDetails;


// BOOLs to keep track of which items are already on the detail view
@property (nonatomic, assign) BOOL addressFlag;

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
    
    for (DDBTableRow *item in self.directoryLevel1) {
        [self.tableRows addObject:item];
    }
}


// Adds the children of the selected object to the table
- (void)navigateDirectory {
    
    [self.tableRows removeAllObjects];
    
    NSMutableArray *currentArray = nil;
    
    // Switch between arrays of items sorted by hashkey. This cuts down the time it takes to
    // scan through arrays.
    switch (self.directoryLevel) {
        case (1):
        {
            currentArray = self.directoryLevel2;
            break;
        }
        case (2):
        {
            currentArray = self.directoryLevel3;
            break;
        }
        case (3):
        {
            currentArray = self.directoryLevel4;
            break;
        }
        case (4):
        {
            currentArray = self.directoryLevel5;
            break;
        }
        case (6):
        {
            currentArray = self.electedOfficials;
            break;
        }
    }
    
    // Add the children of the selected item to _tableRows
    for (DDBTableRow *item in currentArray) {
        
        if ([item.parentID isEqual:self.parentID])
            [self.tableRows addObject:item];
    }
    
    if (self.showDetails == YES)
    {
        [self addDetails];
    }
}


// Adds all items in the global favoritesArray to tableRows. Instead of storing the items themselves in the favorites
// array, we essentially store a reference to it, in the form of the rangeKey. We then search through the directory
// array for the items that match the rangeKey, so the favorites will update with the rest of the app.
- (void)showFavorites {
    [self.favoritesArray removeAllObjects];
    [self.tableRows removeAllObjects];
    self.showingFavorites = YES;
    
    for (NSString *favoriteString in [SingletonFavoritesArray sharedInstance].favoritesArray)
    {
        for (DDBTableRow *item in [SingletonArrayObject sharedInstance].directoryArray)
        {
            NSString *possibleFavoriteString = [item.hashKey stringByAppendingString:item.rangeKey];
            if ([favoriteString isEqual:possibleFavoriteString])
            {
                [self.favoritesArray addObject:item];
                break;
            }
        }
    }
    
    // Sort the favoritesArray by title
    NSSortDescriptor *sortByTitleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByTitleDescriptor, nil];
    NSMutableArray *temp = self.favoritesArray;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.favoritesArray = [temp mutableCopy];
    for (DDBTableRow *item in self.favoritesArray)
    {
        [self.tableRows addObject:item];
    }
}

// Shows the different branches of elected officials
- (void)showElectedOfficials {
    [self.tableRows removeAllObjects];
    for (DDBTableRow *item in self.houseAndSenate)
    {
        [self.tableRows addObject:item];
    }
}


- (void) showN11 {
    [self.tableRows removeAllObjects];
    for (DDBTableRow *item in self.n11)
    {
        [self.tableRows addObject:item];
    }
}

- (void) showNonEmergencyContacts {
    [self.tableRows removeAllObjects];
    for (DDBTableRow *item in self.nonEmergencyContacts)
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
        NSMutableArray *listingsInCountyArray = [self.sections objectForKey:item.county];
        
        if (listingsInCountyArray == nil)
        {
            listingsInCountyArray = [NSMutableArray array];
            
            [self.sections setObject:listingsInCountyArray forKey:item.county];
        }
        
        [listingsInCountyArray addObject:item];
    }
    
    NSArray *unsortedSections = [self.sections allKeys];
    self.sortedSections = [unsortedSections sortedArrayUsingSelector:@selector(compare:)];
    
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
    
    NSString *favoriteString = [_parentItem.hashKey stringByAppendingString:_parentItem.rangeKey];
    
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
                BOOL alreadyFavorite = [[SingletonFavoritesArray sharedInstance].favoritesArray containsObject:favoriteString];
                
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
            NSString *hashKeyString = _parentItem.hashKey;
            NSString *rangeKeyString = _parentItem.rangeKey;
            
            NSString *favoriteString = [hashKeyString stringByAppendingString:rangeKeyString];
            
            BOOL alreadyFavorite = [[SingletonFavoritesArray sharedInstance].favoritesArray containsObject:favoriteString];
            
            // filePath to favoritesArray.archive
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [paths objectAtIndex:0];
            NSString *filePath = [documentPath stringByAppendingString:@"/favoritesArray.archive"];
            
            // If the item is already a favorite
            if (alreadyFavorite)
            {
                // Remove from favorites
                [[SingletonFavoritesArray sharedInstance].favoritesArray removeObject:favoriteString];
                
                // Write the global favoritesArray to the .archive file so it persists
                [NSKeyedArchiver archiveRootObject: [SingletonFavoritesArray sharedInstance].favoritesArray toFile:filePath];
                
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
                [[SingletonFavoritesArray sharedInstance].favoritesArray addObject:favoriteString];
                
                // [[SingletonFavoritesArray sharedInstance].favoritesArray removeAllObjects];  //Use this line to empty the favorites array
                // Write the global favoritesArray to the .archive file so it persists
                [NSKeyedArchiver archiveRootObject: [SingletonFavoritesArray sharedInstance].favoritesArray toFile:filePath];
                
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
    
    if (self.changedListingByCounty == YES)
    {
        self.listingByCounty = YES;
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    // Selection Index for quick scrolling through the table. Lists the alphabet on the right
    // side of the screen
    
    
    NSArray *alphabet = [@"A B C D E F G H I J K L M N O P Q R S T U V W X Y Z" componentsSeparatedByString:@" "];
    
    return alphabet;
    
}


// Implementation of quick scroll. Gives us the title and index of the selected section--in this case, a single letter
// from A to Z
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (!(self.listingByCounty))
    {
        // Extract the first character of each cell's title.
        for (int i = 0; i < [self.tableRows count]; i++) {
            DDBTableRow *item = [self.tableRows objectAtIndex:i];
            NSString *letterString = [item.title substringToIndex:1];
            NSComparisonResult result = [letterString compare:title];
            
            // If we pass the selected letter, scroll to the last character we checked
            if (result == NSOrderedDescending) {
                if (i > 0)
                {
                    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(i-2) inSection:0] atScrollPosition: UITableViewScrollPositionTop animated:YES];
                    return (i-2);
                }
                
            }
        }
        // If we never get a NSOrderedDescending result, scroll all the way to the end.
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.tableRows count]-1) inSection:0] atScrollPosition: UITableViewScrollPositionTop animated:YES];
        return ([self.tableRows count]-1);
    }
    else // if we're listing by county, do the same thing but use the first letter of the counties instead of the
         // first letter of the cell
    {
        for (int i = 0; i < [self.sortedSections count]; i++) {
            NSString *item = [self.sortedSections objectAtIndex:i];
            NSString *letterString = [item substringToIndex:1];
            NSComparisonResult result = [letterString compare:title];
            if (result == NSOrderedDescending) {
                if (i > 0)
                {
                    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:(i-1)] atScrollPosition: UITableViewScrollPositionTop animated:YES];
                    return (i-1);
                }
                else
                {
                    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:(i)] atScrollPosition: UITableViewScrollPositionTop animated:YES];
                    return (i);
                }
            }
        }
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: 0 inSection:([self.sortedSections count]-1)] atScrollPosition: UITableViewScrollPositionTop animated:YES];
        return ([self.sortedSections count]-1);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Add a section for each county
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
        
        // Create a rectangle that bounds the text. Width is 185, and height is calculated based on
        // how much space the text would need if it wraps.
        CGRect rect = [_tableRow.address boundingRectWithSize:CGSizeMake(185.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil];
        
        // Mark that the current table already has an address on it, and we don't need to change the size
        // of any other cells
        self.addressFlag = YES;
        
        // The height of the cell is equal to the height of the rectangle, plus 10 to give the
        // text a little bit of room on the top and bottom
        CGSize size = rect.size;
        return size.height + 10;
    }
    
    // lisingByCounty needs a little bit of extra space
    if (self.listingByCounty == YES)
    {
        return 66.0;
    }
    
    // If we're not displaying an address or a county listing, just use 44 as the size of each cell
    return 44.0;
    
    
}


// numberOfRowsInSection has three cases: displaying details, displaying search results, and displaying
// the whole table. numberOfRowsInSection must be calculated before drawing each table.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // If we're displaying details, check to see if the item has a phone number, fax, and address.
    // Add one to rowCount for phone number and fax. For address, add two, so we can display a dummy
    // cell at the end. If we don't do this, the size of every cell will be the size of the address
    // cell (big) and that looks messy.
    
    // If we're viewing search results, return the number of items in the filteredTableRows array
    if (self.isFiltered == YES)
    {
        return [self.filteredTableRows count];
    }
    if (self.listingByCounty == YES)
    {
        NSString *county = [self.sortedSections objectAtIndex:section];
        NSArray *listingsInCountyArray = [self.sections objectForKey:county];
        return [listingsInCountyArray count];
    }
    // Otherwise just return the number of items in tableRows
    return [self.tableRows count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.listingByCounty == YES)
    {
        NSString *county = [self.sortedSections objectAtIndex:section];
        return county;
    }
    else
    {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // First checks to see if the item being added is a detail based on the prefix in the
    // item's title.
    
    [cell.textLabel setNumberOfLines:2];
    [cell.detailTextLabel setNumberOfLines:2];
    
    // Check at the beginning of the title of each item to see if it is a detail.
    // If the method finds one of the detail prefixes, it will remove the prefix and
    // prepare a cell with the detail.
    if (self.showDetails == YES)
    {
        DDBTableRow *item = self.tableRows[indexPath.row];
        NSString *detailString = item.title;
        NSString *detailSubstring = [detailString substringToIndex:4];
        if ([detailSubstring isEqual:@"tol:"])
        {
            cell.textLabel.text = @"Toll-Free:";
            cell.detailTextLabel.text = [detailString substringFromIndex:4];
            self.tollFree = [detailString substringFromIndex:4];
            return cell;
        }
        else if ([detailSubstring isEqual:@"phn:"])
        {
            cell.textLabel.text = @"Phone:";
            self.phoneNumber2 = [detailString substringFromIndex:4];
            cell.detailTextLabel.text = [detailString substringFromIndex:4];
            return cell;
        }
        else if ([detailSubstring isEqual:@"ph2:"])
        {
            cell.textLabel.text = @"Phone2:";
            self.phoneNumber2 = [detailString substringFromIndex:4];
            cell.detailTextLabel.text = [detailString substringFromIndex:4];
            return cell;
        }
        else if ([detailSubstring isEqual:@"adr:"])
        {
            cell.textLabel.text = @"Address:";
            self.address = [detailString substringFromIndex:4];
            NSString *detailsWithoutPrefix = [detailString substringFromIndex:4];
            cell.detailTextLabel.text = detailsWithoutPrefix;
            cell.detailTextLabel.numberOfLines = 0;
            
            // If the address is the only item we're adding to the list, remove all of the cell
            // divider lines below it because they're ugly.
            if ([self.tableRows count] == 1)
            {
                self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
            }
            
            if ([[detailsWithoutPrefix substringToIndex:3].lowercaseString isEqual:@"see"])
            {
                cell.userInteractionEnabled = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            return cell;
        }
        else if ([detailSubstring isEqual:@"fax:"])
        {
            cell.textLabel.text = @"Fax:";
            cell.detailTextLabel.text = [detailString substringFromIndex:4];
            cell.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        }
    }
    
    
    if (self.isFiltered == YES)
    {
        // Add rows that don't contain details
        DDBTableRow *item = self.filteredTableRows[indexPath.row];
        cell.textLabel.text = item.title;
        cell.detailTextLabel.text = nil;
        return cell;
    }
    else if (self.showingFavorites == YES)
    {
        
        // Use a different style of cell so we have more room for parent title
        [cell initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        
        [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
        cell.detailTextLabel.numberOfLines = 2;
        
        // Search the directory to find a match for the hashKey and rangeKey of the item's parent.
        // Then add the parent's title as the text on the left of the cell.
        DDBTableRow *item = self.tableRows[indexPath.row];
        if (item.parentID == nil)
        {
            cell.textLabel.text = nil;
        }
        else
        {
            for (DDBTableRow *possibleParent in [SingletonArrayObject sharedInstance].directoryArray)
            {
                
                // If the possibleParent has the correct rangeKey and is one level higher in the directory...
                if ([item.parentID isEqual: possibleParent.rangeKey] &&
                    [item.hashKey integerValue] - 1 == [possibleParent.hashKey integerValue])
                {
                    cell.textLabel.text = possibleParent.title;
                    break;
                }
                
            }
        }
        
    cell.detailTextLabel.text = item.title;
        
    return cell;
    }
    
    if (self.listingByCounty == YES)
    {
        // Use a different style of cell so we have more room for parent title
        [cell initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        
        NSString *county = [self.sortedSections objectAtIndex:indexPath.section];
        NSArray *listingsInCountyArray = [self.sections objectForKey:county];
        
        DDBTableRow *listing = [listingsInCountyArray objectAtIndex:indexPath.row];
        
        [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        
        cell.detailTextLabel.text = listing.title;
        
        [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
        cell.detailTextLabel.numberOfLines = 2;
        
        if (listing.parentID == nil)
        {
            cell.textLabel.text = nil;
        }
        else
        {
            for (DDBTableRow *possibleParent in [SingletonArrayObject sharedInstance].directoryArray)
            {
                
                // If the possibleParent has the correct rangeKey and is one level higher in the directory...
                if ([listing.parentID isEqual: possibleParent.rangeKey] &&
                    [listing.hashKey integerValue] - 1 == [possibleParent.hashKey integerValue])
                {
                    cell.textLabel.text = possibleParent.title;
                    break;
                }
            }
        }
        
        return cell;
    }
    
    // Add rows that don't contain details
    if (_tableRows.count)
    {
        
        {
            DDBTableRow *item = self.tableRows[indexPath.row];
            cell.textLabel.text = item.title;
            cell.detailTextLabel.text = nil;
            cell.userInteractionEnabled = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}


// Disable user editing. This keeps users from swiping on table cells to reveal a "delete" button
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Set up an alert for prompting the map application and dialer application
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)
    {
        // Create a phone URL, and open up the dialer with the number.
        NSString *formattedPhoneNumber = [self.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        
        
        NSString *phoneNumberURL = [@"tel://" stringByAppendingString:formattedPhoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberURL]];
    }
    
    return;
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
    if ([cellText  isEqual: @"Phone:"])
    {
        // Prepare a string that says "Dial [phone number]?"
        NSString *messageString = [[@"Dial " stringByAppendingString:self.phoneNumber] stringByAppendingString:@"?"];
        
        // Prepare a prompt
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:messageString
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Okay", nil];
        
        [alert show];
        return;
    }
    if ([cellText  isEqual: @"Phone2:"])
    {
        // Prepare a string that says "Dial [phone number]?"
        NSString *messageString = [[@"Dial " stringByAppendingString:self.phoneNumber2] stringByAppendingString:@"?"];
        self.phoneNumber = self.phoneNumber2;
        
        // Prepare a prompt
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:messageString
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Okay", nil];
        
        [alert show];
        return;
    }
    if ([cellText  isEqual: @"Toll-Free:"])
    {
        // Prepare a string that says "Dial [phone number]?"
        NSString *messageString = [[@"Dial " stringByAppendingString:self.tollFree] stringByAppendingString:@"?"];
        
        self.phoneNumber = self.tollFree;
        
        // Prepare a prompt
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:messageString
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Okay", nil];
        
        [alert show];
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
        indexRow = [self.tableRows objectAtIndex:(indexPath.row)];
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
        mainVewController.phoneNumber2 = indexRow.phone2;
        mainVewController.tollFree = indexRow.tollFree;
        mainVewController.title = indexRow.title;
        
    }
    
    
    mainVewController.parentID = indexRow.rangeKey;
    mainVewController.viewType = DDBMainViewTypeChildren;
    mainVewController.title = indexRow.title;
    
    
    mainVewController.parentItem = indexRow;
    
    // Increment the directory level to drill down the directory
    NSInteger temp = [indexRow.hashKey integerValue];
    temp++;
    mainVewController.directoryLevel = temp;
    
    if (temp < 5)
    {
        mainVewController.directoryLevel1 = self.directoryLevel1;
        mainVewController.directoryLevel2 = self.directoryLevel2;
        mainVewController.directoryLevel3 = self.directoryLevel3;
        mainVewController.directoryLevel4 = self.directoryLevel4;
        mainVewController.directoryLevel5 = self.directoryLevel5;
    }
    else if (temp >= 5 && temp <=7)
    {
        mainVewController.electedOfficials = self.electedOfficials;
        mainVewController.houseAndSenate = self.houseAndSenate;
    }
}

#pragma mark - View lifecycle

- (void)setupView{
    
    // Call the correct method to sort the directory items
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
            break;
        }
            
        case DDBMainViewTypeFavorites:
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
        case DDBMainViewTypeNonEmergencyContacts:
        {
            [self showNonEmergencyContacts];
            break;
        }
        case DDBMainViewTypeN11:
        {
            [self showN11];
            break;
        }
            
    }
    
    
}


/// Add details to _tableRows as DDBTableRow items so tableView population goes smoothly. If the current tableRow
/// has a detail, append a prefix to the detail and add it to _tableRows. cellForRowAtIndexPath will recognize the
/// prefix and create the cell appropriately.
- (void) addDetails
{
    if (_tableRow.fax)
    {
        DDBTableRow *item = [DDBTableRow new];
        NSString *string = _tableRow.fax;
        item.title = [@"fax:" stringByAppendingString:string];
        [self.tableRows insertObject:item atIndex:0];
    }
    if (_tableRow.tollFree)
    {
        DDBTableRow *item = [DDBTableRow new];
        NSString *string = _tableRow.tollFree;
        item.title = [@"tol:" stringByAppendingString:string];
        [self.tableRows insertObject:item atIndex:0];
    }
    if (_tableRow.phone2)
    {
        DDBTableRow *item = [DDBTableRow new];
        NSString *string = _tableRow.phone2;
        item.title = [@"ph2:" stringByAppendingString:string];
        [self.tableRows insertObject:item atIndex:0];
    }
    if (_tableRow.phone)
    {
        DDBTableRow *item = [DDBTableRow new];
        NSString *string = _tableRow.phone;
        item.title = [@"phn:" stringByAppendingString:string];
        [self.tableRows insertObject:item atIndex:0];
    }
    if (_tableRow.address)
    {
        DDBTableRow *item = [DDBTableRow new];
        NSString *string = _tableRow.address;
        item.title = [@"adr:" stringByAppendingString:string];
        [self.tableRows insertObject:item atIndex:0];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableRows = [NSMutableArray new];
    _favoritesArray = [NSMutableArray new];
    _filteredTableRows = [NSMutableArray new];
    
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
    _addressFlag = NO;
    
    
    [self setupView];
    [self.tableView reloadData];
}

@end
