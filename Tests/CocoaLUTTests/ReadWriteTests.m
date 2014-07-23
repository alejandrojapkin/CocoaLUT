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
#import <CocoaLUT/LUTFormatterQuantel.h>
#import <CocoaLUT/LUTFormatterClipster.h>

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

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterCube formatterID]];

    NSURL *lutURL = [self.class uniqueTempFileURLWithFileExtension:[[formatter class] fileExtensions][0]];

    BOOL writeSuccess = [identityLUT writeToURL:lutURL
                                     atomically:YES
                                    formatterID:[[formatter class] formatterID]
                                        options:nil
                                     conformLUT:YES];

    XCTAssert(writeSuccess && [lutURL checkResourceIsReachableAndReturnError:nil], @"LUT didn't write successfully.");

    XCTAssertEqual([LUTFormatter LUTFormatterValidForReadingURL:lutURL], [formatter class], @"LUT isn't recognized with the correct formatter.");

    LUT *readLUT = [LUT LUTFromURL:lutURL];

    [[NSFileManager defaultManager] removeItemAtURL:lutURL error:nil];

    XCTAssert([readLUT equalsLUT:identityLUT]);
}

- (void)testReadWriteQuantel {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterQuantel formatterID]];

    NSURL *lutURL = [self.class uniqueTempFileURLWithFileExtension:[[formatter class] fileExtensions][0]];

    BOOL writeSuccess = [identityLUT writeToURL:lutURL
                                     atomically:YES
                                    formatterID:[[formatter class] formatterID]
                                        options:nil
                                     conformLUT:YES];

    XCTAssert(writeSuccess && [lutURL checkResourceIsReachableAndReturnError:nil], @"LUT didn't write successfully.");

    XCTAssertEqual([LUTFormatter LUTFormatterValidForReadingURL:lutURL], [formatter class], @"LUT isn't recognized with the correct formatter.");

    LUT *readLUT = [LUT LUTFromURL:lutURL];

    [[NSFileManager defaultManager] removeItemAtURL:lutURL error:nil];

    XCTAssert([readLUT equalsLUT:identityLUT]);
    

}

- (void)testReadWriteClipster {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:17 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterClipster formatterID]];

    NSURL *lutURL = [self.class uniqueTempFileURLWithFileExtension:[[formatter class] fileExtensions][0]];

    BOOL writeSuccess = [identityLUT writeToURL:lutURL
                                     atomically:YES
                                    formatterID:[[formatter class] formatterID]
                                        options:nil
                                     conformLUT:YES];

    XCTAssert(writeSuccess && [lutURL checkResourceIsReachableAndReturnError:nil], @"LUT didn't write successfully.");

    XCTAssertEqual([LUTFormatter LUTFormatterValidForReadingURL:lutURL], [formatter class], @"LUT isn't recognized with the correct formatter.");

    LUT *readLUT = [LUT LUTFromURL:lutURL];

    [[NSFileManager defaultManager] removeItemAtURL:lutURL error:nil];

    XCTAssert([readLUT equalsLUT:identityLUT]);
    
    
}


@end
