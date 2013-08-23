//
//  TUMessagePackSerializationWritingTests.m
//  TUMessagePackSerializationTests
//
//  Created by David Beck on 8/22/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <TUMessagePackSerialization/TUMessagePackSerialization.h>


@interface TUMessagePackSerializationWritingTests : XCTestCase

@end

@implementation TUMessagePackSerializationWritingTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)_testWritingWithValue:(id)value type:(NSString *)testType additionalTests:(void(^)(id result))additionalTests options:(TUMessagePackWritingOptions)options
{
    NSData *expectedData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    NSError *error = nil;
    NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:value options:options error:&error];
    
    XCTAssertNil(error, @"Error reading %@: %@", testType, error);
    
    XCTAssertEqualObjects(result, expectedData, @"%@ value incorrect (%@)", testType, result);
    
    if (additionalTests != nil) {
        additionalTests(result);
    }
}

- (void)_testWritingWithValue:(id)value type:(NSString *)testType
{
    [self _testWritingWithValue:value type:testType additionalTests:nil options:0];
}


#pragma mark - Fixint

- (void)testPositiveFixint
{
    [self _testWritingWithValue:@42 type:@"PositiveFixint"];
}

- (void)testNegativeFixint
{
    [self _testWritingWithValue:@-28 type:@"NegativeFixint"];
}


#pragma mark - UInt

- (void)testUInt8
{
    [self _testWritingWithValue:@250 type:@"UInt8"];
}

- (void)testUInt16
{
    [self _testWritingWithValue:@48516 type:@"UInt16"];
}

- (void)testUInt32
{
    [self _testWritingWithValue:@1299962209 type:@"UInt32"];
}

- (void)testUInt64
{
    [self _testWritingWithValue:@6223172016852725913 type:@"UInt64"];
}


#pragma mark - Int

- (void)testInt8
{
    [self _testWritingWithValue:@-100 type:@"Int8"];
}

- (void)testInt16
{
    [self _testWritingWithValue:@-200 type:@"Int16"];
}

- (void)testInt32
{
    [self _testWritingWithValue:@-1299962209 type:@"Int32"];
}

- (void)testInt64
{
    [self _testWritingWithValue:@-6223172016852725913 type:@"Int64"];
}


#pragma mark - Bool

- (void)testPositiveTrue
{
    [self _testWritingWithValue:@YES type:@"True"];
}

- (void)testPositiveFalse
{
    [self _testWritingWithValue:@NO type:@"False"];
}


#pragma mark - Nil

- (void)testNil
{
    [self _testWritingWithValue:[NSNull null] type:@"Nil"];
}

@end
