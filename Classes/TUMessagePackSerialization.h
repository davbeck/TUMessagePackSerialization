//
//  TUMessagePackSerialization.h
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TUMessagePackExt.h"


typedef enum : NSUInteger {
	TUMessagePackReadingMutableContainers = (1UL << 0),
	TUMessagePackReadingMutableLeaves = (1UL << 1),
	TUMessagePackReadingAllowFragments = (1UL << 2),
	TUMessagePackReadingStringsAsData = (1UL << 3),
	TUMessagePackReadingNSNullAsNil = (1UL << 4),
    TUMessagePackReadingLenient = (1UL << 5),
    
    // proposed
    // TUMessagePackReadingLenient
    // If we run out of data for an array or dictionary, return as much valid data as possible
} TUMessagePackReadingOptions;

typedef enum : NSUInteger {
    TUMessagePackWritingCompatabilityMode = (1UL << 0),
} TUMessagePackWritingOptions;


extern NSString *TUMessagePackErrorDomain;
typedef enum : NSInteger {
	TUMessagePackNoMatchingFormatCode,
    TUMessagePackNotEnoughData,
} TUMessagePackErrorCode;


/** You use the TUMessagePackSerialization class to convert [MessagePack](http://msgpack.org) to Foundation objects and convert Foundation objects to MessagePack.
 
 An object that may be converted to MessagePack must have the following properties:
 
 - All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull, or conform to the TUMessagePackExt protocol and register the class with +registerExtWithClass:type:.
 - Numbers are not NaN or infinity.
 
 While MessagePack does not place *any* limitation on dictionary/map keys, some libraries and languages may not be able to interpret all types.
 This class can use an of the buit in types as a key, but may not be able to use ext objects if they do not conform to the NSCopying protocol.
 
 It is the goal of this class to never throw an exception, and to always return an error when there is an issue.
 However, there is at least 1 case where +messagePackObjectWithData:options:error: will return nil, but not an error.
 That is when data contains a single, null object and TUMessagePackReadingNSNullAsNil is set.
 For this reason, you should check if error is nil, and not the returned value.
 */

@interface TUMessagePackSerialization : NSObject

/**---------------------------------------------------------------------------------------
 * @name Creating a MessagePack Object
 *  ---------------------------------------------------------------------------------------
 */

/** Returns a Foundation object from given MessagePack data.
 
 This method will do it's best to either return a valid object, or an error. It is the intent of this method to never throw an exception.
 
 Always check error for nil, rather than result, as valid MessagePack data could return nil.
 
 @param data A data object containing MessagePack data.
 @param opt Options for reading the MessagePack data and creating the Foundation objects. For possible values, see “TUMessagePackReadingOptions.” Pass `0` for no options.
 @param error If an error occurs, upon return contains an NSError object that describes the problem with a corresponding TUMessagePackErrorCode.
 @return A Foundation object from the MessagePack data in data, or nil if an error occurs.
 */
+ (id)messagePackObjectWithData:(NSData *)data options:(TUMessagePackReadingOptions)opt error:(NSError **)error;

/** Registers a class that can be created from MessagePack ext data.
 
 This method is only needed for reading MessagePack data as the object will be provided when writing. If a class is registered with this method, when the corresponding ext code is found, the data will be used to create an object of the given class.
 
 @param extClass A class that can be created from MessagePack ext data. Instances of the class should adopt the TUMessagePackExt protocol.
 @param type The ext type code that the class understands.
 */
+ (void)registerExtWithClass:(Class)extClass type:(uint8_t)type;


/**---------------------------------------------------------------------------------------
 * @name Creating MessagePack Data
 *  ---------------------------------------------------------------------------------------
 */

/** Returns MessagePack data from a Foundation object.
 
 This method will do it's best to either return a valid object, or an error. It is the intent of this method to never throw an exception.
 
 If an error does not occur, the returned value will not be nil. If obj is nil, the returned data will be an NSData object with a length of 0.
 
 @param obj A data object containing MessagePack data.
 @param opt Options for writing the MessagePack objects. For possible values, see “TUMessagePackWritingOptions.” Pass `0` for no options.
 @param error If an error occurs, upon return contains an NSError object that describes the problem with a corresponding TUMessagePackErrorCode.
 @return MessagePack data for obj, or nil if an error occurs.
 */
+ (NSData *)dataWithMessagePackObject:(id)obj options:(TUMessagePackWritingOptions)opt error:(NSError **)error;

/** Checks the given foundation object to determine if it can be written to MessagePack.
 
 While this method is quicker than calling +dataWithMessagePackObject:options:error:, it is safe to call that method without knowing if the object is valid.
 For this reason, if you are going to write the object to data anyway, you should just call that method and handle the error if it ocurs.
 
 @param obj A data object containing MessagePack data. This value should be the same as that passed to dataWithMessagePackObject:options:error:.
 @return YES if obj can be converted to MessagePack data, otherwise NO.
 */
+ (BOOL)isValidMessagePackObject:(id)obj;

@end
