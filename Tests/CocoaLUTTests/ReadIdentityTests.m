//
//  ReadIdentityTests.m
//  CocoaLUTTests
//
//  Created by Greg Cotten on 8/13/14.
//
//

#import <XCTest/XCTest.h>
#import <CocoaLUT/CocoaLUT.h>
#import "TestHelper.h"

@interface ReadIdentityTests : XCTestCase

@end

@implementation ReadIdentityTests

- (void)testReadIdentityResolveCube {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DaVinciResolve33_3D" extension:@"cube"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DaVinciResolve1024_1D" extension:@"cube"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLLustre {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Lustre17" extension:@"3dl"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Lustre17_12bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLNuke {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Nuke32_12bits" extension:@"3dl"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Nuke32_16bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentity3DLSmoke {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Smoke17_12bits" extension:@"3dl"] equalsIdentityLUT]);
}

- (void)testReadIdentityResolveDAT {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DaVinci33" extension:@"dat"] equalsIdentityLUT]);
}

- (void)testReadIdentityFSI {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_FSI64" extension:@"dat"] equalsIdentityLUT]);
}

- (void)testReadIdentityDaVinciDAVLUT {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DaVinci17" extension:@"davlut"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DaVinci33" extension:@"davlut"] equalsIdentityLUT]);
}

- (void)testReadDiscreet1D {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Discreet1D" extension:@"lut"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Nuke32_16bits" extension:@"lut"] equalsIdentityLUT]);
}

- (void)testReadIdentityOLUT {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_resolve_olut_12x6" extension:@"olut"] equalsIdentityLUT]);
}

- (void)testReadIdentityILUT {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Nuke32_16bits" extension:@"ilut"] equalsIdentityLUT]);
    XCTAssertTrue([[TestHelper loadLUT:@"identity_resolve_ilut_14x4" extension:@"ilut"] equalsIdentityLUT]);
}

- (void)testReadIdentityNucodaCMS {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_NucodaCMS33" extension:@"cms"] equalsIdentityLUT]);
}

- (void)testReadIdentityQuantel {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_Quantel33" extension:@"txt"] equalsIdentityLUT]);
}

- (void)testReadIdentityDVSClipster {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_DVSClipster17" extension:@"xml"] equalsIdentityLUT]);
}

- (void)testReadIdentityCMSTestPattern {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_CMSTestPattern33" extension:@"tiff"] equalsIdentityLUT]);
}

- (void)testReadIdentityUnwrappedCube {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_UnwrappedCube33" extension:@"tiff"] equalsIdentityLUT]);
}

- (void)testReadIdentityHaldCLUT {
    XCTAssertTrue([[TestHelper loadLUT:@"identity_HaldCLUT36" extension:@"tiff"] equalsIdentityLUT]);
}



@end
