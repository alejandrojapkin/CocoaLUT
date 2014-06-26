//
//  CocoaLUTTests.swift
//  CocoaLUTTests
//
//  Created by Wil Gieseler on 6/25/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

import XCTest
import Cocoa
import CocoaLUT

class ParserTests: XCTestCase {
    
    func LUTFromBundle(name: String, ext: String) -> LUT {
        let url = NSBundle(forClass: self.dynamicType).URLForResource(name, withExtension: ext)
        return LUT(fromURL: url)
    }
    
    func testParseCubeCrosstalk() {
        XCTAssertEqual(LUTFromBundle("crosstalk", ext: "cube").size, 17)
    }
    
    func testParseCubeHalfredIridas() {
        XCTAssertEqual(LUTFromBundle("halfred_iridas", ext: "cube").size, 17)
    }
    
    func testParseCubeIridas() {
        XCTAssertEqual(LUTFromBundle("iridas", ext: "").size, 2)
    }
    
    func testParse3DLCrosstalk() {
        XCTAssertEqual(LUTFromBundle("crosstalk", ext: "3dl").size, 17)
    }
    
    func testParse3DLHalfredTruelight() {
        XCTAssertEqual(LUTFromBundle("halfred_truelight", ext: "3dl").size, 17)
    }
    
    func testParse3DLHalfredTruelightLog() {
        XCTAssertEqual(LUTFromBundle("halfred_truelight_log", ext: "3dl").size, 17)
    }

}
