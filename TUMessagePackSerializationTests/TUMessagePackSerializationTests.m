//
//  TUMessagePackSerializationTests.m
//  TUMessagePackSerializationTests
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TUMessagePackSerialization.h"


@interface TUMessagePackSerializationTests : XCTestCase

@end

@implementation TUMessagePackSerializationTests

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

- (void)_testReadingWithType:(NSString *)testType expectedValue:(id)expectedValue additionalTests:(void(^)(id result))additionalTests
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    NSError *error = nil;
    id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments error:&error];
    
    XCTAssertNil(error, @"Error reading %@: %@", testType, error);
    
    XCTAssertEqualObjects(result, expectedValue, @"%@ value incorrect (%@)", testType, result);
    
    if (additionalTests != nil) {
        additionalTests(result);
    }
}

- (void)_testReadingWithType:(NSString *)testType expectedValue:(id)expectedValue
{
    [self _testReadingWithType:testType expectedValue:expectedValue additionalTests:nil];
}


#pragma mark - Fixint

- (void)testPositiveFixintReading
{
    [self _testReadingWithType:@"PositiveFixint" expectedValue:@42];
}

- (void)testNegativeFixintReading
{
    [self _testReadingWithType:@"NegativeFixint" expectedValue:@-28];
}


#pragma mark - UInt

- (void)testUInt8Reading
{
    [self _testReadingWithType:@"UInt8" expectedValue:@250];
}

- (void)testUInt16Reading
{
    [self _testReadingWithType:@"UInt16" expectedValue:@48516];
}

- (void)testUInt32Reading
{
    [self _testReadingWithType:@"UInt32" expectedValue:@1299962209];
}

- (void)testUInt64Reading
{
    [self _testReadingWithType:@"UInt64" expectedValue:@6223172016852725913];
}


#pragma mark - Int

- (void)testInt8Reading
{
    [self _testReadingWithType:@"Int8" expectedValue:@-100];
}

- (void)testInt16Reading
{
    [self _testReadingWithType:@"Int16" expectedValue:@-200];
}

- (void)testInt32Reading
{
    [self _testReadingWithType:@"Int32" expectedValue:@-1299962209];
}

- (void)testInt64Reading
{
    [self _testReadingWithType:@"Int64" expectedValue:@-6223172016852725913];
}


#pragma mark - Nil

- (void)testNilReading
{
    [self _testReadingWithType:@"Nil" expectedValue:[NSNull null]];
}

- (void)testNilReadingOption
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"Nil" withExtension:@"msgpack"]];
    
    NSError *error = nil;
    id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments | TUMessagePackReadingNSNullAsNil error:&error];
    
    XCTAssertNil(error, @"Error reading Nil with nil option: %@", error);
    
    XCTAssertTrue(result == nil, @"Nil value incorrect (%@)", result);
}


#pragma mark - Bool

- (void)testTrueReading
{
    [self _testReadingWithType:@"True" expectedValue:@YES additionalTests:^(id result) {
        XCTAssertEqual((id)kCFBooleanTrue, result, @"True does not equeal kCFBooleanTrue constant");
    }];
}

- (void)testFalseReading
{
    [self _testReadingWithType:@"False" expectedValue:@NO additionalTests:^(id result) {
        XCTAssertEqual((id)kCFBooleanFalse, result, @"True does not equeal kCFBooleanFalse constant");
    }];
}

@end
