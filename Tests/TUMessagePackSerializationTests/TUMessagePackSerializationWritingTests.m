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

- (void)testPositiveFixintWriting
{
    [self _testWritingWithValue:@42 type:@"PositiveFixint"];
}

- (void)testNegativeFixintWriting
{
    [self _testWritingWithValue:@-28 type:@"NegativeFixint"];
}


#pragma mark - Bool

- (void)testPositiveTrueWriting
{
    [self _testWritingWithValue:@YES type:@"True"];
}

- (void)testPositiveFalseWriting
{
    [self _testWritingWithValue:@NO type:@"False"];
}


#pragma mark - Nil

- (void)testNilWriting
{
    [self _testWritingWithValue:[NSNull null] type:@"Nil"];
}

@end
