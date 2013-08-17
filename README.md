# TUMessagePackSerialization

You use the TUMessagePackSerialization class to convert [MessagePack](http://msgpack.org) to Foundation objects and convert Foundation objects to MessagePack.
 
 An object that may be converted to MessagePack must have the following properties:
 
 - All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull, or conform to the TUMessagePackExt protocol and register the class with +registerExtWithClass:type:.
 - Numbers are not NaN or infinity.
 
 While MessagePack does not place *any* limitation on dictionary/map keys, some libraries and languages may not be able to interpret all types.
 This class can use an of the buit in types as a key, but may not be able to use ext objects if they do not conform to the NSCopying protocol.
 
 It is the goal of this class to never throw an exception, and to always return an error when there is an issue.
 However, there is at least 1 case where +messagePackObjectWithData:options:error: will return nil, but not an error.
 That is when data contains a single, null object and TUMessagePackReadingNSNullAsNil is set.
 For this reason, you should check if error is nil, and not the returned value.