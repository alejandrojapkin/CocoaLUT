//
//  ReadIdentityTests.m
//  CocoaLUTTests
//
//  Created by Greg Cotten on 8/13/14.
//
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>

@interface ReadIdentityTests : XCTestCase

@end

@implementation ReadIdentityTests

- (LUT *)loadLUT:(NSString *)name extension:(NSString *)ext {
    return [LUT LUTFromURL:[[NSBundle bundleForClass: [self class]] URLForResource:name withExtension:ext]];
}



- (void)testReadIdentityResolveCube {
    XCTAssertTrue([[self loadLUT:@"identity_DaVinciResolve33_3D" extension:@"cube"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_DaVinciResolve1024_1D" extension:@"cube"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLLustre {
    XCTAssertTrue([[self loadLUT:@"identity_Lustre17" extension:@"3dl"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_Lustre17_12bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLNuke {
    XCTAssertTrue([[self loadLUT:@"identity_Nuke32_12bits" extension:@"3dl"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_Nuke32_16bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLSmoke {
    XCTAssertTrue([[self loadLUT:@"identity_Smoke17_12bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentityResolveDAT {
    XCTAssertTrue([[self loadLUT:@"identity_DaVinci33" extension:@"dat"] equalsIdentityLUT]);
}

- (void)testReadIdentityFSI {
    XCTAssertTrue([[self loadLUT:@"identity_FSI64" extension:@"dat"] equalsIdentityLUT]);
}

- (void)testReadIdentityDaVinciDAVLUT {
    XCTAssertTrue([[self loadLUT:@"identity_DaVinci17" extension:@"davlut"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_DaVinci33" extension:@"davlut"] equalsIdentityLUT]);
}

- (void)testReadDiscreet1D {
    XCTAssertTrue([[self loadLUT:@"identity_Discreet1D" extension:@"lut"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_Nuke32_16bits" extension:@"lut"] equalsIdentityLUT]);
}

- (void)testReadIdentityOLUT {
    XCTAssertTrue([[self loadLUT:@"identity_resolve_olut_12x6" extension:@"olut"] equalsIdentityLUT]);
}

- (void)testReadIdentityILUT {
    XCTAssertTrue([[self loadLUT:@"identity_Nuke32_16bits" extension:@"ilut"] equalsIdentityLUT]);
    XCTAssertTrue([[self loadLUT:@"identity_resolve_ilut_14x4" extension:@"ilut"] equalsIdentityLUT]);
}

- (void)testReadIdentityNucodaCMS {
    XCTAssertTrue([[self loadLUT:@"identity_NucodaCMS33" extension:@"cms"] equalsIdentityLUT]);
}

- (void)testReadIdentityQuantel {
    XCTAssertTrue([[self loadLUT:@"identity_Quantel33" extension:@"txt"] equalsIdentityLUT]);
}

- (void)testReadIdentityDVSClipster {
    XCTAssertTrue([[self loadLUT:@"identity_DVSClipster17" extension:@"xml"] equalsIdentityLUT]);
}

- (void)testReadIdentityCMSTestPattern {
    XCTAssertTrue([[self loadLUT:@"identity_CMSTestPattern33" extension:@"tiff"] equalsIdentityLUT]);
}

- (void)testReadIdentityUnwrappedCube {
    XCTAssertTrue([[self loadLUT:@"identity_UnwrappedCube33" extension:@"tiff"] equalsIdentityLUT]);
}

//- (void)testReadIdentityHaldCLUT {
//    XCTAssertTrue([[self loadLUT:@"identity_HaldCLUT36" extension:@"tiff"] equalsIdentityLUT]);
//}



@end
