//
//  TUMessagePackSerialization.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "TUMessagePackSerialization.h"


NSString *TUMessagePackErrorDomain = @"com.ThinkUltimate.MessagePack.Error";


typedef enum : UInt8 {
	TUMessagePackPositiveFixint = 0x00,
} TUMessagePackCode;


@implementation TUMessagePackSerialization

#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    __block id object = nil;
    
    
    NSUInteger position = 0;
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        UInt8 code = ((UInt8 *)bytes)[position - byteRange.location];
        
        if ((code & TUMessagePackPositiveFixint) == TUMessagePackPositiveFixint) {
            object = [NSNumber numberWithUnsignedChar:code];
        }
    }];
    
    
    if (object == nil && error != NULL) {
        *error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    return object;
}


#pragma mark - Writing

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    return nil;
}

@end
