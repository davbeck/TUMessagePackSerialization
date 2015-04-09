//
//  TNKMPDecoder.h
//  Pods
//
//  Created by David Beck on 1/27/15.
//
//

#import <Foundation/Foundation.h>

#import "TUMessagePackSerialization.h"


extern CFTypeRef TNKMPCreateObjectByDecodingData(CFDataRef data, TUMessagePackReadingOptions options, CFErrorRef *error);

