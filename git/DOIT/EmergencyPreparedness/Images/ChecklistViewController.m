//
//  ChecklistViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

/*
 * ChecklistViewController displays a table with the four checklist items. When
 * the user selects an item, the view controller performs a segue to a repurposed
 * manual page view controller and displays the requirements for the checklist. It 
 * also changes the gray checkmark next to the selected item to a green checkmark, 
 * and saves this data into an archive file so the app remembers which items have 
 * been read. Because Dynamo DB can't hold boolean values, there are a couple of 
 * hoops to jump through (namely, converting from an integer to a boolean). I used 1
 * as "true" and 2 as "false" because there can be confusion between 0 an nil.
 */


#import "ChecklistViewController.h"
#import "checklistItem.h"
#import "DDBManager.h"
#import "SingletonArray.h"
#import "ManualPageViewController.h"

@interface ChecklistViewController ()

@property (nonatomic, readwrite) NSMutableArray* checklistItems;
@property (nonatomic, readwrite) NSMutableArray* checkedArray;
@property (nonatomic, readwrite) NSString *checklistText;
@property (nonatomic, readwrite) NSString *checklistTitle;


@end

@implementation ChecklistViewController

// Variables to convert to and from booleans
int checked = 1;
int notChecked = 2;

- (void)sortItems
{
    // Temp is for sorting the array by index
    NSMutableArray *temp = [NSMutableArray new];
    
    // ChecklistTemp(2) are for making copies of the checklist and modifying the items
    // inside.
    NSMutableArray *checklistTemp = [NSMutableArray new];
    NSMutableArray *checklistTemp2 = [NSMutableArray new];
    
    for (DDBTableRow *item in [SingletonArray sharedInstance].sharedArray)
    {
        if ([item.hashKey isEqual:@"Checklist"])
        {
            [temp addObject:item];
        }
        
    }
    
    // Sort the temp array by rangeKey
    NSSortDescriptor *sortByRangeKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rangeKey"
                                                                             ascending:YES];
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByRangeKeyDescriptor, nil];
    [temp sortUsingDescriptors:sortingDescriptor];
    
    // Add all of the checklist texts to checklistTemp2 as strings
    for (DDBTableRow *item in temp)
    {
        NSString *checklistTitle = nil;
        checklistTitle = item.title;
        [checklistTemp addObject:checklistTitle];
        NSString *checklistText = nil;
        
        NSString *stringWithoutNewline = item.text;
        
        // Add newlines to the text
        NSString *stringWithNewline = [stringWithoutNewline stringByReplacingOccurrencesOfString:@"  " withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\r" withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
        
        item.text = stringWithNewline;
        checklistText = item.text;
        [checklistTemp2 addObject:checklistText];
    }
    
    // Load the checklist array into self.checked array from the archive file.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"/checkedArray.archive"];

    NSFileManager *manager = [NSFileManager defaultManager];
    
    if([manager fileExistsAtPath:filePath])
    {
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long size = [attributes fileSize];
        if (attributes && size > 0)
        {
            self.checkedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        }
    }
    
    [self.checklistItems removeAllObjects];
    
    // Set up a checklistItem for each of the four items in the table. A checklistItem consists
    // of a string, which is the requirements for the item in the checklist, and a bool, which
    // indicates if the item has been viewed yet.
    for (int i = 0; i < [checklistTemp count]; i++)
    {
        checklistItem *listItem = [checklistItem new];
        
        listItem.title = checklistTemp[i];
        
        if ([self.checkedArray count] == 0)
        {
            for (int j = 0; j < [checklistTemp count]; j++)
            {
                [self.checkedArray addObject:[NSNumber numberWithInt:notChecked]];
            }
            
            [NSKeyedArchiver archiveRootObject:self.checkedArray toFile:filePath];
         }
        
        // 1 means yes and 2 means no. This way, we avoid confusion with 0 and nil
        NSNumber *checkedInt = self.checkedArray[i];
        
        // Test if the current item means YES or NO and set listItem.checked accordingly
        if ([checkedInt intValue] == checked)
        {
            listItem.checked = YES;
        }
        else if ([checkedInt intValue] == notChecked)
        {
            listItem.checked = NO;
        }
        else if (checkedInt == nil)
        {
            listItem.checked = NO;
            [self.checkedArray insertObject:[NSNumber numberWithInt:notChecked] atIndex:i];
            [NSKeyedArchiver archiveRootObject:self.checkedArray toFile:filePath];
        }
        
        // Add the completed checklistItem to the array
        [self.checklistItems addObject:listItem];
            
    }
    for (int i = 0; i < [checklistTemp2 count]; i++)
    {
        // Replace the text in _checklistItems with the text with newlines from checklistTemp2
        checklistItem *item = self.checklistItems[i];
        item.text = checklistTemp2[i];
        [self.checklistItems replaceObjectAtIndex:i withObject:item];
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.checklistItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Give each cell two lines of text
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    cell.textLabel.numberOfLines = 2;
    
    // Move the text over to make room for the image
    cell.indentationLevel = 7;
    cell.indentationWidth = 10;
    
    for (UIImageView *subview in cell.contentView.subviews)
    {
        // Remove the image that was previously in cell before loading a new one. Otherwise the
        // images stack on top of each other.
        if (subview.tag == 99)
        {
            [subview removeFromSuperview];
        }
    }
    
    // Create an image to set to the left of the cell text (gray or green checkmark)
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 40, 40)];
    imgView.backgroundColor = [UIColor clearColor];
    
    // Set imgView's tag so we can identify it later
    [imgView setTag:99];
    
    // Set the gray or geen checkmark depending on if the item has been viewed
    checklistItem *item = [self.checklistItems objectAtIndex:indexPath.row];
    if (item.checked == YES)
    {
        [imgView setImage:[UIImage imageNamed:@"greenCheck.png"]];
    }
    else
    {
        [imgView setImage:[UIImage imageNamed:@"grayCheck.png"]];
    }
    
    [cell.contentView addSubview:imgView];

    
    cell.textLabel.text = item.title;
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *item = self.checkedArray[indexPath.row];

    // If the item has not been marked as check yet, mark it as checked
    if ([item intValue] == notChecked)
    {
        self.checkedArray[indexPath.row] = [NSNumber numberWithInt:checked];
    }
    
    // Save the newly checked item to checkedArray.archive
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"/checkedArray.archive"];

    [NSKeyedArchiver archiveRootObject:self.checkedArray toFile:filePath];

    // Resort the items so that the newly checked item is reflected in the tableView
    [self sortItems];

    // Set properties to pass to the repurposed ManualPageViewController
    checklistItem *checklistItem = self.checklistItems[indexPath.row];
    self.checklistText = checklistItem.text;
    self.checklistTitle = checklistItem.title;
    
    [self performSegueWithIdentifier:@"navigatToChecklistItem" sender:self];

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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToChecklist" object:nil];
    }
    else if ([buttonTitle isEqual:@"Being Prepared"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToBeingPrepared" object:nil];
    }
    else if ([buttonTitle isEqual:@"Take the Quiz"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToQuiz" object:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Do any additional setup after loading the view.
    self.checklistItems = [NSMutableArray new];
    self.checkedArray = [NSMutableArray new];
    [self sortItems];
    
    
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self sortItems];
    [self.tableView reloadData];
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
    if ([segue.identifier isEqual:@"navigatToChecklistItem"])
    {
        ManualPageViewController *manualPageViewController = [segue destinationViewController];
        manualPageViewController.titleLabelString = self.checklistTitle;
        manualPageViewController.textViewString = self.checklistText;
    }
}


@end
