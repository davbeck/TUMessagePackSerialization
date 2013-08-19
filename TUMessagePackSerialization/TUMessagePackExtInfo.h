//
//  TUMessagePackExtInfo.h
//  TUMessagePackSerialization
//
//  Created by David Beck on 8/16/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TUMessagePackExt.h"


/** TUMessagePackExtInfo is a baisc wrapper around MessagePack Ext data. Use this when you do not want to register a class to handle Ext data.
 */


@interface TUMessagePackExtInfo : NSObject <TUMessagePackExt>

@end
