//
//  MainViewController.m
//  DynamoDBSample
//
//  Created by rts on 7/15/14.
//  Copyright (c) 2014 Amazon Web Services. All rights reserved.
//

#import "MainViewController.h"
#import "DDBMainViewController.h"
#import "DynamoDB.h"
#import "DDBDetailViewController.h"
#import "DDBDynamoDBManager.h"
#import "SingletonArrayObject.h"
#import "SingletonFavoritesArray.h"


@interface MainViewController ()

@property (nonatomic, readonly) NSMutableArray *tableRows;
@property (nonatomic, readonly) NSLock *lock;
@property (nonatomic, strong) NSDictionary *lastEvaluatedKey;
@property (nonatomic, assign) BOOL doneLoading;
@property (nonatomic, retain) NSMutableArray *timeStamp;

// Arrays that hold items from the directory, sorted by hashKey
@property (nonatomic, readonly, strong) NSMutableArray *directoryLevel1;
@property (nonatomic, readonly, strong) NSMutableArray *directoryLevel2;
@property (nonatomic, readonly, strong) NSMutableArray *directoryLevel3;
@property (nonatomic, readonly, strong) NSMutableArray *directoryLevel4;
@property (nonatomic, readonly, strong) NSMutableArray *directoryLevel5;
@property (nonatomic, readonly, strong) NSMutableArray *searchResults;
@property (nonatomic, readonly, strong) NSMutableArray *houseAndSenate;
@property (nonatomic, readonly, strong) NSMutableArray *electedOfficials;
@property (nonatomic, readonly, strong) NSMutableArray *n11;
@property (nonatomic, readonly, strong) NSMutableArray *nonEmergencyContacts;

@property (nonatomic, readwrite) NSString *searchString;
@property (nonatomic, assign) BOOL searching;
@property (nonatomic, assign) BOOL updateDirectory;

@end

@implementation MainViewController

- (BFTask *)checkDatabaseForUpdate:(BOOL)check {
    _lock = [NSLock new];
    if ([self.lock tryLock]){
        if (check) {
            self.lastEvaluatedKey = nil;
            self.doneLoading = NO;
        }
        
        // Turn on the network activity indicator on the status bar
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        //Set up query expression to query all items with hashkey "update" (just the timestamp)
        AWSDynamoDBQueryExpression *queryExpression = [AWSDynamoDBQueryExpression new];
        queryExpression.limit = @20;
        queryExpression.hashKeyValues = (@"update");
        
        AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
        
        // Query the database. Use BFTask to keep the method safe
        return [[[dynamoDBObjectMapper query:[DDBTableRow class]
                                  expression:queryExpression]
                 continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
                     
                     
                     AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                     
                     // Write time stamp back to array from .archive file
                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                     NSString *documentPath = [paths objectAtIndex:0];
                     NSString *filePath = [documentPath stringByAppendingString:@"/timeStamp.archive"];
                     
                     self.timeStamp = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                     
                     self.updateDirectory = [self.timeStamp isEqualToArray:paginatedOutput.items];
                     
                     BOOL success;
                     
                     if (!self.updateDirectory) {
                         
                         // Write the new time stamp to timeStamp.archive
                         success = [NSKeyedArchiver archiveRootObject: paginatedOutput.items toFile:filePath];
                     }
                     
                     
                     return nil;
                 }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     if (!(self.updateDirectory))
                     {
                         // Call refreshList to update the directory array
                         [self.lock unlock];
                         [self refreshList:YES];
                     }
                     
                     // Turn off network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     
                     return nil;
                 }];
        
        
    }
    return nil;
}


- (BFTask *)refreshList:(BOOL)startFromBeginning {
    if ([self.lock tryLock]){
        if (startFromBeginning) {
            self.lastEvaluatedKey = nil;
            self.doneLoading = NO;
        }
        
        // Turn on the network activity indicator on the status bar
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.center = self.view.center;
        [activityView startAnimating];
        [self.view addSubview:activityView];

        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        
        // Set up scan expression to download the database
        AWSDynamoDBScanExpression *scanExpression = [AWSDynamoDBScanExpression new];
        scanExpression.exclusiveStartKey = self.lastEvaluatedKey;
        scanExpression.limit = @10000;
        AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
        
        // Scan the database. Use BFTask to keep the method safe
        return [[[dynamoDBObjectMapper scan:[DDBTableRow class]
                                 expression:scanExpression]
                 continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
                     if (!self.lastEvaluatedKey) {
                         [self.tableRows removeAllObjects];
                     }
                     
                     AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
                     
                     
                     // Copy the new directory to the directory array
                     [SingletonArrayObject sharedInstance].directoryArray = [paginatedOutput.items mutableCopy];
                     
                     // Sort the array by title
                     NSSortDescriptor *sortByRangeKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                              ascending:YES];
                     NSArray *sortingDescriptor = [NSArray arrayWithObjects:sortByRangeKeyDescriptor, nil];
                     NSMutableArray *temp = [SingletonArrayObject sharedInstance].directoryArray;
                     [temp sortUsingDescriptors:sortingDescriptor];
                     [SingletonArrayObject sharedInstance].directoryArray = [temp mutableCopy];
                     
                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                     NSString *documentPath = [paths objectAtIndex:0];
                     NSString *filePath = [documentPath stringByAppendingString:@"/directoryArray.archive"];
                     
                     // Write the directory array to an archive file
                     [NSKeyedArchiver archiveRootObject: [SingletonArrayObject sharedInstance].directoryArray toFile:filePath];
                     
                     
                     
                     return nil;
                 }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                     if (task.error) {
                         NSLog(@"Error: [%@]", task.error);
                     }
                     
                     [self.lock unlock];
                     
                     // Turn of network activity indicator in status bar
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     [activityView stopAnimating];
                     
                     [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                     
                     return nil;
                 }];
    }
    return nil;
}


// Sorts the directory into categories based on hashKey. hashKey really indicates the number
// of parents the item has. This is just to split the array so that the app doesn't have to scan through
// every item whenever it loads a tableView
// Since the directory is sorted in refresh list, everything is in alphabetical order within the
// hashKey arrays.
- (void)sortItems {
    
    // Clear the arrays because the data remains in them even when we navigate away from this
    // view controller
    [self.directoryLevel1 removeAllObjects];
    [self.directoryLevel2 removeAllObjects];
    [self.directoryLevel3 removeAllObjects];
    [self.directoryLevel4 removeAllObjects];
    [self.electedOfficials removeAllObjects];
    [self.houseAndSenate removeAllObjects];
    [self.n11 removeAllObjects];
    [self.nonEmergencyContacts removeAllObjects];
    
    
    // Add items to different arrays based on hashKey
    for (DDBTableRow *item in [SingletonArrayObject sharedInstance].directoryArray) {
        
        
        if ([item.hashKey  isEqual: @"0000"])
        {
            [self.directoryLevel1 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0001"])
        {
            [self.directoryLevel2 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0002"])
        {
            [self.directoryLevel3 addObject:item];
        }
        
        else if ([item.hashKey  isEqual: @"0003"])
        {
            [self.directoryLevel4 addObject:item];
        }
        else if ([item.hashKey isEqual:@"0004"])
        {
            [self.directoryLevel5 addObject:item];
        }
        else if ([item.hashKey  isEqual: @"0005"])
        {
            [self.houseAndSenate addObject:item];
        }
        else if ([item.hashKey isEqual:@"0006"])
        {
            [self.electedOfficials addObject:item];
        }
        else if ([item.hashKey isEqual:@"0008"])
        {
            [self.nonEmergencyContacts addObject:item];
        }
        else if ([item.hashKey isEqual:@"0010"])
            [self.n11 addObject:item];
    }
}



// Search bar implementation
- (void)searchBar:(UISearchBar*) searchBar textDidChange:(NSString *)searchText {
    
    // If the user types, store the string.
    if (searchText.length > 0)
    {
        self.searchString = searchText;
    }
    if (searchText.length == 0)
    {
        [searchBar performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0];
        self.searching = NO;
    }
    
}

// Hide keyboard when "x" button is clicked.
- (void)searchBarTextDidEndEditing:(UISearchBar *) searchBar {
    [searchBar resignFirstResponder];
    self.searching = NO;
}

- (void)searchBarSearchButtonClicked: (UISearchBar *) searchBar {
    
    [self.searchResults removeAllObjects];
    
    // Scan through tableRows for the text in the search bar
    for (DDBTableRow *item in self.directoryLevel1)
    {
        NSRange titleRange = [item.title rangeOfString:self.searchString options:NSCaseInsensitiveSearch];
        if(titleRange.location != NSNotFound)
        {
            // If a match is found, add the current item to directorySearchResults
            [self.searchResults addObject:item];
        }
    }
    
    // Search elected officials
    for (DDBTableRow *item in self.electedOfficials)
    {
        NSRange titleRange = [item.title rangeOfString:self.searchString options:NSCaseInsensitiveSearch];
        if(titleRange.location != NSNotFound)
        {
            [self.searchResults addObject:item];
        }
    }
    
    self.searching = YES;
    
    [self performSegueWithIdentifier:@"listDepartments" sender:searchBar];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) applicationWillEnterForeground:(NSNotification *) notification {
    if ([notification isEqual:UIApplicationWillEnterForegroundNotification])
    {
        [self updateDirectory];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Write the directory to a singleton variable that is accessible from anywhere within the project
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"/directoryArray.archive"];
    
    [SingletonArrayObject sharedInstance].directoryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    // Write the favorites to a singleton variable that is accessible from anywhere within the project
    filePath = [documentPath stringByAppendingString:@"/favoritesArray.archive"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:filePath])
    {
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long size = [attributes fileSize];
        if (attributes && size > 0)
        {
        [SingletonFavoritesArray sharedInstance].favoritesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
        }
    }
    
    // Hide the navigation bar on startup
    [self.navigationController setNavigationBarHidden:YES];
    
    // Initialize arrays to hold the directory
    _directoryLevel1 = [NSMutableArray new];
    _directoryLevel2 = [NSMutableArray new];
    _directoryLevel3 = [NSMutableArray new];
    _directoryLevel4 = [NSMutableArray new];
    _directoryLevel5 = [NSMutableArray new];
    _searchResults = [NSMutableArray new];
    _electedOfficials = [NSMutableArray new];
    _houseAndSenate = [NSMutableArray new];
    _n11 = [NSMutableArray new];
    _nonEmergencyContacts = [NSMutableArray new];
    
        
    // Compare the time stamp item in the locally stored array and the array on DynamoDB.
    // If not equal, checkDatabaseForUpdate calls refreshList to update the array.
    [self checkDatabaseForUpdate:YES];
    
    
    
    // Create a listener so we can refresh the directory when the app is brough up from
    // the background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkDatabaseForUpdate:) name:UIApplicationWillEnterForegroundNotification object:nil];

    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide the navigation controller each time the view draws on the screen
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// Each button has a tag from 0-6. Depending on which button is pressed, a different case
// is satisfied. The cases each set a property of the list screen, which indicates which filter
// to apply to the array before displaying the list.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // tag = 6 is the "About This App" page. Since it doesn't have all of the properties of
    // the mainViewController, the app will crash when it tries to set those properties. So
    // we only set the properties when a different button is selected.
    if ([sender tag] != 6)
    {
        DDBMainViewController *mainViewController = [segue destinationViewController];
        
        [self sortItems];
        
        // Pass the appropriate data to the mainViewController
        if (_searching)
        {
            mainViewController.directoryLevel1 = self.searchResults;
        }
        else
        {
            mainViewController.directoryLevel1 = self.directoryLevel1;
        }
        
        mainViewController.directoryLevel2 = self.directoryLevel2;
        mainViewController.directoryLevel3 = self.directoryLevel3;
        mainViewController.directoryLevel4 = self.directoryLevel4;
        mainViewController.directoryLevel5 = self.directoryLevel5;
        
        switch([sender tag]) {
            case 0:
            {
                mainViewController.viewType = DDBMainViewTypeAtoZ;
                mainViewController.electedOfficials = self.electedOfficials;
                mainViewController.title = @"Directory";
                break;
            }
            case 1:
            {
                mainViewController.viewType = DDBMainViewTypeByCounty;
                mainViewController.title = @"County List";
                break;
            }
            case 2:
            {
                mainViewController.viewType = DDBMainViewTypeElectedOfficials;
                mainViewController.houseAndSenate = self.houseAndSenate;
                mainViewController.electedOfficials = self.electedOfficials;
                mainViewController.title = @"Elected Officials";
                break;
            }
            case 5:
            {
                mainViewController.viewType = DDBMainViewTypeFavorites;
                mainViewController.title=@"Favorites";
                break;
            }
            case 3:
            {
                mainViewController.viewType = DDBMainViewTypeNonEmergencyContacts;
                mainViewController.nonEmergencyContacts = self.nonEmergencyContacts;
                mainViewController.title=@"Non Emergency Contacts";
                break;
            }
            case 4:
            {
                mainViewController.viewType = DDBMainViewTypeN11;
                mainViewController.n11 = self.n11;
                mainViewController.title=@"N11";
            }
        }

    }
        
    }
@end
