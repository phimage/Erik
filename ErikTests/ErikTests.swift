//
//  ErikTests.swift
//  ErikTests
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import XCTest
#if os(OSX)
   @testable  import ErikOSX // rename build name
#else
   @testable  import Erik
#endif

import Kanna

class ErikTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
class TestBrowser : URLBrowser, JavaScriptEvaluator, ErikOSX.HTMLParser {
    func browseURL(URL: NSURL, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        completionHandler?(toHTML, nil)
    }
    var resources: Bool {return true}
    
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        completionHandler?("", nil)
    }
    func parseHTML(html: String) -> HTMLDocument? {
        return nil // self
    }
    var toHTML: String? { return "<html></html>" }
}
/*
extension TestBrowser: HTMLDocument {
    var title: String? { return "title" }
    var head: XMLElement? { return nil }
    var body: XMLElement? { return nil }
    
    var text: String? { return "" }
    var innerHTML: String? { return "" }
    var className: String? { return "" }
    var tagName:   String? { return "" }
    
    func xpath(xpath: String, namespaces: [String:String]?) -> XMLNodeSet { return XMLNodeSet() }
    func xpath(xpath: String) -> XMLNodeSet { return XMLNodeSet() }
    func at_xpath(xpath: String, namespaces: [String:String]?) -> XMLElement? { return nil }
    func at_xpath(xpath: String) -> XMLElement? { return nil }
 
    func css(selector: String, namespaces: [String:String]?) -> XMLNodeSet { return XMLNodeSet() }
    func css(selector: String) -> XMLNodeSet { return XMLNodeSet() }
    func at_css(selector: String, namespaces: [String:String]?) -> XMLElement? { return nil }
    func at_css(selector: String) -> XMLElement? { return nil }
}
*/