//
//  ErikTests.swift
//  ErikTests
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import XCTest
@testable import Erik
import Eki

class ErikTests: XCTestCase {
    
    let url = NSURL(string:"http://www.google.com")!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAsync() {
        let expt = self.expectationWithDescription("Dispatch")
        
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine {
            engine.javaScriptQueue <<< {
                engine.callBackQueue <<< {
                    expt.fulfill()
                }
            }
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    
    func testSubmit() {

        let visitExpectation = self.expectationWithDescription("visit")
        let currentContentExpectation = self.expectationWithDescription("currentContent")

        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                print(error)
                
                XCTFail("\(error)")
            }
            else if let doc = obj {
                visitExpectation.fulfill()
                
                //print(doc)
                // do a google search
                for input in doc.querySelectorAll("input[name='q']") {
                    print(input)
                    
                    let value: String? = "test"
                    input["value"] = value
                    
                    Erik.currentContent { (obj, err) -> Void in
                        if let error = err {
                            print(error)
                            
                            XCTFail("\(error)")
                        }
                        else if let doc = obj {
                            if let input2 = doc.querySelector("input[name='q']") {
                                print(input2)
                                XCTAssertEqual(value, input2["value"])
                            }
                        }
                        else {
                            XCTFail("not parsable")
                        }
                        
                        for input in doc.querySelectorAll("form[name=\"f\"]") {
                            if let form = input as? Form {
                                form.submit()
                            }
                            else {
                                XCTFail("\(input) not a form")
                            }
                            
                            
                            Erik.currentContent {[unowned self] (obj, err) -> Void in
                                if let error = err {
                                    print(error)
                                    XCTFail("\(error)")
                                }
                                else if let doc = obj {
                                    print(doc)
                                    currentContentExpectation.fulfill()
                                    
                                    XCTAssertNotEqual(self.url, Erik.currentURL)
                                    
                                    XCTAssertNotNil("\(Erik.currentURL)".rangeOfString(value!))
                                }
                            }
                        }

                    }
                }
                
                
            }
        }
        
        self.waitForExpectationsWithTimeout(100, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
 
    func testJavascriptError() {
        let visitExpectation = self.expectationWithDescription("visit")
        
        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                XCTFail("\(error)")
            }
            else if let _ = obj {
                Erik.evaluateJavaScript("zae;azeaze") { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.JavaScriptError:
                            visitExpectation.fulfill()
                        default :
                            print(error)
                            XCTFail("Wrong error type")
                            break
                        }
                    }
                    else if let _ = obj {
                        XCTFail("Object must not be returned without errors")
                    }
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(100, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    func testJavascriptTimeOut() {
        let visitExpectation = self.expectationWithDescription("visit")
        
        var timeoutPrevious: NSTimeInterval = 20
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine {
            timeoutPrevious = engine.javaScriptWaitTime
            engine.javaScriptWaitTime = 1
        }
        
        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                XCTFail("\(error)")
            }
            else if let _ = obj {
                var source = "function sleep(milliseconds) {"
                source +=      "var start = new Date().getTime();"
                source +=      "for (var i = 0; i < 1e7; i++) {"
                source +=        "if ((new Date().getTime() - start) > milliseconds){"
                source +=           "break;"
                source +=        "}"
                source +=      "}"
                source +=    "}"
                source +=    "sleep(10);"
                Erik.evaluateJavaScript(source) { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.TimeOutError:
                            visitExpectation.fulfill()
                        default :
                            print(error)
                            XCTFail("Wrong error type")
                            break
                        }
                    }
                    else if let _ = obj {
                        XCTFail("Object must not be returned")
                    }
                    else {
                        visitExpectation.fulfill() // Currently ErikError.TimeOutError could not occur
                    }
                }
            }
        }

        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine {
            engine.javaScriptWaitTime = timeoutPrevious
        }
        self.waitForExpectationsWithTimeout(100, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }

    
    
    func testContentAtStart() {
        let expectation = self.expectationWithDescription("start content")
        let erik = Erik()
        erik.currentContent {(obj, err) -> Void in
            if let _ = obj {
                expectation.fulfill() // currently there is always a content
            }
            else if let error = err {
                switch error {
                case ErikError.NoContent:
                    // expectation.fulfill()
                    break
                default :
                    print(error)
                    break
                }
                XCTFail("Wrong error type \(error)")
            }

        }
        
        self.waitForExpectationsWithTimeout(100, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
}