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

- (void)_testReadingWithType:(NSString *)testType expectedValue:(id)expectedValue
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    NSError *error = nil;
    id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments error:&error];
    
    XCTAssertNotNil(result, @"Error reading %@: %@", testType, error);
    
    XCTAssertTrue([result isEqual:expectedValue], @"%@ value incorrect (%@)", testType, result);
}

- (void)testPositiveFixintReading
{
    [self _testReadingWithType:@"PositiveFixint" expectedValue:@42];
}

- (void)testNegativeFixintReading
{
    [self _testReadingWithType:@"NegativeFixint" expectedValue:@-28];
}

@end
