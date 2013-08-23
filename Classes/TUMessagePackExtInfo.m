//
//  TUMessagePackExtInfo.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/16/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "TUMessagePackExtInfo.h"

@implementation TUMessagePackExtInfo
{
    NSData *_data;
    uint8_t _type;
}

- (id)initWithMessagePackExtData:(NSData *)data type:(uint8_t)type
{
    self = [super init];
    if (self != nil) {
        _data = data;
        _type = type;
    }
    
    return self;
}

- (uint8_t)messagePackExtType
{
    return _type;
}

- (NSData *)messagePackExtData
{
    return _data;
}

@end
