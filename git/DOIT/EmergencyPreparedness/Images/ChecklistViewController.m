//
//  ChecklistViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "ChecklistViewController.h"
#import "checklistItem.h"
#import "DDBManager.h"
#import "SingletonArray.h"

@interface ChecklistViewController ()

@property (nonatomic, readwrite) NSMutableArray* checklistItems;
@property (nonatomic, readwrite) NSMutableArray* checkedArray;


@end

@implementation ChecklistViewController

int checked = 1;
int notChecked = 2;

- (void)sortItems
{
    NSMutableArray *temp = [NSMutableArray new];
    NSMutableArray *checklistTemp = [NSMutableArray new];
    
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
    
    for (DDBTableRow *item in temp)
    {
        NSString *checklistString = nil;
        checklistString = item.text;
        [checklistTemp addObject:checklistString];
        
    }
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"checkedArray" ofType:@".archive"];

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
    
    for (int i = 0; i < [checklistTemp count]; i++)
    {
        checklistItem *listItem = [checklistItem new];
        
        listItem.itemString = checklistTemp[i];
        
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
        
        
        [self.checklistItems addObject:listItem];
            
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
    
    checklistItem *item = [self.checklistItems objectAtIndex:indexPath.row];
    if (item.checked == YES)
    {
        cell.imageView.image = [UIImage imageNamed:@"greenCheck.png"];
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"grayCheck.png"];
    }
    
    cell.textLabel.text = item.itemString;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *item = self.checkedArray[indexPath.row];
    if ([item intValue] == checked)
    {
        self.checkedArray[indexPath.row] = [NSNumber numberWithInt:notChecked];
    }
    else if ([item intValue] == notChecked)
    {
        self.checkedArray[indexPath.row] = [NSNumber numberWithInt:checked];
    }
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"checkedArray" ofType:@".archive"];

    [NSKeyedArchiver archiveRootObject:self.checkedArray toFile:filePath];

    [self sortItems];
    [self.tableView reloadData];
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
}


// Change the appearance of the action sheet buttons
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    
    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setBackgroundImage: [UIImage imageNamed:@"alert.png"] forState:UIControlStateNormal];
            
            [button setBackgroundColor:[UIColor darkGrayColor]];
            //[button setBackgroundColor:[UIColor colorWithRed:84/255 green:90/255 blue:93/255 alpha:1.0]];
            //[button setTintColor:[UIColor lightGrayColor]];
            
            //[button setTintColor:[UIColor colorWithRed:84/255 green:90/255 blue:93/255 alpha:1.0]];
            if ([button.currentTitle  isEqual: @"Checklist"])
            {
                button.enabled = NO;
                [button setEnabled:NO];
            }
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Do any additional setup after loading the view.
    self.checklistItems = [NSMutableArray new];
    self.checkedArray = [NSMutableArray new];
    [self sortItems];

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
