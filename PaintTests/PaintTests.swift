//
//  PaintTests.swift
//  PaintTests
//
//  Created by Edward Huang on 10/22/17.
//  Copyright © 2017 Eddie Huang. All rights reserved.
//

import XCTest
@testable import Paint

class PaintTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRadiansAndDegreeTranslation() {
        XCTAssertEqual(Float(0).radiansToDegrees, Float(0))
        XCTAssertEqual((Float.pi * 2).radiansToDegrees, Float(360))
        XCTAssertEqual((Float.pi).radiansToDegrees, Float(180))
        XCTAssertEqual(Float(360).degreesToRadians, Float.pi * 2)
        XCTAssertEqual(Float(180).degreesToRadians, Float.pi)
    }
}
