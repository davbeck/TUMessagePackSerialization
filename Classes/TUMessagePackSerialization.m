//
//  TUMessagePackSerialization.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "TUMessagePackSerialization.h"

#import "TUMessagePackExtInfo.h"
#import "NSNumber+TUMetaData.h"


NSString *TUMessagePackErrorDomain = @"com.ThinkUltimate.MessagePack.Error";


typedef enum : uint8_t {
	TUMessagePackPositiveFixint = 0x00, // unused... it's special
	TUMessagePackNegativeFixint = 0xE0,
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
    TUMessagePackStr8 = 0xD9,
    TUMessagePackStr16 = 0xDA,
    TUMessagePackStr32 = 0xDB,
    
    TUMessagePackBin8 = 0xC4,
    TUMessagePackBin16 = 0xC5,
    TUMessagePackBin32 = 0xC6,
    
    TUMessagePackFixarray = 0x90,
    TUMessagePackArray16 = 0xDC,
    TUMessagePackArray32 = 0xDD,
    
    TUMessagePackFixmap = 0x80,
    TUMessagePackMap16 = 0xDE,
    TUMessagePackMap32 = 0xDF,
    
    TUMessagePackFixext1 = 0xD4,
    TUMessagePackFixext2 = 0xD5,
    TUMessagePackFixext4 = 0xD6,
    TUMessagePackFixext8 = 0xD7,
    TUMessagePackFixext16 = 0xD8,
    TUMessagePackExt8 = 0xC7,
    TUMessagePackExt16 = 0xC8,
    TUMessagePackExt32 = 0xC9,
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

+ (NSMutableDictionary *)_registeredExtClasses
{
    static NSMutableDictionary *registeredExtClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredExtClasses = [NSMutableDictionary new];
    });
    
    return registeredExtClasses;
}

+ (void)registerExtWithClass:(Class)extClass type:(uint8_t)type
{
    [self _registeredExtClasses][@(type)] = extClass;
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
            
        case TUMessagePackArray16: {
            TUCheckDataForVar(uint16_t);
            uint16_t length = CFSwapInt16BigToHost(TUPopVar(uint16_t));
            
            object = [self _popArray:length];
            
            break;
        } case TUMessagePackArray32: {
            TUCheckDataForVar(uint32_t);
            uint32_t length = CFSwapInt32BigToHost(TUPopVar(uint32_t));
            
            object = [self _popArray:length];
            
            break;
        }
            
        case TUMessagePackMap16: {
            TUCheckDataForVar(uint16_t);
            uint16_t length = CFSwapInt16BigToHost(TUPopVar(uint16_t));
            
            object = [self _popMap:length];
            
            break;
        } case TUMessagePackMap32: {
            TUCheckDataForVar(uint32_t);
            uint32_t length = CFSwapInt32BigToHost(TUPopVar(uint32_t));
            
            object = [self _popMap:length];
            
            break;
        }
            
        case TUMessagePackFixext1: {
            object = [self _popExt:1];
            
            break;
        } case TUMessagePackFixext2: {
            object = [self _popExt:2];
            
            break;
        } case TUMessagePackFixext4: {
            object = [self _popExt:4];
            
            break;
        } case TUMessagePackFixext8: {
            object = [self _popExt:8];
            
            break;
        } case TUMessagePackFixext16: {
            object = [self _popExt:16];
            
            break;
        } case TUMessagePackExt8: {
            TUCheckDataForVar(uint8_t);
            uint8_t length = TUPopVar(uint8_t);
            
            object = [self _popExt:length];
            
            break;
        } case TUMessagePackExt16: {
            TUCheckDataForVar(uint16_t);
            uint16_t length = CFSwapInt16BigToHost(TUPopVar(uint16_t));
            
            object = [self _popExt:length];
            
            break;
        } case TUMessagePackExt32: {
            TUCheckDataForVar(uint32_t);
            uint32_t length = CFSwapInt32BigToHost(TUPopVar(uint32_t));
            
            object = [self _popExt:length];
            
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
            } else  if ((code & 0b11110000) == TUMessagePackFixmap) {
                uint8_t length = code & ~0b11110000;
                object = [self _popMap:length];
            }
            
            break;
        }
    }
    
    
    if (object == nil && _error == nil) {
        _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
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

- (id)_popMap:(NSUInteger)length
{
    id __unsafe_unretained *keys = (id __unsafe_unretained *)alloca(sizeof(id) * length);
    id __unsafe_unretained *objects = (id __unsafe_unretained *)alloca(sizeof(id) * length);
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        __attribute__((objc_precise_lifetime)) id key = [self _popObject];
        __attribute__((objc_precise_lifetime)) id object = [self _popObject];
        
        if (key != nil && object != nil) {
            keys[index] = key;
            objects[index] = object;
            count++;
        } else if (_error != nil) {
            return nil;
        }
    }
    
    return [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:count];
}

- (id)_popExt:(NSUInteger)length
{
    TUCheckDataForVar(uint8_t);
    uint8_t type = TUPopVar(uint8_t);
    NSData *extData = [self _popData:length];
    
    Class extClass = [self.class _registeredExtClasses][@(type)];
    if (extClass == nil) {
        extClass = [TUMessagePackExtInfo class];
    }
    
    return [[extClass alloc] initWithMessagePackExtData:extData type:type];
}


#pragma mark - Writing

#define AddVar(var, position) do { \
__typeof(var) value = var; \
memcpy(data + position, &value, sizeof(var)); \
} while(false);

#define ReturnDataWithNumber(code, rawValue) do { \
void *data = malloc(1 + sizeof(rawValue)); \
memset(data, code, 1); \
AddVar(rawValue, 1); \
return [NSData dataWithBytesNoCopy:data length:1 + sizeof(rawValue)]; \
} while(false);

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *number = obj;
        
        if (number == (id)kCFBooleanTrue) {
            uint8_t value = TUMessagePackTrue;
            return [NSData dataWithBytes:&value length:1];
        } else if (number == (id)kCFBooleanFalse) {
            uint8_t value = TUMessagePackFalse;
            return [NSData dataWithBytes:&value length:1];
        } else if ([number isFloat]) {
            if (strcmp(number.objCType, @encode(double)) == 0) {
                ReturnDataWithNumber(TUMessagePackDouble, CFConvertFloat64HostToSwapped(number.doubleValue));
            } else {
                ReturnDataWithNumber(TUMessagePackFloat, CFConvertFloat32HostToSwapped(number.floatValue));
            }
        } else {
            int64_t signedValue = number.longLongValue;
            
            if ([number isSigned] && signedValue < 0) {
                if (signedValue > -pow(2, 5)) {
                    int8_t value = signedValue;
                    return [NSData dataWithBytes:&value length:sizeof(value)];
                } else if (signedValue > -pow(2, 1 * 8 - 1)) {
                    ReturnDataWithNumber(TUMessagePackInt8, (int8_t)signedValue);
                } else if (signedValue > -pow(2, 2 * 8 - 1)) {
                    ReturnDataWithNumber(TUMessagePackInt16, CFSwapInt16HostToBig(signedValue));
                } else if (signedValue > -pow(2, 4 * 8 - 1)) {
                    ReturnDataWithNumber(TUMessagePackInt32, CFSwapInt32HostToBig(signedValue));
                } else if (signedValue > -pow(2, 8 * 8 - 1)) {
                    ReturnDataWithNumber(TUMessagePackInt64, CFSwapInt64HostToBig(signedValue));
                }
            } else {
                uint64_t unsignedValue = number.unsignedLongLongValue;
                
                if (unsignedValue < pow(2, 7)) {
                    uint8_t value = unsignedValue;
                    return [NSData dataWithBytes:&value length:1];
                } else if (unsignedValue < pow(2, 1 * 8)) {
                    ReturnDataWithNumber(TUMessagePackUInt8, (uint8_t)unsignedValue);
                } else if (unsignedValue < pow(2, 2 * 8)) {
                    ReturnDataWithNumber(TUMessagePackUInt16, CFSwapInt16HostToBig(unsignedValue));
                } else if (unsignedValue < pow(2, 4 * 8)) {
                    ReturnDataWithNumber(TUMessagePackUInt32, CFSwapInt32HostToBig(unsignedValue));
                } else if (unsignedValue < pow(2, 8 * 8)) {
                    ReturnDataWithNumber(TUMessagePackUInt64, CFSwapInt64HostToBig(unsignedValue));
                }
            }
        }
    } else if ([obj isKindOfClass:[NSNull class]]) {
        uint8_t value = TUMessagePackNil;
        return [NSData dataWithBytes:&value length:1];
    } else if ([obj isKindOfClass:[NSString class]]) {
        NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
        
        if (data.length < 32) {
            return [self _mpDataWithData:data code:TUMessagePackFixstr | data.length lengthBytes:0];
        } else if (data.length < pow(2, 1 * 8) && !(opt & TUMessagePackWritingCompatabilityMode)) {
            return [self _mpDataWithData:data code:TUMessagePackStr8 lengthBytes:1];
        } else if (data.length < pow(2, 2 * 8)) {
            return [self _mpDataWithData:data code:TUMessagePackStr16 lengthBytes:2];
        } else if (data.length < pow(2, 4 * 8)) {
            return [self _mpDataWithData:data code:TUMessagePackStr32 lengthBytes:4];
        }
    } else if ([obj isKindOfClass:[NSData class]]) {
        NSData *data = obj;
        
        if (opt & TUMessagePackWritingCompatabilityMode) {
            if (data.length < pow(2, 2 * 8)) {
                return [self _mpDataWithData:data code:TUMessagePackStr16 lengthBytes:2];
            } else if (data.length < pow(2, 4 * 8)) {
                return [self _mpDataWithData:data code:TUMessagePackStr32 lengthBytes:4];
            }
        } else {
            if (data.length < pow(2, 1 * 8)) {
                return [self _mpDataWithData:data code:TUMessagePackBin8 lengthBytes:1];
            } else if (data.length < pow(2, 2 * 8)) {
                return [self _mpDataWithData:data code:TUMessagePackBin16 lengthBytes:2];
            } else if (data.length < pow(2, 4 * 8)) {
                return [self _mpDataWithData:data code:TUMessagePackBin32 lengthBytes:4];
            }
        }
    }
    
    
    if (error != NULL) {
        *error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    
    return nil;
}

+ (NSData *)_mpDataWithData:(NSData *)data code:(TUMessagePackCode)code lengthBytes:(NSUInteger)lengthBytes
{
    void *bytes = malloc(1 + lengthBytes + data.length);
    
    memset(bytes, code, 1);
    
    switch (lengthBytes) {
        case 1: {
            uint8_t length = data.length;
            memcpy(bytes + 1, &length, lengthBytes);
            
            break;
        } case 2: {
            uint16_t length = CFSwapInt16HostToBig(data.length);
            memcpy(bytes + 1, &length, lengthBytes);
            
            break;
        } case 4: {
            uint32_t length = CFSwapInt32HostToBig(data.length);
            memcpy(bytes + 1, &length, lengthBytes);
            
            break;
        }
    }
    
    memcpy(bytes + 1 + lengthBytes, data.bytes, data.length);
    
    return [NSData dataWithBytesNoCopy:bytes length:1 + lengthBytes + data.length];
}

+ (BOOL)isValidMessagePackObject:(id)obj
{
    return NO;
}

@end
