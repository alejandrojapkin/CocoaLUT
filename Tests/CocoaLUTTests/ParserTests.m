//
//  ParserTests.m
//  CocoaLUT
//
//  Created by Wil Gieseler on 6/25/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>
#import "TestHelper.h"

@interface ParserTests : XCTestCase

@end

@implementation ParserTests



- (void)testParseCubeCrosstalk {
    XCTAssertEqual([TestHelper loadLUT:@"crosstalk" extension:@"cube"].size, 17);
}

- (void)testParseCubeHalfredIridas {
    XCTAssertEqual([TestHelper loadLUT:@"halfred_iridas" extension:@"cube"].size, 17);
}

- (void)testParseCubeIridas {
    XCTAssertEqual([TestHelper loadLUT:@"iridas" extension:@"cube"].size, 2);
}

- (void)testParse3DLCrosstalk {
    XCTAssertEqual([TestHelper loadLUT:@"crosstalk" extension:@"3dl"].size, 17);
}

- (void)testParse3DLHalfredTruelight {
    XCTAssertEqual([TestHelper loadLUT:@"halfred_truelight" extension:@"3dl"].size, 17);
}

- (void)testParse3DLHalfredTruelightLog {
    XCTAssertEqual([TestHelper loadLUT:@"halfred_truelight_log" extension:@"3dl"].size, 17);
}

@end
