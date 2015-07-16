//
//  TUMessagePackSerializationTests.m
//  TUMessagePackSerializationTests
//
//  Created by David Beck on 8/10/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <TUMessagePackSerialization/TUMessagePackSerialization.h>


@interface TUMessagePackSerializationReadingTests : XCTestCase

@end

@implementation TUMessagePackSerializationReadingTests

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

- (void)_testReadingPerformanceWithType:(NSString *)testType expectedValue:(id)expectedValue additionalTests:(void(^)(id result))additionalTests options:(TUMessagePackReadingOptions)options
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    [self measureBlock:^{
        id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments | options error:NULL];
        
        if (additionalTests != nil) {
            additionalTests(result);
        }
    }];
}


#pragma mark - Fixint

- (void)testPositiveFixint
{
    [self _testReadingWithType:@"PositiveFixint" expectedValue:@42];
}

- (void)testNegativeFixint
{
    [self _testReadingWithType:@"NegativeFixint" expectedValue:@-28];
}


#pragma mark - UInt

- (void)testUInt8
{
    [self _testReadingWithType:@"UInt8" expectedValue:@250];
}

- (void)testUInt16
{
    [self _testReadingWithType:@"UInt16" expectedValue:@48516];
}

- (void)testUInt32
{
    [self _testReadingWithType:@"UInt32" expectedValue:@1299962209];
}

- (void)testUInt64
{
    [self _testReadingWithType:@"UInt64" expectedValue:@6223172016852725913];
}


#pragma mark - Int

- (void)testInt8
{
    [self _testReadingWithType:@"Int8" expectedValue:@-100];
}

- (void)testInt16
{
    [self _testReadingWithType:@"Int16" expectedValue:@-200];
}

- (void)testInt32
{
    [self _testReadingWithType:@"Int32" expectedValue:@-1299962209];
}

- (void)testInt64
{
    [self _testReadingWithType:@"Int64" expectedValue:@-6223172016852725913];
}


#pragma mark - Floating point

// float reading test will go here when we can create the test file some how

- (void)testDouble
{
    [self _testReadingWithType:@"Double" expectedValue:@5672562398523.6523];
}


#pragma mark - Nil

- (void)testNil
{
    [self _testReadingWithType:@"Nil" expectedValue:[NSNull null]];
}

- (void)testNilOption
{
    NSData *example = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"Nil" withExtension:@"msgpack"]];
    
    NSError *error = nil;
    id result = [TUMessagePackSerialization messagePackObjectWithData:example options:TUMessagePackReadingAllowFragments | TUMessagePackReadingNSNullAsNil error:&error];
    
    XCTAssertNil(error, @"Error reading Nil with nil option: %@", error);
    
    XCTAssertTrue(result == nil, @"Nil value incorrect (%@)", result);
}


#pragma mark - Bool

- (void)testTrue
{
    [self _testReadingWithType:@"True" expectedValue:@YES additionalTests:^(id result) {
        XCTAssertEqual((id)kCFBooleanTrue, result, @"True does not equeal kCFBooleanTrue constant");
    }];
}

- (void)testFalse
{
    [self _testReadingWithType:@"False" expectedValue:@NO additionalTests:^(id result) {
        XCTAssertEqual((id)kCFBooleanFalse, result, @"True does not equeal kCFBooleanFalse constant");
    }];
}


#pragma mark - Strings

- (void)testFixstr
{
    [self _testReadingWithType:@"Fixstr" expectedValue:@"test" additionalTests:nil];
}

// Str8 reading test will go here when we can create the test file some how

- (void)testStr16
{
    [self _testReadingWithType:@"Str16" expectedValue:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tempus aliquet augue a scelerisque. Ut viverra velit nisl, sit amet convallis arcu iaculis id. Curabitur semper, nibh ut ornare hendrerit, orci massa facilisis velit, eget tincidunt enim velit non tellus. Class aptent taciti sociosqu ad litora torquent metus." additionalTests:nil];
}

- (void)testStr32
{
    NSString *testString = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Str32" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
    
    [self _testReadingWithType:@"Str32" expectedValue:testString additionalTests:nil];
    
    [self _testReadingPerformanceWithType:@"Str32" expectedValue:testString additionalTests:nil options:0];
}

- (void)testStrMutableLeaves
{
	[self _testReadingWithType:@"Fixstr" expectedValue:@"test" additionalTests:^(id result) {
		XCTAssertNoThrow([result appendString:@"ing"], @"TUMessagePackReadingMutableLeaves should return a mutable string");
	} options:TUMessagePackReadingMutableLeaves];
	
	[self _testReadingWithType:@"Fixstr" expectedValue:@"test" additionalTests:^(id result) {
		XCTAssertThrows([result appendString:@"ing"], @"Not specifying TUMessagePackReadingMutableLeaves should return a immutable string");
	} options:0];
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
		XCTAssertNoThrow([result appendData:[@"test" dataUsingEncoding:NSUTF8StringEncoding]], @"TUMessagePackReadingMutableLeaves should return a mutable string");
	} options:TUMessagePackReadingStringsAsData | TUMessagePackReadingMutableLeaves];
	
	// there seems to be a bug in NSData that allows you to mutate it, even if it isn't created as an NSMutableData
//	[self _testReadingWithType:@"Str32" expectedValue:testString additionalTests:^(id result) {
//		XCTAssertThrows([result appendData:[@"test" dataUsingEncoding:NSUTF8StringEncoding]], @"Not specifying TUMessagePackReadingMutableLeaves should return a immutable string");
//	} options:TUMessagePackReadingStringsAsData];
}


#pragma mark - Bin

- (void)testBin8
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin8" ofType:@"txt"]];
    
    [self _testReadingWithType:@"Bin8" expectedValue:testData additionalTests:nil];
}

- (void)testBin16
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin16" ofType:@"rtf"]];
    
    [self _testReadingWithType:@"Bin16" expectedValue:testData additionalTests:nil];
}

- (void)testBin32
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin32" ofType:@"pages"]];
    
    [self _testReadingWithType:@"Bin32" expectedValue:testData additionalTests:nil];
}


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
    
    [self _testReadingPerformanceWithType:@"Array32" expectedValue:testArray additionalTests:nil options:0];
}

- (void)testArrayMutableContainers
{
	[self _testReadingWithType:@"Fixarray" expectedValue:@[@1, @"b", @3.5] additionalTests:^(id result) {
		XCTAssertNoThrow([result addObject:@1], @"TUMessagePackReadingMutableContainers should return a mutable array");
	} options:TUMessagePackReadingMutableContainers];
	
	
	[self _testReadingWithType:@"Fixarray" expectedValue:@[@1, @"b", @3.5] additionalTests:^(id result) {
		XCTAssertThrows([result addObject:@1], @"Not specifying TUMessagePackReadingMutableContainers should return a immutable array");
	} options:0];
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
    
    [self _testReadingPerformanceWithType:@"Map32" expectedValue:testMap additionalTests:nil options:0];
}

- (void)testMapMutableContainers
{
	[self _testReadingWithType:@"Fixmap" expectedValue:@{ @"key": @"value", @"one": @1, @"float": @2.8 } additionalTests:^(id result) {
		XCTAssertNoThrow([result setObject:@1 forKey:@"setObject"], @"TUMessagePackReadingMutableContainers should return a mutable map");
	} options:TUMessagePackReadingMutableContainers];
	
	
	[self _testReadingWithType:@"Fixmap" expectedValue:@{ @"key": @"value", @"one": @1, @"float": @2.8 } additionalTests:^(id result) {
		XCTAssertThrows([result setObject:@1 forKey:@"setObject"], @"Not specifying TUMessagePackReadingMutableContainers should return a immutable map");
	} options:0];
}


#pragma mark - Ext

// Ext reading test will go here when we can create the test file some how


#pragma mark - Test Twitter

// this is our 'real world' test that brings it all together
- (void)testTwitter
{
    NSData *twitterData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Twitter" withExtension:@"json"]];
    id twitter = [NSJSONSerialization JSONObjectWithData:twitterData options:0 error:NULL];
    
    [self _testReadingWithType:@"Twitter" expectedValue:twitter];
    
    [self _testReadingPerformanceWithType:@"Twitter" expectedValue:twitter additionalTests:nil options:0];
}

@end





























