//
//  TNKMPDecoder.h
//  Pods
//
//  Created by David Beck on 1/27/15.
//
//

#import <Foundation/Foundation.h>

#import "TUMessagePackSerialization.h"


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

extern inline CFNumberRef TNKMPDecodeNumber(TUReadingInfo *readingInfo, CFNumberType type, NSUInteger length);
extern inline CFDataRef TNKMPDecodeData(TUReadingInfo *readingInfo, NSUInteger stringLength);
extern inline CFTypeRef TNKMPDecodeString(TUReadingInfo *readingInfo, NSUInteger stringLength);
extern inline CFTypeRef TNKMPDecodeExt(TUReadingInfo *readingInfo, NSUInteger length);

extern inline CFArrayRef TNKMPDecodeArray(TUReadingInfo *readingInfo, NSUInteger length);
extern inline CFDictionaryRef TNKMPDecodeMap(TUReadingInfo *readingInfo, NSUInteger length);

extern CFTypeRef TNKMPDecodeObject(TUReadingInfo *readingInfo);

