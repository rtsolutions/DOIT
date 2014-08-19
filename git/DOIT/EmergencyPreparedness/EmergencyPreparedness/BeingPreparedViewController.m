//
//  BeingPreparedViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "BeingPreparedViewController.h"
#import "DDBManager.h"
#import "SingletonArray.h"
#import "ManualPageViewController.h"

@interface BeingPreparedViewController ()

@property (nonatomic, readwrite) NSMutableArray *preparednessManualArray;
@property (nonatomic, readwrite) NSMutableArray *topLevel;
@property (nonatomic, readwrite) NSMutableArray *secondLevel;
@property (nonatomic, readwrite) NSMutableArray *menuArray;
@property (nonatomic, readwrite) NSInteger directoryLevel;
@property (nonatomic, readwrite) DDBTableRow *firstPage;
@property (nonatomic, readwrite) DDBTableRow *currentItem;

@property (nonatomic, readwrite) NSMutableString *usedImages;

@end

@implementation BeingPreparedViewController

- (void)sortItems
{
    
    for (DDBTableRow *item in [SingletonArray sharedInstance].sharedArray)
    {
        // Insert newlines into all of the text where there are double spaces.
        // Four spaces inserts two newlines.
        NSString *stringWithoutNewline = item.text;
        
        NSString *stringWithNewline = [stringWithoutNewline stringByReplacingOccurrencesOfString:@"  " withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\r" withString:@"\r"];
        stringWithNewline = [stringWithNewline stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
        
        
        item.text = stringWithNewline;
        
        
        if ([item.hashKey isEqual:@"0001"])
        {
            // item with rangeKey == "0" is the first page of the manual
            if ([item.rangeKey isEqual:@"0"])
            {
                self.firstPage = item;
            }
            // Top level items have as many as two characters
            else if ([item.rangeKey length] < 3)
            {
                [self.topLevel addObject:item];
            }
            // Subsections have at least three characters
            else if ([item.rangeKey length] >= 3)
            {
                [self.secondLevel addObject:item];
            }
        }
    }
}

- (void)setupView
{
    // Setup first page of manual
    if (self.directoryLevel == 0)
    {
        // Add text and images to all of the appropriate fields
        self.titleLabel.text = self.firstPage.title;
        self.textView.text = self.firstPage.text;
        self.iconImage.image = [UIImage imageNamed:@"alert.png"];
        self.menuArray = self.topLevel;
        [self.showContentsButton setTitle:@"Get Prepared For..." forState:UIControlStateNormal];
    }
    else if (self.directoryLevel == 1)
    {
        // Add text and images to the appropriate fields
        self.titleLabel.text = self.currentItem.title;
        self.textView.text = self.currentItem.text;
        [self.showContentsButton setTitle:@"Learn More" forState:UIControlStateNormal];
        [self.showContentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        
        // To get the name of the image for the current page, take the title of the page,
        // change it all to lowercase, remove the spaces, and append ".png"
        NSString *imageString = [self.currentItem.title lowercaseString];
        imageString = [imageString stringByAppendingString:@".png"];
        imageString = [imageString stringByReplacingOccurrencesOfString:@" " withString:@""];
        self.iconImage.image = [UIImage imageNamed:imageString];
        
        for (DDBTableRow *item in self.secondLevel)
        {
            // Extract the parentID from the current item's rangeKey
            NSString *parentID = item.rangeKey;
            NSUInteger length = [item.rangeKey length];
            
            // Remove characters from the end of the rangeKey until we hit a period
            for (int i = length-1; i >= 0; i--)
            {
                char singleChar = [item.rangeKey characterAtIndex:i];
                NSString *character = [NSString stringWithFormat:@"%c",singleChar];
                parentID = [parentID substringToIndex:[parentID length]-1];

                if ([character isEqual:@"."])
                {
                    break;
                }
                
            }
            if ([parentID isEqual: self.currentItem.rangeKey])
            {
                [self.menuArray addObject:item];
            }
        }
    }
    // Sort the items by index--an integer that's equivalent to the last element of the rangeKey
    // eg if rangeKey == "3.10.7" then index == 7.
    NSSortDescriptor *sortingByIndexDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortingByIndexDescriptor, nil];
    NSMutableArray *temp = self.menuArray;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.menuArray = temp;
}

/// On button press, add the table to the current view.
- (IBAction)showTable:(id)sender
{
    
    [self.tableView setFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height - 108)];
    [self.tableView setHidden:NO];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    [self.hideContentsButton setHidden:NO];
    [self.hideContentsButton setEnabled:YES];
}

/// On button press, remove the table from the current view
- (IBAction)hideTable:(id)sender
{
    [self.tableView setHidden:YES];
    [self.tableView removeFromSuperview];
    [self.tableView reloadData];
    [self.hideContentsButton setHidden:YES];
}

/// Trying to use swipes to show the table of contents. Couldn't get it to work.
- (void)handleSwipeUpFrom:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer == self.swipeDown)
    {
        self.tableView.frame = CGRectZero;
    }
    else if (recognizer == self.swipeUp)
    {
        self.tableView.frame = CGRectMake(108, 0, self.view.frame.size.width, self.view.frame.size.height - 108);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menuArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    DDBTableRow *item = self.menuArray[indexPath.row];
    
    // Let each cell use two lines
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.textLabel setNumberOfLines:2];
    
    cell.textLabel.text = item.title;

    // Check to see if the cell already has an image in it. If it does, remove it
    if (self.directoryLevel == 0)
    {
        for (UIImageView *subview in cell.contentView.subviews)
        {
            if (subview.tag == 99)
            {
                [subview removeFromSuperview];
            }
        }
        
        // Move the cell text over to make room for the image.
        cell.indentationLevel = 7;
        cell.indentationWidth = 10;
        
        // Set up an image view...
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 40, 40)];
        imgView.backgroundColor = [UIColor clearColor];
        
        // Give the image view a tag so we can find it later
        [imgView setTag:99];
        
        // Take the title, change it to all lowercase, remove spaces, and append ".png" to get
        // the image name.
        NSString *imageString = [item.title lowercaseString];
        imageString = [imageString stringByAppendingString:@".png"];
        imageString = [imageString stringByReplacingOccurrencesOfString:@" " withString:@""];
        [imgView setImage:[UIImage imageNamed:imageString]];
        
        [cell.contentView addSubview:imgView];
    }
    

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    DDBTableRow *item = self.menuArray[indexPath.row];
    self.currentItem = item;
    
    // If the next page doesn't have any subsections, navigateToManualPage.
    // If the next page does have subsections, navigate back to the same page with new data.
    if (self.directoryLevel == 1 || [self.currentItem.rangeKey isEqual:@"1"] || [self.currentItem.rangeKey isEqual:@"3"])
    {
        [self performSegueWithIdentifier:@"navigateToManualPage" sender:self];
    }
    else if (self.directoryLevel == 0)
    {
        [self performSegueWithIdentifier:@"navigateToSelf" sender:self];
    }
    
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
    self.topLevel = [NSMutableArray new];
    self.menuArray = [NSMutableArray new];
    self.secondLevel = [NSMutableArray new];
    self.usedImages = nil;
    self.swipeUp = [UISwipeGestureRecognizer new];
    self.swipeDown.numberOfTouchesRequired = 1;
    self.swipeDown = [UISwipeGestureRecognizer new];
    self.swipeDown.numberOfTouchesRequired = 1;
    [self.hideContentsButton setHidden:YES];
    self.hideContentsButton.titleLabel.text = nil;
    [self sortItems];
    [self setupView];
    
    if ([self.menuArray count] == 0)
    {
        [self.showContentsButton setEnabled:NO];
        [self.showContentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
   // [self.tableView setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if (self.directoryLevel == 1 || [self.currentItem.rangeKey isEqual: @"1"] || [self.currentItem.rangeKey isEqual:@"3"])
    {
        ManualPageViewController *manualPageViewController = [segue destinationViewController];
        manualPageViewController.titleLabelString = self.currentItem.title;
        manualPageViewController.textViewString = self.currentItem.text;
        
    }
    else if (self.directoryLevel == 0)
    {
        BeingPreparedViewController *beingPreparedViewController = [segue destinationViewController];
        beingPreparedViewController.currentItem = self.currentItem;
        beingPreparedViewController.directoryLevel = self.directoryLevel + 1;
        beingPreparedViewController.secondLevel = self.secondLevel;
    }
    
    
}

@end
