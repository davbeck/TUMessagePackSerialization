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

- (void)_testReadingWithType:(NSString *)testType expectedValue:(id)expectedValue additionalTests:(void(^)(id result))additionalTests options:(TUMessagePackReadingOptions)options
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    NSError *error = nil;
    id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments | options error:&error];
    
    XCTAssertNil(error, @"Error reading %@: %@", testType, error);
    
    XCTAssertEqualObjects(result, expectedValue, @"%@ value incorrect (%@)", testType, result);
    
    if (additionalTests != nil) {
        additionalTests(result);
    }
}

- (void)_testReadingWithType:(NSString *)testType expectedValue:(id)expectedValue additionalTests:(void(^)(id result))additionalTests
{
    [self _testReadingWithType:testType expectedValue:expectedValue additionalTests:additionalTests options:0];
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


#pragma mark - Floating point

// float reading test will go here when we can create the test file some how

- (void)testDoubleReading
{
    [self _testReadingWithType:@"Double" expectedValue:@5672562398523.6523];
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


#pragma mark - Strings

- (void)testFixstr
{
    [self _testReadingWithType:@"Fixstr" expectedValue:@"test"];
}

// Str8 reading test will go here when we can create the test file some how

- (void)testStr16
{
    [self _testReadingWithType:@"Str16" expectedValue:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tempus aliquet augue a scelerisque. Ut viverra velit nisl, sit amet convallis arcu iaculis id. Curabitur semper, nibh ut ornare hendrerit, orci massa facilisis velit, eget tincidunt enim velit non tellus. Class aptent taciti sociosqu ad litora torquent metus."];
}

- (void)testStr32
{
    NSString *testString = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Str32" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
    
    [self _testReadingWithType:@"Str32" expectedValue:testString];
}

- (void)testMutableLeaves
{
    [self _testReadingWithType:@"Fixstr" expectedValue:@"test" additionalTests:^(id result) {
        XCTAssertTrue([result isKindOfClass:[NSMutableString class]], @"Returned string is not mutable when passing TUMessagePackReadingMutableLeaves.");
    } options:TUMessagePackReadingMutableLeaves];
}

- (void)testStringAsData
{
    NSData *testString = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Str32" ofType:@"txt"]];
    
    [self _testReadingWithType:@"Str32" expectedValue:testString additionalTests:nil options:TUMessagePackReadingStringsAsData];
}

- (void)testMutableLeavesAsData
{
    NSData *testString = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Str32" ofType:@"txt"]];
    
    [self _testReadingWithType:@"Str32" expectedValue:testString additionalTests:^(id result) {
        XCTAssertTrue([result isKindOfClass:[NSMutableData class]], @"Returned data is not mutable when passing TUMessagePackReadingMutableLeaves.");
    } options:TUMessagePackReadingStringsAsData | TUMessagePackReadingMutableLeaves];
}


#pragma mark - Bin

// Bin8|16|32 reading test will go here when we can create the test file some how


#pragma mark - Array

- (void)testFixarray
{
    [self _testReadingWithType:@"Fixarray" expectedValue:@[@1, @"b", @3.5]];
}

- (void)testArray16
{
    NSMutableArray *testArray = [[NSMutableArray alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 200; i++) {
        [testArray addObject:@(i)];
    }
    
    [self _testReadingWithType:@"Array16" expectedValue:testArray];
}

- (void)testArray32
{
    NSMutableArray *testArray = [[NSMutableArray alloc] initWithCapacity:82590];
    for (NSUInteger i = 1; i <= 82590; i++) {
        [testArray addObject:@(i)];
    }
    
    [self _testReadingWithType:@"Array32" expectedValue:testArray];
}


#pragma mark - Map (Dictionary)

- (void)testFixMap
{
    [self _testReadingWithType:@"Fixmap" expectedValue:@{ @"key": @"value", @"one": @1, @"float": @2.8 }];
}

- (void)testMap16
{
    NSMutableDictionary *testMap = [[NSMutableDictionary alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 200; i++) {
        testMap[@(i)] = @(i + 100);
    }
    
    [self _testReadingWithType:@"Map16" expectedValue:testMap];
}

- (void)testMap32
{
    NSMutableDictionary *testMap = [[NSMutableDictionary alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 82590; i++) {
        testMap[@(i)] = @(i + 100);
    }
    
    [self _testReadingWithType:@"Map32" expectedValue:testMap];
}


@end
