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
    
    TUMessagePackFloat = 0xCA,
    TUMessagePackDouble = 0xCB,
    
    TUMessagePackNil = 0xC0,
    
    TUMessagePackTrue = 0xC3,
    TUMessagePackFalse = 0xC2,
    
    TUMessagePackFixstr = 0xA0,
    TUMessagePackStr8 = 0xD9 ,
    TUMessagePackStr16 = 0xDA,
    TUMessagePackStr32 = 0xDB,
    
    TUMessagePackBin8 = 0xC4,
    TUMessagePackBin16 = 0xC5,
    TUMessagePackBin32 = 0xC6,
    
    TUMessagePackFixarray = 0x90,
} TUMessagePackCode;


#define TUCheckDataForVar(type) do { \
    if (_data.length < _position + sizeof(type)) { \
        _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNotEnoughData userInfo:nil]; \
        return nil; \
    } \
} while (0)

#define TUPopVar(type) *(type *)[self _popData:sizeof(type)].bytes


@implementation TUMessagePackSerialization
{
    NSUInteger _position;
    NSData *_data;
    TUMessagePackReadingOptions _options;
    NSError *_error;
}

#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    TUMessagePackSerialization *serialization = [[TUMessagePackSerialization alloc] init];
    
    return [serialization _messagePackObjectWithData:data options:opt error:error];
}

- (id)_messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    _options = opt;
    _data = data;
    _position = 0;
    
    id object = [self _popObject];
    
    if (_error != nil && error != NULL) {
        *error = _error;
    }
    
    return object;
}

- (id)_popObject
{
    id object = nil;
    
    TUCheckDataForVar(uint8_t);
    TUMessagePackCode code = TUPopVar(uint8_t);
    
    switch (code) {
            case TUMessagePackUInt8: {
                TUCheckDataForVar(uint8_t);
                object = [NSNumber numberWithUnsignedChar:TUPopVar(uint8_t)];
                break;
            } case TUMessagePackUInt16: {
                TUCheckDataForVar(uint16_t);
                object = [NSNumber numberWithUnsignedShort:CFSwapInt16BigToHost(TUPopVar(uint16_t))];
                break;
            } case TUMessagePackUInt32: {
                TUCheckDataForVar(uint32_t);
                object = [NSNumber numberWithUnsignedLong:CFSwapInt32BigToHost(TUPopVar(uint32_t))];
                break;
            } case TUMessagePackUInt64: {
                TUCheckDataForVar(uint64_t);
                object = [NSNumber numberWithUnsignedLongLong:CFSwapInt64BigToHost(TUPopVar(uint64_t))];
                break;
            }
            
            case TUMessagePackInt8: {
                TUCheckDataForVar(int8_t);
                object = [NSNumber numberWithChar:TUPopVar(int8_t)];
                break;
            } case TUMessagePackInt16: {
                TUCheckDataForVar(int16_t);
                object = [NSNumber numberWithShort:CFSwapInt16BigToHost(TUPopVar(int16_t))];
                break;
            } case TUMessagePackInt32: {
                TUCheckDataForVar(int32_t);
                object = [NSNumber numberWithLong:CFSwapInt32BigToHost(TUPopVar(int32_t))];
                break;
            } case TUMessagePackInt64: {
                TUCheckDataForVar(int64_t);
                object = [NSNumber numberWithLongLong:CFSwapInt64BigToHost(TUPopVar(int64_t))];
                break;
            }
            
            case TUMessagePackFloat: {
                TUCheckDataForVar(CFSwappedFloat32);
                object = [NSNumber numberWithFloat:CFConvertFloatSwappedToHost(TUPopVar(CFSwappedFloat32))];
                break;
            } case TUMessagePackDouble: {
                TUCheckDataForVar(CFSwappedFloat64);
                object = [NSNumber numberWithDouble:CFConvertDoubleSwappedToHost(TUPopVar(CFSwappedFloat64))];
                break;
            }
            
            case TUMessagePackNil: {
                if ((_options & TUMessagePackReadingNSNullAsNil) == TUMessagePackReadingNSNullAsNil) {
                    // the one case where returning nil is not an error
                    return nil;
                } else {
                    object = [NSNull null];
                }
                break;
            }
            
            case TUMessagePackTrue: {
                object = (id)kCFBooleanTrue;
                break;
            } case TUMessagePackFalse: {
                object = (id)kCFBooleanFalse;
                break;
            }
            
            case TUMessagePackStr8: {
                TUCheckDataForVar(uint8_t);
                
                uint8_t length = TUPopVar(uint8_t);
                object = [self _popString:length];
                break;
            } case TUMessagePackStr16: {
                TUCheckDataForVar(uint16_t);
                
                uint16_t length = CFSwapInt16BigToHost(TUPopVar(uint16_t));
                object = [self _popString:length];
                break;
            } case TUMessagePackStr32: {
                TUCheckDataForVar(uint32_t);
                
                uint32_t length = CFSwapInt32BigToHost(TUPopVar(uint32_t));
                object = [self _popString:length];
                break;
            }
            
            case TUMessagePackBin8: {
                TUCheckDataForVar(uint8_t);
                
                uint8_t length = TUPopVar(uint8_t);
                object = [self _popData:length];
                if (_options & TUMessagePackReadingMutableLeaves) {
                    object = [object mutableCopy];
                }
                
                break;
            } case TUMessagePackBin16: {
                TUCheckDataForVar(uint16_t);
                
                uint16_t length = CFSwapInt16BigToHost(TUPopVar(uint16_t));
                object = [self _popData:length];
                if (_options & TUMessagePackReadingMutableLeaves) {
                    object = [object mutableCopy];
                }
                
                break;
            } case TUMessagePackBin32: {
                TUCheckDataForVar(uint32_t);
                
                uint32_t length = CFSwapInt32BigToHost(TUPopVar(uint32_t));
                object = [self _popData:length];
                if (_options & TUMessagePackReadingMutableLeaves) {
                    object = [object mutableCopy];
                }
                
                break;
            }
            
        default: {
            if (!(code & 0b10000000)) {
                object = [NSNumber numberWithUnsignedChar:code];
            } else if ((code & 0b11100000) == TUMessagePackNegativeFixint) {
                object = [NSNumber numberWithChar:code];
            } else if ((code & 0b11100000) == TUMessagePackFixstr) {
                uint8_t length = code & ~0b11100000;
                object = [self _popString:length];
            } else if ((code & 0b11110000) == TUMessagePackFixarray) {
                uint8_t length = code & ~0b11110000;
                object = [self _popArray:length];
            }
            
            break;
        }
    }
    
    
    if (object == nil && _error == nil) {
        _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    
    return object;
}

- (id)_popString:(NSUInteger)length
{
    NSData *stringData = [self _popData:length];
    
    if (_options & TUMessagePackReadingStringsAsData) {
        if (_options & TUMessagePackReadingMutableLeaves) {
            return [stringData mutableCopy];
        } else {
            return stringData;
        }
    } else {
        if (_options & TUMessagePackReadingMutableLeaves) {
            return [[NSMutableString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
        } else {
            return [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
        }
    }
}

- (id)_popArray:(NSUInteger)length
{
    id __unsafe_unretained *objects = (id __unsafe_unretained *)alloca(sizeof(id) * length);
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        __attribute__((objc_precise_lifetime)) id object = [self _popObject];
        
        if (object != nil) {
            objects[index] = object;
            count++;
        } else if (_error != nil) {
            return nil;
        }
    }
    
    return [[NSArray alloc] initWithObjects:objects count:count];
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
