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

- (void)sortItems
{
    for (DDBTableRow *item in [SingletonArray sharedInstance].sharedArray)
    {
        if ([item.hashKey isEqual:@"quiz"])
        {
            if ([item.rangeKey rangeOfString:@"."].location == NSNotFound)
            {
                [self.categoriesArray addObject:item];
            }
            else
            {
                [self.allQuestionsArray addObject:item];
            }
        }
    }
    
    NSSortDescriptor *sortingByIndexDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortingByIndexDescriptor, nil];
    NSMutableArray *temp = self.categoriesArray;
    [temp sortUsingDescriptors:sortingDescriptor];
    self.categoriesArray = temp;
    
    
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DDBTableRow *selectedItem = self.categoriesArray[indexPath.row];
    
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
    quizQuestionViewController.questionsArray = self.questionsArray;
    quizQuestionViewController.titleString = self.titleString;
}


@end
