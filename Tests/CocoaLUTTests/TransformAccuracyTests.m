//
//  ParserTests.m
//  CocoaLUT
//
//  Created by Wil Gieseler on 6/25/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>
#import <CocoaLUT/LUTColorTransferFunction.h>

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

- (void)testReverse1DIdentity{
    LUT1D *identity = [LUT1D LUTIdentityOfSize:1024 inputLowerBound:0 inputUpperBound:1];

    XCTAssert([[identity LUT1DByReversingWithStrictness:YES autoAdjustInputBounds:NO] equalsLUT:identity], @"LUT1D identity reversed isn't equal to the identity.");
    ;

}

- (void)testReverse1DComplex{
    LUT1D *identity = [LUT1D LUTIdentityOfSize:1024 inputLowerBound:0 inputUpperBound:1];
    LUT1D *linearToGamma26 = (LUT1D *)[LUTColorTransferFunction transformedLUTFromLUT:identity
                          fromColorTransferFunction:[LUTColorTransferFunction linearTransferFunction]
                            toColorTransferFunction:[LUTColorTransferFunction gammaTransferFunctionWithGamma:2.6]];

    XCTAssert([[[linearToGamma26 LUT1DByReversingWithStrictness:YES autoAdjustInputBounds:NO] LUT1DByReversingWithStrictness:YES autoAdjustInputBounds:NO] equalsLUT:linearToGamma26], @"LUT1D twice reversed isn't equal to itself.");

    XCTAssert([[linearToGamma26 LUTByCombiningWithLUT:[linearToGamma26 LUT1DByReversingWithStrictness:YES autoAdjustInputBounds:NO]] equalsIdentityLUT], @"LUT1D + LUT1D Reverse isn't equal to identity.");
}

@end
