//
//  QuizTableViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/8/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "QuizTableViewController.h"
#import "DDBManager.h"
#import "SingletonArray.h"
#import "QuizQuestionViewController.h"

@interface QuizTableViewController ()

@property (nonatomic, readwrite) NSMutableArray *categoriesArray;
@property (nonatomic, readwrite) NSMutableArray *allQuestionsArray;
@property (nonatomic, readwrite) NSMutableArray *questionsArray;
@property (nonatomic, readwrite) NSString *titleString;



@end

@implementation QuizTableViewController

// sortItems loops through the global shared array and places items pertaining to the quiz
// in arrays. Quiz question categories go in self.categoriesArray, and quiz questions go in
// self.allQuestionsArray. Items are then sorted by index.
- (void)sortItems
{
    for (DDBTableRow *item in [SingletonArray sharedInstance].sharedArray)
    {
        // Only look at the quiz questions
        if ([item.hashKey isEqual:@"quiz"])
        {
            // If the string does not contain "." then it has no parents, meaning it must be a category and not a question
            if ([item.rangeKey rangeOfString:@"."].location == NSNotFound)
            {
                [self.categoriesArray addObject:item];
            }
            // Otherwise it's a question
            else
            {
                [self.allQuestionsArray addObject:item];
            }
        }
    }
    
    // Sort the categories in alphabetical order
    NSSortDescriptor *sortingByIndexDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortingByIndexDescriptor, nil];
    NSMutableArray *temp = self.categoriesArray;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.categoriesArray = temp;
    
    // Sort questions by "index". Index is an NSInteger, so we don't have to get the int value out of a string.
    // It's the last digit of the item's path, eg, if the item's path is 7.2.8, the index would be 8.
    sortingByIndexDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    sortingDescriptor = [NSArray arrayWithObjects:sortingByIndexDescriptor, nil];;
    temp = self.allQuestionsArray;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.allQuestionsArray = temp;
    
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categoriesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell1";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    DDBTableRow *item = self.categoriesArray[indexPath.row];
    
    cell.textLabel.text = item.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // deselect the cell and show the deselect animation
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.questionsArray removeAllObjects];
    
    DDBTableRow *selectedItem = self.categoriesArray[indexPath.row];
    
    
    // Loop through self.allQuestionsArray. For each item, take the rangeKey and remove characters
    // from the end until we hit a period. What's left after that is the question's parent's rangeKey,
    // which is the category to which the question belongs. If it matches the selected category's
    // rangeKey, add the question to self.questionsArray
    for (DDBTableRow *item in self.allQuestionsArray)
    {
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
        if ([parentID isEqual: selectedItem.rangeKey])
        {
            [self.questionsArray addObject:item];
        }
    }
    // Set self.titleString to pass it to QuizQuestionViewController
    self.titleString = selectedItem.title;
    [self performSegueWithIdentifier:@"navigateToQuizQuestion" sender:self];
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)showActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Home", @"Being Prepared", @"Checklist", @"Take the Quiz", nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet showFromBarButtonItem:self.menuButton animated:YES];
}

// Set up the actionsheet from the hamburger icon. When a button is selected, send a notification
// to the HomepageViewController to pop the view stack and push to the appropriate view controller
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
    
    self.categoriesArray = [NSMutableArray new];
    self.allQuestionsArray = [NSMutableArray new];
    self.questionsArray = [NSMutableArray new];
    [self sortItems];
    [self.tableView reloadData];
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
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
    QuizQuestionViewController *quizQuestionViewController = [segue destinationViewController];
    quizQuestionViewController.questionsArray = [self.questionsArray copy];
    quizQuestionViewController.titleString = self.titleString;
}


@end
