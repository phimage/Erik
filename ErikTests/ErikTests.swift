//
//  ErikTests.swift
//  ErikTests
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import XCTest
@testable import Erik
import FileKit
import BrightFutures




let url = URL(string:"https://www.google.com")!

class ErikTests: XCTestCase {
    
    #if os(OSX)
    let googleFormSelector = "f"
    #elseif os(iOS)
    let googleFormSelector = "gs"
    #endif
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testVisit() {
        
        let visitExpectation = self.expectation(description: "visit")
        
        Erik.visit(url: url) { (obj, err) -> Void in
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
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsync() {
        let expt = self.expectation(description: "Dispatch")
        
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine {
            engine.javaScriptQueue.async {
                engine.callBackQueue.async {
                    expt.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSubmit() {

        let visitExpectation = self.expectation(description: "visit")
        let inputExpectation = self.expectation(description: "getInput")
        let submitExpectation = self.expectation(description: "submit")
        let currentContentExpectation = self.expectation(description: "currentContent")

        Erik.visit(url: url) { (obj, err) -> Void in
            if let error = err {
                print(error)
                
                XCTFail("\(error)")
            }
            else if let doc = obj {
                visitExpectation.fulfill()
                
                //print(doc)
                // do a google search
                for input in doc.querySelectorAll("input[name='q']") {
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
                                XCTAssertEqual(value, input2["value"])
                            }
                        }
                        else {
                            XCTFail("not parsable")
                        }
                        print(doc.toHTML)
                        for input in doc.querySelectorAll("form[name='\(self.googleFormSelector)']") {
                            submitExpectation.fulfill()
                            if let form = input as? Form {
                                form.submit()
                            }
                            else {
                                XCTFail("\(input) not a form")
                            }
                            
                            
                            Erik.currentContent { (obj, err) -> Void in
                                if let error = err {
                                    print(error)
                                    XCTFail("\(error)")
                                }
                                else if let doc = obj {
                                    print(doc)
                                    currentContentExpectation.fulfill()
                                    
                                    XCTAssertNotEqual(url, Erik.url)
                                    let toto = "\(Erik.url)"
                                    XCTAssertTrue(toto.contains(value!))
                                }
                            }
                        }

                    }
                }
                
                
            }
        }
        
        self.waitForExpectations(timeout: 20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
 
    func testJavascriptError() {
        let visitExpectation = self.expectation(description: "visit")
        
        Erik.visit(url: url) { (obj, err) -> Void in
            if let error = err {
                XCTFail("\(error)")
            }
            else if let _ = obj {
                Erik.evaluate(javaScript: "zae;azeaze") { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.javaScriptError(let message):
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
        
        self.waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    
    func testJavascriptResult() {
        let visitExpectation = self.expectation(description: "visit")

        
        Erik.visit(url: url) { (obj, err) -> Void in
            if let error = err {
                XCTFail("\(error)")
            }
            else if let _ = obj {
                let source = "var resultErik = 1 + 1; 3 + 5;"
                Erik.evaluate(javaScript: source) { (obj, err) -> Void in
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

        self.waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }

    
    func testJavascriptTimeOut() {
        let visitExpectation = self.expectation(description: "visit")
        
        var timeoutPrevious: Int = 20
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine {
            timeoutPrevious = engine.javaScriptWaitTime
            engine.javaScriptWaitTime = 1
        }
        
        Erik.visit(url: url) { (obj, err) -> Void in
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
                Erik.evaluate(javaScript: source) { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.timeOutError:
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
        self.waitForExpectations(timeout: 20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }

    func testContentAtStart() {
        let expectation = self.expectation(description: "start content")
        let erik = Erik()
        erik.currentContent {(obj, err) -> Void in
            if let _ = obj {
                expectation.fulfill() // currently there is always a content
            }
            else if let error = err {
                switch error {
                case ErikError.noContent:
                    // expectation.fulfill()
                    break
                default :
                    print(error)
                    break
                }
                XCTFail("Wrong error type \(error)")
            }

        }
        
        self.waitForExpectations(timeout: 100, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
    
    func testSnapShot() {
        if let engine = Erik.sharedInstance.layoutEngine as? WebKitLayoutEngine,
            let data: ErikImage = engine.snapshot(CGSize(width: 600, height: 400)) {
                
                let path = Path.UserTemporary + "erik\(Date().timeIntervalSince1970).png"
                
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
        
        let visitExpectation = self.expectation(description: "visit")
        let browser = Erik()
  
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
            
            if let form = document.querySelector("form[name=\"\(self.googleFormSelector)\"]") as? Form {
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
        
        self.waitForExpectations(timeout: 20, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
        
    }
    
    
}
