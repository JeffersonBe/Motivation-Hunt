//
//  Motivation_HuntTests.swift
//  Motivation-HuntTests
//
//  Created by Jefferson Bonnaire on 22/09/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import XCTest

class Motivation_HuntTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test() {
        let value = 10
        XCTAssertEqual(value, 10, "ça vaut 10 frères")
    }
}
