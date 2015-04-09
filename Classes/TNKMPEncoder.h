//
//  TNKMPEncoder.h
//  Pods
//
//  Created by David Beck on 1/28/15.
//
//

#import <Foundation/Foundation.h>

#import "TUMessagePackSerialization.h"


extern CFDataRef TNKMPCreateDataByEncodingObject(CFTypeRef object, TUMessagePackWritingOptions options, CFErrorRef *error);
