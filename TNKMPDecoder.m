//
//  TNKMPDecoder.m
//  Pods
//
//  Created by David Beck on 1/27/15.
//
//

#import "TNKMPDecoder.h"

#import "TUMessagePackSerialization_Private.h"
#import "TUMessagePackExtInfo.h"


inline id TNKMPDecodeObject(TUReadingInfo *readingInfo)
{
    id object = nil;
    
    TUMessagePackCode code = TNKMPDecodeUInt8(readingInfo);//[self _popInt8];
    
    switch (code) {
        case TUMessagePackUInt8: {
            object = [[NSNumber alloc] initWithUnsignedChar:TNKMPDecodeUInt8(readingInfo)];
            break;
        } case TUMessagePackUInt16: {
            uint16_t number = TNKMPDecodeUInt16(readingInfo);
            object = [[NSNumber alloc] initWithUnsignedShort:number];
            break;
        } case TUMessagePackUInt32: {
            object = [[NSNumber alloc] initWithUnsignedLong:TNKMPDecodeUInt32(readingInfo)];
            break;
        } case TUMessagePackUInt64: {
            object = [[NSNumber alloc] initWithUnsignedLongLong:TNKMPDecodeUInt64(readingInfo)];
            break;
        }
            
        case TUMessagePackInt8: {
            object = [[NSNumber alloc] initWithChar:(int8_t)TNKMPDecodeUInt8(readingInfo)];
            break;
        } case TUMessagePackInt16: {
            object = [[NSNumber alloc] initWithShort:(int16_t)TNKMPDecodeUInt16(readingInfo)];
            break;
        } case TUMessagePackInt32: {
            object = [[NSNumber alloc] initWithLong:(int32_t)TNKMPDecodeUInt32(readingInfo)];
            break;
        } case TUMessagePackInt64: {
            object = [[NSNumber alloc] initWithLongLong:(int64_t)TNKMPDecodeUInt64(readingInfo)];
            break;
        }
            
        case TUMessagePackFloat: {
            object = [[NSNumber alloc] initWithFloat:TNKMPDecodeFloat32(readingInfo)];
            break;
        } case TUMessagePackDouble: {
            object = [[NSNumber alloc] initWithDouble:TNKMPDecodeFloat64(readingInfo)];
            break;
        }
            
        case TUMessagePackNil: {
            if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) == TUMessagePackReadingNSNullAsNil) {
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
            object = TNKMPDecodeString(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackStr16: {
            object = TNKMPDecodeString(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackStr32: {
            object = TNKMPDecodeString(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackBin8: {
            object = TNKMPDecodeData(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackBin16: {
            object = TNKMPDecodeData(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackBin32: {
            object = TNKMPDecodeData(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackArray16: {
            object = TNKMPDecodeArray(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackArray32: {
            object = TNKMPDecodeArray(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackMap16: {
            object = TNKMPDecodeMap(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackMap32: {
            object = TNKMPDecodeMap(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackFixext1: {
            object = TNKMPDecodeExt(readingInfo, 1);
            break;
        } case TUMessagePackFixext2: {
            object = TNKMPDecodeExt(readingInfo, 2);
            break;
        } case TUMessagePackFixext4: {
            object = TNKMPDecodeExt(readingInfo, 4);
            break;
        } case TUMessagePackFixext8: {
            object = TNKMPDecodeExt(readingInfo, 8);
            break;
        } case TUMessagePackFixext16: {
            object = TNKMPDecodeExt(readingInfo, 16);
            break;
        } case TUMessagePackExt8: {
            object = TNKMPDecodeExt(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackExt16: {
            object = TNKMPDecodeExt(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackExt32: {
            object = TNKMPDecodeExt(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        default: {
            if (!(code & 0b10000000)) {
                object = [[NSNumber alloc] initWithUnsignedChar:code];
            } else if ((code & 0b11100000) == TUMessagePackNegativeFixint) {
                object = [[NSNumber alloc] initWithChar:code];
            } else if ((code & 0b11100000) == TUMessagePackFixstr) {
                uint8_t length = code & ~0b11100000;
                object = TNKMPDecodeString(readingInfo, length);
            } else if ((code & 0b11110000) == TUMessagePackFixarray) {
                uint8_t length = code & ~0b11110000;
                object = TNKMPDecodeArray(readingInfo, length);
            } else  if ((code & 0b11110000) == TUMessagePackFixmap) {
                uint8_t length = code & ~0b11110000;
                object = TNKMPDecodeMap(readingInfo, length);
            } else if (readingInfo->error == NULL) {
                readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNoMatchingFormatCode, nil);
            }
            
            break;
        }
    }
    
    return object;
}

inline uint8_t TNKMPDecodeVariable(TUReadingInfo *readingInfo, void *variable, NSUInteger length)
{
    if (readingInfo->position + length <= readingInfo->length) {
        memcpy(variable, readingInfo->bytes + readingInfo->position, length);
        readingInfo->position += length;
        
        return YES;
    } else if (readingInfo->error == NULL) {
        readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNotEnoughData, nil);
    }
    
    return NO;
}

inline uint8_t TNKMPDecodeUInt8(TUReadingInfo *readingInfo)
{
    uint8_t number = 0;
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return number;
}

inline uint16_t TNKMPDecodeUInt16(TUReadingInfo *readingInfo)
{
    uint16_t number = 0;
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return CFSwapInt16BigToHost(number);
}

inline uint32_t TNKMPDecodeUInt32(TUReadingInfo *readingInfo)
{
    uint32_t number = 0;
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return CFSwapInt32BigToHost(number);
}

inline uint64_t TNKMPDecodeUInt64(TUReadingInfo *readingInfo)
{
    uint64_t number = 0;
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return CFSwapInt64BigToHost(number);
}

inline float TNKMPDecodeFloat32(TUReadingInfo *readingInfo)
{
    CFSwappedFloat32 number = {0};
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return CFConvertFloatSwappedToHost(number);
}

inline double TNKMPDecodeFloat64(TUReadingInfo *readingInfo)
{
    CFSwappedFloat64 number = {0};
    TNKMPDecodeVariable(readingInfo, &number, sizeof(number));
    return CFConvertDoubleSwappedToHost(number);
}

inline NSData *TNKMPDecodeData(TUReadingInfo *readingInfo, NSUInteger length)
{
    if (readingInfo->position + length <= readingInfo->length) {
        NSData *data = nil;
        
        if ((readingInfo->options & TUMessagePackReadingMutableLeaves) != TUMessagePackReadingMutableLeaves) {
            data = [[NSData alloc] initWithBytes:readingInfo->bytes + readingInfo->position length:length];
        } else {
            data = [[NSMutableData alloc] initWithBytes:readingInfo->bytes + readingInfo->position length:length];
        }
        
        readingInfo->position += length;
        return data;
    } else if (readingInfo->error == NULL) {
        readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNotEnoughData, nil);
    }
    
    return nil;
}

inline id TNKMPDecodeString(TUReadingInfo *readingInfo, NSUInteger stringLength)
{
    if ((readingInfo->options & TUMessagePackReadingStringsAsData) != TUMessagePackReadingStringsAsData) {
        if (readingInfo->position + stringLength <= readingInfo->length) {
            NSString *string = nil;
            
            if ((readingInfo->options & TUMessagePackReadingMutableLeaves) != TUMessagePackReadingMutableLeaves) {
                string = [[NSString alloc] initWithBytes:readingInfo->bytes + readingInfo->position length:stringLength encoding:NSUTF8StringEncoding];
            } else {
                string = [[NSMutableString alloc] initWithBytes:readingInfo->bytes + readingInfo->position length:stringLength encoding:NSUTF8StringEncoding];
            }
            
            readingInfo->position += stringLength;
            return string;
        } else if (readingInfo->error == NULL) {
            readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNotEnoughData, nil);
        }
    } else {
        return TNKMPDecodeData(readingInfo, stringLength);
    }
    
    return nil;
}

inline id TNKMPDecodeExt(TUReadingInfo *readingInfo, NSUInteger length)
{
    id object = nil;
    
    uint8_t type = TNKMPDecodeUInt8(readingInfo);
    NSData *extData = TNKMPDecodeData(readingInfo, length);
    
    Class extClass = [TUMessagePackSerialization _registeredExtClasses][@(type)];
    if (extClass == nil) {
        extClass = [TUMessagePackExtInfo class];
    }
    
    object = [[extClass alloc] initWithMessagePackExtData:extData type:type];
    
    return object;
}

inline NSArray *TNKMPDecodeArray(TUReadingInfo *readingInfo, NSUInteger length)
{
    id objects[length];
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        id object = TNKMPDecodeObject(readingInfo);
        
        if (object != nil) {
            objects[count] = object;
            count++;
        } else if (readingInfo->error == NULL) {
            if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) != TUMessagePackReadingNSNullAsNil) {
                objects[count] = [NSNull null];
                count++;
            }
        } else {
            return nil;
        }
    }
    
    return [[NSArray alloc] initWithObjects:objects count:count];
}

inline id TNKMPDecodeMap(TUReadingInfo *readingInfo, NSUInteger length)
{
    id __strong keys[length];
    id __strong objects[length];
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        id key = TNKMPDecodeObject(readingInfo);
        id object = TNKMPDecodeObject(readingInfo);
        
        if (key != nil) {
            if (object != nil) {
                keys[count] = key;
                objects[count] = object;
                count++;
            } else if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) != TUMessagePackReadingNSNullAsNil) {
                keys[count] = key;
                objects[count] = [NSNull null];
                count++;
            }
        }
        
        if (readingInfo->error != NULL) {
            return nil;
        }
    }
    
    return [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:count];
}
