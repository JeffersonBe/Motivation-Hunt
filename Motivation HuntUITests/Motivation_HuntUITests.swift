//
//  Motivation_HuntUITests.swift
//  Motivation HuntUITests
//
//  Created by Jefferson Bonnaire on 24/10/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import XCTest
import UIKit

class Motivation_HuntUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {

        let app = XCUIApplication()
        app.buttons["skipButton"].tap()
        //waitForHittable(element: app.buttons["skipButton"], waitSeconds: 2)
        
        // Motivation Feed Screen
        
        let device = UIDevice.current.model
        
        if (device == "iPad" || device == "iPad Simulator") {
            let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
            element.children(matching: .other).element(boundBy: 1).collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
            
            let collectionView = element.children(matching: .collectionView).element
            let button = collectionView.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0)
            button.tap()
            collectionView.children(matching: .cell).element(boundBy: 5).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0).tap()
            collectionView.tap()
            
            let button2 = collectionView.children(matching: .cell).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0)
            button2.tap()
            app.collectionViews.staticTexts["Love"].tap()
            button2.tap()
            collectionView.children(matching: .cell).element(boundBy: 3).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0).tap()
            collectionView.children(matching: .cell).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0).tap()
            app.collectionViews.staticTexts["Success"].tap()
            snapshot("01MotivationFeedScreen")
        } else {
            let element2 = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
            let collectionViewsQuery = element2.children(matching: .other).element(boundBy: 1).collectionViews
            collectionViewsQuery.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .image).element.tap()
            
            let collectionView = element2.children(matching: .collectionView).element
            let button = collectionView.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0)
            button.tap()
            
            let element3 = collectionView.children(matching: .cell).element(boundBy: 1).children(matching: .other).element
            let element = element3.children(matching: .other).element(boundBy: 0)
            element.swipeUp()
            
            let button2 = element3.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 0)
            button2.tap()
            collectionViewsQuery.children(matching: .cell).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .image).element.tap()
            button.tap()
            element.swipeUp()
            button2.tap()
            collectionViewsQuery.children(matching: .cell).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .image).element.tap()
            button.tap()
            element.swipeUp()
            collectionView.swipeUp()
            app.collectionViews.staticTexts["Success"].tap()
            snapshot("01MotivationFeedScreen")
        }
        
        // Favorites Screen
        let tabBar = app.tabBars
        tabBar.buttons["Favorites"].tap()
        snapshot("02FavoritesScreen")
        
        // Challenges Screen
        tabBar.buttons["Challenges"].tap()
        
        let AddOrCancelButton = app.navigationBars["Challenge"].buttons["AddOrCancelButton"]
        AddOrCancelButton.tap()
        
        let challengeTextField = app.textFields["challengeTextField"]
        challengeTextField.tap()
        challengeTextField.typeText("Launch Motivation Hunt on the Apple App Store")
        
        let addChallengeButton = app.buttons["addChallengeButton"]
        addChallengeButton.tap()
        
        let challengeDatePicker = app.datePickers["challengeDatePicker"]
        
        for _ in 1...2 {
            challengeDatePicker.pickerWheels.element(boundBy: 1).swipeUp()
        }
        
        for _ in 1...1 {
            challengeDatePicker.pickerWheels.element(boundBy: 2).swipeUp()
        }
        
        AddOrCancelButton.tap()
        challengeTextField.tap()
        challengeTextField.typeText("Work on my super awesome app")
        for _ in 1...3 {
            challengeDatePicker.pickerWheels.element(boundBy: 0).swipeUp()
        }
        
        for _ in 1...2 {
            challengeDatePicker.pickerWheels.element(boundBy: 1).swipeUp()
        }
        
        for _ in 1...1 {
            challengeDatePicker.pickerWheels.element(boundBy: 2).swipeUp()
        }
        snapshot("04ChallengeModalScreen")
        
        addChallengeButton.tap()
        AddOrCancelButton.tap()
        challengeTextField.tap()
        challengeTextField.typeText("Be a better person")
        for _ in 1...3 {
            challengeDatePicker.pickerWheels.element(boundBy: 0).swipeUp()
        }
        
        for _ in 1...1 {
            challengeDatePicker.pickerWheels.element(boundBy: 1).swipeUp()
        }
        
        for _ in 1...2 {
            challengeDatePicker.pickerWheels.element(boundBy: 2).swipeUp()
        }
        addChallengeButton.tap()
        
        let tablesQuery = XCUIApplication().tables
        tablesQuery.staticTexts["Launch Motivation Hunt on the Apple App Store"].swipeLeft()
        tablesQuery.buttons["Complete"].tap()
        snapshot("03ChallengeCompletedScreen")
    }
    
}
