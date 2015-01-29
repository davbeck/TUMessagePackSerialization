//
//  TUMessagePackSerialization.m
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import "TUMessagePackSerialization.h"

#import "TUMessagePackExtInfo.h"
#import "NSNumber+TUMetaData.h"
#import "TNKMPDecoder.h"
#import "TNKMPEncoder.h"


NSString *TUMessagePackErrorDomain = @"com.ThinkUltimate.MessagePack.Error";





@interface TUMessagePackSerialization ()
{
    TUMessagePackWritingOptions _options;
    NSError *_error;
    NSMutableData *_data;
}

@end





@implementation TUMessagePackSerialization

#pragma mark - Ext

+ (NSMutableDictionary *)_registeredExtClasses
{
    static NSMutableDictionary *registeredExtClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredExtClasses = [NSMutableDictionary new];
    });
    
    return registeredExtClasses;
}

+ (void)registerExtWithClass:(Class)extClass type:(uint8_t)type
{
    [self _registeredExtClasses][@(type)] = extClass;
}


#pragma mark - Reading

+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error
{
    TUReadingInfo readingInfo;
    readingInfo.options = opt;
    readingInfo.bytes = data.bytes; // for whatever reason, this takes a good chunk of time, so we cache the result
    readingInfo.position = 0;
    readingInfo.length = data.length;
    readingInfo.error = NULL;
    
    id object = CFBridgingRelease(TNKMPDecodeCreateObject(&readingInfo));
    
    if (error != NULL && readingInfo.error != NULL) {
        *error = CFBridgingRelease(readingInfo.error);
    }
    
    return object;
}


#pragma mark - Writing

+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error
{
    CFErrorRef coreError = NULL;
    
    NSData *data = CFBridgingRelease(TNKMPCreateDataByEncodingObject((__bridge CFTypeRef)(obj), &coreError));
    
    if (error != NULL) {
        *error = (__bridge NSError *)(coreError);
    }
    
    return data;
}

+ (BOOL)isValidMessagePackObject:(id)obj
{
    return [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSData class]] || [obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]] || [obj conformsToProtocol:@protocol(TUMessagePackExt)];
}

@end
