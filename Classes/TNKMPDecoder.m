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


typedef struct {
    const void *bytes;
    NSUInteger position;
    NSUInteger length;
    TUMessagePackReadingOptions options;
    CFErrorRef error; // no objc objects in structs :/
} TUReadingInfo;


extern inline uint8_t TNKMPDecodeVariable(TUReadingInfo *readingInfo, void *variable, NSUInteger length);

extern inline uint8_t TNKMPDecodeUInt8(TUReadingInfo *readingInfo);
extern inline uint16_t TNKMPDecodeUInt16(TUReadingInfo *readingInfo);
extern inline uint32_t TNKMPDecodeUInt32(TUReadingInfo *readingInfo);
extern inline uint64_t TNKMPDecodeUInt64(TUReadingInfo *readingInfo);

extern inline float TNKMPDecodeFloat32(TUReadingInfo *readingInfo);
extern inline double TNKMPDecodeFloat64(TUReadingInfo *readingInfo);

extern inline CFDataRef TNKMPDecodeCreateData(TUReadingInfo *readingInfo, NSUInteger stringLength);
extern inline CFTypeRef TNKMPDecodeCreateString(TUReadingInfo *readingInfo, NSUInteger stringLength);
extern inline CFTypeRef TNKMPDecodeCreateExt(TUReadingInfo *readingInfo, NSUInteger length);

extern inline CFArrayRef TNKMPDecodeCreateArray(TUReadingInfo *readingInfo, NSUInteger length);
extern inline CFDictionaryRef TNKMPDecodeCreateMap(TUReadingInfo *readingInfo, NSUInteger length);

extern CFTypeRef TNKMPDecodeCreateObject(TUReadingInfo *readingInfo);



extern CFTypeRef TNKMPCreateObjectByDecodingData(CFDataRef data, TUMessagePackReadingOptions options, CFErrorRef *error)
{
    TUReadingInfo readingInfo;
    readingInfo.options = options;
    readingInfo.bytes = CFDataGetBytePtr(data); // for whatever reason, this takes a good chunk of time, so we cache the result
    readingInfo.position = 0;
    readingInfo.length = CFDataGetLength(data);
    readingInfo.error = NULL;
    
    CFTypeRef object = TNKMPDecodeCreateObject(&readingInfo);
    
    if (error != NULL && readingInfo.error != NULL) {
        *error = (CFErrorRef)CFAutorelease(readingInfo.error);
    }
    
    return object;
}

CFTypeRef TNKMPDecodeCreateObject(TUReadingInfo *readingInfo)
{
    TUMessagePackCode code = TNKMPDecodeUInt8(readingInfo);//[self _popInt8];
    
    switch (code) {
        // CFNumber doesn't support unsigned integers so we have to use the next biggest size
        case TUMessagePackUInt8: {
            int16_t number = TNKMPDecodeUInt8(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt16Type, &number);
        } case TUMessagePackUInt16: {
            int32_t number = TNKMPDecodeUInt16(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt32Type, &number);
        } case TUMessagePackUInt32: {
            int64_t number = TNKMPDecodeUInt32(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt64Type, &number);
        } case TUMessagePackUInt64: {
            int64_t number = TNKMPDecodeUInt64(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt64Type, &number);
        }
            
        case TUMessagePackInt8: {
            int8_t number = TNKMPDecodeUInt8(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt8Type, &number);
        } case TUMessagePackInt16: {
            int16_t number = TNKMPDecodeUInt16(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt16Type, &number);
            break;
        } case TUMessagePackInt32: {
            int32_t number = TNKMPDecodeUInt32(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt32Type, &number);
            break;
        } case TUMessagePackInt64: {
            int64_t number = TNKMPDecodeUInt64(readingInfo);
            return CFNumberCreate(NULL, kCFNumberSInt64Type, &number);
            break;
        }
            
        case TUMessagePackFloat: {
            float number = TNKMPDecodeFloat32(readingInfo);
            return CFNumberCreate(NULL, kCFNumberFloat32Type, &number);
            break;
        } case TUMessagePackDouble: {
            double number = TNKMPDecodeFloat64(readingInfo);
            return CFNumberCreate(NULL, kCFNumberFloat64Type, &number);
            break;
        }
            
        case TUMessagePackNil: {
            if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) == TUMessagePackReadingNSNullAsNil) {
                return nil;
            } else {
                return kCFNull;
            }
            break;
        }
            
        case TUMessagePackTrue: {
            return kCFBooleanTrue;
            break;
        } case TUMessagePackFalse: {
            return kCFBooleanFalse;
            break;
        }
            
        case TUMessagePackStr8: {
            return TNKMPDecodeCreateString(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackStr16: {
            return TNKMPDecodeCreateString(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackStr32: {
            return TNKMPDecodeCreateString(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackBin8: {
            return TNKMPDecodeCreateData(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackBin16: {
            return TNKMPDecodeCreateData(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackBin32: {
            return TNKMPDecodeCreateData(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackArray16: {
            return TNKMPDecodeCreateArray(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackArray32: {
            return TNKMPDecodeCreateArray(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackMap16: {
            return TNKMPDecodeCreateMap(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackMap32: {
            return TNKMPDecodeCreateMap(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        case TUMessagePackFixext1: {
            return TNKMPDecodeCreateExt(readingInfo, 1);
            break;
        } case TUMessagePackFixext2: {
            return TNKMPDecodeCreateExt(readingInfo, 2);
            break;
        } case TUMessagePackFixext4: {
            return TNKMPDecodeCreateExt(readingInfo, 4);
            break;
        } case TUMessagePackFixext8: {
            return TNKMPDecodeCreateExt(readingInfo, 8);
            break;
        } case TUMessagePackFixext16: {
            return TNKMPDecodeCreateExt(readingInfo, 16);
            break;
        } case TUMessagePackExt8: {
            return TNKMPDecodeCreateExt(readingInfo, TNKMPDecodeUInt8(readingInfo));
            break;
        } case TUMessagePackExt16: {
            return TNKMPDecodeCreateExt(readingInfo, TNKMPDecodeUInt16(readingInfo));
            break;
        } case TUMessagePackExt32: {
            return TNKMPDecodeCreateExt(readingInfo, TNKMPDecodeUInt32(readingInfo));
            break;
        }
            
        default: {
            if (!(code & 0b10000000)) {
                int16_t number = code;
                return CFNumberCreate(NULL, kCFNumberSInt16Type, &number);
            } else if ((code & 0b11100000) == TUMessagePackNegativeFixint) {
                return CFNumberCreate(NULL, kCFNumberSInt8Type, &code);
            } else if ((code & 0b11100000) == TUMessagePackFixstr) {
                uint8_t length = code & ~0b11100000;
                return TNKMPDecodeCreateString(readingInfo, length);
            } else if ((code & 0b11110000) == TUMessagePackFixarray) {
                uint8_t length = code & ~0b11110000;
                return TNKMPDecodeCreateArray(readingInfo, length);
            } else  if ((code & 0b11110000) == TUMessagePackFixmap) {
                uint8_t length = code & ~0b11110000;
                return TNKMPDecodeCreateMap(readingInfo, length);
            } else if (readingInfo->error == NULL) {
                readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNoMatchingFormatCode, nil);
            }
        }
    }
    
    return NULL;
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

inline CFDataRef TNKMPDecodeCreateData(TUReadingInfo *readingInfo, NSUInteger length)
{
    if (readingInfo->position + length <= readingInfo->length) {
        CFDataRef data = nil;
        
        if ((readingInfo->options & TUMessagePackReadingMutableLeaves) != TUMessagePackReadingMutableLeaves) {
            data = CFDataCreate(NULL, readingInfo->bytes + readingInfo->position, length);
        } else {
            CFMutableDataRef mutableData = CFDataCreateMutable(NULL, length);
            CFDataAppendBytes(mutableData, readingInfo->bytes + readingInfo->position, length);
            data = mutableData;
        }
        
        readingInfo->position += length;
        return data;
    } else if (readingInfo->error == NULL) {
        readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNotEnoughData, nil);
    }
    
    return nil;
}

inline CFTypeRef TNKMPDecodeCreateString(TUReadingInfo *readingInfo, NSUInteger stringLength)
{
    if ((readingInfo->options & TUMessagePackReadingStringsAsData) != TUMessagePackReadingStringsAsData) {
        if (readingInfo->position + stringLength <= readingInfo->length) {
            CFStringRef string = nil;
            
            string = CFStringCreateWithBytes(NULL, readingInfo->bytes + readingInfo->position, stringLength, kCFStringEncodingUTF8, false);
            if ((readingInfo->options & TUMessagePackReadingMutableLeaves) == TUMessagePackReadingMutableLeaves) {
                CFStringRef oldString = string;
                string = CFStringCreateMutableCopy(NULL, 0, oldString);
                CFRelease(oldString);
            }
            
            readingInfo->position += stringLength;
            return string;
        } else if (readingInfo->error == NULL) {
            readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNotEnoughData, nil);
        }
    } else {
        return TNKMPDecodeCreateData(readingInfo, stringLength);
    }
    
    return nil;
}

inline CFTypeRef TNKMPDecodeCreateExt(TUReadingInfo *readingInfo, NSUInteger length)
{
    uint8_t type = TNKMPDecodeUInt8(readingInfo);
    CFDataRef extData = TNKMPDecodeCreateData(readingInfo, length);
    
    Class extClass = [TUMessagePackSerialization _registeredExtClasses][@(type)];
    if (extClass == nil) {
        extClass = [TUMessagePackExtInfo class];
    }
    
    return CFBridgingRetain([[extClass alloc] initWithMessagePackExtData:CFBridgingRelease(extData) type:type]);
}

inline CFArrayRef TNKMPDecodeCreateArray(TUReadingInfo *readingInfo, NSUInteger length)
{
    CFTypeRef objects[length];
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        CFTypeRef object = TNKMPDecodeCreateObject(readingInfo);
        
        if (object != nil) {
            objects[count] = object;
            count++;
        } else if (readingInfo->error == NULL) {
            if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) != TUMessagePackReadingNSNullAsNil) {
                objects[count] = kCFNull;
                count++;
            }
        } else {
            return nil;
        }
    }
    
    CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
    callbacks.retain = NULL;// these are already +1 retain count
    
    return CFArrayCreate(NULL, objects, count, &callbacks);
}

inline CFDictionaryRef TNKMPDecodeCreateMap(TUReadingInfo *readingInfo, NSUInteger length)
{
    CFTypeRef keys[length];
    CFTypeRef objects[length];
    
    NSUInteger count = 0;
    for (NSUInteger index = 0; index < length; index++) {
        CFTypeRef key = TNKMPDecodeCreateObject(readingInfo);
        CFTypeRef object = TNKMPDecodeCreateObject(readingInfo);
        
        if (key != nil) {
            if (object != nil) {
                keys[count] = key;
                objects[count] = object;
                count++;
            } else if ((readingInfo->options & TUMessagePackReadingNSNullAsNil) != TUMessagePackReadingNSNullAsNil) {
                keys[count] = key;
                objects[count] = kCFNull;
                count++;
            }
        }
        
        if (readingInfo->error != NULL) {
            break;
        }
    }
    
    CFDictionaryKeyCallBacks keysCallback = kCFTypeDictionaryKeyCallBacks;
    keysCallback.retain = NULL;// these are already +1 retain count
    
    CFDictionaryValueCallBacks valuesCallback = kCFTypeDictionaryValueCallBacks;
    valuesCallback.retain = NULL;// these are already +1 retain count
    
    return CFDictionaryCreate(NULL, keys, objects, count, &keysCallback, &valuesCallback);
}
