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


@implementation TUMessagePackSerialization
{
    NSUInteger _position;
    const void *_bytes;
    NSData *_data;
    TUMessagePackReadingOptions _readingOptions;
    TUMessagePackWritingOptions _writingOptions;
    NSError *_error;
}

#pragma mark - Reading

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

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    TUMessagePackSerialization *serialization = [[TUMessagePackSerialization alloc] init];
    
    return [serialization _messagePackObjectWithData:data options:opt error:error];
}

- (id)_messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    _readingOptions = opt;
    _data = data;
    _bytes = _data.bytes; // for whatever reason, this takes a good chunk of time, so we cache the result
    _position = 0;
    
    id object = [self _popObject];
    
    if (_error != nil && error != NULL) {
        *error = _error;
    }
    
    return object;
}

- (id)_popObject
{
    __block id object = nil;
    
    [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
        TUMessagePackCode code = *(uint8_t *)bytes;
        
        
        switch (code) {
            case TUMessagePackUInt8: {
                [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithUnsignedChar:*(uint8_t *)bytes];
                }];
                break;
            } case TUMessagePackUInt16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithUnsignedShort:CFSwapInt16BigToHost(*(uint16_t *)bytes)];
                }];
                break;
            } case TUMessagePackUInt32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithUnsignedLong:CFSwapInt32BigToHost(*(uint32_t *)bytes)];
                }];
                break;
            } case TUMessagePackUInt64: {
                [self _popBytes:sizeof(uint64_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithUnsignedLongLong:CFSwapInt64BigToHost(*(uint64_t *)bytes)];
                }];
                break;
            }
                
            case TUMessagePackInt8: {
                [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithChar:*(uint8_t *)bytes];
                }];
                break;
            } case TUMessagePackInt16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithShort:CFSwapInt16BigToHost(*(uint16_t *)bytes)];
                }];
                break;
            } case TUMessagePackInt32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithLong:CFSwapInt32BigToHost(*(uint32_t *)bytes)];
                }];
                break;
            } case TUMessagePackInt64: {
                [self _popBytes:sizeof(uint64_t) block:^(const void *bytes) {
                    object = [NSNumber numberWithLongLong:CFSwapInt64BigToHost(*(uint64_t *)bytes)];
                }];
                break;
            }
                
            case TUMessagePackFloat: {
                [self _popBytes:sizeof(CFSwappedFloat32) block:^(const void *bytes) {
                    object = [NSNumber numberWithFloat:CFConvertFloatSwappedToHost(*(CFSwappedFloat32 *)bytes)];
                }];
                break;
            } case TUMessagePackDouble: {
                [self _popBytes:sizeof(CFSwappedFloat64) block:^(const void *bytes) {
                    object = [NSNumber numberWithDouble:CFConvertDoubleSwappedToHost(*(CFSwappedFloat64 *)bytes)];
                }];
                break;
            }
                
            case TUMessagePackNil: {
                if ((_readingOptions & TUMessagePackReadingNSNullAsNil) == TUMessagePackReadingNSNullAsNil) {
                    // the one case where returning nil is not an error
                    object = nil;
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
                [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
                    uint8_t length = *(uint8_t *)bytes;
                    object = [self _popString:length];
                }];
                break;
            } case TUMessagePackStr16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    uint16_t length = CFSwapInt16BigToHost(*(uint16_t *)bytes);
                    object = [self _popString:length];
                }];
                break;
            } case TUMessagePackStr32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
                    object = [self _popString:length];
                }];
                break;
            }
                
            case TUMessagePackBin8: {
                [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
                    uint8_t length = *(uint8_t *)bytes;
                    object = [self _popData:length];
                    if (_readingOptions & TUMessagePackReadingMutableLeaves) {
                        object = [object mutableCopy];
                    }
                }];
                break;
            } case TUMessagePackBin16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    uint16_t length = CFSwapInt16BigToHost(*(uint16_t *)bytes);
                    object = [self _popData:length];
                    if (_readingOptions & TUMessagePackReadingMutableLeaves) {
                        object = [object mutableCopy];
                    }
                }];
                break;
            } case TUMessagePackBin32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
                    object = [self _popData:length];
                    if (_readingOptions & TUMessagePackReadingMutableLeaves) {
                        object = [object mutableCopy];
                    }
                }];
                break;
            }
                
            case TUMessagePackArray16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    uint16_t length = CFSwapInt16BigToHost(*(uint16_t *)bytes);
                    object = [self _popArray:length];
                }];
                break;
            } case TUMessagePackArray32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
                    object = [self _popArray:length];
                }];
                break;
            }
                
            case TUMessagePackMap16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    uint16_t length = CFSwapInt16BigToHost(*(uint16_t *)bytes);
                    object = [self _popMap:length];
                }];
                break;
            } case TUMessagePackMap32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
                    object = [self _popMap:length];
                }];
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
                [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
                    uint8_t length = *(uint8_t *)bytes;
                    object = [self _popExt:length];
                }];
                
                break;
            } case TUMessagePackExt16: {
                [self _popBytes:sizeof(uint16_t) block:^(const void *bytes) {
                    uint16_t length = CFSwapInt16BigToHost(*(uint16_t *)bytes);
                    object = [self _popExt:length];
                }];
                
                break;
            } case TUMessagePackExt32: {
                [self _popBytes:sizeof(uint32_t) block:^(const void *bytes) {
                    uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
                    object = [self _popExt:length];
                }];
                
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
                } else {
                    _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
                }
                
                break;
            }
        }
    }];
    
    return object;
}

- (void)_popBytes:(NSUInteger)length block:(void(^)(const void *bytes))block
{
    if (_data.length >= _position + length) {
        // note that this could be called again within the block so we need to incriment position before calling the block
        const void *bytes = _bytes + _position;
        _position += length;
        block(bytes);
    } else {
        _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNotEnoughData userInfo:nil];
    }
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
    __block id object;
    if ((_readingOptions & TUMessagePackReadingStringsAsData) != TUMessagePackReadingStringsAsData) {
        [self _popBytes:length block:^(const void *stringBytes) {
            if ((_readingOptions & TUMessagePackReadingMutableLeaves) != TUMessagePackReadingMutableLeaves) {
                object = [[NSString alloc] initWithBytes:stringBytes length:length encoding:NSUTF8StringEncoding];
            } else {
                object = [[NSMutableString alloc] initWithBytes:stringBytes length:length encoding:NSUTF8StringEncoding];
            }
        }];
    } else {
        if ((_readingOptions & TUMessagePackReadingMutableLeaves) != TUMessagePackReadingMutableLeaves) {
            object = [self _popData:length];
        } else {
            object = [[self _popData:length] mutableCopy];
        }
    }
    
    return object;
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
    __block id object = nil;
    
    [self _popBytes:sizeof(uint8_t) block:^(const void *bytes) {
        uint8_t type = *(uint8_t *)bytes;
        
        NSData *extData = [self _popData:length];
        
        Class extClass = [self.class _registeredExtClasses][@(type)];
        if (extClass == nil) {
            extClass = [TUMessagePackExtInfo class];
        }
        
        object = [[extClass alloc] initWithMessagePackExtData:extData type:type];
    }];
    
    return object;
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
    TUMessagePackSerialization *serialization = [[TUMessagePackSerialization alloc] init];
    
    return [serialization _dataWithMessagePackObject:obj options:opt error:error];
}

- (NSData *)_dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    _writingOptions = opt;
    
    NSData *data = [self _mpDataWithObject:obj];
    
    if (_error != nil && error != NULL) {
        *error = _error;
    }
    
    return data;
}

- (NSData *)_mpDataWithObject:(id)obj
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
        } else if (data.length < pow(2, 1 * 8) && !(_writingOptions & TUMessagePackWritingCompatabilityMode)) {
            return [self _mpDataWithData:data code:TUMessagePackStr8 lengthBytes:1];
        } else if (data.length < pow(2, 2 * 8)) {
            return [self _mpDataWithData:data code:TUMessagePackStr16 lengthBytes:2];
        } else if (data.length < pow(2, 4 * 8)) {
            return [self _mpDataWithData:data code:TUMessagePackStr32 lengthBytes:4];
        }
    } else if ([obj isKindOfClass:[NSData class]]) {
        NSData *data = obj;
        
        if (_writingOptions & TUMessagePackWritingCompatabilityMode) {
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
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *array = obj;
        
        if (array.count < 16) {
            return [self _mpDataWithArray:array code:TUMessagePackFixarray | (uint8_t)array.count lengthBytes:0];
        } else if (array.count < pow(2, 2 * 8)) {
            return [self _mpDataWithArray:array code:TUMessagePackArray16 lengthBytes:2];
        } else if (array.count < pow(2, 4 * 8)) {
            return [self _mpDataWithArray:array code:TUMessagePackArray32 lengthBytes:4];
        }
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = obj;
        
        if (dictionary.count < 16) {
            return [self _mpDataWithDictionary:dictionary code:TUMessagePackFixmap | (uint8_t)dictionary.count lengthBytes:0];
        } else if (dictionary.count < pow(2, 2 * 8)) {
            return [self _mpDataWithDictionary:dictionary code:TUMessagePackMap16 lengthBytes:2];
        } else if (dictionary.count < pow(2, 4 * 8)) {
            return [self _mpDataWithDictionary:dictionary code:TUMessagePackMap32 lengthBytes:4];
        }
    }
    
    
    if (_error == nil) {
        _error = [NSError errorWithDomain:TUMessagePackErrorDomain code:TUMessagePackNoMatchingFormatCode userInfo:nil];
    }
    
    return nil;
}

- (NSData *)_mpDataWithData:(NSData *)data code:(TUMessagePackCode)code lengthBytes:(NSUInteger)lengthBytes
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

- (NSData *)_mpDataWithArray:(NSArray *)array code:(TUMessagePackCode)code lengthBytes:(NSUInteger)lengthBytes
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendBytes:&code length:1];
    
    switch (lengthBytes) {
        case 1: {
            uint8_t length = array.count;
            [data appendBytes:&length length:lengthBytes];
            
            break;
        } case 2: {
            uint16_t length = CFSwapInt16HostToBig(array.count);
            [data appendBytes:&length length:lengthBytes];
            
            break;
        } case 4: {
            uint32_t length = CFSwapInt32HostToBig(array.count);
            [data appendBytes:&length length:lengthBytes];
            
            break;
        }
    }
    
    for (id object in array) {
        NSData *objectData = [self _mpDataWithObject:object];
        
        if (objectData != nil) {
            [data appendData:objectData];
        }
    }
    
    return data;
}

- (NSData *)_mpDataWithDictionary:(NSDictionary *)dictionary code:(TUMessagePackCode)code lengthBytes:(NSUInteger)lengthBytes
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendBytes:&code length:1];
    
    switch (lengthBytes) {
        case 1: {
            uint8_t length = dictionary.count;
            [data appendBytes:&length length:lengthBytes];
            
            break;
        } case 2: {
            uint16_t length = CFSwapInt16HostToBig(dictionary.count);
            [data appendBytes:&length length:lengthBytes];
            
            break;
        } case 4: {
            uint32_t length = CFSwapInt32HostToBig(dictionary.count);
            [data appendBytes:&length length:lengthBytes];
            
            break;
        }
    }
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSData *keyData = [self _mpDataWithObject:key];
        NSData *objData = [self _mpDataWithObject:obj];
        
        if (objData != nil && keyData != nil && _error == nil) {
            [data appendData:keyData];
            [data appendData:objData];
        } else {
            *stop = YES;
        }
    }];
    
    return data;
}

+ (BOOL)isValidMessagePackObject:(id)obj
{
    return NO;
}

@end
