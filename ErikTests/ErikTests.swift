//
//  ErikTests.swift
//  ErikTests
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import XCTest
#if os(OSX)
    @testable import ErikOSX // rename build name
    import AppKit
#else
   @testable import Erik
#endif

import WebKit

class ErikTests: XCTestCase {
    
    #if os(OSX)
       var window: NSWindow?
    #endif
    
    override func setUp() {
        super.setUp()
        
        #if os(OSX)
            if let webView = Erik.sharedInstance.layoutEngine as? WKWebView {
                window = NSWindow(
                    contentRect: webView.bounds,
                    styleMask: NSTitledWindowMask,
                    backing: NSBackingStoreType.Buffered,
                    `defer`: false
                )
                window?.title = "test"
                
                window?.contentView!.addSubview(webView)
                window?.makeKeyAndOrderFront(nil)
            }
        #endif
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        let url = NSURL(string:"http://www.google.com")!

        let visitExpectation = self.expectationWithDescription("visit")
        let getContentExpectation = self.expectationWithDescription("getContent")

        Erik.visitURL(url) { (obj, err) -> Void in
            if let error = err {
                print(error)
                
                XCTFail("\(error)")
            }
            else if let doc = obj {
                visitExpectation.fulfill()
                
                //print(doc)
                for input in doc.querySelectorAll("input[name=\"q\"]") {
                    print(input.innerHTML)
                    
                    input["value"] = "test"
                }
                
                for input in doc.querySelectorAll("form[name=\"f\"]") {
                    if let form = input as? Form {
                        form.submit()
                    }
                    else {
                         XCTFail("\(input) not a form")
                    }
                    
                    
                    Erik.visitURL(url) { (obj, err) -> Void in
                        if let error = err {
                            print(error)
                            
                            XCTFail("\(error)")
                        }
                        else if let doc = obj {
                            getContentExpectation.fulfill()
                            
                            print(doc)
                        }
                    }
                }
                
            }
        }
        
        self.waitForExpectationsWithTimeout(50, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
}