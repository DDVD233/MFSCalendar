//
//  MFSCalendarUITests.swift
//  MFSCalendarUITests
//
//  Created by 戴元平 on 9/21/17.
//  Copyright © 2017 David. All rights reserved.
//

import XCTest

class MFSCalendarUITests: XCTestCase {
    let app = XCUIApplication()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITEST"]
        app.launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
//        let app = app2
//        let usernameTextField = app.textFields["Username"]
//        usernameTextField.tap()
//        usernameTextField.typeText("")
//        usernameTextField.typeText("WeiD")
//
//        let passwordSecureTextField = app.secureTextFields["Password"]
//        passwordSecureTextField.tap()
//        passwordSecureTextField.tap()
//        passwordSecureTextField.typeText("torsan89")
//        app.buttons["LOG IN"].tap()
//        app.tabBars.buttons["Homework"].tap()
//        app.tables.children(matching: .cell).element(boundBy: 0).children(matching: .textView).element.tap()
//
//        let app2 = app
//        app2.tables/*@START_MENU_TOKEN@*/.buttons["More Info"]/*[[".cells.buttons[\"More Info\"]",".buttons[\"More Info\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app2.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["TOPICS"]/*[[".cells.staticTexts[\"TOPICS\"]",".staticTexts[\"TOPICS\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .collectionView).element.tap()
//
        
                
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
