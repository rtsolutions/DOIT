//
//  checklistItem.h
//  EmergencyPreparedness
//
//  Created by rts on 8/6/14.
//  Copyright (c) 2014 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface checklistItem : NSObject

@property (nonatomic, assign) BOOL checked;
@property (nonatomic, assign) NSString *text;
@property (nonatomic, assign) NSString *title;

@end
