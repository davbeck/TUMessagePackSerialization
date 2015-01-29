//
//  TNKMPEncoder.h
//  Pods
//
//  Created by David Beck on 1/28/15.
//
//

#import <Foundation/Foundation.h>

#import "TUMessagePackSerialization.h"


typedef struct {
    CFMutableDataRef data;
    TUMessagePackWritingOptions options;
    CFErrorRef error; // no objc objects in structs :/
} TNKMPEncodeInfo;

extern CFDataRef TNKMPCreateDataByEncodingObject(CFTypeRef object, CFErrorRef *error);
