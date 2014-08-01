//
//  SingletonArray.h
//

#import <Foundation/Foundation.h>

@interface SingletonArray : NSObject

@property (nonatomic, retain) NSMutableArray *alertsArray;
+(SingletonArray*) sharedInstance;

@end


