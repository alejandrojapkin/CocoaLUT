//
//  ParserTests.m
//  CocoaLUT
//
//  Created by Wil Gieseler on 6/25/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>

@interface TransformAccuracyTests : XCTestCase

@end

@implementation TransformAccuracyTests


- (void)testResizeAccuracy1D {
    LUT1D *identity = [LUT1D LUTIdentityOfSize:1024 inputLowerBound:0 inputUpperBound:1];
    LUT1D *lut = [identity LUTByResizingToSize:2048];
    lut = [lut LUTByResizingToSize:4096];
    lut = [lut LUTByResizingToSize:1024];

    XCTAssert([identity equalsLUT:lut], @"1D Resize precision error.");
}

- (void)testResizeAccuracy3D {
    LUT3D *identity = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    LUT3D *lut = [identity LUTByResizingToSize:64];
    lut = [lut LUTByResizingToSize:35];
    lut = [lut LUTByResizingToSize:33];

    XCTAssert([identity equalsLUT:lut], @"3D Resize precision error.");
}

@end
