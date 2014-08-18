//
//  QuizQuestionViewController.m
//  EmergencyPreparedness
//
//  Created by rts on 8/8/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import "QuizQuestionViewController.h"
#import "DDBManager.h"


@interface QuizQuestionViewController ()

@property (nonatomic, readwrite) NSMutableArray *answers;
@property (nonatomic, readwrite) NSMutableArray *correctAnswerIndexes;
@property (nonatomic, readwrite) NSMutableArray *correctAnswers;
@property (nonatomic, readwrite) NSMutableArray *chosenAnswerIndexes;

@property (nonatomic, readwrite) NSInteger currentQuestionIndex;
@property (nonatomic, readwrite) DDBTableRow *currentQuestion;
@property (nonatomic, assign) BOOL showingAnswers;



@end

@implementation QuizQuestionViewController

- (void)getCurrentQuestion
{
    self.currentQuestion = self.questionsArray[self.currentQuestionIndex];
}

- (void)setupQuestions
{
    // Each question has as many as 8 answers.
    NSString *answer1 = self.currentQuestion.answer1;
    NSString *answer2 = self.currentQuestion.answer2;
    NSString *answer3 = self.currentQuestion.answer3;
    NSString *answer4 = self.currentQuestion.answer4;
    NSString *answer5 = self.currentQuestion.answer5;
    NSString *answer6 = self.currentQuestion.answer6;
    NSString *answer7 = self.currentQuestion.answer7;
    NSString *answer8 = self.currentQuestion.answer8;
    
    // Check to make sure each answer exists before adding it to self.answers
    [self.answers addObject:answer1];
    if (answer2)
    {
        [self.answers addObject:answer2];
    }
    if(answer3)
    {
        [self.answers addObject:answer3];
    }
    if (answer4)
    {
        [self.answers addObject:answer4];
    }
    if (answer5)
    {
        [self.answers addObject:answer5];
    }
    if (answer6)
    {
        [self.answers addObject:answer6];
    }
    if (answer7)
    {
        [self.answers addObject:answer7];
    }
    if (answer8)
    {
        [self.answers addObject:answer8];
    }
    
    // correctanswer is a string. That way multiple correct answers can be stored as strings separated by spaces,
    // and then they can be parsed out.
    NSArray *correctAnswersTemp = [self.currentQuestion.correctanswer componentsSeparatedByString:@" "];
    for (NSString *numberString in correctAnswersTemp)
    {
        NSInteger value = [numberString integerValue];
        
        value--;    // Decrement to get the index rather than the answer number
        
        NSNumber *number = [NSNumber numberWithInt:value];
        [self.correctAnswerIndexes addObject:number];
    }
    
    // Add the correct answers to an array self.correctAnswers
    for (NSNumber *index in self.correctAnswerIndexes)
    {
        [self.correctAnswers addObject:self.answers[[index integerValue]]];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.answers count];
}

/// Calcuate how much space each row is going to need, then add 25 points of padding
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
    
    CGRect rect = [self.answers[indexPath.row] boundingRectWithSize:CGSizeMake(230.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil];
    CGSize size = rect.size;
    return size.height + 25;
                                 
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For some reason the app couldn't find "Cell" so I used "Cell2" instead
    static NSString *CellIdentifier = @"Cell2";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *answer = self.answers[indexPath.row];
    
    cell.textLabel.text = answer;
    
    // Word wrap the answers, and let them use as many lines as they need
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    cell.textLabel.numberOfLines = 0;
    
    // Move the text 70 points to the right (10 points x 7 indents = 70 points)
    cell.indentationLevel = 7;
    cell.indentationWidth = 10;
    
    // If we've already clicked on "ANSWER QUESTION", only the correct answers are in the table.
    // Add a green checkmark next to them.
    if (self.showingAnswers == YES)
    {
        for (UIImageView *subview in cell.contentView.subviews)
        {
            if (subview.tag == 99)
            {
                [subview removeFromSuperview];
            }
        }
        // Quick little hack to tell if we're displaying a correct answer or an incorrect answer.
        // When showing answers, self. showing answers has the correct answers as the beginning of the array.
        // If we display those answers and still haven't reached the end of self.answers, then we must be
        // displaying the incorrect answers at the end of the array.
        if (indexPath.row >= [self.correctAnswerIndexes count])
        {
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 30, 30)];
            imgView.backgroundColor = [UIColor clearColor];
            
            [imgView setTag:99];
            [imgView setImage:[UIImage imageNamed:@"wrong.png"]];
            
            [cell.contentView addSubview:imgView];
        }
        
        else
        {
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 30, 30)];
            imgView.backgroundColor = [UIColor clearColor];
            
            [imgView setTag:99];
            [imgView setImage:[UIImage imageNamed:@"greenCheck.png"]];
            
            [cell.contentView addSubview:imgView];
        }
    }
    
    return cell;
}

/// Switch between adding a green checkmark and adding the answer to chosen answers, and removing
/// the checkmark and removing the answer from chosen answers
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Remove
    if (self.showingAnswers == NO)
    {
        BOOL removedImage = NO;
        NSNumber *chosenAnswer = [NSNumber numberWithInt:indexPath.row];
        
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        for (UIImageView *subview in cell.contentView.subviews)
        {
            if (subview.tag == 99)
            {
                [subview removeFromSuperview];
                removedImage = YES;
                
                [self.chosenAnswerIndexes removeObjectIdenticalTo:chosenAnswer];
                
                break;
                
            }
        }
        
        // Add
        if (removedImage == NO)
        {
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 5, 30, 30)];
            imgView.backgroundColor = [UIColor clearColor];
            
            [imgView setTag:99];
            [imgView setImage:[UIImage imageNamed:@"grayCheck.png"]];
            
            [cell.contentView addSubview:imgView];
            
            [self.chosenAnswerIndexes addObject:chosenAnswer];
        }
    }
}

/// Action performed on button press
- (IBAction)answerQuestion:(id)sender
{
    
    if ([self.answerButton.titleLabel.text isEqual:@"FINISH QUIZ"])
    {
        // Pop back to the home view controller, then navigate back to the quiz menu
        [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndPushToQuiz" object:nil];
    }
    
    else if ([self.answerButton.titleLabel.text isEqual:@"NEXT QUESTION"])
    {
        // Navigate to self, and display the data for the next question
        [self performSegueWithIdentifier:@"navigateToSelf" sender:self];
    }
    
    else if ([self.answerButton.titleLabel.text isEqual:@"ANSWER QUESTION"])
    {
        // Only show the correct answers
        self.showingAnswers = YES;
        NSMutableArray *answersCopy = [self.answers copy];
        [self.answers removeAllObjects];
        for (NSString *answer in self.correctAnswers)
        {
            [self.answers addObject:answer];
        }
        
        [self.questionTextView setHidden:YES];
        [self.checkmarkImageView setHidden:NO];
        
        // Make sets with the correct answers and the user's chosen answers
        NSSet *set1 = [NSSet setWithArray:self.correctAnswerIndexes];
        NSSet *set2 = [NSSet setWithArray:self.chosenAnswerIndexes];
        
        // Check if they're equal. If they are, display the green checkmark. If not, keep the gray checkmark.
        if ([set1 isEqualToSet:set2])
        {
            self.checkmarkImageView.image = [UIImage imageNamed:@"greenCheck.png"];
        }
        else
        {
            self.checkmarkImageView.image = [UIImage imageNamed:@"wrong.png"];
            
            
            // Add the incorrect answers at the end of self.answers
            for (NSNumber *number in self.chosenAnswerIndexes)
            {
                if (!([self.correctAnswerIndexes containsObject:number]))
                {
                    NSInteger index = [number integerValue];
                    [self.answers addObject:answersCopy[index]];
                }
            }
        }
        
        [self.tableView reloadData];

        
        // If we're at the end of the array, prepare to finish the quiz. Otherwise, set up for another question
        if ((self.currentQuestionIndex + 1) == [self.questionsArray count])
        {
            [self.answerButton setTitle:@"FINISH QUIZ" forState:UIControlStateNormal];
        }
        else
        {
            [self.answerButton setTitle:@"NEXT QUESTION" forState:UIControlStateNormal];
        }
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

- (IBAction)showActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Home", @"Being Prepared", @"Checklist", @"Take the Quiz", nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet showFromBarButtonItem:self.menuButton animated:YES];
}

// Instead of actually performing a segue, each of these cases sends a notification. The homepageViewController has an
// observer for each notification, and will call a method to perform the segue when it receives a notification.
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


- (void) setupView
{
    // Initialize arrays to hold the data
    self.answers = [NSMutableArray new];
    self.correctAnswers = [NSMutableArray new];
    self.correctAnswerIndexes = [NSMutableArray new];
    self.chosenAnswerIndexes = [NSMutableArray new];
    [self.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.titleLabel setNumberOfLines:2];
    
    // Get the question at the current index
    [self getCurrentQuestion];
    
    // Sort the question into answers and correct answers, and keep track of indexes
    [self setupQuestions];
    
    
    // Add data to all of the views in the viewcontroller
    self.titleLabel.text = [@"Quiz: " stringByAppendingString:self.titleString];
    [self.answerButton setTitle:@"ANSWER QUESTION" forState:UIControlStateNormal];
    [self.answerButton.titleLabel setHidden:NO];
    [self.checkmarkImageView setHidden:YES];
    self.questionTextView.text = self.currentQuestion.title;
    
    // Remove the separator lines after the last answer
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    // Add a line between the tableView and the textView
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 225, self.view.bounds.size.width, 1)];
    lineView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:lineView];
    
    // Show the question number, eg "5 of 11"
    NSString *questionNumberLabelString = [NSString stringWithFormat:@"%d", self.currentQuestionIndex + 1];
    questionNumberLabelString = [questionNumberLabelString stringByAppendingString:@" of "];
    questionNumberLabelString = [questionNumberLabelString stringByAppendingString:[NSString stringWithFormat:@"%d",[self.questionsArray count]]];
    self.questionNumberLabel.text = questionNumberLabelString;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
    // Do any additional setup after loading the view.
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
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    QuizQuestionViewController *quizQuestionViewController = [segue destinationViewController];
    quizQuestionViewController.currentQuestionIndex = self.currentQuestionIndex + 1;
    quizQuestionViewController.questionsArray = [self.questionsArray copy];
    quizQuestionViewController.titleString = self.titleString;
}


@end
