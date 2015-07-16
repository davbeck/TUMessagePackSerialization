//
//  TNKMPEncoder.m
//  Pods
//
//  Created by David Beck on 1/28/15.
//
//

#import "TNKMPEncoder.h"

#import "NSNumber+TUMetaData.h"


typedef struct {
    CFMutableDataRef data;
    TUMessagePackWritingOptions options;
    CFErrorRef error; // no objc objects in structs :/
} TNKMPEncodeInfo;

extern void TNKMPEncodeObject(TNKMPEncodeInfo *readingInfo, CFTypeRef object);
extern inline void TNKMPEncodeCode(TNKMPEncodeInfo *readingInfo, TUMessagePackCode code);
extern inline void TNKMPEncodeDataObjectAsString(TNKMPEncodeInfo *readingInfo, CFDataRef data);
extern inline void TNKMPEncodeData(TNKMPEncodeInfo *readingInfo, CFDataRef data);
extern inline void TNKMPEncodeString(TNKMPEncodeInfo *readingInfo, CFStringRef string);
extern inline void TNKMPEncodeArray(TNKMPEncodeInfo *readingInfo, CFArrayRef array);
extern inline void TNKMPEncodeMap(TNKMPEncodeInfo *readingInfo, CFDictionaryRef dictionary);


#define EncodeValue(codeValue, rawValue) do { \
TNKMPEncodeCode(readingInfo, codeValue); \
typeof(rawValue) value = rawValue; \
CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value)); \
} while(false);




CFDataRef TNKMPCreateDataByEncodingObject(CFTypeRef object, TUMessagePackWritingOptions options, CFErrorRef *error)
{
    TNKMPEncodeInfo encodeInfo;
    encodeInfo.data = CFDataCreateMutable(NULL, 0);
    encodeInfo.options = options;
    encodeInfo.error = NULL;
    
    TNKMPEncodeObject(&encodeInfo, object);
    
    if (error != NULL && encodeInfo.error != NULL) {
        *error = (CFErrorRef)CFAutorelease(encodeInfo.error);
    }
    
    return encodeInfo.data;
}

void TNKMPEncodeObject(TNKMPEncodeInfo *readingInfo, CFTypeRef object)
{
    CFTypeID type = CFGetTypeID(object);
    
    if (object == kCFBooleanTrue) {
        uint8_t value = TUMessagePackTrue;
        CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
    } else if (object == kCFBooleanFalse) {
        uint8_t value = TUMessagePackFalse;
        CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
    } else if (type == CFNumberGetTypeID()) {
        if (object == kCFBooleanTrue) {
            uint8_t value = TUMessagePackTrue;
            CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
        } else if (object == kCFBooleanFalse) {
            uint8_t value = TUMessagePackFalse;
            CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
        } else if (CFNumberIsFloatType(object)) {
            if (CFNumberGetByteSize(object) == 8) {
                double number = 0.0;
                CFNumberGetValue(object, kCFNumberFloat64Type, &number);
                EncodeValue(TUMessagePackDouble, CFConvertFloat64HostToSwapped(number));
            } else {
                float number = 0.0;
                CFNumberGetValue(object, kCFNumberFloat32Type, &number);
                EncodeValue(TUMessagePackDouble, CFConvertFloat32HostToSwapped(number));
            }
        } else {
            int64_t signedValue = 0;
            CFNumberGetValue(object, kCFNumberSInt64Type, &signedValue);
            // note that CFNumber doesn't actually support unsingend numbers, so large unsigned 64bit ints may overflow
            
            if (signedValue < 0) {
                if (signedValue > -pow(2, 5)) {
                    int8_t value = signedValue;
                    CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
                } else if (signedValue > -pow(2, 1 * 8 - 1)) {
                    EncodeValue(TUMessagePackInt8, (int8_t)signedValue);
                } else if (signedValue > -pow(2, 2 * 8 - 1)) {
                    EncodeValue(TUMessagePackInt16, CFSwapInt16HostToBig(signedValue));
                } else if (signedValue > -pow(2, 4 * 8 - 1)) {
                    EncodeValue(TUMessagePackInt32, CFSwapInt32HostToBig((int32_t)signedValue));
                } else if (signedValue > -pow(2, 8 * 8 - 1)) {
                    EncodeValue(TUMessagePackInt64, CFSwapInt64HostToBig(signedValue));
                } else if (readingInfo->error == nil) {
                    readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
                }
            } else {
                if (signedValue < pow(2, 7)) {
                    uint8_t value = signedValue;
                    CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
                } else if (signedValue < pow(2, 1 * 8)) {
                    EncodeValue(TUMessagePackUInt8, (uint8_t)signedValue);
                } else if (signedValue < pow(2, 2 * 8)) {
                    EncodeValue(TUMessagePackUInt16, CFSwapInt16HostToBig(signedValue));
                } else if (signedValue < pow(2, 4 * 8)) {
                    EncodeValue(TUMessagePackUInt32, CFSwapInt32HostToBig((uint32_t)signedValue));
                } else if (signedValue < pow(2, 8 * 8)) {
                    EncodeValue(TUMessagePackUInt64, CFSwapInt64HostToBig(signedValue));
                } else if (readingInfo->error == nil) {
                    readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
                }
            }
        }
    } else if (object == kCFNull || object == nil) {
        uint8_t value = TUMessagePackNil;
        CFDataAppendBytes(readingInfo->data, (UInt8 *)&value, sizeof(value));
    } else if (type == CFStringGetTypeID()) {
        // if the CFString is currently storing the string using UTF8, this will be MUCH faster, but will return NULL if it isn't
        const char *cString = CFStringGetCStringPtr(object, kCFStringEncodingUTF8);
        
        if (cString != NULL) {
            size_t length = strlen(cString);
            
            if (length < 32) {
                TNKMPEncodeCode(readingInfo, TUMessagePackFixstr | length);
            } else if (length < pow(2, 1 * 8) && !(readingInfo->options & TUMessagePackWritingCompatabilityMode)) {
                EncodeValue(TUMessagePackStr8, (uint8_t)length);
            } else if (length < pow(2, 2 * 8)) {
                EncodeValue(TUMessagePackStr16, CFSwapInt16HostToBig(length));
            } else if (length < pow(2, 4 * 8)) {
                EncodeValue(TUMessagePackStr32, CFSwapInt32HostToBig((uint32_t)length));
            } else if (readingInfo->error == nil) {
                readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
            }
            
            CFIndex position = CFDataGetLength(readingInfo->data);
            
            CFDataIncreaseLength(readingInfo->data, length);
            UInt8 *bytes = CFDataGetMutableBytePtr(readingInfo->data) + position;
            
            memcpy(bytes, cString, length);
        } else {
            CFDataRef data = CFStringCreateExternalRepresentation(NULL, object, kCFStringEncodingUTF8, 0);
            TNKMPEncodeDataObjectAsString(readingInfo, data);
            CFRelease(data);
        }
    } else if (type == CFDataGetTypeID()) {
        if (readingInfo->options & TUMessagePackWritingCompatabilityMode) {
            // encode the data as string, because old MessagePack doesn't know the difference
            TNKMPEncodeDataObjectAsString(readingInfo, object);
        } else {
            CFIndex dataLength = CFDataGetLength(object);
            
            if (dataLength < pow(2, 1 * 8)) {
                EncodeValue(TUMessagePackBin8, (uint8_t)dataLength);
            } else if (dataLength < pow(2, 2 * 8)) {
                EncodeValue(TUMessagePackBin16, CFSwapInt16HostToBig(dataLength));
            } else if (dataLength < pow(2, 4 * 8)) {
                EncodeValue(TUMessagePackBin32, CFSwapInt32HostToBig((uint32_t)dataLength));
            } else if (readingInfo->error == nil) {
                readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
            }
            
            TNKMPEncodeData(readingInfo, object);
        }
    } else if (type == CFArrayGetTypeID()) {
        CFIndex arrayLength = CFArrayGetCount(object);
        
        if (arrayLength < 16) {
            TNKMPEncodeCode(readingInfo, TUMessagePackFixarray | (uint8_t)arrayLength);
        } else if (arrayLength < pow(2, 2 * 8)) {
            EncodeValue(TUMessagePackArray16, CFSwapInt16HostToBig(arrayLength));
        } else if (arrayLength < pow(2, 4 * 8)) {
            EncodeValue(TUMessagePackArray32, CFSwapInt32HostToBig((uint32_t)arrayLength));
        } else if (readingInfo->error == nil) {
            readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
        }
        
        TNKMPEncodeArray(readingInfo, object);
    } else if (type == CFDictionaryGetTypeID()) {
        CFIndex mapLength = CFDictionaryGetCount(object);
        
        if (mapLength < 16) {
            TNKMPEncodeCode(readingInfo, TUMessagePackFixmap | (uint8_t)mapLength);
        } else if (mapLength < pow(2, 2 * 8)) {
            EncodeValue(TUMessagePackMap16, CFSwapInt16HostToBig(mapLength));
        } else if (mapLength < pow(2, 4 * 8)) {
            EncodeValue(TUMessagePackMap32, CFSwapInt32HostToBig((uint32_t)mapLength));
        } else if (readingInfo->error == nil) {
            readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
        }
        
        TNKMPEncodeMap(readingInfo, object);
    } else if (readingInfo->error == nil) {
        readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackNoMatchingFormatCode, NULL);
    }
}

inline void TNKMPEncodeCode(TNKMPEncodeInfo *readingInfo, TUMessagePackCode code)
{
    CFDataAppendBytes(readingInfo->data, &code, sizeof(code));
}

inline void TNKMPEncodeDataObjectAsString(TNKMPEncodeInfo *readingInfo, CFDataRef data)
{
    CFIndex length = CFDataGetLength(data);
    
    if (length < 32) {
        TNKMPEncodeCode(readingInfo, TUMessagePackFixstr | length);
    } else if (length < pow(2, 1 * 8) && !(readingInfo->options & TUMessagePackWritingCompatabilityMode)) {
        EncodeValue(TUMessagePackStr8, (uint8_t)length);
    } else if (length < pow(2, 2 * 8)) {
        EncodeValue(TUMessagePackStr16, CFSwapInt16HostToBig(length));
    } else if (length < pow(2, 4 * 8)) {
        EncodeValue(TUMessagePackStr32, CFSwapInt32HostToBig((uint32_t)length));
    } else if (readingInfo->error == nil) {
        readingInfo->error = CFErrorCreate(NULL, (CFStringRef)TUMessagePackErrorDomain, TUMessagePackObjectTooBig, NULL);
    }
    
    TNKMPEncodeData(readingInfo, data);
}

inline void TNKMPEncodeData(TNKMPEncodeInfo *readingInfo, CFDataRef data)
{
    CFDataAppendBytes(readingInfo->data, CFDataGetBytePtr(data), CFDataGetLength(data));
}

inline void TNKMPEncodeString(TNKMPEncodeInfo *readingInfo, CFStringRef string)
{
    CFIndex position = CFDataGetLength(readingInfo->data);
    CFIndex length = CFStringGetLength(string);
    
    CFDataIncreaseLength(readingInfo->data, length);
    UInt8 *bytes = CFDataGetMutableBytePtr(readingInfo->data) + position;
    
    CFStringGetBytes(string, CFRangeMake(0, length), kCFStringEncodingUTF8, 0, false, bytes, length, NULL);
}

void TNKMPEncodeObjectFromArray(const void *object, void *readingInfo)
{
    TNKMPEncodeObject(readingInfo, object);
}

inline void TNKMPEncodeArray(TNKMPEncodeInfo *readingInfo, CFArrayRef array)
{
    CFArrayApplyFunction(array, CFRangeMake(0, CFArrayGetCount(array)), &TNKMPEncodeObjectFromArray, readingInfo);
}

void TNKMPEncodeKeyAndObjectFromDictionary(const void *key, const void *object, void *readingInfo)
{
    TNKMPEncodeObject(readingInfo, key);
    TNKMPEncodeObject(readingInfo, object);
}

inline void TNKMPEncodeMap(TNKMPEncodeInfo *readingInfo, CFDictionaryRef dictionary)
{
    CFDictionaryApplyFunction(dictionary, &TNKMPEncodeKeyAndObjectFromDictionary, readingInfo);
}
