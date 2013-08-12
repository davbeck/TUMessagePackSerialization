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
    
    TUMessagePackInt8 = 0xD0,
    TUMessagePackInt16 = 0xD1,
    TUMessagePackInt32 = 0xD2,
    TUMessagePackInt64 = 0xD3,
    
    TUMessagePackNil = 0xC0,
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
            
        case TUMessagePackInt8: {
            object = [NSNumber numberWithChar:TUPopVar(int8_t)];
            break;
        } case TUMessagePackInt16: {
            object = [NSNumber numberWithShort:CFSwapInt16BigToHost(TUPopVar(int16_t))];
            break;
        } case TUMessagePackInt32: {
            object = [NSNumber numberWithLong:CFSwapInt32BigToHost(TUPopVar(int32_t))];
            break;
        } case TUMessagePackInt64: {
            object = [NSNumber numberWithLongLong:CFSwapInt64BigToHost(TUPopVar(int64_t))];
            break;
        }
            
        case TUMessagePackNil: {
            object = [NSNull null];
            break;
        }
            
        default: {
            if (!(code & 0b10000000)) {
                object = [NSNumber numberWithUnsignedChar:code];
            } else if ((code & TUMessagePackNegativeFixint) == TUMessagePackNegativeFixint) {
                object = [NSNumber numberWithChar:code];
            }
            
            break;
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
