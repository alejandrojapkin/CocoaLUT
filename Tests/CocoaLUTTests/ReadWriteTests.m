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
#import <CocoaLUT/LUTFormatterNucodaCMS.h>
#import <CocoaLUT/LUTFormatterDiscreet1DLUT.h>
#import <CocoaLUT/LUTFormatterOLUT.h>
#import <CocoaLUT/LUTFormatterILUT.h>
#import <CocoaLUT/LUTFormatterCMSTestPattern.h>
#import <CocoaLUT/LUTFormatterUnwrappedTexture.h>
#import <CocoaLUT/LUTFormatterHaldCLUT.h>
#import <CocoaLUT/LUTFormatterFSIDAT.h>
#import <CocoaLUT/LUTFormatterResolveDAT.h>
#import "TestHelper.h"


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

- (void)testReadWriteSerializedDataRepresentation{
    LUT1D *identityLUT1D = [LUT1D LUTIdentityOfSize:2048 inputLowerBound:0 inputUpperBound:1];
    
    LUT1D *read1D = [LUT1D LUTFromDataRepresentation:[identityLUT1D dataRepresentation]];
    
    XCTAssert([read1D equalsLUT:identityLUT1D]);
    
    LUT3D *identityLUT3D = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    
    LUT3D *read3D = [LUT3D LUTFromDataRepresentation:[identityLUT3D dataRepresentation]];
    
    XCTAssert([read3D equalsLUT:identityLUT3D]);
}

- (void)testReadWriteCube1D {
    LUT1D *identityLUT = [LUT1D LUTIdentityOfSize:2048 inputLowerBound:0 inputUpperBound:1];

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

- (void)testReadWriteCube3D {
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

- (void)testReadWriteResolveDAT {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterResolveDAT formatterID]];

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

- (void)testReadWriteFSIDAT {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:64 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterFSIDAT formatterID]];

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

- (void)testReadWriteNucoda1D {
    LUT1D *identityLUT = [LUT1D LUTIdentityOfSize:2048 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterNucodaCMS formatterID]];

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

- (void)testReadWriteNucoda3D {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterNucodaCMS formatterID]];

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

- (void)testReadWriteHaldCLUT{
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:36 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterHaldCLUT formatterID]];

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

- (void)testReadWriteCMSTestPattern {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterCMSTestPattern formatterID]];

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

- (void)testReadWriteUnwrappedCube {
    LUT3D *identityLUT = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterUnwrappedTexture formatterID]];

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

- (void)testReadWriteDiscreet1D {
    LUT1D *identityLUT = [LUT1D LUTIdentityOfSize:2048 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterDiscreet1DLUT formatterID]];

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

- (void)testReadWriteILUT {
    LUT1D *identityLUT = [LUT1D LUTIdentityOfSize:16384 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterILUT formatterID]];

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

- (void)testReadWriteOLUT {
    LUT1D *identityLUT = [LUT1D LUTIdentityOfSize:4096 inputLowerBound:0 inputUpperBound:1];

    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:[LUTFormatterOLUT formatterID]];

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
