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
{
    NSUInteger _position;
    
    TUMessagePackCode _currentCode;
    NSMutableData *_currentObjectData;
}

#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    TUMessagePackSerialization *serialization = [TUMessagePackSerialization new];
    
    return [serialization _messagePackObjectWithData:data options:opt error:error];
}

- (id)_messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    __block id object = nil;
    _position = 0;
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        if (_currentObjectData != nil) {
            object = [self _readObjectWithCode:_currentCode bytes:bytes byteRange:byteRange options:opt error:error];
        }
        
        
        UInt8 code = ((UInt8 *)bytes)[_position - byteRange.location];
        _position++;
        
        // first we check mixed codes (codes that mix code and value)
        if (!(code & 0b10000000)) {
            object = [NSNumber numberWithUnsignedChar:code];
        } else if ((code & TUMessagePackNegativeFixint) == TUMessagePackNegativeFixint) {
            object = [NSNumber numberWithChar:code];
        } else {
            object = [self _readObjectWithCode:code bytes:bytes + _position - byteRange.location byteRange:NSMakeRange(_position, byteRange.length - _position + byteRange.location) options:opt error:error];
        }
    }];
    
    
    if (object == nil && error != NULL) {
        *error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    return object;
}

- (id)_readObjectWithCode:(TUMessagePackCode)code bytes:(const void *)bytes byteRange:(NSRange)byteRange options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    NSMutableData *objectData;
    if (_currentObjectData != nil) {
        objectData = _currentObjectData;
    } else {
        objectData = [NSMutableData new];
    }
    
    switch (code) {
        case TUMessagePackUInt8: {
            if (objectData.length + byteRange.length > _position - byteRange.location) {
                [objectData appendBytes:bytes length:1 - objectData.length];
                
                UInt8 value = *((UInt8 *)[objectData bytes]);
                return [NSNumber numberWithUnsignedChar:value];
            } else {
                [objectData appendBytes:bytes length:byteRange.length];
                
                _currentCode = TUMessagePackUInt8;
                _currentObjectData = [NSMutableData new];
            }
            break;
        } case TUMessagePackUInt64: {
            if (objectData.length + byteRange.length > _position - byteRange.location) {
                [objectData appendBytes:bytes length:8 - objectData.length];
                
                UInt64 value = *((UInt64 *)[objectData bytes]);
                return [NSNumber numberWithLongLong:value];
            } else {
                [objectData appendBytes:bytes length:byteRange.length];
                
                _currentCode = TUMessagePackUInt8;
                _currentObjectData = [NSMutableData new];
            }
            break;
        }
    }
    
    return nil;
}


#pragma mark - Writing

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    return nil;
}

@end
