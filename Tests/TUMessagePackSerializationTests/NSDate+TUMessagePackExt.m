//
//  NSDate+TUMessagePackExt.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/16/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "NSDate+TUMessagePackExt.h"

#import "TUMessagePackSerialization.h"


#define TUDateExtType 70


@implementation NSDate (TUMessagePackExt)

+ (void)load
{
    [TUMessagePackSerialization registerExtWithClass:self type:TUDateExtType];
}


#pragma mark - Ext Reading

- (id)initWithMessagePackExtData:(NSData *)data type:(uint8_t)type
{
    if (type != TUDateExtType || data.length < sizeof(NSTimeInterval)) {
        return nil;
    }
    
    NSTimeInterval timestamp = *(NSTimeInterval *)data.bytes;
    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}


#pragma mark - Ext Writing

- (uint8_t)messagePackExtType
{
    return TUDateExtType;
}

- (NSData *)messagePackExtData
{
    NSTimeInterval timestamp = self.timeIntervalSince1970;
    return [NSData dataWithBytes:&timestamp length:sizeof(timestamp)];
}

@end
