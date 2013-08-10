//
//  TUMessagePackSerialization.h
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
	TUMessagePackReadingMutableContainers = (1UL << 0),
	TUMessagePackReadingMutableLeaves = (1UL << 1),
	TUMessagePackReadingAllowFragments = (1UL << 2),
	TUMessagePackReadingStringsAsData = (1UL << 3),
} TUMessagePackReadingOptions;

typedef enum : NSUInteger {
    TUMessagePackWritingCompatabilityMode = (1UL << 0),
} TUMessagePackWritingOptions;


extern NSString *TUMessagePackErrorDomain;
typedef enum : NSInteger {
	TUMessagePackNoMatchingFormatCode,
} TUMessagePackErrorCode;


@interface TUMessagePackSerialization : NSObject

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error;

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error;

@end
