//
//  ParserTests.m
//  CocoaLUT
//
//  Created by Wil Gieseler on 6/25/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>

@interface ParserTests : XCTestCase

@end

@implementation ParserTests

- (LUT *)loadLUT:(NSString *)name extension:(NSString *)ext {
    return [LUT LUTFromURL:[[NSBundle bundleForClass: [self class]] URLForResource:name withExtension:ext]];
}

- (void)testParseCubeCrosstalk {
    XCTAssertEqual([self loadLUT:@"crosstalk" extension:@"cube"].size, 17);
}

- (void)testParseCubeHalfredIridas {
    XCTAssertEqual([self loadLUT:@"halfred_iridas" extension:@"cube"].size, 17);
}

//- (void)testParseCubeIridas {
//    XCTAssertEqual([self loadLUT:@"iridas" extension:@"cube"].size, 17);
//}

- (void)testParse3DLCrosstalk {
    XCTAssertEqual([self loadLUT:@"crosstalk" extension:@"3dl"].size, 17);
}

- (void)testParse3DLHalfredTruelight {
    XCTAssertEqual([self loadLUT:@"halfred_truelight" extension:@"3dl"].size, 17);
}

- (void)testParse3DLHalfredTruelightLog {
    XCTAssertEqual([self loadLUT:@"halfred_truelight_log" extension:@"3dl"].size, 17);
}

@end
