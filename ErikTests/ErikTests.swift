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
import Kanna

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
        let jsString = "1;"


        let visitExpectation = self.expectationWithDescription("visit")
        let javaScriptExpectation = self.expectationWithDescription("js")

        Erik.visitURL(url) { (obj, err) -> Void in
            visitExpectation.fulfill()
            if let error = err {
               print(error)
            }
            
            if let doc = obj as? HTMLDocument {
                print(doc)
                for input in doc.xpath("input[@id='st-ib']") {
                    print(input.text)
                }
            }
            // else this is an error ?
            
            Erik.evaluateJavaScript(jsString) { (obj, err) -> Void in
                print(obj)
                if let error = err {
                    print(error)
                }
                else {
                     javaScriptExpectation.fulfill()
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(500, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })
    }
    
}