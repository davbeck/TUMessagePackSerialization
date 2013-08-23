//
//  TUMessagePackExt.h
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/16/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TUMessagePackExt <NSObject>
@required

/**---------------------------------------------------------------------------------------
 * @name Creating a MessagePack Object From Ext Data
 *  ---------------------------------------------------------------------------------------
 */

/** Returns an object from the given MessagePack data
 
 If a class is registered with a given type, and that type is encountered while reading MessagePack data, this method will be called to convert the data to MessagePack data.
 
 @param data A data object containing MessagePack data. Does not include Ext metadata or type.
 @param type The type of the Ext data. This should be a type that was registered previously.
 @return An object from the MessagePack data in data, or nil if an error occurs.
 */
- (id)initWithMessagePackExtData:(NSData *)data type:(uint8_t)type;

- (uint8_t)messagePackExtType;
- (NSData *)messagePackExtData;

@end
