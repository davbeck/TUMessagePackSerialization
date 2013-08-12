//
//  TUMessagePackSerialization.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "TUMessagePackSerialization.h"


NSString *TUMessagePackErrorDomain = @"com.ThinkUltimate.MessagePack.Error";


typedef enum : uint8_t {
    // mixed codes
	TUMessagePackPositiveFixint = 0x00, // unused... it's special
	TUMessagePackNegativeFixint = 0xe0,
    
    // full codes
    TUMessagePackUInt8 = 0xcc,
    TUMessagePackUInt64 = 0xcf,
} TUMessagePackCode;


#define TUPopVar(type) *(type *)[_data subdataWithRange:NSMakeRange(_position, sizeof(type))].bytes; _position += sizeof(type);


@implementation TUMessagePackSerialization
{
    NSUInteger _position;
    NSData *_data;
}

#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    TUMessagePackSerialization *serialization = [[TUMessagePackSerialization alloc] init];
    
    return [serialization _messagePackObjectWithData:data options:opt error:error];
}

- (id)_messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    __block id object = nil;
    
    
    _data = data;
    _position = 0;
    
    
    TUMessagePackCode code = TUPopVar(uint8_t);
    
    // first we check mixed codes (codes that mix code and value)
    if (!(code & 0b10000000)) {
        object = [NSNumber numberWithUnsignedChar:code];
    } else if ((code & TUMessagePackNegativeFixint) == TUMessagePackNegativeFixint) {
        object = [NSNumber numberWithChar:code];
    } else {
        // the rest of the codes are all 8 bits
        switch (code) {
            case TUMessagePackUInt8: {
                if (_data.length >= _position + 8/8) {
                    uint8_t value = TUPopVar(uint8_t);
                    object = [NSNumber numberWithUnsignedChar:value];
                }
                break;
            } case TUMessagePackUInt64: {
                if (_data.length >= _position + 64/8) {
                    uint64_t value = TUPopVar(uint64_t);
                    value = CFSwapInt64BigToHost(value);
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
