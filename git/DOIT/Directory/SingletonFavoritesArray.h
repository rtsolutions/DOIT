//
//  SingletonArrayObject.h
//  DynamoDBSample
//
//  Created by rts on 7/17/14.
//  Copyright (c) 2014 Amazon Web Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingletonFavoritesArray : NSObject

@property (nonatomic, retain) NSMutableArray *favoritesArray;
+(SingletonFavoritesArray*) sharedInstance;

@end


