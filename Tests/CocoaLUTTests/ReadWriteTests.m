//
//  ParserTests.m
//  CocoaLUT
//
//  Created by Greg Cotten on 6/26/14.
//  Copyright (c) 2014 Greg Cotten. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>
#import <CocoaLUT/LUTFormatterCube.h>

@interface ReadWriteTests : XCTestCase

@end

@implementation ReadWriteTests

- (LUT *)loadLUT:(NSString *)name extension:(NSString *)ext {
    return [LUT LUTFromURL:[[NSBundle bundleForClass: [self class]] URLForResource:name withExtension:ext]];
}

+ (NSURL *)uniqueTempFileURLWithFileExtension:(NSString *)fileExtension{
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], [NSString stringWithFormat:@"file.%@", fileExtension]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    return fileURL;
    
}

- (void)testReadWriteCube {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    NSDictionary *outputOptions = [LUTFormatterCube defaultOptions];
    NSData *lutData = [identityLUT dataFromLUTWithUTIString:[LUTFormatterCube utiString] options:outputOptions];
    NSURL *lutURL = [self.class uniqueTempFileURLWithFileExtension:@".cube"];
    [lutData writeToURL:lutURL atomically:YES];
    XCTAssert([lutURL checkResourceIsReachableAndReturnError:nil], @"Cube didn't write successfully.");
    
    XCTAssertEqual([LUTFormatter LUTFormatterValidForReadingURL:lutURL], [LUTFormatterCube class], @"LUT isn't recognized as a cube.");
    
    LUT *readLUT = [LUT LUTFromURL:lutURL];
    
    XCTAssert([readLUT equalsLUT:identityLUT]);
}


@end