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
	TUMessagePackNegativeFixint = 0xE0,
    
    // full codes
    TUMessagePackUInt8 = 0xCC,
    TUMessagePackUInt16 = 0xCD,
    TUMessagePackUInt32 = 0xCE,
    TUMessagePackUInt64 = 0xCF,
} TUMessagePackCode;


#define TUPopVar(type) *(type *)[self _popData:sizeof(type)].bytes


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
                object = [NSNumber numberWithUnsignedChar:TUPopVar(uint8_t)];
                break;
            } case TUMessagePackUInt16: {
                object = [NSNumber numberWithUnsignedShort:CFSwapInt16BigToHost(TUPopVar(uint16_t))];
                break;
            } case TUMessagePackUInt32: {
                object = [NSNumber numberWithUnsignedLong:CFSwapInt32BigToHost(TUPopVar(uint32_t))];
                break;
            } case TUMessagePackUInt64: {
                object = [NSNumber numberWithUnsignedLongLong:CFSwapInt64BigToHost(TUPopVar(uint64_t))];
                break;
            }
        }
    }
    
    
    if (object == nil && error != NULL) {
        *error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    return object;
}

- (NSData *)_popData:(NSUInteger)length
{
    if (_data.length >= _position + length) {
        NSData *data = [_data subdataWithRange:NSMakeRange(_position, length)];
        _position += length;
        
        return data;
    }
    
    return nil;
}


#pragma mark - Writing

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    return nil;
}

@end
