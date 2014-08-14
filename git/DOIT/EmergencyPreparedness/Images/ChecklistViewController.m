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
#import "ManualPageViewController.h"

@interface ChecklistViewController ()

@property (nonatomic, readwrite) NSMutableArray* checklistItems;
@property (nonatomic, readwrite) NSMutableArray* checkedArray;
@property (nonatomic, readwrite) NSString *checklistText;
@property (nonatomic, readwrite) NSString *checklistTitle;


@end

@implementation ChecklistViewController

int checked = 1;
int notChecked = 2;

- (void)sortItems
{
    NSMutableArray *temp = [NSMutableArray new];
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
    
    for (DDBTableRow *item in temp)
    {
        NSString *checklistTitle = nil;
        checklistTitle = item.title;
        [checklistTemp addObject:checklistTitle];
        NSString *checklistText = nil;
        
        NSString *stringWithoutNewline = item.text;
        
        NSString *stringWithNewline = [stringWithoutNewline stringByReplacingOccurrencesOfString:@"  " withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\r" withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
        
        
        item.text = stringWithNewline;
        checklistText = item.text;
        [checklistTemp2 addObject:checklistText];
        
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"checkedArray.archive"];

    NSFileManager *manager = [NSFileManager defaultManager];
    
    if([manager fileExistsAtPath:filePath])
    {
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long size = [attributes fileSize];
        if (attributes && size > 0)
        {
            self.checkedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            //self.checkedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:@"checkedArray.archive"];
        }
    }
    
    [self.checklistItems removeAllObjects];
    
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
    for (int i = 0; i < [checklistTemp2 count]; i++)
    {
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
    
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    cell.textLabel.numberOfLines = 2;
    
    cell.indentationLevel = 7;
    cell.indentationWidth = 10;
    
    for (UIImageView *subview in cell.contentView.subviews)
    {
        if (subview.tag == 99)
        {
            [subview removeFromSuperview];
        }
    }
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 40, 40)];
    imgView.backgroundColor = [UIColor clearColor];
    
    [imgView setTag:99];
    
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

    if ([item intValue] == notChecked)
    {
        self.checkedArray[indexPath.row] = [NSNumber numberWithInt:checked];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"checkedArray.archive"];

    [NSKeyedArchiver archiveRootObject:self.checkedArray toFile:filePath];

    [self sortItems];

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
