//
//  SingletonArrayObject.m
//  DynamoDBSample
//
//  Created by rts on 7/17/14.
//  Copyright (c) 2014 Amazon Web Services. All rights reserved.
//

#import "SingletonFavoritesArray.h"

@implementation SingletonFavoritesArray


+(SingletonFavoritesArray*) sharedInstance{
    static SingletonFavoritesArray* _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
        _shared.favoritesArray = [[NSMutableArray alloc] init];
    });
    return _shared;
}
@end