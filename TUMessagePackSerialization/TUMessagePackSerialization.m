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
    // mixed codes
	TUMessagePackPositiveFixint = 0x00, // unused... it's special
	TUMessagePackNegativeFixint = 0xe0,
    
    // full codes
    TUMessagePackUInt8 = 0xcc,
    TUMessagePackUInt64 = 0xcf,
} TUMessagePackCode;


@implementation TUMessagePackSerialization

#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    __block id object = nil;
    
    
    __block NSUInteger position = 0;
    const void *bytes = data.bytes;
    
    UInt8 code = ((UInt8 *)bytes)[position];
    position++;
    
    // first we check mixed codes (codes that mix code and value)
    if (!(code & 0b10000000)) {
        object = [NSNumber numberWithUnsignedChar:code];
    } else if ((code & TUMessagePackNegativeFixint) == TUMessagePackNegativeFixint) {
        object = [NSNumber numberWithChar:code];
    } else {
        // the rest of the codes are all 8 bits
        switch (code) {
            case TUMessagePackUInt8: {
                if (data.length >= position + 8/8) {
                    UInt8 value = ((UInt8 *)bytes)[position];
                    object = [NSNumber numberWithUnsignedChar:value];
                }
                break;
            } case TUMessagePackUInt64: {
                if (data.length >= position + 64/8) {
                    UInt64 value = ((UInt64 *)bytes)[position];
                    object = [NSNumber numberWithUnsignedLongLong:value];
                }
                break;
            }
        }
    }
    
    
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
