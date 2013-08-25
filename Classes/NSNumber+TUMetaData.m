//
//  NSNumber+TUMetaData.m
//  Pods
//
//  Created by David Beck on 8/22/13.
//
//

#import "NSNumber+TUMetaData.h"

@implementation NSNumber (TUMetaData)

- (BOOL)isFloat
{
    return CFNumberIsFloatType((__bridge CFNumberRef)(self));
}

- (BOOL)isSigned
{
    char *unsignedTypes[] = {
        @encode(unsigned char),
        @encode(unsigned short),
        @encode(unsigned int),
        @encode(unsigned long),
        @encode(unsigned long long)
    };
    
    for (uint8_t i = 0; i < 5; i++) {
        if (strcmp(unsignedTypes[i], self.objCType) == 0) {
            return NO;
        }
    }
    
    return YES;
}

@end
