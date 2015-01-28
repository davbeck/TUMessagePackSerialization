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
#import "TNKMPDecoder.h"


NSString *TUMessagePackErrorDomain = @"com.ThinkUltimate.MessagePack.Error";





@interface TUMessagePackSerialization ()
{
    @public
    TUReadingInfo _readingInfo;
    TUMessagePackWritingOptions _writingOptions;
    NSError *_error;
}

@end





@implementation TUMessagePackSerialization

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
    _readingInfo.options = opt;
    _readingInfo.bytes = data.bytes; // for whatever reason, this takes a good chunk of time, so we cache the result
    _readingInfo.position = 0;
    _readingInfo.length = data.length;
    
    id object = CFBridgingRelease(TNKMPDecodeObject(&_readingInfo));
    
    if (error != NULL && _readingInfo.error != NULL) {
        *error = CFBridgingRelease(_readingInfo.error);
    }
    
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
                    ReturnDataWithNumber(TUMessagePackInt32, CFSwapInt32HostToBig((int32_t)signedValue));
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
                    ReturnDataWithNumber(TUMessagePackUInt32, CFSwapInt32HostToBig((uint32_t)unsignedValue));
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
            uint32_t length = CFSwapInt32HostToBig((uint32_t)data.length);
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
            uint32_t length = CFSwapInt32HostToBig((uint32_t)array.count);
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
            uint32_t length = CFSwapInt32HostToBig((uint32_t)dictionary.count);
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
