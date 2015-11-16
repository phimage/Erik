//
//  WebKitTests.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import XCTest

#if os(OSX)
    import ErikOSX // rename build name
#else
    import Erik
#endif

import WebKit
import Kanna

#if os(OSX)
    import AppKit
#endif


class WebKitTests: XCTestCase {
    
    var webView: WKWebView?
    var configuration: WKWebViewConfiguration?

    override func setUp() {
        super.setUp()
        configuration = WKWebViewConfiguration()
        let frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        webView = WKWebView(frame: frame, configuration: configuration!)
    }
    
    override func tearDown() {
        super.tearDown()
        configuration = nil
        webView = nil
    }

    func testExample() {
        let url = NSURL(string:"http://www.google.com")!
        let jsString = "return 1;"
        let javaScriptEvaluator =  webView! //configuration!.userContentController
        let htmlParser = KanaParser()
        let urlBrowser = webView!
        
        
#if os(OSX)
            var window = NSWindow(webView!.bounds)
            window.contentView.addSubview(webView)
            
            window.makeKeyAndOrderFront(self)
#endif
        
        

        let visitExpectation = self.expectationWithDescription("visit")
        let javaScriptExpectation = self.expectationWithDescription("visit")

        let browser = Browser(urlBrowser: urlBrowser, htmlParser: htmlParser, javaScriptEvaluator: javaScriptEvaluator)
        browser.visitURL(url, completionHandler: { (obj, err) -> Void in
            visitExpectation.fulfill()
            
            print(obj)
            print(err)
            
            if let doc = obj as? HTMLDocument {
                /*
<input class="gsfi" id="lst-ib" maxlength="2048" name="q" autocomplete="off" title="Rechercher" type="text" value="" aria-label="Rech." aria-haspopup="false" role="combobox" aria-autocomplete="both" dir="ltr" spellcheck="false" style="border: none; padding: 0px; margin: 0px; height: auto; width: 100%; position: absolute; z-index: 6; left: 0px; outline: none; background: url(data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D) transparent;">
*/
                for input in doc.xpath("input[@id='st-ib']") {
                    
                }
                
                
            }
            // else this is an error
            
            javaScriptEvaluator.evaluateJavaScript(jsString, completionHandler: { (obj, err) -> Void in
                javaScriptExpectation.fulfill()
  
                print(obj)
                print(err)
            })
        })
        
        
        self.waitForExpectationsWithTimeout(500, handler: { error in
            XCTAssertNil(error, "Oh, we got timeout")
        })

    }



}
