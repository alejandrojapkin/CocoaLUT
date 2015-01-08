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
#import <CocoaLUT/LUTColorSpace.h>
#import "TestHelper.h"

@interface TransformAccuracyTests : XCTestCase

@end

@implementation TransformAccuracyTests


- (void)testResizeAccuracy1DIdentity {
    LUT1D *identity = [LUT1D LUTIdentityOfSize:1024 inputLowerBound:0 inputUpperBound:1];
    LUT1D *lut = [identity LUTByResizingToSize:2048];
    lut = [lut LUTByResizingToSize:4096];
    lut = [lut LUTByResizingToSize:1024];

    XCTAssert([identity equalsLUT:lut], @"1D Resize precision error.");
}

- (void)testResizeAccuracy3DIdentity {
    LUT3D *identity = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    LUT3D *lut = [identity LUTByResizingToSize:64];
    lut = [lut LUTByResizingToSize:35];
    lut = [lut LUTByResizingToSize:33];

    XCTAssert([identity equalsLUT:lut], @"3D Resize precision error.");
}

- (void)testResizeAccuracy3DComplex {
    LUT3D *lut33 = (LUT3D *)[TestHelper loadLUT:@"AlexaV3_K1S1_LogC2Video_Rec709_EE_33" extension:@"cube"];
    LUT3D *lut33Resized65 = [lut33 LUTByResizingToSize:65];
    
    LUT3D *lut65 = (LUT3D *)[TestHelper loadLUT:@"AlexaV3_K1S1_LogC2Video_Rec709_EE_65" extension:@"cube"];
    
    LUTColor *sMAPE = [lut33Resized65 symetricalMeanAbsolutePercentageError:lut65];
    LUTColor *maxAbsoluteError = [lut33Resized65 maximumAbsoluteError:lut65];
    LUTColor *averageAbsoluteError = [lut33Resized65 averageAbsoluteError:lut65];
    
    XCTAssert(sMAPE.red <= 0.010395 && sMAPE.green <= 0.010160 && sMAPE.blue <= 0.007201, @"3D Resize Up precision error."); //tetrahedral interpolation resize sMAPE
    XCTAssert(maxAbsoluteError.red <= 0.132559 && maxAbsoluteError.green <= 0.114145 && maxAbsoluteError.blue <= 0.078125, @"3D Resize Up precision error."); //tetrahedral interpolation resize MAE
    XCTAssert(averageAbsoluteError.red <= 0.001069 && averageAbsoluteError.green <= 0.000813 && averageAbsoluteError.blue <= 0.000516, @"3D Resize Up precision error."); //tetrahedral interpolation resize AAE
    
    
    LUT3D *lut65Resized33 = [lut65 LUTByResizingToSize:33];
    
    XCTAssert([lut65Resized33 equalsLUT:lut33],@"3D Resize Down precision error.");
    
    
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
