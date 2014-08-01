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

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, DDBMainViewType) {
    DDBMainViewTypeAtoZ,
    DDBMainViewTypeElectedOfficials,
    DDBMainViewTypeByCounty,
    DDBMainViewTypeChildren,
    DDBMainViewTypeDetails,
    DDBMainViewTypeFavorites,
    DDBMainViewTypeN11,
    DDBMainViewTypeNonEmergencyContacts

};



@interface DDBMainViewController : UITableViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) DDBMainViewType viewType;
@property (nonatomic, assign) BOOL needsToRefresh;


// Arrays to hold items with hashKeys 0000, 0001, 0002, 0003 so the app doesn't have
// to search through the whole array every time
@property (nonatomic, readwrite, strong) NSMutableArray *directoryLevel1;
@property (nonatomic, readwrite, strong) NSMutableArray *directoryLevel2;
@property (nonatomic, readwrite, strong) NSMutableArray *directoryLevel3;
@property (nonatomic, readwrite, strong) NSMutableArray *directoryLevel4;
@property (nonatomic, readwrite, strong) NSMutableArray *electedOfficials;
@property (nonatomic, readwrite, strong) NSMutableArray *houseAndSenate;
@property (nonatomic, readwrite, strong) NSMutableArray *n11;
@property (nonatomic, readwrite, strong) NSMutableArray *nonEmergencyContacts;



// A string from the search bar on the home page. Used to filter results
@property (nonatomic, readwrite, strong) NSString *searchString;

- (IBAction)showActionSheet:(id)sender;

@end

