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
import FileKit
import BrightFutures

let url = NSURL(string:"https://www.google.com")!
let PageLoadedPolicy = WebKitLayoutEngine.PageLoadedPolicy.navigationDelegate

#if os(OSX)
let googleFormSelector = "f"
#elseif os(iOS)
let googleFormSelector = "gs"
#endif

class ErikTests: XCTestCase {

    
    override func setUp() {
        super.setUp()
        
        (Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine)?.pageLoadedPolicy = PageLoadedPolicy
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testVisit() {
        
        let visitExpectation = self.expectationWithDescription("visit")
        
        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                print(error)
                
                XCTFail("\(error)")
            }
            else if let _ = obj {
                XCTAssertNotNil(Erik.title)
                visitExpectation.fulfill()
                
                // XCTAssertEqual(Erik.url?.host ?? "dummy", url.host) // failed is redirected to google.XXX TODO how to force lang (request header?)
                XCTAssertEqual(Erik.url?.scheme ?? "dummy", url.scheme)
            }
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
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
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testSubmit() {

        let visitExpectation = self.expectationWithDescription("visit")
        let inputExpectation = self.expectationWithDescription("getInput")
        let submitExpectation = self.expectationWithDescription("submit")
        let currentContentExpectation = self.expectationWithDescription("currentContent")

        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                print(error)
                
                XCTFail("\(error)")
            }
            else if let docVisit = obj {
                visitExpectation.fulfill()
                
                //print(doc)
                // do a google search
                if let input = docVisit.querySelector("input[name='q']") {
                    inputExpectation.fulfill()
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
                                let currentValue = input2["value"]
                                XCTAssertEqual(value, currentValue)
                            }
                            else {
                                XCTFail("input not found ")
                            }
                            let gSelector = "form[name='\(googleFormSelector)']"
                            if let form = doc.querySelector(gSelector) as? Form {
                                submitExpectation.fulfill()
                                
                                form.submit()
                                
                                Erik.currentContent { (obj, err) -> Void in
                                    if let error = err {
                                        print(error)
                                        XCTFail("\(error)")
                                    }
                                    else if let docSubmit = obj {
                                        print(docSubmit)
                                        currentContentExpectation.fulfill()
                                        
                                        XCTAssertNotEqual(url, Erik.url)
                                        
                                        XCTAssertNotNil("\(Erik.url)".rangeOfString(value!))
                                    }
                                }
                                
                                
                            } else {
                                if let _ = docVisit.querySelector("form[name='\(googleFormSelector)']") as? Form {
                                    
                                    XCTFail("Form found before js, not after ")
                                } else {
                                    
                                    XCTFail("Form not found ")
                                }
                            }
                            
                        }
                        else {
                            XCTFail("no doc")
                        }
                    }
                    
                } else {
                    print(docVisit)
                    XCTFail("not input")
                }
            }
            
        }
        
        self.waitForExpectationsWithTimeout(30, handler: { error in
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
                        case ErikError.JavaScriptError(let message):
                            print(message)
                            visitExpectation.fulfill()
                        default :
                            print("\(error)")
                            XCTFail("Wrong error type \(error)")
                        }
                    }
                    else if let _ = obj {
                        XCTFail("Object must not be returned without errors")
                    }
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    
    func testJavascriptResult() {
        let visitExpectation = self.expectationWithDescription("visit")

        
        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                XCTFail("\(error)")
            }
            else if let _ = obj {
                let source = "var resultErik = 1 + 1; 3 + 5;"
                Erik.evaluateJavaScript(source) { (obj, err) -> Void in
                    if let error = err {
                        XCTFail("Unexpected error \(error)")
                    }
                    else if let result = obj as? Int {
                        XCTAssertEqual(2, result)
                        visitExpectation.fulfill()
                    }
                    else {
                        XCTFail("no result returned")
                    }
                }
            }
        }

        self.waitForExpectationsWithTimeout(5, handler: { error in
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
                            print("\(error)")
                            XCTFail("Wrong error type \(error)")
                        }
                    }
                    else if let result = obj {
                        XCTFail("Object \(result) must not be returned")
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
        self.waitForExpectationsWithTimeout(20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }

    func testContentAtStart() {
        let expectation = self.expectationWithDescription("start content")
        let browser = Erik()
        (browser.layoutEngine as? WebKitLayoutEngine)?.pageLoadedPolicy = PageLoadedPolicy
        browser.noContentPattern = nil
        browser.currentContent {(obj, err) -> Void in
            if let _ = obj {
                expectation.fulfill() // there is content
            }
            else if let error = err {
                XCTFail("\(error)")
            }
        }
        
        self.waitForExpectationsWithTimeout(20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    func testContentAtStartNoContent() {
        let expectation = self.expectationWithDescription("start content")
        let browser = Erik()
        (browser.layoutEngine as? WebKitLayoutEngine)?.pageLoadedPolicy = PageLoadedPolicy
        browser.currentContent {(obj, err) -> Void in
            if let _ = obj {
                XCTFail("Must have no content")
            }
            else if let error = err {
                switch error {
                case ErikError.NoContent:
                    expectation.fulfill()
                    break
                default :
                    print(error)
                    XCTFail("Wrong error type \(error)")
                    break
                }
            }
            
        }
        
        self.waitForExpectationsWithTimeout(20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    
    func testSnapShot() {
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine,
            data: ErikImage = engine.snapshot(CGSize(width: 600, height: 400)) {
                
                let path = Path.UserTemporary + "erik\(NSDate().timeIntervalSince1970).png"
                
                print("Write snapshot to \(path)")
                
                do {
                    try data |> File<ErikImage>(path: path)
                }
                catch let e {
                    XCTFail("\(e)")
                }
        }
    }

    func testFuture() {
        let value: String? = "test"
        
        let visitExpectation = self.expectationWithDescription("visit")
        let browser = Erik()
        (browser.layoutEngine as? WebKitLayoutEngine)?.pageLoadedPolicy = PageLoadedPolicy
  
        var future: Future<Document, NSError> = browser.visitURLFuture(url)
   
        future = future.flatMap { document -> Future<Document, NSError> in
            
            if let input = document.querySelector("input[name='q']") {
                input["value"] = value
            }
            return browser.currentContentFuture()
        }
        
        future = future.flatMap { document -> Future<Document, NSError> in
            
            if let input2 = document.querySelector("input[name='q']") {
                print(input2)
                XCTAssertEqual(value, input2["value"])
            }
            
            if let form = document.querySelector("form[name=\"\(googleFormSelector)\"]") as? Form {
                form.submit()
            }
            
            return browser.currentContentFuture()
        }
        
        future.onSuccess { document in
            visitExpectation.fulfill()
        }
        future.onFailure { error in
            XCTFail("\(error)")
        }
        
        self.waitForExpectationsWithTimeout(20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
        
    }
    
    
}