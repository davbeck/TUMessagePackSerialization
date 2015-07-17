# TUMessagePackSerialization for Objective-C

[![Version](http://cocoapod-badges.herokuapp.com/v/TUMessagePackSerialization/badge.png)](http://cocoadocs.org/docsets/TUMessagePackSerialization)
[![Platform](http://cocoapod-badges.herokuapp.com/p/TUMessagePackSerialization/badge.png)](http://cocoadocs.org/docsets/TUMessagePackSerialization)

[MessagePack: It's like JSON. but fast and small.](http://msgpack.org)

MessagePack is an awesome format and alternative to JSON that stores data in binary instead of plain text. For many languages, including Objective-C, the format that is stored is nearly identical to the raw format that is used by the language to store the data in memory and use it. Because of this, it should be much faster to decode and encode because in many cases you are just doing a memory copy from one place to another.

At least, that is the theory, when I started exploring using MessagePack on iOS, I found that the official ObjC library was actually *slower* than the built in `NSJSONSerialization`. In part, that is because Apple has done a really good job at optomizing their JSON parser, but I felt it should be faster. Here's some stats taken from various serialization options using samples of various api responses:

![Serialization stats](http://davbeck.s3.amazonaws.com/TUMessagePackSerialization-Stats.svg)

Note that I tried to get a comparison to [`plists`](https://en.wikipedia.org/wiki/Property_list), but they don't support `null`, which makes translating api results difficult. When I was able to get it to work, it was much slower than the other options.

## Usage

### Encoding objects as MessagePack data

```objc
NSError *error = nil;
NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:value options:0 error:&error];
```

### Decoding MessagePack data as objects

```objc
NSError *error = nil;
id result = [TUMessagePackSerialization messagePackObjectWithData:example options:0 error:&error];
```

----

To run the tests project; clone the repo, and run `pod install` from the Project directory first.

You use the TUMessagePackSerialization class to convert [MessagePack](http://msgpack.org) to Foundation objects and convert Foundation objects to MessagePack.
 
 An object that may be converted to MessagePack must have the following properties:
 
 - All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull, or conform to the TUMessagePackExt protocol and register the class with +registerExtWithClass:type:.
 - Numbers are not NaN or infinity.
 
 While MessagePack does not place *any* limitation on dictionary/map keys, some libraries and languages may not be able to interpret all types.
 This class can use any of the built in types as a key, but may not be able to use ext objects if they do not conform to the NSCopying protocol.
 
 It is the goal of this class to never throw an exception, and to always return an error when there is an issue.
 However, there is at least 1 case where +messagePackObjectWithData:options:error: will return nil, but not an error.
 That is when data contains a single, null object and TUMessagePackReadingNSNullAsNil is set.
 For this reason, you should check if error is nil, and not the returned value.

## Requirements

The tests require Xcode 5, but the actual library has been tested on iOS 6 and should work on previous versions as well.

## Installation

TUMessagePackSerialization is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "TUMessagePackSerialization", '~> 1.0'

## Author

David Beck ([@davbeck](http://twitter.com/davbeck))

## License

TUMessagePackSerialization is available under the MIT license. See the LICENSE file for more info.

